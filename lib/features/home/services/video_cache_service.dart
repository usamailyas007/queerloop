import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';

import '../models/reel_item_model.dart';

enum VideoSourceType { file, network, asset, none }

class ResolvedVideoSource {
  const ResolvedVideoSource._({
    required this.type,
    this.file,
    this.uri,
    this.assetPath,
    this.formatHint,
    this.isLocalCache = false,
  });

  final VideoSourceType type;
  final File? file;
  final Uri? uri;
  final String? assetPath;
  final VideoFormat? formatHint;
  final bool isLocalCache;

  factory ResolvedVideoSource.file(File file, {bool isLocalCache = false}) =>
      ResolvedVideoSource._(
        type: VideoSourceType.file,
        file: file,
        isLocalCache: isLocalCache,
      );

  factory ResolvedVideoSource.network(Uri uri, {VideoFormat? formatHint}) =>
      ResolvedVideoSource._(
        type: VideoSourceType.network,
        uri: uri,
        formatHint: formatHint,
      );

  factory ResolvedVideoSource.asset(String assetPath) => ResolvedVideoSource._(
        type: VideoSourceType.asset,
        assetPath: assetPath,
      );

  factory ResolvedVideoSource.none() =>
      const ResolvedVideoSource._(type: VideoSourceType.none);
}

/// Central video caching and adaptive quality service.
/// - Selects video quality (360p / 480p on slow/mobile data, 720p on WiFi).
/// - Saves loaded videos to local disk cache so offline & future loads need NO internet.
class VideoCacheService {
  VideoCacheService._();
  static final VideoCacheService instance = VideoCacheService._();

  Directory? _cacheDir;
  final Set<String> _currentlyCaching = <String>{};
  final Map<String, String> _resolvedAdaptiveUrls = <String, String>{};
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 2),
    ),
  );

  /// Initialize local cache directory on app start
  Future<void> init() async {
    try {
      final Directory docDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${docDir.path}/reels_cache');
      if (!_cacheDir!.existsSync()) {
        _cacheDir!.createSync(recursive: true);
      }
    } catch (_) {}
  }

  String _cleanKey(String id) {
    return id.replaceAll(RegExp(r'[^\w\-]'), '_');
  }

  /// Check if local cached file exists for this reel/video
  File? getLocalCachedFile(String id) {
    if (_cacheDir == null) return null;
    final String clean = _cleanKey(id);
    final File f = File('${_cacheDir!.path}/$clean.mp4');
    if (f.existsSync() && f.lengthSync() > 10240) {
      return f;
    }
    return null;
  }

  /// Check connection to determine if user is on mobile/slow data or WiFi
  Future<bool> isMobileOrSlowNetwork() async {
    try {
      final List<ConnectivityResult> results =
          await Connectivity().checkConnectivity();
      if (results.contains(ConnectivityResult.mobile)) {
        return true;
      }
      if (results.contains(ConnectivityResult.none) || results.isEmpty) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Resolves the optimal streaming URL based on internet speed (adaptive bitrate)
  Future<String> resolveAdaptiveUrl(String originalUrl) async {
    if (!originalUrl.contains('.m3u8')) {
      return originalUrl;
    }

    if (_resolvedAdaptiveUrls.containsKey(originalUrl)) {
      return _resolvedAdaptiveUrls[originalUrl]!;
    }

    final bool isMobile = await isMobileOrSlowNetwork();

    try {
      final Uri playlistUri = Uri.parse(originalUrl);
      final Response<String> response = await _dio
          .get<String>(
            originalUrl,
            options: Options(responseType: ResponseType.plain),
          )
          .timeout(const Duration(seconds: 3));

      final String content = response.data ?? '';
      final List<String> lines = content.split('\n');
      final bool isMaster =
          lines.any((String l) => l.startsWith('#EXT-X-STREAM-INF'));

      if (isMaster) {
        String? selectedVariant;
        int lowestBandwidth = 999999999;
        int highestBandwidth = -1;
        String? lowestVariant;
        String? highestVariant;

        for (int i = 0; i < lines.length; i++) {
          final String line = lines[i].trim();
          if (line.startsWith('#EXT-X-STREAM-INF')) {
            final RegExpMatch? bwMatch =
                RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
            final int bw =
                bwMatch != null ? int.tryParse(bwMatch.group(1)!) ?? 0 : 0;

            for (int j = i + 1; j < lines.length; j++) {
              final String nextLine = lines[j].trim();
              if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
                final String resolved =
                    playlistUri.resolve(nextLine).toString();
                if (bw < lowestBandwidth && bw > 0) {
                  lowestBandwidth = bw;
                  lowestVariant = resolved;
                }
                if (bw > highestBandwidth) {
                  highestBandwidth = bw;
                  highestVariant = resolved;
                }
                // Check if line indicates 360p or 480p
                if (isMobile &&
                    (line.contains('360') ||
                        nextLine.contains('360') ||
                        line.contains('480') ||
                        nextLine.contains('480'))) {
                  selectedVariant = resolved;
                }
                break;
              }
            }
            if (selectedVariant != null) break;
          }
        }

        // On mobile / slow network, pick 360p/480p or lowest bandwidth variant
        // On fast WiFi, pick highest / 720p variant
        final String chosen = selectedVariant ??
            (isMobile ? (lowestVariant ?? originalUrl) : (highestVariant ?? originalUrl));
        _resolvedAdaptiveUrls[originalUrl] = chosen;
        return chosen;
      }
    } catch (_) {
      // Fallback directly to original URL on network error
    }

    _resolvedAdaptiveUrls[originalUrl] = originalUrl;
    return originalUrl;
  }

  /// Saves the video to local disk cache in background so next time no internet is needed
  void cacheVideoInBackground(String id, String videoUrl) {
    if (videoUrl.isEmpty) return;
    final String clean = _cleanKey(id);
    if (_currentlyCaching.contains(clean)) return;

    if (_cacheDir == null) return;
    final File destFile = File('${_cacheDir!.path}/$clean.mp4');
    if (destFile.existsSync() && destFile.lengthSync() > 10240) return;

    _currentlyCaching.add(clean);
    unawaited(_doCacheToDisk(clean, videoUrl, destFile));
  }

  Future<void> _doCacheToDisk(
    String id,
    String videoUrl,
    File destFile,
  ) async {
    final File tempFile = File('${destFile.path}.tmp');
    try {
      if (tempFile.existsSync()) {
        try {
          tempFile.deleteSync();
        } catch (_) {}
      }

      if (videoUrl.contains('.m3u8')) {
        // HLS Stream caching: parse segments and stitch into local .mp4
        final Uri playlistUri = Uri.parse(videoUrl);
        final Response<String> res = await _dio.get<String>(
          videoUrl,
          options: Options(responseType: ResponseType.plain),
        );
        final String content = res.data ?? '';
        final List<String> lines = content.split('\n');

        // Check if master playlist
        String mediaPlaylistUrl = videoUrl;
        if (lines.any((String l) => l.startsWith('#EXT-X-STREAM-INF'))) {
          // Pick lowest bandwidth variant for fast caching
          for (int i = 0; i < lines.length; i++) {
            if (lines[i].startsWith('#EXT-X-STREAM-INF')) {
              for (int j = i + 1; j < lines.length; j++) {
                final String next = lines[j].trim();
                if (next.isNotEmpty && !next.startsWith('#')) {
                  mediaPlaylistUrl = playlistUri.resolve(next).toString();
                  break;
                }
              }
              break;
            }
          }
        }

        // Get media playlist segments
        final Response<String> mediaRes = await _dio.get<String>(
          mediaPlaylistUrl,
          options: Options(responseType: ResponseType.plain),
        );
        final Uri mediaUri = Uri.parse(mediaPlaylistUrl);
        final List<String> segLines = (mediaRes.data ?? '').split('\n');
        final List<String> segUrls = <String>[];

        for (final String l in segLines) {
          final String trimmed = l.trim();
          if (trimmed.isNotEmpty && !trimmed.startsWith('#')) {
            segUrls.add(mediaUri.resolve(trimmed).toString());
          }
        }

        if (segUrls.isNotEmpty) {
          final IOSink sink = tempFile.openWrite();
          for (final String segUrl in segUrls) {
            final Response<List<int>> segRes = await _dio.get<List<int>>(
              segUrl,
              options: Options(responseType: ResponseType.bytes),
            );
            if (segRes.data != null && segRes.data!.isNotEmpty) {
              sink.add(segRes.data!);
            }
          }
          await sink.flush();
          await sink.close();
        }
      } else {
        // Direct MP4 / binary video download
        await _dio.download(videoUrl, tempFile.path);
      }

      if (tempFile.existsSync() && tempFile.lengthSync() > 10240) {
        if (destFile.existsSync()) {
          try {
            destFile.deleteSync();
          } catch (_) {}
        }
        await tempFile.rename(destFile.path);
      }
    } catch (_) {
      try {
        if (tempFile.existsSync()) tempFile.deleteSync();
      } catch (_) {}
    } finally {
      _currentlyCaching.remove(id);
    }
  }

  /// Main method: Resolves video source for playback.
  /// 1. If cached on disk -> returns local file instantly (no internet needed!).
  /// 2. If not cached -> returns adaptive quality stream URL and caches in background.
  Future<ResolvedVideoSource> resolveVideoSource(ReelItemModel reel) async {
    // 1. Direct device file if given
    if (reel.videoFilePath != null && reel.videoFilePath!.isNotEmpty) {
      final File local = File(reel.videoFilePath!);
      if (local.existsSync()) {
        return ResolvedVideoSource.file(local);
      }
    }

    // 2. Check local disk cache (WORKS OFFLINE WITHOUT INTERNET!)
    final File? cached = getLocalCachedFile(reel.id);
    if (cached != null) {
      return ResolvedVideoSource.file(cached, isLocalCache: true);
    }

    final String? videoUrl = reel.videoUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final bool isHls =
          videoUrl.contains('.m3u8') || videoUrl.contains('m3u8');

      // Resolve adaptive quality URL (360p on slow/mobile, 720p on fast)
      final String adaptiveUrl = isHls
          ? await resolveAdaptiveUrl(videoUrl)
          : videoUrl;

      // Start background caching to disk for subsequent instant offline playback
      cacheVideoInBackground(reel.id, isHls ? adaptiveUrl : videoUrl);

      final Uri uri = Uri.parse(adaptiveUrl);
      return ResolvedVideoSource.network(
        uri,
        formatHint: isHls ? VideoFormat.hls : null,
      );
    }

    if (reel.videoAsset.isNotEmpty) {
      return ResolvedVideoSource.asset(reel.videoAsset);
    }

    return ResolvedVideoSource.none();
  }
}

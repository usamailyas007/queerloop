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

  /// Check if local cached file exists for this reel/video.
  ///
  /// HLS content is NEVER cached to disk (see [resolveVideoSource]) —
  /// concatenating independently-encoded HLS segments into one file isn't
  /// reliable, confirmed with real device evidence: byte-perfect, fully
  /// 188-byte-aligned stitched files still failed to open on iOS. Any
  /// `.ts` file found here is a stale leftover from an earlier build and
  /// is always discarded, never trusted, regardless of how "valid" it
  /// looks structurally. Direct-downloaded (non-HLS) content is cached as
  /// its real format (`.mp4`).
  File? getLocalCachedFile(String id) {
    if (_cacheDir == null) return null;
    final String clean = _cleanKey(id);

    final File tsFile = File('${_cacheDir!.path}/$clean.ts');
    if (tsFile.existsSync()) {
      try {
        tsFile.deleteSync();
      } catch (_) {}
    }

    final File mp4File = File('${_cacheDir!.path}/$clean.mp4');
    if (mp4File.existsSync() && mp4File.lengthSync() > 10240) {
      if (_looksLikeRawMpegTs(mp4File)) {
        // Leftover corrupted cache from an earlier build — stitched MPEG-TS
        // segments were mislabeled with a .mp4 extension. Delete so it
        // re-caches correctly under the corrected extension.
        try {
          mp4File.deleteSync();
        } catch (_) {}
        return null;
      }
      return mp4File;
    }

    return null;
  }

  /// Raw MPEG-TS packets start with sync byte 0x47 at the start of every
  /// 188-byte packet. A genuine MP4 file never starts this way (it starts
  /// with a 4-byte box size followed by an ASCII box type like `ftyp`).
  bool _looksLikeRawMpegTs(File file) {
    try {
      final RandomAccessFile raf = file.openSync();
      final List<int> header = raf.readSync(189);
      raf.closeSync();
      return header.length > 188 && header[0] == 0x47 && header[188] == 0x47;
    } catch (_) {
      return false;
    }
  }

  /// A complete, non-corrupted stitched TS file must: start with the TS
  /// sync byte, and have a total length that's an exact multiple of 188
  /// bytes (the fixed TS packet size) — any truncation from an interrupted
  /// write breaks that alignment, which is exactly how a half-written file
  /// from an app reload gets caught here instead of being played.
  bool _isValidMpegTs(File file) {
    try {
      final int length = file.lengthSync();
      if (length < 188 || length % 188 != 0) return false;
      final RandomAccessFile raf = file.openSync();
      final List<int> header = raf.readSync(1);
      raf.closeSync();
      return header.isNotEmpty && header[0] == 0x47;
    } catch (_) {
      return false;
    }
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
        String? capVariant; // 480p — the feed-playback quality ceiling
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
                // Cap feed playback at 480p even on fast networks. This is
                // partly a performance choice (a reels-style small
                // on-screen tile doesn't benefit from 1080p) and partly a
                // reliability one right now: 480p is the only rendition
                // confirmed to have both a correctly RFC-6381-formatted
                // CODECS string and a 16-pixel-aligned width (272px,
                // 272/16=17 exactly) — 720p's master-playlist codec tag is
                // malformed (`avc1.77.30`, not valid hex) and 1080p (610px
                // width, not 16-aligned) is the exact rendition currently
                // failing to initialize on iOS. Revisit this cap once the
                // 720p/1080p encodes are confirmed clean.
                if (!isMobile &&
                    (line.contains('480') || nextLine.contains('480'))) {
                  capVariant = resolved;
                }
                break;
              }
            }
            if (selectedVariant != null) break;
          }
        }

        // On mobile / slow network, pick 360p/480p or lowest bandwidth variant.
        // On fast WiFi, prefer the 720p cap; only fall back to the true
        // highest-bandwidth variant (which may be 1080p+) if no 720p
        // rendition exists at all.
        final String chosen = selectedVariant ??
            (isMobile
                ? (lowestVariant ?? originalUrl)
                : (capVariant ?? highestVariant ?? originalUrl));
        _resolvedAdaptiveUrls[originalUrl] = chosen;
        return chosen;
      }
    } catch (_) {
      // Fallback directly to original URL on network error
    }

    _resolvedAdaptiveUrls[originalUrl] = originalUrl;
    return originalUrl;
  }

  /// Saves the video to local disk cache in background so next time no internet is needed.
  ///
  /// HLS sources get stitched from raw MPEG-TS segments, so they're saved
  /// with a `.ts` extension to match their real format — labeling stitched
  /// TS data as `.mp4` is what caused "Cannot Open: media may be damaged"
  /// on iOS. Direct (non-HLS) downloads keep `.mp4`.
  void cacheVideoInBackground(String id, String videoUrl) {
    if (videoUrl.isEmpty) return;
    final String clean = _cleanKey(id);
    if (_currentlyCaching.contains(clean)) return;

    if (_cacheDir == null) return;
    final bool isHls = videoUrl.contains('.m3u8');
    final File destFile =
        File('${_cacheDir!.path}/$clean${isHls ? '.ts' : '.mp4'}');
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

      final bool isHls = videoUrl.contains('.m3u8');
      if (isHls) {
        // HLS Stream caching: parse segments and stitch into local .ts
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

      final bool complete = tempFile.existsSync() &&
          tempFile.lengthSync() > 10240 &&
          (!isHls || _isValidMpegTs(tempFile));

      if (complete) {
        if (destFile.existsSync()) {
          try {
            destFile.deleteSync();
          } catch (_) {}
        }
        await tempFile.rename(destFile.path);
      } else {
        // Partial/corrupted write (e.g. interrupted by an app reload mid
        // segment download) — discard rather than ever finalize a file
        // that could crash native playback.
        try {
          if (tempFile.existsSync()) tempFile.deleteSync();
        } catch (_) {}
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
      // ignore: avoid_print
      print('[VIDEO_SIZE] 💽 USING CACHE FILE : id=${reel.id} path=${cached.path} size=${cached.existsSync() ? cached.lengthSync() : -1} bytes');
      return ResolvedVideoSource.file(cached, isLocalCache: true);
    }

    final String? videoUrl = reel.videoUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final bool isHls =
          videoUrl.contains('.m3u8') || videoUrl.contains('m3u8');

      // Live playback: for HLS, feed the player a specific resolution's
      // MEDIA (sub) playlist directly — NOT the master playlist.
      //
      // This backend's master playlist has a malformed CODECS attribute on
      // its 720p variant (`avc1.77.30` — old-style dot-decimal, not valid
      // RFC 6381 hex like the other three variants' `avc1.4d40xx`).
      // AVPlayer (iOS) parses every variant's codec string when it loads a
      // master playlist, even ones it never ends up selecting, and can
      // stall indefinitely on a non-conformant one; ExoPlayer (Android) is
      // far more lenient, which is why this only ever broke iOS. A media
      // playlist has no CODECS declarations at all (verified against the
      // real backend response), so going straight to one sidesteps the bad
      // variant entirely instead of working around broken manifest data.
      final String playbackUrl =
          isHls ? await resolveAdaptiveUrl(videoUrl) : videoUrl;

      // Background-cache for instant replay / offline viewing — NON-HLS
      // only. Proven, with real cached files on a real device: byte-level
      // concatenation of independently-encoded HLS segments does NOT
      // reliably produce one valid continuous TS file, even when every
      // segment is individually perfect and the result is fully
      // byte-aligned (confirmed — files that passed every integrity check
      // still failed to open on iOS identically to corrupted ones). Each
      // segment is self-contained for proper HLS streaming; concatenating
      // them for single-pass file playback isn't guaranteed to work and
      // isn't worth re-attempting. Live network streaming (above) is the
      // only reliable path for HLS now.
      if (!isHls) {
        cacheVideoInBackground(reel.id, playbackUrl);
      }

      final Uri uri = Uri.parse(playbackUrl);
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

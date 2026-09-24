import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';

import '../widgets/app_snackbar.dart';
import '../widgets/download_banner_overlay.dart';

class MediaDownloadService {
  MediaDownloadService._();

  /// Downloads an image or video (including HLS .m3u8 playlists) and saves it
  /// to the device's Photo Gallery with non-blocking TikTok-style floating banner.
  static Future<bool> downloadMedia({
    required BuildContext context,
    required String? mediaUrl,
    String? title,
    bool isVideo = false,
    bool allowDownloads = true,
    bool isCreator = false,
  }) async {
    // 1. Check if downloads are permitted
    if (!allowDownloads && !isCreator) {
      AppSnackBar.show(
        context,
        title: 'Downloads Disabled',
        subtitle: 'The creator has turned off downloads for this post.',
        type: SnackBarType.info,
      );
      return false;
    }

    if (mediaUrl == null || mediaUrl.trim().isEmpty) {
      AppSnackBar.show(
        context,
        title: 'Download Failed',
        subtitle: 'No media found to download.',
        type: SnackBarType.error,
      );
      return false;
    }

    final String cleanUrl = mediaUrl.trim();
    final bool detectedVideo = isVideo ||
        cleanUrl.endsWith('.mp4') ||
        cleanUrl.endsWith('.mov') ||
        cleanUrl.endsWith('.m3u8') ||
        cleanUrl.contains('video') ||
        cleanUrl.contains('/videos/');

    // Show non-blocking floating banner (TikTok style)
    // Scrolling, swiping and interactions are NOT blocked!
    final ValueNotifier<DownloadBannerState> bannerNotifier =
        DownloadBannerOverlay.show(
      context,
      isVideo: detectedVideo,
    );

    try {
      final String safeTitle = (title ?? 'queerloop')
          .replaceAll(RegExp(r'[^\w\-]'), '_')
          .trim();
      final int timestamp = DateTime.now().millisecondsSinceEpoch;
      final String extension = detectedVideo ? 'mp4' : 'jpg';
      final String fileName = '${safeTitle}_$timestamp.$extension';

      final Directory tempDir = await getTemporaryDirectory();
      final File tempFile = File('${tempDir.path}/$fileName');
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      final Dio dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(minutes: 5),
        ),
      );

      final bool isHls = cleanUrl.contains('.m3u8');

      if (isHls) {
        // ── 1. HLS Video Download: Extract & Concatenate all .ts segments ──
        bannerNotifier.value = DownloadBannerState(
          progress: 0.05,
          percentageText: '5%',
          statusText: 'Preparing ${detectedVideo ? "video" : "media"}... 5%',
        );

        final List<String> segments =
            await _extractHlsSegmentUrls(dio, cleanUrl);

        if (segments.isEmpty) {
          throw Exception('No playable video segments found.');
        }

        final int totalSegments = segments.length;
        final IOSink sink = tempFile.openWrite();

        try {
          for (int i = 0; i < totalSegments; i++) {
            final String segmentUrl = segments[i];
            final Response<List<int>> segRes = await dio.get<List<int>>(
              segmentUrl,
              options: Options(responseType: ResponseType.bytes),
            );

            if (segRes.data != null && segRes.data!.isNotEmpty) {
              sink.add(segRes.data!);
            }

            final double progress = (i + 1) / totalSegments;
            final int pct = (progress * 100).toInt();

            bannerNotifier.value = DownloadBannerState(
              progress: progress,
              percentageText: '$pct%',
              statusText:
                  'Downloading ${detectedVideo ? "video" : "media"}... $pct%',
            );
          }
        } finally {
          await sink.flush();
          await sink.close();
        }
      } else if (cleanUrl.startsWith('http://') ||
          cleanUrl.startsWith('https://')) {
        // ── 2. Direct Network Download (MP4 or Image) ────────────────────
        await dio.download(
          cleanUrl,
          tempFile.path,
          onReceiveProgress: (int received, int total) {
            if (total > 0) {
              final double progress = (received / total).clamp(0.0, 1.0);
              final int pct = (progress * 100).toInt();
              bannerNotifier.value = DownloadBannerState(
                progress: progress,
                percentageText: '$pct%',
                statusText:
                    'Downloading ${detectedVideo ? "video" : "photo"}... $pct%',
              );
            }
          },
        );
      } else if (cleanUrl.startsWith('assets/')) {
        // ── 3. Asset Download ──────────────────────────────────────────
        bannerNotifier.value = const DownloadBannerState(
          progress: 0.5,
          percentageText: '50%',
          statusText: 'Saving media... 50%',
        );
        final ByteData data = await rootBundle.load(cleanUrl);
        await tempFile.writeAsBytes(data.buffer.asUint8List());
      } else {
        // ── 4. Local File ──────────────────────────────────────────────
        final File localFile = File(cleanUrl);
        if (!await localFile.exists()) {
          throw Exception('Local media file does not exist.');
        }
        await localFile.copy(tempFile.path);
      }

      // ── 5. Save to Device Photo Gallery / Camera Roll ───────────────────
      bannerNotifier.value = const DownloadBannerState(
        progress: 1.0,
        percentageText: '100%',
        statusText: 'Saving to album...',
      );

      if (!kIsWeb) {
        final PermissionState ps =
            await PhotoManager.requestPermissionExtend();
        if (ps.isAuth || ps.hasAccess) {
          if (detectedVideo) {
            await PhotoManager.editor.saveVideo(
              tempFile,
              title: fileName,
            );
          } else {
            await PhotoManager.editor.saveImage(
              await tempFile.readAsBytes(),
              filename: fileName,
            );
          }
        } else {
          // Fallback to Documents Directory
          final Directory docDir = await getApplicationDocumentsDirectory();
          final File fallbackFile = File('${docDir.path}/$fileName');
          await tempFile.copy(fallbackFile.path);
        }
      }

      // Mark Complete -> Automatically animates out after 2.2s!
      bannerNotifier.value = DownloadBannerState(
        progress: 1.0,
        percentageText: '100%',
        statusText: '${detectedVideo ? "Video" : "Photo"} saved to album',
        isCompleted: true,
      );

      return true;
    } catch (e) {
      debugPrint('⚠️ [MediaDownloadService] Download error: $e');
      bannerNotifier.value = const DownloadBannerState(
        isError: true,
        errorMessage: 'Download failed. Please try again.',
      );
      return false;
    }
  }

  /// Parses an HLS Master / Media playlist and extracts all playable segment URLs.
  static Future<List<String>> _extractHlsSegmentUrls(
    Dio dio,
    String playlistUrl,
  ) async {
    final Uri playlistUri = Uri.parse(playlistUrl);
    final Response<String> response = await dio.get<String>(
      playlistUrl,
      options: Options(responseType: ResponseType.plain),
    );

    final String content = response.data ?? '';
    final List<String> lines = content.split('\n');

    // Check if it is a Multivariant (Master) playlist containing variant streams
    final bool isMaster =
        lines.any((String l) => l.startsWith('#EXT-X-STREAM-INF'));

    if (isMaster) {
      String? bestVariantUrl;
      int maxBandwidth = -1;

      for (int i = 0; i < lines.length; i++) {
        final String line = lines[i].trim();
        if (line.startsWith('#EXT-X-STREAM-INF')) {
          final RegExpMatch? match =
              RegExp(r'BANDWIDTH=(\d+)').firstMatch(line);
          final int bandwidth =
              match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;

          // Next non-comment line is the child playlist URL
          for (int j = i + 1; j < lines.length; j++) {
            final String nextLine = lines[j].trim();
            if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
              if (bandwidth > maxBandwidth || bestVariantUrl == null) {
                maxBandwidth = bandwidth;
                bestVariantUrl = playlistUri.resolve(nextLine).toString();
              }
              break;
            }
          }
        }
      }

      if (bestVariantUrl != null) {
        return _extractHlsSegmentUrls(dio, bestVariantUrl);
      }
    }

    // Media playlist: extract all media segment URLs (lines following #EXTINF)
    final List<String> segments = <String>[];
    for (int i = 0; i < lines.length; i++) {
      final String line = lines[i].trim();
      if (line.startsWith('#EXTINF:')) {
        for (int j = i + 1; j < lines.length; j++) {
          final String nextLine = lines[j].trim();
          if (nextLine.isNotEmpty && !nextLine.startsWith('#')) {
            final String resolved = playlistUri.resolve(nextLine).toString();
            segments.add(resolved);
            break;
          }
        }
      }
    }

    return segments;
  }
}

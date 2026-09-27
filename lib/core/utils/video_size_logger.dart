import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

/// Tracks, calculates, and prints video size for videos fetched on the feed.
class VideoSizeLogger {
  static final Set<String> _loggedKeys = <String>{};

  /// Format raw bytes into human readable format (e.g. "14.25 MB (14,942,208 bytes)")
  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 Bytes';
    if (bytes < 1024) return '$bytes Bytes';
    if (bytes < 1024 * 1024) {
      final double kb = bytes / 1024.0;
      return '${kb.toStringAsFixed(2)} KB ($bytes bytes)';
    }
    final double mb = bytes / (1024.0 * 1024.0);
    return '${mb.toStringAsFixed(2)} MB ($bytes bytes)';
  }

  /// Queries the remote server via HEAD or Range GET request to fetch Content-Length.
  static Future<int?> getNetworkFileSize(String url) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 4);
      final Uri uri = Uri.parse(url);

      // 1. Try HEAD request
      final HttpClientRequest headReq = await client.headUrl(uri);
      final HttpClientResponse headResp = await headReq.close();
      if (headResp.contentLength > 0) {
        return headResp.contentLength;
      }

      // 2. Fallback: Range request for byte 0
      final HttpClientRequest rangeReq = await client.getUrl(uri);
      rangeReq.headers.add('Range', 'bytes=0-0');
      final HttpClientResponse rangeResp = await rangeReq.close();

      final String? contentRange = rangeResp.headers.value('content-range');
      if (contentRange != null && contentRange.contains('/')) {
        final String totalStr = contentRange.split('/').last.trim();
        final int? total = int.tryParse(totalStr);
        if (total != null && total > 0) {
          return total;
        }
      }
      if (rangeResp.contentLength > 0) {
        return rangeResp.contentLength;
      }
    } catch (_) {
      // Ignore network errors on size probe
    } finally {
      client?.close(force: true);
    }
    return null;
  }

  /// Logs the feed video file size, resolution, and duration.
  static void logFeedVideoSize({
    required String id,
    String? title,
    String? videoUrl,
    File? file,
    String? assetPath,
    VideoPlayerController? controller,
    String stage = 'Feed',
  }) {
    unawaited(_resolveAndPrint(
      id: id,
      title: title,
      videoUrl: videoUrl,
      file: file,
      assetPath: assetPath,
      controller: controller,
      stage: stage,
    ));
  }

  static Future<void> _resolveAndPrint({
    required String id,
    String? title,
    String? videoUrl,
    File? file,
    String? assetPath,
    VideoPlayerController? controller,
    required String stage,
  }) async {
    final String dedupeKey =
        '$id-${videoUrl ?? file?.path ?? assetPath ?? controller.hashCode}';
    if (_loggedKeys.contains(dedupeKey)) return;
    _loggedKeys.add(dedupeKey);

    int? fileSizeBytes;
    String sourceType = 'Network Stream';
    String sourcePath = '';

    if (file != null && file.existsSync()) {
      sourceType = 'Local / Cached Disk File';
      sourcePath = file.path;
      try {
        fileSizeBytes = file.lengthSync();
      } catch (_) {}
    } else if (assetPath != null && assetPath.isNotEmpty) {
      sourceType = 'App Asset';
      sourcePath = assetPath;
      try {
        final ByteData data = await rootBundle.load(assetPath);
        fileSizeBytes = data.lengthInBytes;
      } catch (_) {}
    } else if (videoUrl != null && videoUrl.isNotEmpty) {
      sourceType = 'Network Stream (URL)';
      sourcePath = videoUrl;
      fileSizeBytes = await getNetworkFileSize(videoUrl);
    }

    final String formattedSize = fileSizeBytes != null
        ? formatBytes(fileSizeBytes)
        : 'Size not available via header (Streaming/HLS)';

    String dimensions = 'Unknown';
    String durationStr = 'Unknown';

    if (controller != null && controller.value.isInitialized) {
      final Size size = controller.value.size;
      dimensions = '${size.width.toInt()} x ${size.height.toInt()}';
      final Duration dur = controller.value.duration;
      final double sec = dur.inMilliseconds / 1000.0;
      durationStr = '${sec.toStringAsFixed(1)}s (${dur.inSeconds} seconds)';
    }

    // Every line starts with [VIDEO_SIZE] so it is not filtered out by main.dart
    // ignore: avoid_print
    print('[VIDEO_SIZE] ==============================================================');
    // ignore: avoid_print
    print('[VIDEO_SIZE] 🎬 FEED VIDEO    : ${title != null && title.isNotEmpty ? "$title ($id)" : id}');
    // ignore: avoid_print
    print('[VIDEO_SIZE] 📍 Status        : $stage');
    // ignore: avoid_print
    print('[VIDEO_SIZE] 📦 Source Type   : $sourceType');
    // ignore: avoid_print
    print('[VIDEO_SIZE] 📁 URL / Path    : $sourcePath');
    // ignore: avoid_print
    print('[VIDEO_SIZE] 💾 File Size     : $formattedSize');
    if (dimensions != 'Unknown') {
      // ignore: avoid_print
      print('[VIDEO_SIZE] 📐 Resolution    : $dimensions');
    }
    if (durationStr != 'Unknown') {
      // ignore: avoid_print
      print('[VIDEO_SIZE] ⏱️ Duration      : $durationStr');
    }
    // ignore: avoid_print
    print('[VIDEO_SIZE] ==============================================================');
  }
}

// Media Upload Service — manages presigned S3 URLs, direct binary upload, and media status polling.
// Interfaces with Media Service on Port 3014 and Amazon S3.

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../models/create_post_models.dart';

class MediaUploadService {
  MediaUploadService(this._apiClient, {Dio? rawDio})
      : _s3Dio = rawDio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 30),
                sendTimeout: const Duration(minutes: 5),
                receiveTimeout: const Duration(seconds: 30),
              ),
            );

  final ApiClient _apiClient;

  /// Dedicated Dio instance for direct Amazon S3 PUT requests without QueerLoop+ authorization headers.
  final Dio _s3Dio;

  // ── Step 1: Get Upload URL ────────────────────────────────────────────────
  // POST /media/upload-url (Media Service, via Gateway)
  // Request: { type: "video" | "image" }
  // Response: { uploadUrl, id / mediaId }
  Future<MediaUploadResult> getUploadUrl({
    required String fileType,
    String? filename,
    String? contentType,
    int? fileSize,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('[VIDEO_UPLOAD] ℹ️ Mock API is ON. Returning mock upload URL.');
      final String mockId = 'media_${DateTime.now().millisecondsSinceEpoch}';
      return MediaUploadResult(
        id: mockId,
        uploadUrl: 'https://mock-s3.queerloop.example/uploads/$mockId',
        status: 'pending',
      );
    }

    // Backend strictly enforces: { "type": "video" | "image" }
    final String type = fileType.toLowerCase() == 'video' ? 'video' : 'image';
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'type': type,
    };

    debugPrint(
        '[VIDEO_UPLOAD] ▶️ Requesting upload URL: type=$type filename=$filename contentType=$contentType fileSize=${fileSize != null ? '${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB' : 'n/a (not sent to backend)'}');
    final dynamic response = await _apiClient.post(
      ApiEndpoints.mediaUploadUrl,
      body: requestBody,
      timeout: const Duration(minutes: 2),
    );

    debugPrint('[VIDEO_UPLOAD] 📥 Upload URL response: $response');
    if (response is Map<String, dynamic>) {
      final MediaUploadResult result = MediaUploadResult.fromJson(response);
      debugPrint(
          '[VIDEO_UPLOAD] 🔑 Parsed media id="${result.id}" uploadUrl="${result.uploadUrl}"');
      if (result.id.trim().isEmpty) {
        debugPrint(
            '[VIDEO_UPLOAD] ⚠️ WARNING: id could not be extracted from response keys: ${response.keys}');
      }
      return result;
    }
    debugPrint(
        '[VIDEO_UPLOAD] ❌ FAILED: unexpected response shape from upload-url endpoint: $response');
    throw const ApiException('Invalid response format from upload-url endpoint.');
  }

  // ── Step 2: Upload Bytes to Amazon S3 (Direct Upload) ─────────────────────
  // PUT <uploadUrl> (No QueerLoop+ service, no Bearer auth)
  Future<void> uploadFileToS3({
    required String uploadUrl,
    required File file,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('[VIDEO_UPLOAD] ℹ️ Mock S3 upload simulating...');
      final int total = await file.length();
      onProgress?.call(total ~/ 2, total);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      onProgress?.call(total, total);
      return;
    }

    final int fileLength = await file.length();
    final double fileMb = fileLength / (1024 * 1024);
    final Stopwatch stopwatch = Stopwatch()..start();
    debugPrint(
        '[VIDEO_UPLOAD] ▶️ Starting S3 upload: path=${file.path} size=${fileMb.toStringAsFixed(2)} MB ($fileLength bytes) contentType=$contentType');
    final Stream<List<int>> stream = file.openRead();

    int lastLoggedPercent = -1;
    try {
      await _s3Dio.put<dynamic>(
        uploadUrl,
        data: stream,
        options: Options(
          headers: <String, dynamic>{
            'Content-Type': contentType,
            'Content-Length': fileLength,
          },
        ),
        onSendProgress: (int sent, int total) {
          if (total > 0) {
            final int percent = ((sent / total) * 100).floor();
            // Log every ~20% so progress is visible without flooding the console.
            if (percent >= lastLoggedPercent + 20) {
              lastLoggedPercent = percent;
              debugPrint(
                  '[VIDEO_UPLOAD] 📶 S3 upload progress: $percent% ($sent/$total bytes, ${stopwatch.elapsed.inSeconds}s elapsed)');
            }
          }
          onProgress?.call(sent, total);
        },
      );
      stopwatch.stop();
      final double speedMbps = stopwatch.elapsed.inMilliseconds > 0
          ? (fileMb * 1000) / stopwatch.elapsed.inMilliseconds
          : 0;
      debugPrint(
          '[VIDEO_UPLOAD] ✅ S3 upload complete: ${fileMb.toStringAsFixed(2)} MB in ${stopwatch.elapsed.inSeconds}s (~${speedMbps.toStringAsFixed(2)} MB/s)');
    } on DioException catch (e) {
      stopwatch.stop();
      debugPrint(
          '[VIDEO_UPLOAD] ❌ S3 upload FAILED after ${stopwatch.elapsed.inSeconds}s: status=${e.response?.statusCode} message=${e.message} responseBody=${e.response?.data}');
      throw ApiException(
        'Failed to upload media to storage: ${e.message}',
        statusCode: e.response?.statusCode,
        kind: ApiErrorKind.network,
      );
    }
  }

  // ── Step 3: Complete upload (image-only / mock-mode) ──────────────────────
  // POST /media/:id/complete (Media Service, Port 3014)
  Future<MediaUploadResult> completeUpload(String mediaId) async {
    final String cleanId = mediaId.trim();
    if (cleanId.isEmpty) {
      throw const ApiException(
        'Cannot complete media upload: mediaId is empty.',
        kind: ApiErrorKind.client,
      );
    }

    if (AppConfig.useMockApi) {
      debugPrint('[VIDEO_UPLOAD] ℹ️ Mock complete upload for $cleanId');
      return MediaUploadResult(id: cleanId, status: 'ready');
    }

    debugPrint('[VIDEO_UPLOAD] ▶️ Completing upload for media: $cleanId');
    final dynamic response = await _apiClient.post(
      ApiEndpoints.mediaComplete(cleanId),
    );
    debugPrint('[VIDEO_UPLOAD] 📥 Complete upload response: $response');
    if (response is Map<String, dynamic>) {
      return MediaUploadResult.fromJson(response);
    }
    return MediaUploadResult(id: cleanId, status: 'ready');
  }

  // ── Step 4: Poll Media Status ─────────────────────────────────────────────
  // GET /media/:id (Media Service, Port 3014)
  Future<MediaUploadResult> getMediaStatus(String mediaId) async {
    final String cleanId = mediaId.trim();
    if (cleanId.isEmpty) {
      throw const ApiException(
        'Cannot get media status: mediaId is empty.',
        kind: ApiErrorKind.client,
      );
    }

    if (AppConfig.useMockApi) {
      return MediaUploadResult(id: cleanId, status: 'ready');
    }

    final dynamic response = await _apiClient.get(
      ApiEndpoints.mediaStatus(cleanId),
      useCache: false,
    );
    // Logged RAW (not just the parsed status) because rejection reasons
    // (e.g. content-moderation failures) may be present in fields the
    // MediaUploadResult model doesn't currently parse out.
    debugPrint('[VIDEO_UPLOAD] 📡 Raw status response for $cleanId: $response');
    if (response is Map<String, dynamic>) {
      return MediaUploadResult.fromJson(response);
    }
    throw const ApiException('Invalid media status response.');
  }

  final Set<String> _cancelledMediaIds = <String>{};

  /// Cancels polling for a specific media ID, or cancels all active polls if [mediaId] is null.
  void cancelPolling([String? mediaId]) {
    if (mediaId != null && mediaId.trim().isNotEmpty) {
      _cancelledMediaIds.add(mediaId.trim());
      debugPrint('[VIDEO_UPLOAD] 🛑 Cancelled polling for: $mediaId');
    } else {
      _cancelledMediaIds.add('*');
      debugPrint('[VIDEO_UPLOAD] 🛑 Cancelled all active media polling.');
    }
  }

  /// Polls GET /media/:id until status == 'ready', cancelled, or timeout occurs.
  /// Server transcode updates status to ready upon completion.
  Future<MediaUploadResult> pollUntilReady(
    String mediaId, {
    Duration interval = const Duration(seconds: 2),
    Duration timeout = const Duration(seconds: 25),
    void Function(String status)? onStatusChange,
    bool Function()? isCancelled,
  }) async {
    final String cleanId = mediaId.trim();
    if (cleanId.isEmpty) {
      throw const ApiException(
        'Cannot poll media status: mediaId is empty.',
        kind: ApiErrorKind.client,
      );
    }

    _cancelledMediaIds.remove(cleanId);
    _cancelledMediaIds.remove('*');

    if (AppConfig.useMockApi) {
      debugPrint('[VIDEO_UPLOAD] ℹ️ Mock transcoding delay...');
      onStatusChange?.call('transcoding');
      await Future<void>.delayed(const Duration(seconds: 2));
      onStatusChange?.call('ready');
      return MediaUploadResult(id: cleanId, status: 'ready');
    }

    debugPrint(
        '[VIDEO_UPLOAD] ⏳ Starting status polling for $cleanId (timeout=${timeout.inSeconds}s, interval=${interval.inSeconds}s)...');
    final Stopwatch pollStopwatch = Stopwatch()..start();
    final DateTime deadline = DateTime.now().add(timeout);
    int consecutive404Count = 0;

    while (DateTime.now().isBefore(deadline)) {
      if (_cancelledMediaIds.contains(cleanId) ||
          _cancelledMediaIds.contains('*') ||
          (isCancelled != null && isCancelled())) {
        debugPrint('[VIDEO_UPLOAD] 🛑 Stopped polling for $cleanId: cancelled.');
        throw const ApiException(
          'Media status polling cancelled.',
          kind: ApiErrorKind.client,
        );
      }

      try {
        final MediaUploadResult current = await getMediaStatus(cleanId);
        consecutive404Count = 0;
        final String statusLower = current.status.toLowerCase();
        debugPrint(
            '[VIDEO_UPLOAD] 📡 Status poll for $cleanId: $statusLower (${pollStopwatch.elapsed.inSeconds}s elapsed)');
        onStatusChange?.call(current.status);

        if (statusLower == 'ready' ||
            statusLower == 'uploaded' ||
            statusLower == 'completed' ||
            statusLower == 'done' ||
            statusLower == 'active') {
          debugPrint(
              '[VIDEO_UPLOAD] ✅ Media $cleanId ready after ${pollStopwatch.elapsed.inSeconds}s: downloadUrl=${current.downloadUrl}');
          return current;
        }

        if (statusLower == 'failed' || statusLower == 'error') {
          // The raw response (logged above in getMediaStatus) is the place
          // to look for *why* — e.g. a content-moderation rejection — since
          // MediaUploadResult doesn't currently parse a rejection-reason
          // field out of the backend's response.
          debugPrint(
              '[VIDEO_UPLOAD] ❌ Media $cleanId REJECTED by server after ${pollStopwatch.elapsed.inSeconds}s (status=$statusLower). See the raw status response logged above for the reason.');
          throw ApiException(
            'Media transcoding failed on server.',
            kind: ApiErrorKind.server,
          );
        }
      } catch (e) {
        if (e is ApiException && e.kind == ApiErrorKind.server) rethrow;
        if (e is ApiException &&
            e.kind == ApiErrorKind.client &&
            e.message.contains('cancelled')) {
          rethrow;
        }
        if (e is ApiException && e.statusCode == 404) {
          consecutive404Count++;
          debugPrint(
              '[VIDEO_UPLOAD] ⚠️ Status poll 404 ($consecutive404Count/5) for media ID: $cleanId');
          if (consecutive404Count >= 5) {
            throw ApiException(
              'Media not found on server (404) after 5 polling attempts for ID: $cleanId',
              statusCode: 404,
              kind: ApiErrorKind.client,
            );
          }
        } else {
          debugPrint('[VIDEO_UPLOAD] ⚠️ Poll attempt error (retrying): $e');
        }
      }

      if (_cancelledMediaIds.contains(cleanId) ||
          _cancelledMediaIds.contains('*') ||
          (isCancelled != null && isCancelled())) {
        debugPrint('[VIDEO_UPLOAD] 🛑 Stopped polling for $cleanId: cancelled.');
        throw const ApiException(
          'Media status polling cancelled.',
          kind: ApiErrorKind.client,
        );
      }

      await Future<void>.delayed(interval);
    }

    debugPrint(
        '[VIDEO_UPLOAD] ❌ Media $cleanId TIMED OUT after ${pollStopwatch.elapsed.inSeconds}s with no terminal status.');
    throw const ApiException(
      'Media processing timed out. Please try again.',
      kind: ApiErrorKind.timeout,
    );
  }
}

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

  /// Dedicated Dio instance for direct Amazon S3 PUT requests without QueerLoop authorization headers.
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
      debugPrint('ℹ️ [MediaUpload] Mock API is ON. Returning mock upload URL.');
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

    debugPrint('🚀 [MediaUpload] Requesting upload URL with type: $type');
    final dynamic response = await _apiClient.post(
      ApiEndpoints.mediaUploadUrl,
      body: requestBody,
      timeout: const Duration(minutes: 2),
    );

    debugPrint('📥 [MediaUpload] Upload URL Response: $response');
    if (response is Map<String, dynamic>) {
      final MediaUploadResult result = MediaUploadResult.fromJson(response);
      debugPrint('🔑 [MediaUpload] Parsed Media ID: "${result.id}", uploadUrl: "${result.uploadUrl}"');
      if (result.id.trim().isEmpty) {
        debugPrint('⚠️ [MediaUpload] Warning: ID could not be extracted from keys: ${response.keys}');
      }
      return result;
    }
    throw const ApiException('Invalid response format from upload-url endpoint.');
  }

  // ── Step 2: Upload Bytes to Amazon S3 (Direct Upload) ─────────────────────
  // PUT <uploadUrl> (No QueerLoop service, no Bearer auth)
  Future<void> uploadFileToS3({
    required String uploadUrl,
    required File file,
    required String contentType,
    void Function(int sent, int total)? onProgress,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [MediaUpload] Mock S3 Upload simulating...');
      final int total = await file.length();
      onProgress?.call(total ~/ 2, total);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      onProgress?.call(total, total);
      return;
    }

    debugPrint('🚀 [MediaUpload] Starting direct Amazon S3 upload (size: ${await file.length()} bytes)');
    final int fileLength = await file.length();
    final Stream<List<int>> stream = file.openRead();

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
        onSendProgress: onProgress,
      );
      debugPrint('✅ [MediaUpload] Direct S3 upload complete.');
    } on DioException catch (e) {
      debugPrint('❌ [MediaUpload] S3 upload failed: ${e.message}');
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
      debugPrint('ℹ️ [MediaUpload] Mock complete upload for $cleanId');
      return MediaUploadResult(id: cleanId, status: 'ready');
    }

    debugPrint('🚀 [MediaUpload] Completing upload for media: $cleanId');
    final dynamic response = await _apiClient.post(
      ApiEndpoints.mediaComplete(cleanId),
    );
    debugPrint('📥 [MediaUpload] Complete upload response: $response');
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
      debugPrint('🛑 [MediaUpload] Cancelled polling for: $mediaId');
    } else {
      _cancelledMediaIds.add('*');
      debugPrint('🛑 [MediaUpload] Cancelled all active media polling.');
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
      debugPrint('ℹ️ [MediaUpload] Mock transcoding delay...');
      onStatusChange?.call('transcoding');
      await Future<void>.delayed(const Duration(seconds: 2));
      onStatusChange?.call('ready');
      return MediaUploadResult(id: cleanId, status: 'ready');
    }

    debugPrint('⏳ [MediaUpload] Starting status polling for $cleanId...');
    final DateTime deadline = DateTime.now().add(timeout);
    int consecutive404Count = 0;

    while (DateTime.now().isBefore(deadline)) {
      if (_cancelledMediaIds.contains(cleanId) ||
          _cancelledMediaIds.contains('*') ||
          (isCancelled != null && isCancelled())) {
        debugPrint('🛑 [MediaUpload] Stopped polling for $cleanId: cancelled.');
        throw const ApiException(
          'Media status polling cancelled.',
          kind: ApiErrorKind.client,
        );
      }

      try {
        final MediaUploadResult current = await getMediaStatus(cleanId);
        consecutive404Count = 0;
        final String statusLower = current.status.toLowerCase();
        debugPrint('📡 [MediaUpload] Status poll for $cleanId: $statusLower');
        onStatusChange?.call(current.status);

        if (statusLower == 'ready' ||
            statusLower == 'uploaded' ||
            statusLower == 'completed' ||
            statusLower == 'done' ||
            statusLower == 'active') {
          return current;
        }

        if (statusLower == 'failed' || statusLower == 'error') {
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
              '⚠️ [MediaUpload] Status poll 404 ($consecutive404Count/5) for media ID: $cleanId');
          if (consecutive404Count >= 5) {
            throw ApiException(
              'Media not found on server (404) after 5 polling attempts for ID: $cleanId',
              statusCode: 404,
              kind: ApiErrorKind.client,
            );
          }
        } else {
          debugPrint('⚠️ [MediaUpload] Poll attempt error (retrying): $e');
        }
      }

      if (_cancelledMediaIds.contains(cleanId) ||
          _cancelledMediaIds.contains('*') ||
          (isCancelled != null && isCancelled())) {
        debugPrint('🛑 [MediaUpload] Stopped polling for $cleanId: cancelled.');
        throw const ApiException(
          'Media status polling cancelled.',
          kind: ApiErrorKind.client,
        );
      }

      await Future<void>.delayed(interval);
    }

    throw const ApiException(
      'Media processing timed out. Please try again.',
      kind: ApiErrorKind.timeout,
    );
  }
}

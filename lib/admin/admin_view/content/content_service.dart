// Content moderation service — /admin/posts*, /posts/trending, /media/:id.
// Mirrors the app-side feature services (see features/profile_setup/profile_setup_service.dart).

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import 'models/content_post.dart';

class ContentService {
  const ContentService(this._client);

  final ApiClient _client;

  /// GET /admin/posts — paginated post list (1-based `page`).
  Future<ContentPostsPage> fetchPosts({
    required int page,
    required int limit,
  }) async {
    debugPrint('🚀 [ContentService] GET ${ApiEndpoints.adminPosts}?page=$page&limit=$limit');
    final dynamic data = await _client.get(
      ApiEndpoints.adminPosts,
      query: <String, dynamic>{'page': page, 'limit': limit},
      useCache: false,
    );
    return ContentPostsPage.fromJson(data as Map<String, dynamic>);
  }

  /// GET /posts/trending — a plain list, no pagination wrapper.
  Future<List<ContentPost>> fetchTrending({int limit = 6}) async {
    debugPrint('🚀 [ContentService] GET ${ApiEndpoints.postsTrending}?limit=$limit');
    final dynamic data = await _client.get(
      ApiEndpoints.postsTrending,
      query: <String, dynamic>{'limit': limit},
      useCache: false,
    );
    final List<dynamic> list = data is List<dynamic>
        ? data
        : (data is Map<String, dynamic>
            ? (data['items'] as List<dynamic>? ?? <dynamic>[])
            : <dynamic>[]);
    return list
        .map((dynamic e) => ContentPost.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /media/:id — resolve a media ref to real URLs (image url, or video
  /// stream + poster). Returns null if it can't be resolved.
  Future<MediaAsset?> fetchMedia(String id) async {
    try {
      final dynamic data =
          await _client.get(ApiEndpoints.media(id), useCache: true);
      return MediaAsset.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('⚠️ [ContentService] media $id failed: $e');
      return null;
    }
  }

  /// PATCH /admin/posts/:id/hide
  Future<void> hidePost(String id) async {
    debugPrint('🚀 [ContentService] PATCH ${ApiEndpoints.adminPostHide(id)}');
    await _client.patch(ApiEndpoints.adminPostHide(id));
  }

  /// PATCH /admin/posts/:id/restore
  Future<void> restorePost(String id) async {
    debugPrint('🚀 [ContentService] PATCH ${ApiEndpoints.adminPostRestore(id)}');
    await _client.patch(ApiEndpoints.adminPostRestore(id));
  }
}

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

  /// GET /posts/:id — a single post (author + media refs). Used to preview the
  /// content behind a report.
  ///
  /// This endpoint 404s once a post is hidden or removed — exactly the case a
  /// moderator/admin most needs to see — so a failure here falls back to
  /// paging through GET /admin/posts (capped at a few hundred) looking for a
  /// matching id, since there is no /admin/posts/:id. Returns null if the post
  /// can't be found either way (e.g. hard deleted).
  Future<ContentPost?> fetchPostById(String id) async {
    try {
      debugPrint('🚀 [ContentService] GET ${ApiEndpoints.post(id)}');
      final dynamic data =
          await _client.get(ApiEndpoints.post(id), useCache: false);
      return ContentPost.fromJson(data as Map<String, dynamic>);
    } catch (e) {
      debugPrint('⚠️ [ContentService] GET ${ApiEndpoints.post(id)} failed '
          '($e) — the post may be hidden/removed. Falling back to '
          '${ApiEndpoints.adminPosts}.');
    }

    const int pageSize = 100;
    const int maxPages = 5; // up to 500 posts — a manual, on-demand lookup.
    for (int page = 1; page <= maxPages; page++) {
      try {
        final dynamic data = await _client.get(
          ApiEndpoints.adminPosts,
          query: <String, dynamic>{'page': page, 'limit': pageSize},
          useCache: false,
        );
        final Map<String, dynamic> map = data as Map<String, dynamic>;
        final List<dynamic> items =
            map['items'] as List<dynamic>? ?? <dynamic>[];
        for (final dynamic item in items) {
          final Map<String, dynamic> post = item as Map<String, dynamic>;
          if (post['id'] == id) {
            return ContentPost.fromJson(post);
          }
        }
        if (items.length < pageSize) {
          break; // last page
        }
      } catch (e) {
        debugPrint('⚠️ [ContentService] ${ApiEndpoints.adminPosts} page '
            '$page failed: $e');
        break;
      }
    }
    return null;
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

  /// DELETE /admin/posts/:id — hard-delete a post (bypasses ownership check).
  Future<void> deletePost(String id) async {
    debugPrint('🚀 [ContentService] DELETE ${ApiEndpoints.adminPost(id)}');
    await _client.delete(ApiEndpoints.adminPost(id));
  }
}

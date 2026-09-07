// Post Content Service — manages post publishing and engagement actions.
// Interfaces with Content Service on Port 3013.

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../models/create_post_models.dart';

class PostContentService {
  const PostContentService(this._client);

  final ApiClient _client;

  // ── Create Post ───────────────────────────────────────────────────────────
  // POST /posts (Content Service, Port 3013)
  // Backend Schema: { type: "TEXT"|"PHOTO"|"VIDEO", body: string, mediaRefs: string[], tags: string[], visibility: "EVERYONE"|"FOLLOWERS"|"COMMUNITY_ONLY", communityId?: string }
  Future<PostResponseModel> createPost({
    required String body,
    required String type, // "TEXT" | "PHOTO" | "VIDEO"
    required String visibility, // "EVERYONE" | "FOLLOWERS" | "COMMUNITY_ONLY"
    List<String> mediaRefs = const <String>[],
    List<String> tags = const <String>[],
    String? communityId,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [PostContent] Mock API is ON. Returning mock created post.');
      return PostResponseModel(
        id: 'post_${DateTime.now().millisecondsSinceEpoch}',
        caption: body,
        type: type,
        mediaRefs: mediaRefs,
        tags: tags,
        communityId: communityId,
        visibility: visibility,
        createdAt: DateTime.now().toIso8601String(),
      );
    }

    // Deduplicate mediaRefs to prevent duplicate entry issues
    final List<String> distinctMediaRefs = mediaRefs.toSet().toList();

    debugPrint(
        '🚀 [PostContent] Creating post (type: $type, visibility: $visibility, mediaRefs: $distinctMediaRefs)');
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'type': type,
      'body': body,
      'mediaRefs': distinctMediaRefs,
      'tags': tags,
      'visibility': visibility,
    };

    // Only send communityId if provided and valid UUID
    if (communityId != null &&
        RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(communityId.trim())) {
      requestBody['communityId'] = communityId.trim();
    }

    final dynamic response = await _client.post(
      ApiEndpoints.posts,
      body: requestBody,
    );

    debugPrint('📥 [PostContent] Create Post Response: $response');
    if (response is Map<String, dynamic>) {
      return PostResponseModel.fromJson(response);
    }
    throw const ApiException('Invalid response format when creating post.');
  }

  // ── Read One Post ─────────────────────────────────────────────────────────
  // GET /posts/:id (Content Service, Port 3013)
  Future<PostResponseModel> getPost(String postId) async {
    if (AppConfig.useMockApi) {
      return PostResponseModel(id: postId, caption: 'Mock post content');
    }

    final dynamic response = await _client.get(ApiEndpoints.post(postId));
    if (response is Map<String, dynamic>) {
      return PostResponseModel.fromJson(response);
    }
    throw const ApiException('Post not found or invalid response.');
  }

  // ── List Posts by Author ──────────────────────────────────────────────────
  // GET /posts?authorId=:authorId (Content Service, Port 3013)
  Future<List<PostResponseModel>> getPostsByAuthor(String authorId) async {
    if (AppConfig.useMockApi) {
      return const <PostResponseModel>[];
    }

    final dynamic response =
        await _client.get(ApiEndpoints.postsByAuthor(authorId));
    if (response is List) {
      return response
          .map((dynamic item) =>
              PostResponseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return <PostResponseModel>[];
  }

  // ── List All Feed Posts (All Types) ───────────────────────────────────────
  // GET /posts (Content Service, Port 3013)
  Future<List<PostResponseModel>> getFeedPosts() async {
    if (AppConfig.useMockApi) {
      return const <PostResponseModel>[];
    }

    final dynamic response =
        await _client.get(ApiEndpoints.posts, useCache: false);
    if (response is List) {
      return response
          .map((dynamic item) =>
              PostResponseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return <PostResponseModel>[];
  }

  // ── Trending Posts (Video-Only) ───────────────────────────────────────────
  // GET /posts/trending (Content Service, Port 3013)
  Future<List<PostResponseModel>> getTrendingPosts() async {
    if (AppConfig.useMockApi) {
      return const <PostResponseModel>[];
    }

    final dynamic response = await _client.get(ApiEndpoints.trendingPosts);
    if (response is List) {
      return response
          .map((dynamic item) =>
              PostResponseModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    return <PostResponseModel>[];
  }

  // ── Record View ───────────────────────────────────────────────────────────
  // POST /posts/:id/view (Content Service, Port 3013)
  Future<void> recordView(String postId) async {
    if (AppConfig.useMockApi) return;
    try {
      await _client.post(ApiEndpoints.postView(postId));
    } catch (e) {
      debugPrint('⚠️ [PostContent] Failed to record view for $postId: $e');
    }
  }

  // ── Like Post ─────────────────────────────────────────────────────────────
  // POST /posts/:id/like (Content Service, Port 3013)
  Future<void> likePost(String postId) async {
    if (AppConfig.useMockApi) return;
    await _client.post(ApiEndpoints.postLike(postId));
  }

  // ── Unlike Post ───────────────────────────────────────────────────────────
  // DELETE /posts/:id/like (Content Service, Port 3013)
  Future<void> unlikePost(String postId) async {
    if (AppConfig.useMockApi) return;
    await _client.delete(ApiEndpoints.postLike(postId));
  }

  // ── Create Comment ────────────────────────────────────────────────────────
  // POST /posts/:id/comments (Content Service, Port 3013)
  // Backend Schema: { body: string (1-500 chars) }
  Future<Map<String, dynamic>> createComment({
    required String postId,
    required String content,
  }) async {
    final String trimmedBody = content.trim();
    if (AppConfig.useMockApi) {
      return <String, dynamic>{
        'id': 'comment_${DateTime.now().millisecondsSinceEpoch}',
        'body': trimmedBody,
        'content': trimmedBody,
      };
    }

    final dynamic response = await _client.post(
      ApiEndpoints.postComments(postId),
      body: <String, dynamic>{'body': trimmedBody},
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
  }

  // ── Get Comments ──────────────────────────────────────────────────────────
  // GET /posts/:id/comments (Content Service, Port 3013)
  Future<List<dynamic>> getComments(String postId) async {
    if (AppConfig.useMockApi) return const <dynamic>[];
    final dynamic response = await _client.get(ApiEndpoints.postComments(postId));
    if (response is List) return response;
    return const <dynamic>[];
  }
}

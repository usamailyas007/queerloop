// Post Content Service — manages post publishing and engagement actions.
// Interfaces with Content Service on Port 3013.

import 'dart:convert';

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

    // Only send communityId if provided and valid UUID or Mongo ObjectId
    if (communityId != null &&
        (RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
                .hasMatch(communityId.trim()) ||
            RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(communityId.trim()))) {
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
      debugPrint('📡 [FeedAPI] Mock API is ON — skipping real call');
      return const <PostResponseModel>[];
    }

    try {
      debugPrint('📡 [FeedAPI] Calling GET /posts ...');
      final dynamic response =
          await _client.get(ApiEndpoints.posts, useCache: false);
      // Print full JSON in chunks so Flutter doesn't truncate
      final String jsonStr = const JsonEncoder.withIndent('  ').convert(response);
      const int chunkSize = 800;
      for (int i = 0; i < jsonStr.length; i += chunkSize) {
        final String chunk = jsonStr.substring(i, i + chunkSize > jsonStr.length ? jsonStr.length : i + chunkSize);
        debugPrint('📡 [FeedAPI] /posts[$i]: $chunk');
      }
      final List<PostResponseModel> parsed = _parsePostsList(response);
      if (parsed.isNotEmpty) return parsed;
      debugPrint('📡 [FeedAPI] /posts returned 0 parsed items, trying fallbacks...');
    } catch (e) {
      debugPrint('📡 [FeedAPI] /posts FAILED: $e');
    }

    // Fallback 1: Dedicated Search Posts endpoint GET /search?q=&limit=20
    try {
      debugPrint('📡 [FeedAPI] Trying fallback /search ...');
      final dynamic searchResponse = await _client.get(
        ApiEndpoints.searchPosts(query: '', limit: 20),
        useCache: false,
      );
      debugPrint('📡 [FeedAPI] Raw /search response: $searchResponse');
      final List<PostResponseModel> searchParsed =
          _parsePostsList(searchResponse);
      if (searchParsed.isNotEmpty) return searchParsed;
    } catch (e) {
      debugPrint('📡 [FeedAPI] /search FAILED: $e');
    }

    // Fallback 2: Discover Multi-Tab Search GET /discover/search?query=&tab=posts
    try {
      debugPrint('📡 [FeedAPI] Trying fallback /discover/search ...');
      final dynamic discoverResponse = await _client.get(
        ApiEndpoints.discoverSearch(query: '', tab: 'posts'),
        useCache: false,
      );
      debugPrint('📡 [FeedAPI] Raw /discover/search response: $discoverResponse');
      final List<PostResponseModel> discoverParsed =
          _parsePostsList(discoverResponse);
      if (discoverParsed.isNotEmpty) return discoverParsed;
    } catch (e) {
      debugPrint('📡 [FeedAPI] /discover/search FAILED: $e');
    }

    // Fallback 3: Community feed GET /feed/community
    try {
      debugPrint('📡 [FeedAPI] Trying fallback /feed/community ...');
      final List<PostResponseModel> commPosts = await getCommunityFeed();
      if (commPosts.isNotEmpty) return commPosts;
    } catch (e) {
      debugPrint('⚠️ [PostContent] Fallback /feed/community failed: $e');
    }

    return const <PostResponseModel>[];
  }

  // ── Trending Posts (Video-Only) ───────────────────────────────────────────
  // GET /posts/trending (Content Service, Port 3013)
  Future<List<PostResponseModel>> getTrendingPosts() async {
    if (AppConfig.useMockApi) {
      return const <PostResponseModel>[];
    }

    try {
      final dynamic response = await _client.get(ApiEndpoints.trendingPosts);
      return _parsePostsList(response);
    } catch (e) {
      debugPrint('⚠️ [PostContent] Failed to fetch trending posts (/posts/trending): $e');
      return const <PostResponseModel>[];
    }
  }

  // ── Following Feed ────────────────────────────────────────────────────────
  // GET /feed/following
  Future<List<PostResponseModel>> getFollowingFeed() async {
    if (AppConfig.useMockApi) {
      return const <PostResponseModel>[];
    }
    debugPrint(
        '🚀 [PostContent] Fetching Following Feed (GET ${ApiEndpoints.feedFollowing})');
    try {
      final dynamic response =
          await _client.get(ApiEndpoints.feedFollowing, useCache: false);
      return _parsePostsList(response);
    } catch (e) {
      debugPrint('⚠️ [PostContent] Failed to fetch following feed: $e');
      return const <PostResponseModel>[];
    }
  }

  // ── Community Feed ────────────────────────────────────────────────────────
  // GET /feed/community?communityId=:id OR ?scope=joined
  Future<List<PostResponseModel>> getCommunityFeed({
    String? communityId,
    String? scope,
  }) async {
    if (AppConfig.useMockApi) {
      return const <PostResponseModel>[];
    }
    if (communityId != null && communityId.trim().isNotEmpty) {
      final List<PostResponseModel> posts =
          await getPostsByCommunity(communityId.trim());
      if (posts.isNotEmpty) return posts;
    }
    final String path = ApiEndpoints.feedCommunity(
      communityId: communityId,
      scope: scope,
    );
    debugPrint('🚀 [PostContent] Fetching Community Feed (GET $path)');
    try {
      final dynamic response = await _client.get(path, useCache: false);
      return _parsePostsList(response);
    } catch (e) {
      debugPrint('⚠️ [PostContent] Failed to fetch community feed: $e');
      return const <PostResponseModel>[];
    }
  }

  List<PostResponseModel> _parsePostsList(dynamic response) {
    List<dynamic> rawList = <dynamic>[];
    if (response is List) {
      rawList = response;
    } else if (response is Map<String, dynamic>) {
      if (response['data'] is List) {
        rawList = response['data'] as List<dynamic>;
      } else if (response['posts'] is List) {
        rawList = response['posts'] as List<dynamic>;
      } else if (response['items'] is List) {
        rawList = response['items'] as List<dynamic>;
      } else if (response['feed'] is List) {
        rawList = response['feed'] as List<dynamic>;
      } else if (response['results'] is List) {
        rawList = response['results'] as List<dynamic>;
      }
    }
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(PostResponseModel.fromJson)
        .toList();
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

  // ── Save Post ─────────────────────────────────────────────────────────────
  // POST /posts/:id/save (Content Service)
  Future<void> savePost(String postId) async {
    if (AppConfig.useMockApi) return;
    await _client.post(ApiEndpoints.postSave(postId));
  }

  // ── Unsave Post ───────────────────────────────────────────────────────────
  // DELETE /posts/:id/save (Content Service)
  Future<void> unsavePost(String postId) async {
    if (AppConfig.useMockApi) return;
    await _client.delete(ApiEndpoints.postSave(postId));
  }

  // ── Delete Post / Video Post ──────────────────────────────────────────────
  // DELETE /posts/:id (Content Service)
  Future<void> deletePost(String postId) async {
    if (AppConfig.useMockApi) return;
    await _client.delete(ApiEndpoints.post(postId));
  }

  // ── Create Comment or Reply ───────────────────────────────────────────────
  // POST /posts/:id/comments (Content Service)
  // Backend Schema: { body: string (1-500 chars), parentId?: string }
  Future<Map<String, dynamic>> createComment({
    required String postId,
    required String content,
    String? parentId,
  }) async {
    final String trimmedBody = content.trim();
    final Map<String, dynamic> body = <String, dynamic>{'body': trimmedBody};
    if (parentId != null && parentId.trim().isNotEmpty) {
      body['parentId'] = parentId.trim();
    }

    if (AppConfig.useMockApi) {
      return <String, dynamic>{
        'id': 'comment_${DateTime.now().millisecondsSinceEpoch}',
        'body': trimmedBody,
        'parentId': ?parentId,
      };
    }

    final dynamic response = await _client.post(
      ApiEndpoints.postComments(postId),
      body: body,
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return <String, dynamic>{};
  }

  // ── Get Comments ──────────────────────────────────────────────────────────
  // GET /posts/:id/comments (Content Service)
  Future<List<dynamic>> getComments(String postId) async {
    if (AppConfig.useMockApi) return const <dynamic>[];
    final dynamic response =
        await _client.get(ApiEndpoints.postComments(postId), useCache: false);
    if (response is List) return response;
    if (response is Map<String, dynamic>) {
      if (response['data'] is List) return response['data'] as List<dynamic>;
      if (response['comments'] is List) {
        return response['comments'] as List<dynamic>;
      }
    }
    return const <dynamic>[];
  }

  // ── Like Comment ──────────────────────────────────────────────────────────
  // POST /comments/:id/like
  Future<void> likeComment(String commentId) async {
    if (AppConfig.useMockApi) return;
    await _client.post(ApiEndpoints.commentLike(commentId));
  }

  // ── Unlike Comment ────────────────────────────────────────────────────────
  // DELETE /comments/:id/like
  Future<void> unlikeComment(String commentId) async {
    if (AppConfig.useMockApi) return;
    await _client.delete(ApiEndpoints.commentLike(commentId));
  }

  // ── Delete Comment or Reply ───────────────────────────────────────────────
  // DELETE /comments/:id
  Future<void> deleteComment(String commentId) async {
    if (AppConfig.useMockApi) return;
    await _client.delete(ApiEndpoints.comment(commentId));
  }

  // ── List Posts by Community ───────────────────────────────────────────────
  // GET /posts?communityId=:communityId
  Future<List<PostResponseModel>> getPostsByCommunity(
      String communityId) async {
    if (AppConfig.useMockApi) return const <PostResponseModel>[];
    try {
      final dynamic response = await _client.get(
        ApiEndpoints.postsByCommunity(communityId),
        useCache: false,
      );
      return _parsePostsList(response);
    } catch (e) {
      debugPrint('⚠️ [PostContent] Failed to fetch community posts: $e');
      return const <PostResponseModel>[];
    }
  }

  // ── List User's Liked Posts ───────────────────────────────────────────────
  // GET /users/me/likes
  Future<List<PostResponseModel>> getLikedPosts() async {
    if (AppConfig.useMockApi) return const <PostResponseModel>[];
    try {
      final dynamic response =
          await _client.get(ApiEndpoints.userLikes, useCache: false);
      return _parsePostsList(response);
    } catch (e) {
      debugPrint('⚠️ [PostContent] Failed to fetch liked posts: $e');
      return const <PostResponseModel>[];
    }
  }

  // ── List User's Saved Posts ───────────────────────────────────────────────
  // GET /users/me/saved
  Future<List<PostResponseModel>> getSavedPosts() async {
    if (AppConfig.useMockApi) return const <PostResponseModel>[];
    try {
      final dynamic response =
          await _client.get(ApiEndpoints.userSaved, useCache: false);
      return _parsePostsList(response);
    } catch (e) {
      debugPrint('⚠️ [PostContent] Failed to fetch saved posts: $e');
      return const <PostResponseModel>[];
    }
  }
}

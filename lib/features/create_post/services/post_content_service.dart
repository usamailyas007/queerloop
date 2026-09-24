// Post Content Service — manages post publishing and engagement actions.
// Interfaces with Content Service on Port 3013.


import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/cache/cache_manager.dart';
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
    bool allowComments = true,
    bool allowDownloads = false,
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
        allowComments: allowComments,
        allowDownloads: allowDownloads,
        createdAt: DateTime.now().toIso8601String(),
      );
    }

    // Deduplicate mediaRefs to prevent duplicate entry issues
    final List<String> distinctMediaRefs = mediaRefs.toSet().toList();

    debugPrint(
        '🚀 [PostContent] Creating post (type: $type, visibility: $visibility, mediaRefs: $distinctMediaRefs, allowComments: $allowComments, allowDownload: $allowDownloads)');
    final Map<String, dynamic> requestBody = <String, dynamic>{
      'type': type,
      'body': body,
      'visibility': visibility,
    };

    if (type == 'VIDEO' || type == 'PHOTO') {
      requestBody['allowComments'] = allowComments;
      requestBody['allowDownload'] = allowDownloads;
    }

    if (distinctMediaRefs.isNotEmpty) {
      requestBody['mediaRefs'] = distinctMediaRefs;
    }

    if (tags.isNotEmpty) {
      requestBody['tags'] = tags;
    }

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

  // ── Author Profile Resolution ──────────────────────────────────────────────
  // GET /users/:id (User Service)
  Future<AuthorInfo?> getAuthorInfo(String userId) async {
    final String cleanId = userId.trim();
    if (cleanId.isEmpty) return null;

    final AuthorInfo? cached = AuthorProfileCache.get(cleanId);
    if (cached != null) return cached;

    // Check persistent CacheManager
    try {
      final dynamic cachedData =
          CacheManager.instance.get('profile_details_$cleanId');
      if (cachedData is Map) {
        final Map<String, dynamic> c = Map<String, dynamic>.from(cachedData);
        final dynamic userObj = c['data'] ?? c['user'] ?? c['profile'] ?? c;
        if (userObj is Map) {
          final String? u = (userObj['username'] ??
                  userObj['userName'] ??
                  userObj['handle'])
              ?.toString();
          if (u != null && u.trim().isNotEmpty) {
            final String? d = (userObj['displayName'] ??
                    userObj['display_name'] ??
                    userObj['name'] ??
                    userObj['fullName'])
                ?.toString();
            final String? a = (userObj['avatarUrl'] ??
                    userObj['avatar'] ??
                    userObj['profilePic'])
                ?.toString();
            final bool? hideLikes =
                (userObj['hideMyLikes'] ?? userObj['hideLikes']) as bool?;
            final AuthorInfo info = AuthorInfo(
              id: cleanId,
              username: u.trim(),
              displayName:
                  (d != null && d.trim().isNotEmpty) ? d.trim() : u.trim(),
              avatarUrl: a,
              hideMyLikes: hideLikes,
            );
            AuthorProfileCache.set(cleanId, info);
            return info;
          }
        }
      }
    } catch (_) {}

    // Fetch from User API: GET /users/:id
    try {
      final dynamic data = await _client
          .get(ApiEndpoints.user(cleanId), useCache: true)
          .timeout(const Duration(seconds: 4));

      if (data is Map) {
        final Map<String, dynamic> c = Map<String, dynamic>.from(data);
        final dynamic userObj = c['data'] ?? c['user'] ?? c['profile'] ?? c;
        if (userObj is Map) {
          final String? u = (userObj['username'] ??
                  userObj['userName'] ??
                  userObj['handle'])
              ?.toString();
          if (u != null && u.trim().isNotEmpty) {
            final String? d = (userObj['displayName'] ??
                    userObj['display_name'] ??
                    userObj['name'] ??
                    userObj['fullName'])
                ?.toString();
            final String? a = (userObj['avatarUrl'] ??
                    userObj['avatar'] ??
                    userObj['profilePic'])
                ?.toString();
            final bool? hideLikes =
                (userObj['hideMyLikes'] ?? userObj['hideLikes']) as bool?;
            final AuthorInfo info = AuthorInfo(
              id: cleanId,
              username: u.trim(),
              displayName:
                  (d != null && d.trim().isNotEmpty) ? d.trim() : u.trim(),
              avatarUrl: a,
              hideMyLikes: hideLikes,
            );
            AuthorProfileCache.set(cleanId, info);
            CacheManager.instance.put('profile_details_$cleanId', data,
                ttl: const Duration(days: 7));
            return info;
          }
        }
      }
    } catch (e) {
      debugPrint(
          '⚠️ [PostContentService] Failed to resolve author info for $cleanId: $e');
    }

    return null;
  }

  Future<void> getAuthorsInfo(Iterable<String> userIds) async {
    final Set<String> needed = <String>{};
    for (final String id in userIds) {
      final String clean = id.trim();
      if (clean.isNotEmpty && !AuthorProfileCache.contains(clean)) {
        needed.add(clean);
      }
    }
    if (needed.isEmpty) return;

    await Future.wait(
      needed.map((String id) => getAuthorInfo(id)),
    );
  }

  // ── List Posts by Author ──────────────────────────────────────────────────
  // GET /posts?authorId=:authorId (Content Service, Port 3013)
  Future<List<PostResponseModel>> getPostsByAuthor(String authorId) async {
    if (AppConfig.useMockApi) {
      return const <PostResponseModel>[];
    }

    final dynamic response =
        await _client.get(ApiEndpoints.postsByAuthor(authorId));
    return _parsePostsList(response);
  }

  // ── List All Feed Posts (All Types) ───────────────────────────────────────
  // GET /posts (Content Service, Port 3013)
  Future<List<PostResponseModel>> getFeedPosts() async {
    if (AppConfig.useMockApi) {
      debugPrint('📡 [FeedAPI] Mock API is ON — skipping real call');
      return const <PostResponseModel>[];
    }

    Future<List<PostResponseModel>> attempt() async {
      debugPrint('📡 [FeedAPI] Calling GET ${ApiEndpoints.posts} ...');
      dynamic response;
      try {
        response = await _client.get(ApiEndpoints.posts, useCache: false);
      } catch (authErr) {
        debugPrint('📡 [FeedAPI] Authenticated GET ${ApiEndpoints.posts} failed, falling back to no-auth: $authErr');
        response = await _client.getNoAuth(ApiEndpoints.posts);
      }
      final List<PostResponseModel> posts = _parsePostsList(response);
      debugPrint('📡 [FeedAPI] GET ${ApiEndpoints.posts} returned ${posts.length} parsed items');
      return posts;
    }

    try {
      return await attempt();
    } catch (e) {
      // Log full error details to help diagnose auth vs backend issues
      if (e is ApiException) {
        debugPrint('📡 [FeedAPI] /posts FAILED: $e');
        debugPrint('📡 [FeedAPI]   status=${e.statusCode}, kind=${e.kind}, code=${e.code}');
        debugPrint('📡 [FeedAPI]   data=${e.data}');

        // Retry once after 1s on 5xx server errors (transient gateway issues)
        if (e.statusCode != null && e.statusCode! >= 500) {
          debugPrint('📡 [FeedAPI] Retrying /posts in 1s (5xx error)...');
          await Future<void>.delayed(const Duration(seconds: 1));
          try {
            return await attempt();
          } catch (retryError) {
            debugPrint('📡 [FeedAPI] Retry also failed: $retryError');
          }
        }
      } else {
        debugPrint('📡 [FeedAPI] /posts FAILED: $e');
      }
      return const <PostResponseModel>[];
    }
  }

  // ── Trending Posts (All Types) ───────────────────────────────────────────
  // GET /posts/trending (Content Service, Port 3013)
  Future<List<PostResponseModel>> getTrendingPosts() async {
    if (AppConfig.useMockApi) {
      return const <PostResponseModel>[];
    }

    try {
      final dynamic response =
          await _client.getNoAuth(ApiEndpoints.trendingPosts);
      return _parsePostsList(response);
    } catch (e) {
      debugPrint('⚠️ [PostContent] Failed to fetch trending posts (/posts/trending): $e');
      return const <PostResponseModel>[];
    }
  }

  // ── For You Feed ───────────────────────────────────────────────────────────
  // GET /feed/for-you
  Future<List<PostResponseModel>> getForYouFeed({String? authToken}) async {
    if (AppConfig.useMockApi) {
      return const <PostResponseModel>[];
    }
    if (authToken != null && authToken.isNotEmpty) {
      _client.authToken = authToken;
    }
    debugPrint(
        '🚀 [PostContent] Fetching For You Feed (GET ${ApiEndpoints.feedForYou})');
    try {
      final dynamic response = await _client.get(
        ApiEndpoints.feedForYou,
        useCache: false,
      );
      return _parsePostsList(response);
    } catch (e) {
      debugPrint('⚠️ [PostContent] Failed to fetch for-you feed: $e');
      rethrow;
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
  // For All Communities: calls GET /posts (Content Service)
  // For filtered Community: calls GET /posts?communityId=:id
  Future<List<PostResponseModel>> getCommunityFeed({
    String? communityId,
    String? scope,
  }) async {
    if (AppConfig.useMockApi) {
      return const <PostResponseModel>[];
    }
    // Filtered by specific community: GET /posts?communityId=:id
    if (communityId != null && communityId.trim().isNotEmpty) {
      return await getPostsByCommunity(communityId.trim());
    } else {
      // "All Communities" -> Always call GET /posts directly
      return await getFeedPosts();
    }
  }

  List<PostResponseModel> _parsePostsList(dynamic response) {
    List<dynamic> rawList = <dynamic>[];
    if (response is List) {
      rawList = response;
    } else if (response is Map) {
      if (response['data'] is List) {
        rawList = response['data'] as List<dynamic>;
      } else if (response['data'] is Map) {
        final Map dataMap = response['data'] as Map;
        if (dataMap['posts'] is List) {
          rawList = dataMap['posts'] as List<dynamic>;
        } else if (dataMap['items'] is List) {
          rawList = dataMap['items'] as List<dynamic>;
        } else if (dataMap['feed'] is List) {
          rawList = dataMap['feed'] as List<dynamic>;
        } else if (dataMap['results'] is List) {
          rawList = dataMap['results'] as List<dynamic>;
        } else if (dataMap['rows'] is List) {
          rawList = dataMap['rows'] as List<dynamic>;
        }
      } else if (response['posts'] is List) {
        rawList = response['posts'] as List<dynamic>;
      } else if (response['items'] is List) {
        rawList = response['items'] as List<dynamic>;
      } else if (response['feed'] is List) {
        rawList = response['feed'] as List<dynamic>;
      } else if (response['results'] is List) {
        rawList = response['results'] as List<dynamic>;
      } else if (response['rows'] is List) {
        rawList = response['rows'] as List<dynamic>;
      } else if (response['content'] is List) {
        rawList = response['content'] as List<dynamic>;
      }
    }
    final List<PostResponseModel> result = <PostResponseModel>[];
    for (final dynamic item in rawList) {
      if (item is Map) {
        try {
          if (item['deletedAt'] != null || item['deleted_at'] != null) {
            continue;
          }
          final String status = (item['status'] ?? '').toString().toLowerCase();
          if (status == 'deleted' || status == 'removed') {
            continue;
          }
          final Map<String, dynamic> typed = item.map<String, dynamic>(
            (dynamic k, dynamic v) => MapEntry<String, dynamic>(k.toString(), v),
          );
          result.add(PostResponseModel.fromJson(typed));
        } catch (e) {
          debugPrint('⚠️ [PostContent] Error parsing post item: $e');
        }
      }
    }
    return result;
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
  // POST /comments/:id/like or POST /posts/:postId/comments/:id/like
  Future<void> likeComment(String commentId, {String? postId}) async {
    if (AppConfig.useMockApi) return;
    try {
      await _client.post(
        ApiEndpoints.commentLike(commentId),
        body: <String, dynamic>{},
      );
    } catch (e) {
      if (postId != null && postId.isNotEmpty) {
        try {
          await _client.post(
            '/posts/$postId/comments/$commentId/like',
            body: <String, dynamic>{},
          );
          return;
        } catch (_) {}
      }
      debugPrint('⚠️ [PostContentService] Failed to like comment $commentId: $e');
      rethrow;
    }
  }

  // ── Unlike Comment ────────────────────────────────────────────────────────
  // DELETE /comments/:id/like or DELETE /posts/:postId/comments/:id/like
  Future<void> unlikeComment(String commentId, {String? postId}) async {
    if (AppConfig.useMockApi) return;
    try {
      await _client.delete(ApiEndpoints.commentLike(commentId));
    } catch (e) {
      if (postId != null && postId.isNotEmpty) {
        try {
          await _client.delete('/posts/$postId/comments/$commentId/like');
          return;
        } catch (_) {}
      }
      debugPrint('⚠️ [PostContentService] Failed to unlike comment $commentId: $e');
      rethrow;
    }
  }

  // ── Delete Comment or Reply ───────────────────────────────────────────────
  // DELETE /comment/:id
  Future<void> deleteComment(String commentId) async {
    if (AppConfig.useMockApi) return;
    try {
      await _client.delete(ApiEndpoints.comment(commentId));
    } catch (e) {
      debugPrint('⚠️ [PostContent] DELETE /comment/$commentId failed: $e, trying fallback');
      try {
        await _client.delete('/comments/$commentId');
      } catch (_) {
        rethrow;
      }
    }
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
      try {
        final dynamic fallbackRes = await _client.getNoAuth(
          ApiEndpoints.postsByCommunity(communityId),
        );
        return _parsePostsList(fallbackRes);
      } catch (_) {}
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

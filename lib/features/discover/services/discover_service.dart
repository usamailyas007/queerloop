import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/cache/user_relationship_cache.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../create_post/models/create_post_models.dart';
import '../models/discover_models.dart';
import '../widgets/search_tag_tile.dart';

/// Service responsible for all Discover and Search API interactions.
class DiscoverService {
  const DiscoverService(this._client);

  final ApiClient _client;

  // ── Trending Hashtags ──────────────────────────────────────────────────────
  /// GET /discover/trending
  Future<List<TrendingItem>> getTrendingHashtags() async {
    try {
      debugPrint('🚀 [DiscoverService] Fetching trending hashtags...');
      final dynamic res = await _client.get(
        ApiEndpoints.discoverTrending,
        useCache: false,
      );

      final List<dynamic> list = _extractList(res, keys: <String>[
        'data',
        'trending',
        'hashtags',
        'items',
      ]);

      return list.asMap().entries.map((MapEntry<int, dynamic> entry) {
        if (entry.value is Map<String, dynamic>) {
          return TrendingItem.fromJson(
            entry.value as Map<String, dynamic>,
            index: entry.key,
          );
        }
        return TrendingItem.fromJson(
          <String, dynamic>{'tag': entry.value.toString()},
          index: entry.key,
        );
      }).toList();
    } on ApiException catch (e) {
      debugPrint('❌ [DiscoverService] getTrendingHashtags error: $e');
      return <TrendingItem>[];
    } catch (e, stack) {
      debugPrint('❌ [DiscoverService] getTrendingHashtags unexpected: $e\n$stack');
      return <TrendingItem>[];
    }
  }

  // ── Creators ───────────────────────────────────────────────────────────────
  /// GET /discover/creators?type=to_watch | new
  Future<List<DiscoverCreator>> getCreators({required String type}) async {
    try {
      debugPrint('🚀 [DiscoverService] Fetching creators (type: $type)...');
      final dynamic res = await _client.get(
        ApiEndpoints.discoverCreators(type: type),
        useCache: false,
      );

      final List<dynamic> list = _extractList(res, keys: <String>[
        'data',
        'creators',
        'users',
        'items',
      ]);

      return list
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) => DiscoverCreator.fromJson(item))
          .toList();
    } on ApiException catch (e) {
      debugPrint('❌ [DiscoverService] getCreators ($type) error: $e');
      return <DiscoverCreator>[];
    } catch (e, stack) {
      debugPrint('❌ [DiscoverService] getCreators ($type) unexpected: $e\n$stack');
      return <DiscoverCreator>[];
    }
  }

  // ── Communities ────────────────────────────────────────────────────────────
  /// GET /communities
  Future<List<DiscoverCommunity>> getCommunities() async {
    try {
      debugPrint('🚀 [DiscoverService] Fetching communities...');
      final dynamic res = await _client.get(
        ApiEndpoints.communities,
        useCache: false,
      );

      final List<dynamic> list = _extractList(res, keys: <String>[
        'data',
        'communities',
        'items',
      ]);

      return list
          .whereType<Map<String, dynamic>>()
          .map(DiscoverCommunity.fromJson)
          .toList();
    } on ApiException catch (e) {
      debugPrint('❌ [DiscoverService] getCommunities error: $e');
      return <DiscoverCommunity>[];
    } catch (e, stack) {
      debugPrint('❌ [DiscoverService] getCommunities unexpected: $e\n$stack');
      return <DiscoverCommunity>[];
    }
  }

  // ── Explore Communities ───────────────────────────────────────────────────
  /// GET /communities/explore?excludeJoined=true&sort=trending&page=1&limit=10
  Future<List<DiscoverCommunity>> getExploreCommunities({
    bool excludeJoined = true,
    String sort = 'trending',
    String? category,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final String url = ApiEndpoints.communitiesExplore(
        excludeJoined: excludeJoined,
        sort: sort,
        category: category,
        page: page,
        limit: limit,
      );
      debugPrint('🚀 [DiscoverService] Fetching explore communities: GET $url');
      final dynamic res = await _client.get(url, useCache: false);
      final List<dynamic> list = _extractList(res, keys: <String>[
        'data',
        'communities',
        'items',
        'results',
      ]);
      return list
          .whereType<Map<String, dynamic>>()
          .map(DiscoverCommunity.fromJson)
          .toList();
    } on ApiException catch (e) {
      debugPrint('❌ [DiscoverService] getExploreCommunities error: $e');
      // Fallback to getCommunities if explore endpoint is not yet active
      return getCommunities();
    } catch (e, stack) {
      debugPrint('❌ [DiscoverService] getExploreCommunities unexpected: $e\n$stack');
      return getCommunities();
    }
  }


  // ── Posts API (Live Existing Posts) ─────────────────────────────────────────
  /// GET /posts
  Future<List<PostResponseModel>> getLivePosts() async {
    try {
      final dynamic res = await _client.get(
        ApiEndpoints.posts,
        useCache: false,
      );
      return _parsePostsResponse(res);
    } catch (e) {
      if (!_client.isAuthenticated) {
        try {
          final dynamic fallbackRes = await _client.getNoAuth(ApiEndpoints.posts);
          return _parsePostsResponse(fallbackRes);
        } catch (_) {}
      }
      return <PostResponseModel>[];
    }
  }

  List<PostResponseModel> _parsePostsResponse(dynamic response) {
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
        }
      } else if (response['posts'] is List) {
        rawList = response['posts'] as List<dynamic>;
      } else if (response['items'] is List) {
        rawList = response['items'] as List<dynamic>;
      } else if (response['feed'] is List) {
        rawList = response['feed'] as List<dynamic>;
      }
    }
    debugPrint('📦 [DiscoverLivePosts] RAW type: ${response.runtimeType}');
    final List<PostResponseModel> list = rawList
        .whereType<Map<String, dynamic>>()
        .map(PostResponseModel.fromJson)
        .toList();
    debugPrint('📦 [DiscoverLivePosts] Parsed ${list.length} live posts');
    return list;
  }

  // ── Multi-Tab Search ───────────────────────────────────────────────────────
  /// All tab: GET /discover/search?query=:query&tab=all
  /// Dedicated tabs: GET /discover/search?query=:query&tab=:tab
  Future<MultiTabSearchResults> search({
    required String query,
    String tab = 'all',
  }) async {
    final String q = query.trim();
    if (q.isEmpty) {
      return const MultiTabSearchResults();
    }

    try {
      debugPrint('🔍 [DiscoverService] Searching query: "$q", tab: "$tab"');

      // 1. Query discover search API
      final dynamic res = await _client.get(
        ApiEndpoints.discoverSearch(query: q, tab: tab),
        useCache: false,
      );
      MultiTabSearchResults results = _parseSearchResults(res, activeTab: tab);

      // ── DEBUG: Print raw discover search response structure ────────────────
      debugPrint('📦 [DiscoverSearch] RAW response type: ${res.runtimeType}');
      if (res is Map) {
        debugPrint('📦 [DiscoverSearch] Top-level keys: ${res.keys.toList()}');
      } else if (res is List) {
        debugPrint('📦 [DiscoverSearch] response is List, length: ${res.length}');
      }
      debugPrint('📦 [DiscoverSearch] Parsed: ${results.posts.length} posts, ${results.reels.length} reels');
      // ──────────────────────────────────────────────────────────────────────

      // 2. Fetch live existing posts from Posts API to reconcile deleted/stale content
      final List<PostResponseModel> livePosts = await getLivePosts();

      // Build lookup indices of live existing posts
      final Map<String, PostResponseModel> livePostsById = <String, PostResponseModel>{};
      final Map<String, PostResponseModel> livePostsByMediaRef = <String, PostResponseModel>{};
      final Map<String, int> liveTagCounts = <String, int>{};

      for (final PostResponseModel lp in livePosts) {
        if (!lp.isPublished) continue;
        if (DeletedPostsRegistry.isDeleted(lp.id)) continue;
        livePostsById[lp.id.toLowerCase()] = lp;
        for (final String m in lp.mediaRefs) {
          final String clean = m.replaceAll(RegExp(r'^/+|^media/'), '').trim().toLowerCase();
          if (clean.isNotEmpty) {
            livePostsByMediaRef[clean] = lp;
          }
        }
        for (final String t in lp.tags) {
          final String clean = t.replaceAll('#', '').trim().toLowerCase();
          if (clean.isNotEmpty) {
            liveTagCounts[clean] = (liveTagCounts[clean] ?? 0) + 1;
          }
        }
      }

      // 3. Process Posts: Use refId as media reference ID and filter out deleted/stale posts
      final List<DiscoverSearchResult> verifiedPosts = <DiscoverSearchResult>[];
      final Set<String> seenPostKeys = <String>{};
      for (final DiscoverSearchResult p in results.posts) {
        final String id = (p.id ?? '').trim();
        if (id.isNotEmpty && DeletedPostsRegistry.isDeleted(id)) continue;
        if (p.status != null && p.status!.trim().toLowerCase() != 'published') continue;

        // refId in search API is the post ID (e.g. 223bcc3f-0770-4f52-a639-ca196e26cad7)
        final String? postRefId = (p.refId != null && p.refId!.trim().isNotEmpty)
            ? p.refId!.trim()
            : null;
        final String? cleanRef = (postRefId ?? (p.mediaRefs.isNotEmpty ? p.mediaRefs.first : null))
            ?.replaceAll(RegExp(r'^/+|^media/'), '')
            .trim();

        if (cleanRef != null && cleanRef.isNotEmpty && DeletedPostsRegistry.isDeleted(cleanRef)) continue;

        final String idLower = id.toLowerCase();
        final String cleanRefLower = cleanRef?.toLowerCase() ?? '';

        if (idLower.isNotEmpty && seenPostKeys.contains('id:$idLower')) continue;
        if (cleanRefLower.isNotEmpty && seenPostKeys.contains('id:$cleanRefLower')) continue;

        PostResponseModel? matchingLive = (cleanRefLower.isNotEmpty ? livePostsById[cleanRefLower] : null) ??
            (idLower.isNotEmpty ? livePostsById[idLower] : null) ??
            (cleanRefLower.isNotEmpty ? livePostsByMediaRef[cleanRefLower] : null);

        if (matchingLive == null && cleanRefLower.isNotEmpty) {
          try {
            dynamic postData;
            try {
              postData = await _client.get(
                ApiEndpoints.post(cleanRefLower),
                useCache: false,
              );
            } catch (_) {
              if (!_client.isAuthenticated) {
                postData = await _client.getNoAuth(ApiEndpoints.post(cleanRefLower));
              }
            }
            if (postData is Map) {
              final dynamic postMap = postData['data'] is Map
                  ? postData['data']
                  : postData;
              matchingLive = PostResponseModel.fromJson(
                (postMap as Map).cast<String, dynamic>(),
              );
              livePostsById[cleanRefLower] = matchingLive;
            }
          } catch (err) {
            debugPrint('⚠️ [DiscoverService] Failed to fetch post $cleanRefLower: $err');
          }
        }

        // If post was explicitly marked as deleted in registry, skip
        if (matchingLive != null && DeletedPostsRegistry.isDeleted(matchingLive.id)) {
          continue;
        }

        // Only show posts whose status is "published"
        final String effectivePostStatus = (matchingLive?.status ?? p.status ?? '').trim().toLowerCase();
        if (effectivePostStatus != 'published') {
          continue;
        }

        // Resolve real media URLs from matchingLive or mediaRefs
        String? resolvedImageUrl;
        String? resolvedThumbUrl;
        List<String> effectiveMediaRefs = p.mediaRefs;

        if (matchingLive != null) {
          effectiveMediaRefs = matchingLive.mediaRefs;
          resolvedImageUrl = matchingLive.postImageUrl;
          resolvedThumbUrl = matchingLive.postImageUrl;

          if (resolvedImageUrl == null && matchingLive.mediaRefs.isNotEmpty) {
            final String m = matchingLive.mediaRefs.first.replaceAll(RegExp(r'^/+|^media/'), '').trim();
            if (m.startsWith('http://') || m.startsWith('https://')) {
              resolvedImageUrl = m;
            } else if (matchingLive.authorId != null && matchingLive.authorId!.isNotEmpty) {
              resolvedImageUrl = '${AppConfig.cdnUrl}/images/original/${matchingLive.authorId}/$m.jpg';
            } else {
              resolvedImageUrl = '${AppConfig.cdnUrl}/images/original/$m.jpg';
            }
            resolvedThumbUrl = resolvedImageUrl;
          }
        } else if (p.mediaRefs.isNotEmpty) {
          final String m = p.mediaRefs.first.replaceAll(RegExp(r'^/+|^media/'), '').trim();
          if (m.startsWith('http://') || m.startsWith('https://')) {
            resolvedImageUrl = m;
          } else if (p.authorId != null && p.authorId!.isNotEmpty) {
            resolvedImageUrl = '${AppConfig.cdnUrl}/images/original/${p.authorId}/$m.jpg';
          } else {
            resolvedImageUrl = '${AppConfig.cdnUrl}/images/original/$m.jpg';
          }
          resolvedThumbUrl = resolvedImageUrl;
        } else if (p.imageAsset.isNotEmpty &&
            (p.imageAsset.startsWith('http://') || p.imageAsset.startsWith('https://') || p.imageAsset.startsWith('assets/')) &&
            !(postRefId != null && p.imageAsset.contains(postRefId))) {
          // Only preserve existing imageAsset if it wasn't fabricated with postRefId
          resolvedImageUrl = p.imageAsset;
          resolvedThumbUrl = p.thumbnailUrl ?? p.imageAsset;
        }

        final String? effectiveId = (p.refId != null && p.refId!.trim().isNotEmpty)
            ? p.refId!.trim()
            : p.id?.trim();
        PostInteractionRegistry.linkIds(<String?>[
          effectiveId,
          p.id,
          p.refId,
          cleanRef,
          matchingLive?.id,
          ...p.mediaRefs,
          ...?matchingLive?.mediaRefs,
        ]);
        final int regPostViews = PostInteractionRegistry.getViewsCount(
          effectiveId,
          fallback: p.id != null ? PostInteractionRegistry.getViewsCount(p.id) : 0,
        );
        final int vCount = (matchingLive?.viewsCount ?? 0) > 0
            ? matchingLive!.viewsCount
            : (p.viewsCount > 0 ? p.viewsCount : regPostViews);

        if (vCount > 0) {
          if (effectiveId != null && effectiveId.isNotEmpty) {
            PostInteractionRegistry.setViewsCount(effectiveId, vCount);
          }
          if (p.id != null && p.id!.isNotEmpty) {
            PostInteractionRegistry.setViewsCount(p.id!, vCount);
          }
        }

        final String? formattedV = vCount >= 1000000
            ? '${(vCount / 1000000).toStringAsFixed(1)}M'
            : (vCount >= 1000
                ? '${(vCount / 1000).toStringAsFixed(1)}K'
                : (vCount > 0 ? '$vCount' : null));

        if (effectiveId != null && effectiveId.isNotEmpty) {
          seenPostKeys.add('id:${effectiveId.toLowerCase()}');
        }
        if (cleanRefLower.isNotEmpty) {
          seenPostKeys.add('id:$cleanRefLower');
        }

        final bool isPostLiked = (effectiveId != null && PostInteractionRegistry.isLiked(effectiveId)) ||
            (p.id != null && PostInteractionRegistry.isLiked(p.id!)) ||
            (p.refId != null && PostInteractionRegistry.isLiked(p.refId!)) ||
            (matchingLive != null && PostInteractionRegistry.isLiked(matchingLive.id)) ||
            (matchingLive?.isLiked ?? p.isLiked);

        final bool isPostSaved = (effectiveId != null && PostInteractionRegistry.isSaved(effectiveId)) ||
            (p.id != null && PostInteractionRegistry.isSaved(p.id!)) ||
            (p.refId != null && PostInteractionRegistry.isSaved(p.refId!)) ||
            (matchingLive != null && PostInteractionRegistry.isSaved(matchingLive.id)) ||
            (matchingLive?.isSaved ?? p.isSaved);

        final int postLikes = PostInteractionRegistry.getLikeCount(
          effectiveId ?? p.id ?? '',
          fallback: matchingLive?.likesCount ?? p.likesCount ?? 0,
        );

        verifiedPosts.add(p.copyWith(
          id: matchingLive?.id ?? p.id,
          refId: postRefId ?? p.refId,
          status: matchingLive?.status ?? p.status,
          imageAsset: resolvedImageUrl ?? '',
          thumbnailUrl: resolvedThumbUrl ?? resolvedImageUrl,
          mediaRefs: effectiveMediaRefs,
          caption: matchingLive?.caption ?? p.caption,
          likesCount: postLikes,
          commentsCount: matchingLive?.commentsCount ?? p.commentsCount,
          viewsCount: vCount,
          viewCount: formattedV ?? p.viewCount,
          isLiked: isPostLiked,
          isSaved: isPostSaved,
          authorId: matchingLive?.authorId ?? p.authorId,
          authorUsername: matchingLive?.authorName ?? matchingLive?.authorDisplayName ?? p.authorUsername,
          authorAvatar: matchingLive?.authorAvatar ?? p.authorAvatar,
          type: (matchingLive?.type != null && matchingLive!.type.isNotEmpty) ? matchingLive.type : p.type,
          allowComments: matchingLive?.allowComments ?? p.allowComments,
          allowDownloads: matchingLive?.allowDownloads ?? p.allowDownloads,
          allowCommentsFrom: matchingLive?.allowCommentsFrom ?? p.allowCommentsFrom,
          isAuthorPrivate: matchingLive?.isAuthorPrivate ?? p.isAuthorPrivate,
          communityId: matchingLive?.communityId ?? p.communityId,
        ));

        // ── DEBUG: print each verified post ───────────────────────────────
        final DiscoverSearchResult dbg = verifiedPosts.last;
        debugPrint(
          '  📌 [DiscoverPost] id=${dbg.id} '
          'likesCount=${dbg.likesCount} '
          'isLiked=${dbg.isLiked} '
          'isSaved=${dbg.isSaved} '
          'type=${dbg.type} '
          'caption="${(dbg.caption ?? '').length > 30 ? (dbg.caption ?? '').substring(0, 30) : (dbg.caption ?? '')}"',
        );
      }

      // If verifiedPosts is empty or tab is posts/all, pull matching live posts from Posts API
      if (verifiedPosts.isEmpty && livePosts.isNotEmpty) {
        final String qLower = q.toLowerCase();
        for (final PostResponseModel lp in livePosts) {
          if (!lp.isPublished) continue;
          final String lpIdLower = lp.id.trim().toLowerCase();
          if (seenPostKeys.contains('id:$lpIdLower')) continue;
          if (DeletedPostsRegistry.isDeleted(lp.id)) continue;
          if (lp.type.toUpperCase() == 'VIDEO') continue;
          final bool match = lp.caption.toLowerCase().contains(qLower) ||
              (lp.authorName?.toLowerCase().contains(qLower) ?? false) ||
              (lp.authorDisplayName?.toLowerCase().contains(qLower) ?? false) ||
              lp.tags.any((String t) => t.toLowerCase().contains(qLower));
          if (match) {
            final String? ref = lp.mediaRefs.isNotEmpty ? lp.mediaRefs.first : null;
            String? url = lp.postImageUrl;
            if (url == null && ref != null && ref.isNotEmpty) {
              if (ref.startsWith('http')) {
                url = ref;
              } else if (lp.authorId != null && lp.authorId!.isNotEmpty) {
                url = '${AppConfig.cdnUrl}/images/original/${lp.authorId}/$ref.jpg';
              }
            }
            final bool isLpLiked = PostInteractionRegistry.isLiked(lp.id) ||
                (ref != null && PostInteractionRegistry.isLiked(ref)) ||
                lp.isLiked;
            final bool isLpSaved = PostInteractionRegistry.isSaved(lp.id) ||
                (ref != null && PostInteractionRegistry.isSaved(ref)) ||
                lp.isSaved;
            final int lpLikes = PostInteractionRegistry.getLikeCount(
              ref ?? lp.id,
              fallback: lp.likesCount,
            );

            verifiedPosts.add(DiscoverSearchResult(
              id: lp.id,
              refId: ref,
              status: lp.status,
              caption: lp.caption,
              type: lp.type,
              authorId: lp.authorId,
              authorUsername: lp.authorName ?? lp.authorDisplayName,
              authorAvatar: lp.authorAvatar,
              imageAsset: url ?? '',
              thumbnailUrl: url,
              mediaRefs: lp.mediaRefs,
              likesCount: lpLikes,
              commentsCount: lp.commentsCount,
              viewsCount: lp.viewsCount,
              isLiked: isLpLiked,
              isSaved: isLpSaved,
              communityId: lp.communityId,
            ));
            seenPostKeys.add('id:$lpIdLower');
            if (ref != null && ref.trim().isNotEmpty) {
              seenPostKeys.add('id:${ref.trim().toLowerCase()}');
            }
          }
        }
      }

      // 4. Process Reels: Use refId to resolve actual media; if media does not exist, skip it!
      final List<DiscoverSearchResult> verifiedReels = <DiscoverSearchResult>[];
      final Set<String> seenReelKeys = <String>{};
      for (final DiscoverSearchResult r in results.reels) {
        final String id = (r.id ?? '').trim();
        if (id.isNotEmpty && DeletedPostsRegistry.isDeleted(id)) continue;
        if (r.status != null && r.status!.trim().toLowerCase() != 'published') continue;

        final String? refId = r.refId ?? (r.mediaRefs.isNotEmpty ? r.mediaRefs.first : null);
        if (refId == null || refId.trim().isEmpty) {
          // No media reference ID -> cannot resolve media -> skip!
          continue;
        }

        final String cleanRef = refId.replaceAll(RegExp(r'^/+|^media/'), '').trim();
        if (cleanRef.isNotEmpty && DeletedPostsRegistry.isDeleted(cleanRef)) continue;

        final String idLower = id.toLowerCase();
        final String cleanRefLower = cleanRef.toLowerCase();

        if (idLower.isNotEmpty && seenReelKeys.contains('id:$idLower')) continue;
        if (cleanRefLower.isNotEmpty && seenReelKeys.contains('id:$cleanRefLower')) continue;


        // Check against live posts first: by refId (post ID), search doc id, or media ref
        PostResponseModel? matchingLive = (cleanRef.isNotEmpty ? livePostsById[cleanRefLower] : null) ??
            (idLower.isNotEmpty ? livePostsById[idLower] : null) ??
            (cleanRefLower.isNotEmpty ? livePostsByMediaRef[cleanRefLower] : null);

        // If not in livePosts (since livePosts only fetches the latest 10 items), fetch post by id directly
        if (matchingLive == null && cleanRef.isNotEmpty) {
          try {
            dynamic postData;
            try {
              postData = await _client.get(
                ApiEndpoints.post(cleanRef),
                useCache: false,
              );
            } catch (_) {
              if (!_client.isAuthenticated) {
                postData = await _client.getNoAuth(ApiEndpoints.post(cleanRef));
              }
            }
            if (postData is Map) {
              final dynamic postMap = postData['data'] is Map
                  ? postData['data']
                  : postData;
              matchingLive = PostResponseModel.fromJson(
                (postMap as Map).cast<String, dynamic>(),
              );
              livePostsById[cleanRefLower] = matchingLive;
            }
          } catch (_) {
            // cleanRef may be a media ref
          }
        }

        // If post was explicitly marked as deleted in registry, skip
        if (matchingLive != null && DeletedPostsRegistry.isDeleted(matchingLive.id)) {
          continue;
        }

        // Only show reels whose status is "published"
        final String effectiveReelStatus = (matchingLive?.status ?? r.status ?? '').trim().toLowerCase();
        if (effectiveReelStatus != 'published') {
          continue;
        }

        // Determine actual media ref for the video
        final String mediaId = (matchingLive != null && matchingLive.mediaRefs.isNotEmpty)
            ? matchingLive.mediaRefs.first.replaceAll(RegExp(r'^/+|^media/'), '').trim()
            : cleanRef;

        final String resolvedVid = (mediaId.startsWith('http://') || mediaId.startsWith('https://'))
            ? mediaId
            : '${AppConfig.cdnUrl}/videos/processed/$mediaId/master.m3u8';

        final String resolvedThumb = (matchingLive?.thumbnailUrl != null && matchingLive!.thumbnailUrl!.isNotEmpty)
            ? matchingLive.thumbnailUrl!
            : (matchingLive?.postImageUrl != null && matchingLive!.postImageUrl!.isNotEmpty && !matchingLive.postImageUrl!.endsWith('.m3u8'))
                ? matchingLive.postImageUrl!
                : ((mediaId.startsWith('http://') || mediaId.startsWith('https://'))
                    ? mediaId.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg')
                    : '${AppConfig.cdnUrl}/videos/processed/$mediaId/thumb.0000000.jpg');

        final String reelEffectiveId = matchingLive?.id ?? (id.isNotEmpty ? id : cleanRef);
        final int regViews = PostInteractionRegistry.getViewsCount(
          reelEffectiveId,
          fallback: PostInteractionRegistry.getViewsCount(
            cleanRef,
            fallback: id.isNotEmpty ? PostInteractionRegistry.getViewsCount(id) : 0,
          ),
        );
        final int effectiveViews = (matchingLive?.viewsCount ?? 0) > 0
            ? matchingLive!.viewsCount
            : (r.viewsCount > 0 ? r.viewsCount : regViews);

        if (effectiveViews > 0) {
          PostInteractionRegistry.setViewsCount(reelEffectiveId, effectiveViews);
          if (cleanRef.isNotEmpty) PostInteractionRegistry.setViewsCount(cleanRef, effectiveViews);
          if (id.isNotEmpty) PostInteractionRegistry.setViewsCount(id, effectiveViews);
        }

        final String? formattedViews = effectiveViews >= 1000000
            ? '${(effectiveViews / 1000000).toStringAsFixed(1)}M'
            : (effectiveViews >= 1000
                ? '${(effectiveViews / 1000).toStringAsFixed(1)}K'
                : (effectiveViews > 0 ? '$effectiveViews' : null));

        if (idLower.isNotEmpty) seenReelKeys.add('id:$idLower');
        if (cleanRefLower.isNotEmpty) seenReelKeys.add('id:$cleanRefLower');
        PostInteractionRegistry.linkIds(<String?>[
          reelEffectiveId,
          id,
          cleanRef,
          r.id,
          r.refId,
          matchingLive?.id,
          ...r.mediaRefs,
          ...?matchingLive?.mediaRefs,
        ]);
        final bool isReelLiked = PostInteractionRegistry.isLiked(reelEffectiveId) ||
            (id.isNotEmpty && PostInteractionRegistry.isLiked(id)) ||
            (cleanRef.isNotEmpty && PostInteractionRegistry.isLiked(cleanRef)) ||
            (r.id != null && PostInteractionRegistry.isLiked(r.id!)) ||
            (r.refId != null && PostInteractionRegistry.isLiked(r.refId!)) ||
            (matchingLive != null && PostInteractionRegistry.isLiked(matchingLive.id)) ||
            (matchingLive?.isLiked ?? r.isLiked);

        final bool isReelSaved = PostInteractionRegistry.isSaved(reelEffectiveId) ||
            (id.isNotEmpty && PostInteractionRegistry.isSaved(id)) ||
            (cleanRef.isNotEmpty && PostInteractionRegistry.isSaved(cleanRef)) ||
            (r.id != null && PostInteractionRegistry.isSaved(r.id!)) ||
            (r.refId != null && PostInteractionRegistry.isSaved(r.refId!)) ||
            (matchingLive != null && PostInteractionRegistry.isSaved(matchingLive.id)) ||
            (matchingLive?.isSaved ?? r.isSaved);

        final int reelLikes = PostInteractionRegistry.getLikeCount(
          reelEffectiveId,
          fallback: matchingLive?.likesCount ?? r.likesCount ?? 0,
        );

        verifiedReels.add(r.copyWith(
          id: reelEffectiveId,
          refId: cleanRef,
          status: matchingLive?.status ?? r.status,
          videoUrl: resolvedVid,
          thumbnailUrl: resolvedThumb,
          imageAsset: resolvedThumb,
          caption: (matchingLive?.caption != null && matchingLive!.caption.isNotEmpty)
              ? matchingLive.caption
              : r.caption,
          likesCount: reelLikes,
          commentsCount: matchingLive?.commentsCount ?? r.commentsCount,
          viewsCount: effectiveViews,
          viewCount: formattedViews ?? r.viewCount,
          isLiked: isReelLiked,
          isSaved: isReelSaved,
          authorId: matchingLive?.authorId ?? r.authorId,
          authorUsername: matchingLive?.authorName ?? matchingLive?.authorDisplayName ?? r.authorUsername,
          authorAvatar: matchingLive?.authorAvatar ?? r.authorAvatar,
          communityId: matchingLive?.communityId ?? r.communityId,
          isAuthorPrivate: matchingLive?.isAuthorPrivate ?? r.isAuthorPrivate,
          allowComments: matchingLive?.allowComments ?? r.allowComments,
          allowDownloads: matchingLive?.allowDownloads ?? r.allowDownloads,
          allowCommentsFrom: matchingLive?.allowCommentsFrom ?? r.allowCommentsFrom,
        ));
      }

      // 5. Process Tags: Preserve all search tags and supplement with live tags
      final List<TagSearchResultItem> verifiedTags = <TagSearchResultItem>[];
      final Set<String> addedTagNames = <String>{};

      for (final TagSearchResultItem t in results.tags) {
        final String cleanTag = t.name.replaceAll('#', '').trim().toLowerCase();
        final String count = (liveTagCounts.containsKey(cleanTag) && liveTagCounts[cleanTag]! > 0)
            ? '${liveTagCounts[cleanTag]!}'
            : (t.postsCount.isNotEmpty ? t.postsCount : '0');
        verifiedTags.add(TagSearchResultItem(
          name: t.name,
          postsCount: count,
        ));
        addedTagNames.add(cleanTag);
      }

      // Also add any live tags matching search query that were not returned by search API
      if (livePosts.isNotEmpty) {
        final String qClean = q.replaceAll('#', '').trim().toLowerCase();
        for (final MapEntry<String, int> entry in liveTagCounts.entries) {
          if (!addedTagNames.contains(entry.key) && entry.key.contains(qClean)) {
            verifiedTags.add(TagSearchResultItem(
              name: '#${entry.key}',
              postsCount: '${entry.value}',
            ));
            addedTagNames.add(entry.key);
          }
        }
      }

      return results.copyWith(
        posts: verifiedPosts,
        reels: verifiedReels,
        tags: verifiedTags,
      );
    } on ApiException catch (e) {
      debugPrint('❌ [DiscoverService] search error: $e');
      return const MultiTabSearchResults();
    } catch (e, stack) {
      debugPrint('❌ [DiscoverService] search unexpected: $e\n$stack');
      return const MultiTabSearchResults();
    }
  }

  // ── Recent Searches ────────────────────────────────────────────────────────
  /// GET /discover/recent-searches
  Future<List<RecentSearchItem>> getRecentSearches() async {
    try {
      debugPrint('🚀 [DiscoverService] Fetching recent searches...');
      final dynamic res = await _client.get(
        ApiEndpoints.discoverRecentSearches,
        useCache: false,
      );

      final List<dynamic> list = _extractList(res, keys: <String>[
        'data',
        'recentSearches',
        'searches',
        'items',
      ]);

      return list.map((dynamic item) => RecentSearchItem.fromJson(item)).toList();
    } on ApiException catch (e) {
      debugPrint('❌ [DiscoverService] getRecentSearches error: $e');
      return <RecentSearchItem>[];
    } catch (e, stack) {
      debugPrint('❌ [DiscoverService] getRecentSearches unexpected: $e\n$stack');
      return <RecentSearchItem>[];
    }
  }

  /// POST /discover/recent-searches
  Future<RecentSearchItem?> saveRecentSearch(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return null;

    try {
      debugPrint('💾 [DiscoverService] Saving recent search: "$trimmed"');
      final dynamic res = await _client.post(
        ApiEndpoints.discoverRecentSearches,
        body: <String, dynamic>{'query': trimmed},
      );

      if (res is Map<String, dynamic>) {
        final dynamic data = res['data'] ?? res;
        return RecentSearchItem.fromJson(data);
      }
      return RecentSearchItem(id: trimmed, query: trimmed);
    } on ApiException catch (e) {
      debugPrint('⚠️ [DiscoverService] saveRecentSearch error (non-fatal): $e');
      return RecentSearchItem(id: trimmed, query: trimmed);
    } catch (e) {
      debugPrint('⚠️ [DiscoverService] saveRecentSearch unexpected: $e');
      return RecentSearchItem(id: trimmed, query: trimmed);
    }
  }

  /// DELETE /discover/recent-searches/:id
  Future<bool> deleteRecentSearch(String id) async {
    try {
      debugPrint('🗑️ [DiscoverService] Deleting recent search id: $id');
      await _client.delete(ApiEndpoints.discoverRecentSearch(id));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [DiscoverService] deleteRecentSearch error: $e');
      return false;
    } catch (e) {
      debugPrint('❌ [DiscoverService] deleteRecentSearch unexpected: $e');
      return false;
    }
  }

  /// DELETE /discover/recent-searches
  Future<bool> clearAllRecentSearches() async {
    try {
      debugPrint('🗑️ [DiscoverService] Clearing all recent searches');
      await _client.delete(ApiEndpoints.discoverRecentSearches);
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [DiscoverService] clearAllRecentSearches error: $e');
      return false;
    } catch (e) {
      debugPrint('❌ [DiscoverService] clearAllRecentSearches unexpected: $e');
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<dynamic> _extractList(dynamic res, {required List<String> keys}) {
    if (res is List) return res;
    if (res is Map) {
      for (final String key in keys) {
        if (res[key] is List) return res[key] as List<dynamic>;
        if (res[key] is Map) {
          final Map sub = res[key] as Map;
          for (final String subKey in keys) {
            if (sub[subKey] is List) {
              return sub[subKey] as List<dynamic>;
            }
          }
        }
      }
    }
    return <dynamic>[];
  }

  MultiTabSearchResults _parseSearchResults(dynamic res, {required String activeTab}) {
    if (res == null) return const MultiTabSearchResults();

    Map<String, dynamic>? dataMap;
    if (res is Map) {
      if (res['data'] is Map) {
        dataMap = (res['data'] as Map).cast<String, dynamic>();
      } else {
        dataMap = res.cast<String, dynamic>();
      }
    }

    final List<DiscoverSearchResult> posts = <DiscoverSearchResult>[];
    final List<DiscoverSearchResult> reels = <DiscoverSearchResult>[];
    final List<DiscoverPerson> people = <DiscoverPerson>[];
    final List<TagSearchResultItem> tags = <TagSearchResultItem>[];
    final List<DiscoverCommunity> communities = <DiscoverCommunity>[];

    // Case 1: Direct list returned for specific tab
    if (res is List) {
      switch (activeTab) {
        case 'posts':
          posts.addAll(
            res.whereType<Map>().map((Map m) => DiscoverSearchResult.fromJson(m.cast<String, dynamic>())),
          );
          break;
        case 'reels':
          for (final dynamic item in res) {
            if (item is Map) {
              final Map<String, dynamic> rMap = item.cast<String, dynamic>();
              rMap['postType'] ??= 'VIDEO';
              reels.add(DiscoverSearchResult.fromJson(rMap));
            }
          }
          break;
        case 'people':
          people.addAll(
            res.whereType<Map>().map((Map m) => DiscoverPerson.fromJson(m.cast<String, dynamic>())),
          );
          break;
        case 'tags':
          tags.addAll(
            res.whereType<Map>().map((Map m) => TagSearchResultItem.fromJson(m.cast<String, dynamic>())),
          );
          break;
        case 'communities':
          communities.addAll(
            res.whereType<Map>().map((Map m) => DiscoverCommunity.fromJson(m.cast<String, dynamic>())),
          );
          break;
        default:
          posts.addAll(
            res.whereType<Map>().map((Map m) => DiscoverSearchResult.fromJson(m.cast<String, dynamic>())),
          );
          break;
      }
      return MultiTabSearchResults(
        posts: posts,
        reels: reels,
        people: people,
        tags: tags,
        communities: communities,
      );
    }

    if (dataMap == null) return const MultiTabSearchResults();

    // Parse Posts
    final dynamic postsRaw = dataMap['posts'] ??
        (activeTab == 'posts'
            ? (dataMap['items'] ?? dataMap['results'] ?? dataMap['data'])
            : null);
    if (postsRaw is List) {
      posts.addAll(
        postsRaw.whereType<Map>().map((Map m) => DiscoverSearchResult.fromJson(m.cast<String, dynamic>())),
      );
    }

    // Parse Reels
    final dynamic reelsRaw = dataMap['reels'] ??
        (activeTab == 'reels'
            ? (dataMap['items'] ?? dataMap['results'] ?? dataMap['data'])
            : null);
    if (reelsRaw is List) {
      for (final dynamic r in reelsRaw) {
        if (r is Map) {
          final Map<String, dynamic> rMap = Map<String, dynamic>.from(r.cast<String, dynamic>());
          rMap['postType'] ??= 'VIDEO';
          reels.add(DiscoverSearchResult.fromJson(rMap));
        }
      }
    }

    // Parse People / Users
    final dynamic peopleRaw = dataMap['people'] ??
        dataMap['users'] ??
        (activeTab == 'people' ? (dataMap['items'] ?? dataMap['results']) : null);
    if (peopleRaw is List) {
      people.addAll(
        peopleRaw.whereType<Map>().map((Map m) => DiscoverPerson.fromJson(m.cast<String, dynamic>())),
      );
    }

    // Parse Tags / Hashtags
    final dynamic tagsRaw = dataMap['tags'] ??
        dataMap['hashtags'] ??
        (activeTab == 'tags' ? (dataMap['items'] ?? dataMap['results']) : null);
    if (tagsRaw is List) {
      for (final dynamic t in tagsRaw) {
        if (t is Map) {
          tags.add(TagSearchResultItem.fromJson(t.cast<String, dynamic>()));
        } else if (t is String) {
          tags.add(TagSearchResultItem(name: t.startsWith('#') ? t : '#$t'));
        }
      }
    }

    // Parse Communities
    final dynamic communitiesRaw = dataMap['communities'] ??
        (activeTab == 'communities' ? (dataMap['items'] ?? dataMap['results']) : null);
    if (communitiesRaw is List) {
      communities.addAll(
        communitiesRaw.whereType<Map>().map((Map m) => DiscoverCommunity.fromJson(m.cast<String, dynamic>())),
      );
    }

    return MultiTabSearchResults(
      posts: posts,
      reels: reels,
      people: people,
      tags: tags,
      communities: communities,
    );
  }
}

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

  static final Map<String, Map<String, String>> _mediaStatusCache =
      <String, Map<String, String>>{};

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
      try {
        final dynamic fallbackRes = await _client.getNoAuth(ApiEndpoints.posts);
        return _parsePostsResponse(fallbackRes);
      } catch (_) {
        return <PostResponseModel>[];
      }
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
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(PostResponseModel.fromJson)
        .toList();
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

      // 2. Fetch live existing posts from Posts API to reconcile deleted/stale content
      final List<PostResponseModel> livePosts = await getLivePosts();

      // Build lookup indices of live existing posts
      final Map<String, PostResponseModel> livePostsById = <String, PostResponseModel>{};
      final Map<String, PostResponseModel> livePostsByMediaRef = <String, PostResponseModel>{};
      final Map<String, int> liveTagCounts = <String, int>{};

      for (final PostResponseModel lp in livePosts) {
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
      for (final DiscoverSearchResult p in results.posts) {
        final String id = p.id ?? '';
        if (id.isNotEmpty && DeletedPostsRegistry.isDeleted(id)) continue;

        final String? cleanRef = (p.refId ?? (p.mediaRefs.isNotEmpty ? p.mediaRefs.first : null))
            ?.replaceAll(RegExp(r'^/+|^media/'), '')
            .trim()
            .toLowerCase();

        final PostResponseModel? matchingLive = (id.isNotEmpty ? livePostsById[id.toLowerCase()] : null) ??
            (cleanRef != null && cleanRef.isNotEmpty ? livePostsByMediaRef[cleanRef] : null);

        // If livePosts API is active and this post is missing from livePosts, it has been deleted!
        if (livePosts.isNotEmpty && matchingLive == null) {
          debugPrint('🗑️ [DiscoverService] Skipping deleted post: id=$id, refId=$cleanRef');
          continue;
        }

        final String? effectiveRefId = p.refId ??
            (matchingLive != null && matchingLive.mediaRefs.isNotEmpty ? matchingLive.mediaRefs.first : null) ??
            cleanRef;

        // Resolve media URL from refId (NOT id)
        String? mediaUrl;
        if (effectiveRefId != null && effectiveRefId.isNotEmpty) {
          if (effectiveRefId.startsWith('http://') || effectiveRefId.startsWith('https://')) {
            mediaUrl = effectiveRefId;
          } else if (matchingLive?.authorId != null && matchingLive!.authorId!.isNotEmpty) {
            mediaUrl = '${AppConfig.cdnUrl}/images/original/${matchingLive.authorId}/$effectiveRefId.jpg';
          } else if (p.authorId != null && p.authorId!.isNotEmpty) {
            mediaUrl = '${AppConfig.cdnUrl}/images/original/${p.authorId}/$effectiveRefId.jpg';
          } else {
            mediaUrl = '${AppConfig.cdnUrl}/images/original/$effectiveRefId.jpg';
          }
        }

        verifiedPosts.add(p.copyWith(
          refId: effectiveRefId,
          imageAsset: mediaUrl ?? matchingLive?.postImageUrl ?? p.imageAsset,
          thumbnailUrl: mediaUrl ?? matchingLive?.postImageUrl ?? p.thumbnailUrl,
          caption: matchingLive?.caption ?? p.caption,
          likesCount: matchingLive?.likesCount ?? p.likesCount,
          commentsCount: matchingLive?.commentsCount ?? p.commentsCount,
          viewsCount: matchingLive?.viewsCount ?? p.viewsCount,
          isLiked: matchingLive?.isLiked ?? p.isLiked,
          isSaved: matchingLive?.isSaved ?? p.isSaved,
          authorId: matchingLive?.authorId ?? p.authorId,
          authorUsername: matchingLive?.authorName ?? matchingLive?.authorDisplayName ?? p.authorUsername,
          authorAvatar: matchingLive?.authorAvatar ?? p.authorAvatar,
        ));
      }

      // If verifiedPosts is empty or tab is posts/all, pull matching live posts from Posts API
      if (verifiedPosts.isEmpty && livePosts.isNotEmpty) {
        final String qLower = q.toLowerCase();
        final Set<String> existingIds = verifiedPosts.map((DiscoverSearchResult p) => p.id ?? '').toSet();
        for (final PostResponseModel lp in livePosts) {
          if (existingIds.contains(lp.id)) continue;
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
            verifiedPosts.add(DiscoverSearchResult(
              id: lp.id,
              refId: ref,
              caption: lp.caption,
              type: lp.type,
              authorId: lp.authorId,
              authorUsername: lp.authorName ?? lp.authorDisplayName,
              authorAvatar: lp.authorAvatar,
              imageAsset: url ?? '',
              thumbnailUrl: url,
              mediaRefs: lp.mediaRefs,
              likesCount: lp.likesCount,
              commentsCount: lp.commentsCount,
              viewsCount: lp.viewsCount,
              isLiked: lp.isLiked,
              communityId: lp.communityId,
            ));
            existingIds.add(lp.id);
          }
        }
      }

      // 4. Process Reels: Use refId to resolve actual media; if media does not exist, skip it!
      final List<DiscoverSearchResult> verifiedReels = <DiscoverSearchResult>[];
      for (final DiscoverSearchResult r in results.reels) {
        final String id = r.id ?? '';
        if (id.isNotEmpty && DeletedPostsRegistry.isDeleted(id)) continue;

        final String? refId = r.refId ?? (r.mediaRefs.isNotEmpty ? r.mediaRefs.first : null);
        if (refId == null || refId.trim().isEmpty) {
          // No media reference ID -> cannot resolve media -> skip!
          continue;
        }

        final String cleanRef = refId.replaceAll(RegExp(r'^/+|^media/'), '').trim();

        // Check if media resolution is already cached
        if (_mediaStatusCache.containsKey(cleanRef)) {
          final Map<String, String> cached = _mediaStatusCache[cleanRef]!;
          if (cached['exists'] == 'false') {
            // Media does not exist -> skip!
            continue;
          }
          final String? url = cached['url'];
          final String? thumb = cached['thumbnailUrl'];
          verifiedReels.add(r.copyWith(
            refId: cleanRef,
            videoUrl: url ?? r.videoUrl,
            thumbnailUrl: thumb ?? r.thumbnailUrl,
            imageAsset: thumb ?? url ?? r.imageAsset,
          ));
          continue;
        }

        // Check against live posts first: if live post has this ref and is active
        final PostResponseModel? matchingLive = (id.isNotEmpty ? livePostsById[id.toLowerCase()] : null) ??
            livePostsByMediaRef[cleanRef.toLowerCase()];

        // If not in livePosts and livePosts is populated, verify with Media Status API
        if (livePosts.isNotEmpty && matchingLive == null) {
          try {
            final dynamic mediaData = await _client.get(
              ApiEndpoints.mediaStatus(cleanRef),
              useCache: false,
            );
            if (mediaData is Map<String, dynamic>) {
              final String? url = mediaData['url'] as String? ?? mediaData['downloadUrl'] as String?;
              final String? thumb = mediaData['thumbnailUrl'] as String?;
              final String? status = mediaData['status']?.toString().toLowerCase();

              if (status == 'failed' || (url == null && thumb == null)) {
                _mediaStatusCache[cleanRef] = <String, String>{'exists': 'false'};
                continue;
              }

              final String resolvedVid = url ?? '${AppConfig.cdnUrl}/videos/processed/$cleanRef/master.m3u8';
              final String resolvedThumb = thumb ?? '${AppConfig.cdnUrl}/videos/processed/$cleanRef/thumbnail.jpg';

              _mediaStatusCache[cleanRef] = <String, String>{
                'exists': 'true',
                'url': resolvedVid,
                'thumbnailUrl': resolvedThumb,
              };

              verifiedReels.add(r.copyWith(
                refId: cleanRef,
                videoUrl: resolvedVid,
                thumbnailUrl: resolvedThumb,
                imageAsset: resolvedThumb,
              ));
            } else {
              _mediaStatusCache[cleanRef] = <String, String>{'exists': 'false'};
              continue;
            }
          } catch (e) {
            debugPrint('⚠️ [DiscoverService] Reel media $cleanRef not found: $e');
            _mediaStatusCache[cleanRef] = <String, String>{'exists': 'false'};
            // Media no longer exists -> skip!
            continue;
          }
        } else if (matchingLive != null) {
          // Reel exists in live posts!
          final String resolvedVid = matchingLive.postImageUrl ??
              '${AppConfig.cdnUrl}/videos/processed/$cleanRef/master.m3u8';
          final String resolvedThumb =
              '${AppConfig.cdnUrl}/videos/processed/$cleanRef/thumbnail.jpg';

          _mediaStatusCache[cleanRef] = <String, String>{
            'exists': 'true',
            'url': resolvedVid,
            'thumbnailUrl': resolvedThumb,
          };

          verifiedReels.add(r.copyWith(
            refId: cleanRef,
            videoUrl: resolvedVid,
            thumbnailUrl: resolvedThumb,
            imageAsset: resolvedThumb,
            caption: matchingLive.caption.isNotEmpty ? matchingLive.caption : r.caption,
            likesCount: matchingLive.likesCount,
            commentsCount: matchingLive.commentsCount,
            viewsCount: matchingLive.viewsCount,
            isLiked: matchingLive.isLiked,
            authorId: matchingLive.authorId ?? r.authorId,
            authorUsername: matchingLive.authorName ?? matchingLive.authorDisplayName ?? r.authorUsername,
            authorAvatar: matchingLive.authorAvatar ?? r.authorAvatar,
          ));
        } else {
          // livePosts was empty -> verify via mediaStatus
          try {
            final dynamic mediaData = await _client.get(
              ApiEndpoints.mediaStatus(cleanRef),
              useCache: false,
            );
            if (mediaData is Map<String, dynamic>) {
              final String? url = mediaData['url'] as String? ?? mediaData['downloadUrl'] as String?;
              final String? thumb = mediaData['thumbnailUrl'] as String?;
              if (url == null && thumb == null) {
                _mediaStatusCache[cleanRef] = <String, String>{'exists': 'false'};
                continue;
              }
              final String resolvedVid = url ?? '${AppConfig.cdnUrl}/videos/processed/$cleanRef/master.m3u8';
              final String resolvedThumb = thumb ?? '${AppConfig.cdnUrl}/videos/processed/$cleanRef/thumbnail.jpg';
              _mediaStatusCache[cleanRef] = <String, String>{
                'exists': 'true',
                'url': resolvedVid,
                'thumbnailUrl': resolvedThumb,
              };
              verifiedReels.add(r.copyWith(
                refId: cleanRef,
                videoUrl: resolvedVid,
                thumbnailUrl: resolvedThumb,
                imageAsset: resolvedThumb,
              ));
            } else {
              _mediaStatusCache[cleanRef] = <String, String>{'exists': 'false'};
              continue;
            }
          } catch (_) {
            _mediaStatusCache[cleanRef] = <String, String>{'exists': 'false'};
            continue;
          }
        }
      }

      // 5. Process Tags: Do not display tags from deleted posts; verify against live posts
      final List<TagSearchResultItem> verifiedTags = <TagSearchResultItem>[];
      final Set<String> addedTagNames = <String>{};

      for (final TagSearchResultItem t in results.tags) {
        final String cleanTag = t.name.replaceAll('#', '').trim().toLowerCase();
        if (livePosts.isNotEmpty) {
          // If we have live posts, only show tags that actually exist in live posts!
          if (liveTagCounts.containsKey(cleanTag) && liveTagCounts[cleanTag]! > 0) {
            verifiedTags.add(TagSearchResultItem(
              name: t.name,
              postsCount: '${liveTagCounts[cleanTag]!}',
            ));
            addedTagNames.add(cleanTag);
          }
        } else {
          verifiedTags.add(t);
          addedTagNames.add(cleanTag);
        }
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
    if (res is Map<String, dynamic>) {
      for (final String key in keys) {
        if (res[key] is List) return res[key] as List<dynamic>;
        if (res[key] is Map<String, dynamic>) {
          for (final String subKey in keys) {
            if ((res[key] as Map<String, dynamic>)[subKey] is List) {
              return (res[key] as Map<String, dynamic>)[subKey] as List<dynamic>;
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
    if (res is Map<String, dynamic>) {
      if (res['data'] is Map<String, dynamic>) {
        dataMap = res['data'] as Map<String, dynamic>;
      } else {
        dataMap = res;
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
          posts.addAll(res.whereType<Map<String, dynamic>>().map(DiscoverSearchResult.fromJson));
          break;
        case 'reels':
          for (final dynamic item in res) {
            if (item is Map<String, dynamic>) {
              final Map<String, dynamic> rMap = Map<String, dynamic>.from(item);
              rMap['postType'] ??= 'VIDEO';
              reels.add(DiscoverSearchResult.fromJson(rMap));
            }
          }
          break;
        case 'people':
          people.addAll(res.whereType<Map<String, dynamic>>().map(DiscoverPerson.fromJson));
          break;
        case 'tags':
          tags.addAll(res.whereType<Map<String, dynamic>>().map(TagSearchResultItem.fromJson));
          break;
        case 'communities':
          communities.addAll(res.whereType<Map<String, dynamic>>().map(DiscoverCommunity.fromJson));
          break;
        default:
          posts.addAll(res.whereType<Map<String, dynamic>>().map(DiscoverSearchResult.fromJson));
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
      posts.addAll(postsRaw.whereType<Map<String, dynamic>>().map(DiscoverSearchResult.fromJson));
    }

    // Parse Reels
    final dynamic reelsRaw = dataMap['reels'] ??
        (activeTab == 'reels'
            ? (dataMap['items'] ?? dataMap['results'] ?? dataMap['data'])
            : null);
    if (reelsRaw is List) {
      for (final dynamic r in reelsRaw) {
        if (r is Map<String, dynamic>) {
          final Map<String, dynamic> rMap = Map<String, dynamic>.from(r);
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
      people.addAll(peopleRaw.whereType<Map<String, dynamic>>().map(DiscoverPerson.fromJson));
    }

    // Parse Tags / Hashtags
    final dynamic tagsRaw = dataMap['tags'] ??
        dataMap['hashtags'] ??
        (activeTab == 'tags' ? (dataMap['items'] ?? dataMap['results']) : null);
    if (tagsRaw is List) {
      for (final dynamic t in tagsRaw) {
        if (t is Map<String, dynamic>) {
          tags.add(TagSearchResultItem.fromJson(t));
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
        communitiesRaw.whereType<Map<String, dynamic>>().map(DiscoverCommunity.fromJson),
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

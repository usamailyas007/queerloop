import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
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

  // ── Multi-Tab Search ───────────────────────────────────────────────────────
  /// Posts: GET /search?q=:query&limit=10
  /// Other tabs & All: GET /discover/search?query=:query&tab=:tab
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

      // ── Dedicated Posts Search Endpoint ──────────────────────────────────
      if (tab == 'posts') {
        try {
          debugPrint('🔍 [DiscoverService] Calling /search?q=$q&limit=10');
          final dynamic res = await _client.get(
            ApiEndpoints.searchPosts(query: q, limit: 10),
            useCache: false,
          );
          final MultiTabSearchResults parsed =
              _parseSearchResults(res, activeTab: 'posts');
          if (parsed.posts.isNotEmpty) {
            return parsed;
          }
        } catch (e) {
          debugPrint(
            '⚠️ [DiscoverService] /search?q= error: $e, falling back to /discover/search',
          );
        }

        // Fallback to /discover/search?query=:query&tab=posts
        final dynamic resFallback = await _client.get(
          ApiEndpoints.discoverSearch(query: q, tab: 'posts'),
          useCache: false,
        );
        return _parseSearchResults(resFallback, activeTab: 'posts');
      }

      // ── All or Other Tabs (People, Tags, Communities) ─────────────────────
      final dynamic res = await _client.get(
        ApiEndpoints.discoverSearch(query: q, tab: tab),
        useCache: false,
      );
      MultiTabSearchResults results = _parseSearchResults(res, activeTab: tab);

      // If tab == 'all' and no posts were returned, query /search?q=:query&limit=10 to populate posts
      if (tab == 'all' && results.posts.isEmpty) {
        try {
          final dynamic postsRes = await _client.get(
            ApiEndpoints.searchPosts(query: q, limit: 10),
            useCache: false,
          );
          final MultiTabSearchResults postsParsed =
              _parseSearchResults(postsRes, activeTab: 'posts');
          if (postsParsed.posts.isNotEmpty) {
            results = results.copyWith(posts: postsParsed.posts);
          }
        } catch (_) {}
      }

      return results;
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
    final List<DiscoverPerson> people = <DiscoverPerson>[];
    final List<TagSearchResultItem> tags = <TagSearchResultItem>[];
    final List<DiscoverCommunity> communities = <DiscoverCommunity>[];

    // Case 1: Direct list returned for specific tab
    if (res is List) {
      switch (activeTab) {
        case 'posts':
          posts.addAll(res.whereType<Map<String, dynamic>>().map(DiscoverSearchResult.fromJson));
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
      people: people,
      tags: tags,
      communities: communities,
    );
  }
}

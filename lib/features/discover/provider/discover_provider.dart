import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/cache/user_relationship_cache.dart';
import '../../../core/theme/app_images.dart';
import '../../home/models/post_item_model.dart';
import '../../home/models/reel_item_model.dart';
import '../models/discover_models.dart';
import '../services/discover_service.dart';
import '../widgets/search_tag_tile.dart';

class DiscoverProvider extends ChangeNotifier {
  DiscoverProvider({DiscoverService? discoverService})
      : _discoverService = discoverService {
    fetchDiscoverData();
  }

  final DiscoverService? _discoverService;

  Timer? _debounceTimer;

  // ── Loading States ──────────────────────────────────────────────────────────
  bool _isInitialLoading = true;
  bool _isLoadingTrending = false;
  bool _isLoadingCreatorsToWatch = false;
  bool _isLoadingNewCreators = false;
  bool _isLoadingSearch = false;
  bool _isLoadingRecentSearches = false;

  bool get isInitialLoading => _isInitialLoading;
  bool get isDiscoverLoading =>
      _isInitialLoading || (_isLoadingTrending && _trendingItems.isEmpty);
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isLoadingCreatorsToWatch => _isLoadingCreatorsToWatch;
  bool get isLoadingNewCreators => _isLoadingNewCreators;
  bool get isLoadingSearch => _isLoadingSearch;
  bool get isLoadingRecentSearches => _isLoadingRecentSearches;

  // ── Search State ────────────────────────────────────────────────────────────
  bool _isSearchFocused = false;
  String _searchQuery = '';

  bool get isSearchFocused => _isSearchFocused;
  String get searchQuery => _searchQuery;
  bool get isSearching => _searchQuery.trim().isNotEmpty;

  // ── Search Tab ──────────────────────────────────────────────────────────────
  // 0=All, 1=Posts, 2=Reels, 3=People, 4=Tags, 5=Communities
  int _selectedSearchTab = 0;
  int get selectedSearchTab => _selectedSearchTab;

  static const List<String> _tabMapping = <String>[
    'all',
    'posts',
    'reels',
    'people',
    'tags',
    'communities',
  ];

  // In-memory search cache: "tab:query" -> MultiTabSearchResults
  final Map<String, MultiTabSearchResults> _searchCache = <String, MultiTabSearchResults>{};

  // Live search results
  MultiTabSearchResults _searchResults = const MultiTabSearchResults();
  MultiTabSearchResults get currentSearchResults => _searchResults;

  // Live content from HomeFeedProvider for seamless offline/in-app search matching
  List<PostItemModel> _liveHomePosts = const <PostItemModel>[];
  List<ReelItemModel> _liveHomeReels = const <ReelItemModel>[];

  void syncHomeFeedContent({
    List<PostItemModel> posts = const <PostItemModel>[],
    List<ReelItemModel> reels = const <ReelItemModel>[],
  }) {
    _liveHomePosts = posts;
    _liveHomeReels = reels;
    _updateTrendingCountsWithLiveFeed();
  }

  // Current authenticated user (to exclude from search/explore)
  String? _currentUserId;
  String? _currentUsername;

  void setCurrentUser({String? userId, String? username}) {
    if (_currentUserId != userId || _currentUsername != username) {
      _currentUserId = userId;
      _currentUsername = username;
      notifyListeners();
    }
  }

  List<DiscoverSearchResult> _filterDeletedPosts(List<DiscoverSearchResult> list) {
    return list.where((DiscoverSearchResult p) {
      final String id = p.id ?? '';
      return id.isNotEmpty && !DeletedPostsRegistry.isDeleted(id);
    }).toList();
  }

  List<DiscoverSearchResult> _filterVisiblePosts(List<DiscoverSearchResult> list) {
    return list.where((DiscoverSearchResult p) {
      final bool isFollowing = UserRelationshipCache.isFollowing(
        userId: p.authorId,
        username: p.authorUsername,
      );
      return PostVisibilityFilter.canViewPost(
        visibility: p.visibility,
        authorId: p.authorId,
        authorUsername: p.authorUsername,
        currentUserId: _currentUserId,
        currentUsername: _currentUsername,
        isGuest: _currentUserId == null || _currentUserId!.isEmpty,
        isFollowing: isFollowing,
        isAuthorPrivate: p.isAuthorPrivate,
      );
    }).toList();
  }

  List<DiscoverSearchResult> get searchResults =>
      _filterVisiblePosts(_filterDeletedPosts(_searchResults.posts));

  List<DiscoverSearchResult> get postsResults =>
      searchResults.where((DiscoverSearchResult p) => !p.isReel).toList();

  List<DiscoverSearchResult> get reelsResults {
    final List<DiscoverSearchResult> fromReels =
        _filterVisiblePosts(_filterDeletedPosts(_searchResults.reels));
    final List<DiscoverSearchResult> fromPosts =
        searchResults.where((DiscoverSearchResult p) => p.isReel).toList();
    final Set<String> seenIds = <String>{};
    final List<DiscoverSearchResult> combined = <DiscoverSearchResult>[];
    for (final DiscoverSearchResult r in <DiscoverSearchResult>[...fromReels, ...fromPosts]) {
      final String id = r.id ?? '';
      if (id.isNotEmpty && !DeletedPostsRegistry.isDeleted(id) && seenIds.add(id)) {
        combined.add(r);
      }
    }
    return combined;
  }

  List<DiscoverPerson> get peopleResults {
    if (_currentUserId == null && _currentUsername == null) {
      return _searchResults.people;
    }
    final String cleanUid = _currentUserId?.trim().toLowerCase() ?? '';
    final String cleanUname = _currentUsername?.replaceAll('@', '').trim().toLowerCase() ?? '';
    return _searchResults.people.where((DiscoverPerson p) {
      if (cleanUid.isNotEmpty && p.id != null && p.id!.trim().toLowerCase() == cleanUid) {
        return false;
      }
      if (cleanUname.isNotEmpty && p.username.replaceAll('@', '').trim().toLowerCase() == cleanUname) {
        return false;
      }
      return true;
    }).toList();
  }

  List<TagSearchResultItem> get tagResults => _searchResults.tags;

  List<DiscoverCommunity> get communityResults => _searchResults.communities;

  bool get hasResults {
    if (_searchQuery.trim().isEmpty) return false;
    if (_isLoadingSearch) return true; // Show results layout during search transition

    switch (_selectedSearchTab) {
      case 0:
        return _searchResults.isNotEmpty ||
            _searchResults.posts.isNotEmpty ||
            _searchResults.reels.isNotEmpty ||
            _searchResults.people.isNotEmpty ||
            _searchResults.tags.isNotEmpty ||
            _searchResults.communities.isNotEmpty;
      case 1:
        return postsResults.isNotEmpty;
      case 2:
        return reelsResults.isNotEmpty;
      case 3:
        return _searchResults.people.isNotEmpty;
      case 4:
        return _searchResults.tags.isNotEmpty;
      case 5:
        return _searchResults.communities.isNotEmpty;
      default:
        return _searchResults.isNotEmpty;
    }
  }

  void setSearchFocused(bool focused) {
    if (_isSearchFocused == focused) return;
    _isSearchFocused = focused;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;

    _debounceTimer?.cancel();
    final String trimmed = query.trim();

    if (trimmed.isEmpty) {
      _isLoadingSearch = false;
      _searchResults = const MultiTabSearchResults();
      notifyListeners();
      return;
    }

    _isLoadingSearch = true;
    notifyListeners();

    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      _executeSearch(trimmed, _selectedSearchTab);
    });
  }

  void setSelectedSearchTab(int index) {
    if (_selectedSearchTab == index) return;
    _selectedSearchTab = index;
    notifyListeners();

    final String trimmed = _searchQuery.trim();
    if (trimmed.isNotEmpty) {
      _executeSearch(trimmed, index);
    }
  }

  void clearSearchQuery() {
    _debounceTimer?.cancel();
    _searchQuery = '';
    _isSearchFocused = false;
    _isLoadingSearch = false;
    _searchResults = const MultiTabSearchResults();
    notifyListeners();
  }

  void notifyPostDeleted(String postId) {
    final String clean = postId.trim();
    if (clean.isEmpty) return;
    DeletedPostsRegistry.markDeleted(clean);
    _searchCache.clear();
    _liveHomePosts = _liveHomePosts.where((PostItemModel p) => p.id != clean).toList();
    _liveHomeReels = _liveHomeReels.where((ReelItemModel r) => r.id != clean).toList();
    _searchResults = _searchResults.copyWith(
      posts: _searchResults.posts.where((DiscoverSearchResult p) => p.id != clean).toList(),
      reels: _searchResults.reels.where((DiscoverSearchResult r) => r.id != clean).toList(),
    );
    notifyListeners();
  }

  Future<void> _executeSearch(String query, int tabIndex) async {
    final String tabName =
        (tabIndex >= 0 && tabIndex < _tabMapping.length) ? _tabMapping[tabIndex] : 'all';
    final String cacheKey = '$tabName:${query.toLowerCase()}';

    if (_searchCache.containsKey(cacheKey)) {
      _searchResults = _searchCache[cacheKey]!;
      _isLoadingSearch = false;
      notifyListeners();
      return;
    }

    if (_discoverService == null) {
      _isLoadingSearch = false;
      notifyListeners();
      return;
    }

    try {
      MultiTabSearchResults results = await _discoverService.search(
        query: query,
        tab: tabName,
      );

      // Merge matching posts and reels from live home feed so recently created or loaded content is immediately searchable
      final String qLower = query.toLowerCase();
      final List<DiscoverSearchResult> localMatchedPosts = <DiscoverSearchResult>[];
      final List<DiscoverSearchResult> localMatchedReels = <DiscoverSearchResult>[];

      if (tabName == 'all' || tabName == 'posts') {
        for (final PostItemModel p in _liveHomePosts) {
          if (DeletedPostsRegistry.isDeleted(p.id)) continue;
          if (p.postType.toUpperCase().trim() == 'VIDEO') continue;
          if (p.content.toLowerCase().contains(qLower) ||
              p.username.toLowerCase().contains(qLower)) {
            localMatchedPosts.add(DiscoverSearchResult.fromPostItem(p));
          }
        }
      }

      if (tabName == 'all' || tabName == 'reels') {
        for (final ReelItemModel r in _liveHomeReels) {
          if (DeletedPostsRegistry.isDeleted(r.id)) continue;
          if (r.caption.toLowerCase().contains(qLower) ||
              r.username.toLowerCase().contains(qLower) ||
              r.tags.any((String t) => t.toLowerCase().contains(qLower))) {
            localMatchedReels.add(DiscoverSearchResult.fromReelItem(r));
          }
        }
      }

      final List<DiscoverSearchResult> filteredPosts = results.posts
          .where((DiscoverSearchResult p) => !DeletedPostsRegistry.isDeleted(p.id ?? ''))
          .toList();
      final List<DiscoverSearchResult> filteredReels = results.reels
          .where((DiscoverSearchResult r) => !DeletedPostsRegistry.isDeleted(r.id ?? ''))
          .toList();

      if (localMatchedPosts.isNotEmpty) {
        final Set<String> existingIds =
            filteredPosts.map((DiscoverSearchResult p) => p.id ?? '').toSet();
        for (final DiscoverSearchResult lm in localMatchedPosts) {
          if (lm.id != null && !existingIds.contains(lm.id)) {
            filteredPosts.add(lm);
            existingIds.add(lm.id!);
          }
        }
      }

      if (localMatchedReels.isNotEmpty) {
        final Set<String> existingReelIds =
            filteredReels.map((DiscoverSearchResult r) => r.id ?? '').toSet();
        for (final DiscoverSearchResult lr in localMatchedReels) {
          if (lr.id != null && !existingReelIds.contains(lr.id)) {
            filteredReels.add(lr);
            existingReelIds.add(lr.id!);
          }
        }
      }

      results = results.copyWith(posts: filteredPosts, reels: filteredReels);

      _searchCache[cacheKey] = results;

      // Only apply if the search query hasn't changed while request was in-flight
      if (_searchQuery.trim() == query) {
        _searchResults = results;
        _isLoadingSearch = false;
        notifyListeners();

        // Save to recent searches if there are results
        if (results.isNotEmpty) {
          saveRecentSearch(query);
        }
      }
    } catch (_) {
      if (_searchQuery.trim() == query) {
        _isLoadingSearch = false;
        notifyListeners();
      }
    }
  }

  // ── Recent Searches ──────────────────────────────────────────────────────────
  final List<RecentSearchItem> _recentSearches = <RecentSearchItem>[];

  List<String> get recentSearches =>
      _recentSearches.map((RecentSearchItem r) => r.query).toList();

  List<RecentSearchItem> get recentSearchesItems =>
      List<RecentSearchItem>.unmodifiable(_recentSearches);

  Future<void> fetchRecentSearches() async {
    if (_discoverService == null) return;
    _isLoadingRecentSearches = true;
    notifyListeners();

    try {
      final List<RecentSearchItem> items = await _discoverService.getRecentSearches();
      _recentSearches.clear();
      _recentSearches.addAll(items);
    } finally {
      _isLoadingRecentSearches = false;
      notifyListeners();
    }
  }

  Future<void> saveRecentSearch(String query) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return;

    // Optimistic local update
    _recentSearches.removeWhere((RecentSearchItem item) => item.query.toLowerCase() == trimmed.toLowerCase());
    _recentSearches.insert(0, RecentSearchItem(id: trimmed, query: trimmed));
    notifyListeners();

    if (_discoverService != null) {
      await _discoverService.saveRecentSearch(trimmed);
    }
  }

  Future<void> removeRecentSearch(String queryOrId) async {
    // Optimistic local removal
    final int index = _recentSearches.indexWhere(
      (RecentSearchItem item) => item.id == queryOrId || item.query == queryOrId,
    );
    String idToDelete = queryOrId;
    if (index != -1) {
      idToDelete = _recentSearches[index].id;
      _recentSearches.removeAt(index);
      notifyListeners();
    }

    if (_discoverService != null) {
      await _discoverService.deleteRecentSearch(idToDelete);
    }
  }

  Future<void> clearAllRecentSearches() async {
    _recentSearches.clear();
    notifyListeners();

    if (_discoverService != null) {
      await _discoverService.clearAllRecentSearches();
    }
  }

  // ── Trending Hashtags ────────────────────────────────────────────────────────
  List<TrendingItem> _trendingItems = const <TrendingItem>[
    TrendingItem(
      rank: '01',
      hashtag: '#chosenfamily',
      postsCount: '28.4K posts today',
      thumbnailAsset: '',
    ),
    TrendingItem(
      rank: '02',
      hashtag: '#prideprep2026',
      postsCount: '19.7K posts today',
      thumbnailAsset: '',
    ),
    TrendingItem(
      rank: '03',
      hashtag: '#binderfitcheck',
      postsCount: '11.2K posts today',
      thumbnailAsset: '',
    ),
    TrendingItem(
      rank: '04',
      hashtag: '#queerbooktok',
      postsCount: '8.9K posts today',
      thumbnailAsset: '',
    ),
  ];

  List<TrendingItem> get trendingItems => _trendingItems.take(4).toList();

  Future<void> fetchTrendingHashtags() async {
    if (_discoverService == null) return;
    _isLoadingTrending = true;
    notifyListeners();

    try {
      final List<TrendingItem> items =
          await _discoverService.getTrendingHashtags();
      if (items.isNotEmpty) {
        _trendingItems = items.take(4).toList();
      }
      _updateTrendingCountsWithLiveFeed();
    } finally {
      _isLoadingTrending = false;
      notifyListeners();
    }
  }

  void updateHashtagCount(String hashtag, int actualCount) {
    final String clean = hashtag.replaceAll('#', '').toLowerCase();
    bool updated = false;
    _trendingItems = _trendingItems.map((TrendingItem item) {
      final String itemClean = item.hashtag.replaceAll('#', '').toLowerCase();
      if (itemClean == clean) {
        final String countText = actualCount > 1000
            ? '${(actualCount / 1000).toStringAsFixed(1)}K posts'
            : '$actualCount ${actualCount == 1 ? 'post' : 'posts'}';
        updated = true;
        return item.copyWith(postsCount: countText);
      }
      return item;
    }).toList();
    if (updated) {
      notifyListeners();
    }
  }

  void _updateTrendingCountsWithLiveFeed() {
    if (_trendingItems.isEmpty) return;
    bool changed = false;
    final List<TrendingItem> updated = _trendingItems.map((TrendingItem item) {
      final String clean = item.hashtag.replaceAll('#', '').toLowerCase();
      if (clean.isEmpty) return item;

      int liveMatchCount = 0;
      final Set<String> seen = <String>{};
      for (final PostItemModel p in _liveHomePosts) {
        if (DeletedPostsRegistry.isDeleted(p.id)) continue;
        final String cLower = p.content.toLowerCase();
        if (cLower.contains('#$clean') || cLower.contains(clean)) {
          if (seen.add(p.id)) liveMatchCount++;
        }
      }
      for (final ReelItemModel r in _liveHomeReels) {
        if (DeletedPostsRegistry.isDeleted(r.id)) continue;
        final String cLower = r.caption.toLowerCase();
        final bool hasTag = r.tags.any(
          (String t) => t.toLowerCase().replaceAll('#', '') == clean,
        );
        if (hasTag || cLower.contains('#$clean') || cLower.contains(clean)) {
          if (seen.add(r.id)) liveMatchCount++;
        }
      }

      int existingCount = 0;
      final Match? m = RegExp(r'(\d+)').firstMatch(item.postsCount);
      if (m != null) {
        existingCount = int.tryParse(m.group(1)!) ?? 0;
      }

      int countToUse = existingCount;
      if (_liveHomePosts.isNotEmpty || _liveHomeReels.isNotEmpty) {
        if (DeletedPostsRegistry.allDeletedIds.isNotEmpty) {
          countToUse = liveMatchCount;
        } else {
          countToUse = liveMatchCount > existingCount ? liveMatchCount : existingCount;
        }
      }

      final String countText = countToUse > 1000
          ? '${(countToUse / 1000).toStringAsFixed(1)}K posts'
          : '$countToUse ${countToUse == 1 ? 'post' : 'posts'}';
      if (countText != item.postsCount) {
        changed = true;
        return item.copyWith(postsCount: countText);
      }
      return item;
    }).toList();

    if (changed) {
      _trendingItems = updated;
      notifyListeners();
    }
  }

  // ── Creators ─────────────────────────────────────────────────────────────────
  List<DiscoverCreator> _creatorsToWatch = const <DiscoverCreator>[
    DiscoverCreator(avatarAsset: AppImages.user1, username: 'jahvi'),
    DiscoverCreator(avatarAsset: AppImages.user2, username: 'molly'),
    DiscoverCreator(avatarAsset: AppImages.user3, username: 'theo'),
    DiscoverCreator(avatarAsset: AppImages.user4, username: 'kt'),
  ];

  List<DiscoverCreator> get creatorsToWatch {
    if (_currentUsername == null || _currentUsername!.isEmpty) {
      return _creatorsToWatch;
    }
    final String cleanUname = _currentUsername!.replaceAll('@', '').trim().toLowerCase();
    return _creatorsToWatch.where((DiscoverCreator c) =>
      c.username.replaceAll('@', '').trim().toLowerCase() != cleanUname
    ).toList();
  }

  Future<void> fetchCreatorsToWatch() async {
    if (_discoverService == null) return;
    _isLoadingCreatorsToWatch = true;
    notifyListeners();

    try {
      final List<DiscoverCreator> creators =
          await _discoverService.getCreators(type: 'to_watch');
      if (creators.isNotEmpty) {
        _creatorsToWatch = creators;
      }
    } finally {
      _isLoadingCreatorsToWatch = false;
      notifyListeners();
    }
  }

  List<DiscoverCreator> _newCreators = const <DiscoverCreator>[
    DiscoverCreator(avatarAsset: AppImages.user2, username: 'jamal'),
    DiscoverCreator(avatarAsset: AppImages.user3, username: 'molly'),
    DiscoverCreator(avatarAsset: AppImages.user1, username: 'theo'),
    DiscoverCreator(avatarAsset: AppImages.user4, username: 'kt'),
  ];

  List<DiscoverCreator> get newCreators {
    if (_currentUsername == null || _currentUsername!.isEmpty) {
      return _newCreators;
    }
    final String cleanUname = _currentUsername!.replaceAll('@', '').trim().toLowerCase();
    return _newCreators.where((DiscoverCreator c) =>
      c.username.replaceAll('@', '').trim().toLowerCase() != cleanUname
    ).toList();
  }

  Future<void> fetchNewCreators() async {
    if (_discoverService == null) return;
    _isLoadingNewCreators = true;
    notifyListeners();

    try {
      final List<DiscoverCreator> creators =
          await _discoverService.getCreators(type: 'new');
      if (creators.isNotEmpty) {
        _newCreators = creators;
      }
    } finally {
      _isLoadingNewCreators = false;
      notifyListeners();
    }
  }

  // ── Unified Initial / Refresh Fetch ──────────────────────────────────────────
  Future<void> fetchDiscoverData({bool refresh = false}) async {
    if (!refresh && _trendingItems.isEmpty) {
      _isInitialLoading = true;
      notifyListeners();
    }
    if (_discoverService == null) {
      _isInitialLoading = false;
      notifyListeners();
      return;
    }
    try {
      await Future.wait<void>(<Future<void>>[
        fetchTrendingHashtags(),
        fetchCreatorsToWatch(),
        fetchNewCreators(),
        fetchRecentSearches(),
        fetchCommunities(),
      ]);
    } finally {
      _isInitialLoading = false;
      notifyListeners();
    }
  }

  // ── Dynamic Tags & Creators ──────────────────────────────────────────────────
  List<String> get suggestedTags {
    if (_trendingItems.isNotEmpty) {
      return _trendingItems
          .map((TrendingItem t) => t.hashtag)
          .where((String h) => h.isNotEmpty)
          .take(8)
          .toList();
    }
    return const <String>[];
  }

  List<DiscoverCreator> get youMightLike => _creatorsToWatch;

  bool _isLoadingCommunities = false;
  bool get isLoadingCommunities => _isLoadingCommunities;

  Future<void> fetchCommunities({
    bool excludeJoined = true,
    String sort = 'trending',
  }) async {
    if (_discoverService == null) return;
    _isLoadingCommunities = true;
    notifyListeners();

    try {
      final List<DiscoverCommunity> fetched =
          await _discoverService.getExploreCommunities(
        excludeJoined: excludeJoined,
        sort: sort,
        limit: 10,
      );
      if (fetched.isNotEmpty) {
        _communities = fetched;
      }
    } catch (e) {
      debugPrint('⚠️ [DiscoverProvider] fetchCommunities error: $e');
    } finally {
      _isLoadingCommunities = false;
      notifyListeners();
    }
  }

  List<DiscoverCommunity> _communities = const <DiscoverCommunity>[
    DiscoverCommunity(
      imageAsset: AppImages.queer,
      name: 'Queer',
      description: 'Embracing every shade of identity',
      isJoined: false,
    ),
    DiscoverCommunity(
      imageAsset: AppImages.transgender,
      name: 'Transgender',
      description: 'Strength in authentic self-expression',
      isJoined: false,
    ),
    DiscoverCommunity(
      imageAsset: AppImages.lesbian,
      name: 'Lesbian',
      description: 'Sisterhood, pride, and connection',
      isJoined: true,
    ),
    DiscoverCommunity(
      imageAsset: AppImages.gay,
      name: 'Gay',
      description: 'Bold voices, proud community vibes',
      isJoined: false,
    ),
    DiscoverCommunity(
      imageAsset: AppImages.bisexual,
      name: 'Bisexual',
      description: 'Embracing love beyond gender',
      isJoined: false,
    ),
    DiscoverCommunity(
      imageAsset: AppImages.nonBinary,
      name: 'Non-binary',
      description: 'Beyond the binary, fully valid',
      isJoined: false,
    ),
    DiscoverCommunity(
      imageAsset: AppImages.pansexual,
      name: 'Pansexual',
      description: 'Hearts open to all genders',
      isJoined: false,
    ),
    DiscoverCommunity(
      imageAsset: AppImages.asexual,
      name: 'Asexual / Ace',
      description: 'Beyond labels, your own expression',
      isJoined: false,
    ),
  ];

  List<DiscoverCommunity> get communities => _communities;

  // ── Toggle Following ─────────────────────────────────────────────────────────
  final Map<String, bool> _followStates = <String, bool>{};

  bool isFollowing(String username) {
    if (_followStates.containsKey(username)) return _followStates[username]!;
    try {
      return peopleResults
          .firstWhere((DiscoverPerson p) => p.username == username)
          .isFollowing;
    } catch (_) {
      return false;
    }
  }

  void toggleFollow(String username) {
    _followStates[username] = !isFollowing(username);
    notifyListeners();
  }

  // ── Join Community ───────────────────────────────────────────────────────────
  final Map<String, bool> _joinStates = <String, bool>{};

  bool isJoined(String communityName) {
    if (_joinStates.containsKey(communityName)) return _joinStates[communityName]!;
    try {
      return communities
          .firstWhere((DiscoverCommunity c) => c.name == communityName)
          .isJoined;
    } catch (_) {
      return false;
    }
  }

  void toggleJoin(String communityName) {
    _joinStates[communityName] = !isJoined(communityName);
    notifyListeners();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

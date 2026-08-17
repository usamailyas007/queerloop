import 'package:flutter/material.dart';

import '../../../core/theme/app_images.dart';
import '../models/discover_models.dart';
import '../widgets/search_tag_tile.dart';

class DiscoverProvider extends ChangeNotifier {
  // ── Search State ─────────────────────────────────────────────────────
  bool _isSearchFocused = false;
  String _searchQuery = '';
  bool _hasResults = true; // toggle between results/no-results

  bool get isSearchFocused => _isSearchFocused;
  String get searchQuery => _searchQuery;
  bool get hasResults => _hasResults;
  bool get isSearching => _searchQuery.isNotEmpty;

  // ── Search Tab ───────────────────────────────────────────────────────
  // 0=All, 1=Posts, 2=Reels, 3=People, 4=Tags, 5=Communities
  int _selectedSearchTab = 0;
  int get selectedSearchTab => _selectedSearchTab;

  void setSearchFocused(bool focused) {
    _isSearchFocused = focused;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    // Simulate: "fit guide" has results, anything else might not
    _hasResults = query.toLowerCase().contains('fit');
    notifyListeners();
  }

  void setSelectedSearchTab(int index) {
    _selectedSearchTab = index;
    notifyListeners();
  }

  void clearSearchQuery() {
    _searchQuery = '';
    _isSearchFocused = false;
    notifyListeners();
  }

  // ── Recent Searches ──────────────────────────────────────────────────
  final List<String> _recentSearches = <String>[
    'binder fit guide',
    '@jules.does',
    '#chosenfamily',
  ];

  List<String> get recentSearches =>
      List<String>.unmodifiable(_recentSearches);

  void removeRecentSearch(String query) {
    _recentSearches.remove(query);
    notifyListeners();
  }

  void clearAllRecentSearches() {
    _recentSearches.clear();
    notifyListeners();
  }

  // ── Suggested Tags ───────────────────────────────────────────────────
  final List<String> suggestedTags = const <String>[
    '#transjoy',
    '#dragbrunch',
    '#comingout',
    '#queerbooks',
    '#binderfit',
    '#prideprep',
  ];

  // ── Search Results ───────────────────────────────────────────────────
  final List<DiscoverSearchResult> searchResults = const <DiscoverSearchResult>[
    DiscoverSearchResult(imageAsset: AppImages.searchResult1, viewCount: '12.4K'),
    DiscoverSearchResult(imageAsset: AppImages.searchResult2),
    DiscoverSearchResult(imageAsset: AppImages.searchResult3),
    DiscoverSearchResult(imageAsset: AppImages.searchResult4),
    DiscoverSearchResult(imageAsset: AppImages.searchResult5),
    DiscoverSearchResult(imageAsset: AppImages.searchResult6),
  ];

  // ── Tag Results ──────────────────────────────────────────────────────
  final List<TagSearchResultItem> tagResults = const <TagSearchResultItem>[
    TagSearchResultItem(
      name: '#topsurgery',
      postsCount: '41.2K',
      weeklyCount: '2.4K',
      imageAsset: AppImages.searchResult1,
    ),
    TagSearchResultItem(
      name: '#topsurgeryrecovery',
      postsCount: '18.9K',
      weeklyCount: '1.1K',
      imageAsset: AppImages.searchResult2,
    ),
    TagSearchResultItem(
      name: '#topsurgeryjourney',
      postsCount: '9.4K',
      weeklyCount: '620',
      imageAsset: AppImages.searchResult3,
    ),
    TagSearchResultItem(
      name: '#scarcare',
      postsCount: '6.8K',
      weeklyCount: '410',
      imageAsset: AppImages.searchResult4,
    ),
    TagSearchResultItem(
      name: '#postopday1',
      postsCount: '3.3K',
      weeklyCount: '180',
      imageAsset: AppImages.searchResult5,
    ),
    TagSearchResultItem(
      name: '#surgeonreviews',
      postsCount: '2.1K',
      weeklyCount: '96',
      imageAsset: AppImages.searchResult6,
    ),
  ];

  // ── People Results ───────────────────────────────────────────────────
  final List<DiscoverPerson> peopleResults = const <DiscoverPerson>[
    DiscoverPerson(
      avatarAsset: AppImages.user1,
      username: 'rowankeeps',
      pronouns: 'they/them',
      followers: '41K followers',
      isFollowing: false,
    ),
    DiscoverPerson(
      avatarAsset: AppImages.user2,
      username: 'jules.does',
      pronouns: 'she/they',
      followers: '12K followers',
      isFollowing: true,
    ),
  ];

  // ── You Might Like ───────────────────────────────────────────────────
  final List<DiscoverCreator> youMightLike = const <DiscoverCreator>[
    DiscoverCreator(avatarAsset: AppImages.user1, username: 'sam.a'),
    DiscoverCreator(avatarAsset: AppImages.user2, username: 'nadia'),
    DiscoverCreator(avatarAsset: AppImages.user3, username: 'theo'),
    DiscoverCreator(avatarAsset: AppImages.user4, username: 'kit'),
  ];

  // ── Trending ─────────────────────────────────────────────────────────
  final List<TrendingItem> trendingItems = const <TrendingItem>[
    TrendingItem(
      rank: '01',
      hashtag: '#chosenfamily',
      postsCount: '28.4K posts today',
      thumbnailAsset: AppImages.forYouImg,
    ),
    TrendingItem(
      rank: '02',
      hashtag: '#prideprep2026',
      postsCount: '19.7K posts today',
      thumbnailAsset: AppImages.followingImg,
    ),
    TrendingItem(
      rank: '03',
      hashtag: '#binderfitcheck',
      postsCount: '11.2K posts today',
      thumbnailAsset: AppImages.communityImg,
    ),
    TrendingItem(
      rank: '04',
      hashtag: '#queerbooktok',
      postsCount: '8.9K posts today',
      thumbnailAsset: AppImages.emptyHomeImg,
    ),
  ];

  // ── Communities ──────────────────────────────────────────────────────
  final List<DiscoverCommunity> communities = const <DiscoverCommunity>[
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

  // ── Creators To Watch ────────────────────────────────────────────────
  final List<DiscoverCreator> creatorsToWatch = const <DiscoverCreator>[
    DiscoverCreator(avatarAsset: AppImages.user1, username: 'jahvi'),
    DiscoverCreator(avatarAsset: AppImages.user2, username: 'molly'),
    DiscoverCreator(avatarAsset: AppImages.user3, username: 'theo'),
    DiscoverCreator(avatarAsset: AppImages.user4, username: 'kt'),
  ];

  final List<DiscoverCreator> newCreators = const <DiscoverCreator>[
    DiscoverCreator(avatarAsset: AppImages.user2, username: 'jamal'),
    DiscoverCreator(avatarAsset: AppImages.user3, username: 'molly'),
    DiscoverCreator(avatarAsset: AppImages.user1, username: 'theo'),
    DiscoverCreator(avatarAsset: AppImages.user4, username: 'kt'),
  ];

  // ── Toggle Following ─────────────────────────────────────────────────
  final Map<String, bool> _followStates = <String, bool>{};

  bool isFollowing(String username) {
    if (_followStates.containsKey(username)) return _followStates[username]!;
    try {
      return peopleResults.firstWhere((DiscoverPerson p) => p.username == username).isFollowing;
    } catch (_) {
      return false;
    }
  }

  void toggleFollow(String username) {
    _followStates[username] = !isFollowing(username);
    notifyListeners();
  }

  // ── Join Community ───────────────────────────────────────────────────
  final Map<String, bool> _joinStates = <String, bool>{};

  bool isJoined(String communityName) {
    if (_joinStates.containsKey(communityName)) return _joinStates[communityName]!;
    try {
      return communities.firstWhere((DiscoverCommunity c) => c.name == communityName).isJoined;
    } catch (_) {
      return false;
    }
  }

  void toggleJoin(String communityName) {
    _joinStates[communityName] = !isJoined(communityName);
    notifyListeners();
  }
}

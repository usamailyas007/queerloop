import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_images.dart';
import '../../create_post/models/create_post_models.dart';
import '../../create_post/services/media_upload_service.dart';
import '../../create_post/services/post_content_service.dart';
import '../models/post_item_model.dart';
import '../models/reel_item_model.dart';
import '../services/reel_video_preloader.dart';

enum TopTab { following, forYou, communities }
enum SubMode { reels, posts }

class _FeedBatch {
  const _FeedBatch({required this.reels, required this.posts});
  final List<ReelItemModel> reels;
  final List<PostItemModel> posts;
}

class HomeFeedProvider extends ChangeNotifier {
  HomeFeedProvider({
    PostContentService? contentService,
    MediaUploadService? mediaService,
  })  : _contentService = contentService,
        _mediaService = mediaService {
    loadFeed();
  }

  PostContentService? _contentService;
  MediaUploadService? _mediaService;

  String? _currentUserId;
  final Set<String> _userLikedPostIds = <String>{};

  bool _isGuest = false;
  int _bottomNavIndex = 0; // 0: Home, 1: Discover, 2: Create, 3: Messages, 4: Profile
  TopTab _activeTopTab = TopTab.forYou;
  SubMode _activeSubMode = SubMode.reels;
  String _selectedCommunityFilter = 'All Communities';
  String? _selectedCommunityId;

  static final List<PostItemModel> _defaultForYouPosts = <PostItemModel>[
    const PostItemModel(
      id: 'post_1',
      username: '@theo.vance',
      pronounsTime: 'he/him · 18m',
      avatarAsset: AppImages.user4,
      content:
          'Told my grandma about Dev over the phone and she said "finally, you sounded lonely in December." Eleven months of rehearsing a speech for nothing.',
      likesCount: 5600,
      commentsCount: 311,
      postImageAsset: AppImages.forYouImg,
      isLiked: false,
    ),
    const PostItemModel(
      id: 'post_2',
      username: '@nadia.builds',
      pronounsTime: 'she/her · 1h',
      avatarAsset: AppImages.user1,
      content:
          'Reminder that the Tuesday support call is open to anyone, camera off is normal, and nobody has to speak.',
      likesCount: 1200,
      commentsCount: 311,
      isLiked: false,
    ),
  ];

  // Tab-specific feed stores to keep tabs independent and smooth
  final List<ReelItemModel> _forYouReels = <ReelItemModel>[];
  final List<PostItemModel> _forYouPosts =
      List<PostItemModel>.from(_defaultForYouPosts);

  final List<ReelItemModel> _followingReels = <ReelItemModel>[];
  final List<PostItemModel> _followingPosts = <PostItemModel>[];

  final List<ReelItemModel> _communityReels = <ReelItemModel>[];
  final List<PostItemModel> _communityPosts = <PostItemModel>[];

  bool _isLoadingForYou = true;
  bool _isLoadingFollowing = false;
  bool _isLoadingCommunities = false;

  // In-memory cache for resolved media URLs to prevent duplicate CDN fetches
  final Map<String, MediaUploadResult> _mediaCache = <String, MediaUploadResult>{};

  // Getters
  String? get currentUserId => _currentUserId;
  bool get isGuest => _isGuest;
  int get bottomNavIndex => _bottomNavIndex;
  TopTab get activeTopTab => _activeTopTab;
  SubMode get activeSubMode => _activeSubMode;
  String get selectedCommunityFilter => _selectedCommunityFilter;
  String? get selectedCommunityId => _selectedCommunityId;

  bool get isLoadingFeed {
    switch (_activeTopTab) {
      case TopTab.following:
        return _isLoadingFollowing;
      case TopTab.communities:
        return _isLoadingCommunities;
      case TopTab.forYou:
        return _isLoadingForYou;
    }
  }

  String _prefsKeyForUser(String userId) => 'user_liked_posts_$userId';

  /// Synchronize feed with currently authenticated user.
  /// Isolates like states per user so each account has their own likes.
  Future<void> updateUser(String? newUserId) async {
    if (_currentUserId == newUserId) return;
    _currentUserId = newUserId;
    _userLikedPostIds.clear();

    if (newUserId != null && newUserId.isNotEmpty) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final List<String>? savedLikes =
            prefs.getStringList(_prefsKeyForUser(newUserId));
        if (savedLikes != null) {
          _userLikedPostIds.addAll(savedLikes);
        }
      } catch (e) {
        debugPrint('⚠️ [HomeFeedProvider] Error loading user likes: $e');
      }
    }

    _syncInMemLikedState();
    notifyListeners();

    // Refresh active feed to fetch latest like counts
    await loadFeed(force: true);
  }

  void _syncInMemLikedState() {
    void syncReels(List<ReelItemModel> list) {
      for (int i = 0; i < list.length; i++) {
        final ReelItemModel r = list[i];
        final bool shouldBeLiked =
            _currentUserId != null && _userLikedPostIds.contains(r.id);
        if (r.isLiked != shouldBeLiked) {
          list[i] = r.copyWith(isLiked: shouldBeLiked);
        }
      }
    }

    void syncPosts(List<PostItemModel> list) {
      for (int i = 0; i < list.length; i++) {
        final PostItemModel p = list[i];
        final bool shouldBeLiked =
            _currentUserId != null && _userLikedPostIds.contains(p.id);
        if (p.isLiked != shouldBeLiked) {
          list[i] = p.copyWith(isLiked: shouldBeLiked);
        }
      }
    }

    syncReels(_forYouReels);
    syncReels(_followingReels);
    syncReels(_communityReels);

    syncPosts(_forYouPosts);
    syncPosts(_followingPosts);
    syncPosts(_communityPosts);
  }

  Future<void> _persistUserLikes() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKeyForUser(_currentUserId!),
        _userLikedPostIds.toList(),
      );
    } catch (e) {
      debugPrint('⚠️ [HomeFeedProvider] Error saving user likes: $e');
    }
  }

  List<ReelItemModel> get reels {
    switch (_activeTopTab) {
      case TopTab.following:
        return _followingReels;
      case TopTab.communities:
        return _communityReels;
      case TopTab.forYou:
        return _forYouReels;
    }
  }

  bool _isValidPostItem(PostItemModel p) {
    final String t = p.postType.toUpperCase().trim();
    if (t == 'VIDEO' || t == 'REEL') return false;
    final String? img = p.postImageUrl?.toLowerCase();
    if (img != null &&
        (img.endsWith('.mp4') ||
            img.endsWith('.mov') ||
            img.endsWith('.webm') ||
            img.endsWith('.mkv'))) {
      return false;
    }
    final bool hasText = p.content.trim().isNotEmpty;
    final bool hasImage = (p.postImageUrl != null && p.postImageUrl!.trim().isNotEmpty) ||
        (p.postImageAsset != null && p.postImageAsset!.trim().isNotEmpty);
    return hasText || hasImage;
  }

  bool _isReelOrVideo(PostResponseModel post) {
    final String postType = post.type.toUpperCase().trim();
    if (postType == 'VIDEO' || postType == 'REEL') return true;
    if (post.duration != null && post.duration!.trim().isNotEmpty) return true;
    for (final String ref in post.mediaRefs) {
      final String lower = ref.toLowerCase();
      if (lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.webm') ||
          lower.endsWith('.mkv') ||
          lower.contains('/videos/') ||
          lower.contains('/video/')) {
        return true;
      }
    }
    return false;
  }

  List<PostItemModel> get posts {
    switch (_activeTopTab) {
      case TopTab.following:
        return List<PostItemModel>.unmodifiable(
            _followingPosts.where(_isValidPostItem));
      case TopTab.communities:
        return List<PostItemModel>.unmodifiable(
            _communityPosts.where(_isValidPostItem));
      case TopTab.forYou:
        return List<PostItemModel>.unmodifiable(
            _forYouPosts.where(_isValidPostItem));
    }
  }

  bool get isFollowingEmpty => _followingReels.isEmpty && _followingPosts.isEmpty;

  void updateServices({
    PostContentService? contentService,
    MediaUploadService? mediaService,
  }) {
    if (contentService != null) _contentService = contentService;
    if (mediaService != null) _mediaService = mediaService;
  }

  // ── Helpers to Build Reel & Post Models from Backend Response ──────────────
  Future<ReelItemModel> _buildReelItem(PostResponseModel post) async {
    String? videoUrl;
    String? thumbnailUrl;

    if (post.mediaRefs.isNotEmpty) {
      final String mediaId = post.mediaRefs.first.trim();
      if (mediaId.startsWith('http://') || mediaId.startsWith('https://')) {
        videoUrl = mediaId;
      } else if (_mediaService != null) {
        MediaUploadResult? media = _mediaCache[mediaId];
        if (media == null) {
          try {
            media = await _mediaService!.getMediaStatus(mediaId);
            _mediaCache[mediaId] = media;
          } catch (e) {
            debugPrint('⚠️ [HomeFeed] Could not resolve reel media $mediaId: $e');
          }
        }
        videoUrl = media?.url ?? media?.downloadUrl;
        thumbnailUrl = media?.thumbnailUrl;
      }
    }

    final bool isLiked = _currentUserId != null &&
        (_userLikedPostIds.contains(post.id) || post.isLiked);
    if (isLiked && _currentUserId != null) {
      _userLikedPostIds.add(post.id);
    }

    final String resolvedUsername = (post.authorName != null && post.authorName!.isNotEmpty)
        ? (post.authorName!.startsWith('@') ? post.authorName! : '@${post.authorName!}')
        : (post.authorId != null && post.authorId!.length >= 6
            ? '@user_${post.authorId!.substring(0, 6)}'
            : (post.id.length >= 6 ? '@user_${post.id.substring(0, 6)}' : '@creator'));

    final String resolvedAvatar = (post.authorAvatar != null && post.authorAvatar!.isNotEmpty)
        ? post.authorAvatar!
        : AppImages.user1;

    return ReelItemModel(
      id: post.id,
      authorId: post.authorId,
      authorDisplayName: post.authorDisplayName,
      username: resolvedUsername,
      pronounsTime: _formatTime(post.createdAt),
      avatarAsset: resolvedAvatar,
      videoAsset: '',
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: post.body.isNotEmpty ? post.body : post.caption,
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      isLiked: isLiked,
      tags: post.tags,
      communityId: post.communityId,
      durationText: (post.duration != null && post.duration!.isNotEmpty)
          ? post.duration!
          : '0:30',
    );
  }

  Future<PostItemModel> _buildPostItem(PostResponseModel post) async {
    String? imageUrl = post.postImageUrl;

    if (imageUrl == null || imageUrl.isEmpty) {
      if (post.mediaRefs.isNotEmpty) {
        for (final String rawRef in post.mediaRefs) {
          final String ref = rawRef.trim();
          if (ref.isEmpty) continue;
          final String lower = ref.toLowerCase();
          final bool isVideoFile = lower.endsWith('.mp4') ||
              lower.endsWith('.mov') ||
              lower.endsWith('.webm') ||
              lower.endsWith('.mkv');
          if (isVideoFile) continue;

          if (ref.startsWith('http://') || ref.startsWith('https://')) {
            imageUrl = ref;
            break;
          } else if (ref.startsWith('assets/')) {
            imageUrl = ref;
            break;
          } else if (ref.startsWith('/') ||
              lower.endsWith('.jpg') ||
              lower.endsWith('.jpeg') ||
              lower.endsWith('.png') ||
              lower.endsWith('.webp') ||
              lower.endsWith('.gif')) {
            final String base = AppConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
            final String path = ref.startsWith('/') ? ref : '/$ref';
            imageUrl = '$base$path';
            break;
          } else if (_mediaService != null) {

            MediaUploadResult? media = _mediaCache[ref];
            if (media == null) {
              try {
                media = await _mediaService!.getMediaStatus(ref);
                _mediaCache[ref] = media;
              } catch (e) {
                debugPrint('⚠️ [HomeFeed] Could not resolve post media $ref: $e');
              }
            }
            final String? resolved =
                media?.url ?? media?.downloadUrl ?? media?.thumbnailUrl;
            if (resolved != null && resolved.isNotEmpty) {
              final String resLower = resolved.toLowerCase();
              if (!resLower.endsWith('.mp4') &&
                  !resLower.endsWith('.mov') &&
                  !resLower.endsWith('.webm') &&
                  !resLower.endsWith('.mkv')) {
                imageUrl = resolved;
                break;
              }
            } else if (ref.length >= 24 && AppConfig.baseUrl.isNotEmpty) {
              // Direct gateway media endpoint fallback
              final String base = AppConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
              imageUrl = '$base/media/$ref';
              break;
            }
          } else {
            // No mediaService — use gateway endpoint directly for opaque IDs
            if (ref.length >= 24 && AppConfig.baseUrl.isNotEmpty) {
              final String base = AppConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
              imageUrl = '$base/media/$ref';
              break;
            }
          }
        }
      }
    }

    final bool isLiked = _currentUserId != null &&
        (_userLikedPostIds.contains(post.id) || post.isLiked);
    if (isLiked && _currentUserId != null) {
      _userLikedPostIds.add(post.id);
    }

    final String resolvedPostUsername = (post.authorName != null && post.authorName!.isNotEmpty)
        ? (post.authorName!.startsWith('@') ? post.authorName! : '@${post.authorName!}')
        : (post.authorId != null && post.authorId!.length >= 6
            ? '@user_${post.authorId!.substring(0, 6)}'
            : (post.id.length >= 6 ? '@user_${post.id.substring(0, 6)}' : '@creator'));

    final String resolvedPostAvatar = (post.authorAvatar != null && post.authorAvatar!.isNotEmpty)
        ? post.authorAvatar!
        : AppImages.user4;

    return PostItemModel(
      id: post.id,
      authorId: post.authorId,
      username: resolvedPostUsername,
      pronounsTime: _formatTime(post.createdAt),
      avatarAsset: resolvedPostAvatar,
      content: post.body.isNotEmpty ? post.body : post.caption,
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      postImageUrl: imageUrl,
      postType: post.type,
      communityId: post.communityId,
      isLiked: isLiked,
    );
  }

  // ── Unified Post & Reel Parser (used by Following & Community feeds) ───────
  Future<_FeedBatch> _processPosts(List<PostResponseModel> rawPosts) async {
    final List<ReelItemModel> parsedReels = <ReelItemModel>[];
    final List<PostItemModel> parsedPosts = <PostItemModel>[];

    for (final PostResponseModel post in rawPosts) {
      final bool isVideo = _isReelOrVideo(post);

      if (isVideo) {
        parsedReels.add(await _buildReelItem(post));
      } else {
        final PostItemModel item = await _buildPostItem(post);
        if (_isValidPostItem(item)) {
          parsedPosts.add(item);
        }
      }
    }

    return _FeedBatch(reels: parsedReels, posts: parsedPosts);
  }

  // ── 1. Load For You Feed (Strict Separation of Posts & Reels) ──────────────
  Future<void> loadForYouFeed({bool force = false}) async {
    if (_contentService == null) {
      _isLoadingForYou = false;
      notifyListeners();
      return;
    }

    if (!force &&
        _forYouReels.isNotEmpty &&
        _forYouPosts.isNotEmpty &&
        !_forYouPosts.any((PostItemModel p) => p.id.startsWith('post_'))) {
      _isLoadingForYou = false;
      return;
    }

    _isLoadingForYou = true;
    notifyListeners();

    try {
      // 1. Fetch Trending Reels (From /posts/trending, all treated as reels)
      List<PostResponseModel> trendingPosts = <PostResponseModel>[];
      try {
        trendingPosts = await _contentService!.getTrendingPosts();
      } catch (e) {
        debugPrint('⚠️ [HomeFeedProvider] Error getting trending posts: $e');
      }

      final List<ReelItemModel> liveReels = <ReelItemModel>[];
      for (final PostResponseModel post in trendingPosts) {
        try {
          liveReels.add(await _buildReelItem(post));
        } catch (e) {
          debugPrint('⚠️ [HomeFeedProvider] Error building reel: $e');
        }
      }

      // 2. Fetch General Feed Posts (/posts, /search, /feed/community)
      List<PostResponseModel> feedPosts = <PostResponseModel>[];
      try {
        feedPosts = await _contentService!.getFeedPosts();
      } catch (e) {
        debugPrint('⚠️ [HomeFeedProvider] Error getting feed posts: $e');
      }

      final List<PostItemModel> livePosts = <PostItemModel>[];
      for (final PostResponseModel post in feedPosts) {
        try {
          final bool isVideoOrReel = _isReelOrVideo(post);

          // Video/Reel posts belong exclusively to Reels
          if (isVideoOrReel) {
            if (!liveReels.any((r) => r.id == post.id)) {
              liveReels.add(await _buildReelItem(post));
            }
          } else {
            final PostItemModel item = await _buildPostItem(post);
            if (_isValidPostItem(item)) {
              livePosts.add(item);
            }
          }
        } catch (e) {
          debugPrint('⚠️ [HomeFeedProvider] Error building post: $e');
        }
      }

      // Important: Never add trendingPosts to livePosts since trendingPosts are exclusively reels!

      if (liveReels.isNotEmpty || _forYouReels.isEmpty) {
        _forYouReels
          ..clear()
          ..addAll(liveReels);
      }

      if (livePosts.isNotEmpty) {
        _forYouPosts
          ..clear()
          ..addAll(livePosts);
      } else {
        // Fallback to high quality default curated posts if no feed posts exist
        _forYouPosts
          ..clear()
          ..addAll(_defaultForYouPosts);
      }

      if (_forYouReels.isNotEmpty && _activeTopTab == TopTab.forYou) {
        ReelVideoPreloader.instance.preloadSurrounding(_forYouReels, 0);
      }
    } catch (e) {
      debugPrint('❌ [HomeFeedProvider] Failed to load For You feed: $e');
    } finally {
      _isLoadingForYou = false;
      notifyListeners();
    }
  }

  // ── 2. Load Following Feed (GET /feed/following) ───────────────────────────
  Future<void> loadFollowingFeed({bool force = false}) async {
    if (_contentService == null) return;
    if (_isLoadingFollowing) return;

    if (!force && (_followingReels.isNotEmpty || _followingPosts.isNotEmpty)) {
      return;
    }

    _isLoadingFollowing = true;
    notifyListeners();

    try {
      final List<PostResponseModel> rawPosts =
          await _contentService!.getFollowingFeed();

      final _FeedBatch batch = await _processPosts(rawPosts);

      _followingReels
        ..clear()
        ..addAll(batch.reels.map((ReelItemModel r) => r.copyWith(isFollowing: true)));

      _followingPosts
        ..clear()
        ..addAll(batch.posts);

      if (_followingReels.isNotEmpty && _activeTopTab == TopTab.following) {
        ReelVideoPreloader.instance.preloadSurrounding(_followingReels, 0);
      }
    } catch (e) {
      debugPrint('❌ [HomeFeedProvider] Failed to load Following feed: $e');
    } finally {
      _isLoadingFollowing = false;
      notifyListeners();
    }
  }

  // ── 3. Load Community Feed (GET /feed/community?...) ───────────────────────
  Future<void> loadCommunityFeed({bool force = false}) async {
    if (_contentService == null) return;
    if (_isLoadingCommunities) return;

    if (!force &&
        (_communityReels.isNotEmpty || _communityPosts.isNotEmpty) &&
        _selectedCommunityId == null) {
      return;
    }

    _isLoadingCommunities = true;
    notifyListeners();

    try {
      final List<PostResponseModel> rawPosts;
      if (_selectedCommunityId != null && _selectedCommunityId!.isNotEmpty) {
        rawPosts = await _contentService!.getCommunityFeed(
          communityId: _selectedCommunityId,
        );
      } else {
        rawPosts = await _contentService!.getCommunityFeed(
          scope: 'joined',
        );
      }

      final _FeedBatch batch = await _processPosts(rawPosts);

      _communityReels
        ..clear()
        ..addAll(batch.reels);

      _communityPosts
        ..clear()
        ..addAll(batch.posts);

      if (_communityReels.isNotEmpty && _activeTopTab == TopTab.communities) {
        ReelVideoPreloader.instance.preloadSurrounding(_communityReels, 0);
      }
    } catch (e) {
      debugPrint('❌ [HomeFeedProvider] Failed to load Community feed: $e');
    } finally {
      _isLoadingCommunities = false;
      notifyListeners();
    }
  }

  // ── General Feed Refresh (refreshes current active tab) ───────────────────
  Future<void> loadFeed({bool force = false}) async {
    switch (_activeTopTab) {
      case TopTab.forYou:
        await loadForYouFeed(force: force || _forYouReels.isNotEmpty || _forYouPosts.isNotEmpty);
        break;
      case TopTab.following:
        await loadFollowingFeed(force: true);
        break;
      case TopTab.communities:
        await loadCommunityFeed(force: true);
        break;
    }
  }

  String _formatTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 'Just now';
    try {
      final DateTime dt = DateTime.parse(createdAt);
      final Duration diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d ago';
      if (diff.inHours > 0) return '${diff.inHours}h ago';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
      return 'Just now';
    } catch (_) {
      return 'Recently';
    }
  }

  // Record a view for a post/reel
  void recordView(String postId) {
    if (_contentService != null && postId.contains('-')) {
      _contentService!.recordView(postId);
    }
  }

  // Helpers to synchronize item mutations across all tabs
  void _updateReelInAllLists(String id, ReelItemModel Function(ReelItemModel) updater) {
    void updateInList(List<ReelItemModel> list) {
      final int idx = list.indexWhere((r) => r.id == id);
      if (idx != -1) list[idx] = updater(list[idx]);
    }

    updateInList(_forYouReels);
    updateInList(_followingReels);
    updateInList(_communityReels);
  }

  void _updatePostInAllLists(String id, PostItemModel Function(PostItemModel) updater) {
    void updateInList(List<PostItemModel> list) {
      final int idx = list.indexWhere((p) => p.id == id);
      if (idx != -1) list[idx] = updater(list[idx]);
    }

    updateInList(_forYouPosts);
    updateInList(_followingPosts);
    updateInList(_communityPosts);
  }

  // Increment comment count locally when comment is added
  void incrementCommentCount(String postId) {
    _updatePostInAllLists(postId, (p) => p.copyWith(commentsCount: p.commentsCount + 1));
    _updateReelInAllLists(postId, (r) => r.copyWith(commentsCount: r.commentsCount + 1));
    notifyListeners();
  }

  // Actions
  void setGuestMode(bool val) {
    if (_isGuest == val) return;
    _isGuest = val;
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    if (index != 0) {
      ReelVideoPreloader.instance.pauseAll();
    }
    if (index == 0 && _bottomNavIndex != 0) {
      _activeTopTab = TopTab.forYou;
    }
    _bottomNavIndex = index;
    notifyListeners();
  }

  void resetToHome() {
    ReelVideoPreloader.instance.pauseAll();
    _bottomNavIndex = 0;
    _activeTopTab = TopTab.forYou;
    _activeSubMode = SubMode.reels;
    _selectedCommunityFilter = 'All Communities';
    _selectedCommunityId = null;
    notifyListeners();
  }

  void setTopTab(TopTab tab) {
    if (_activeTopTab == tab) return;
    ReelVideoPreloader.instance.pauseAll();
    _activeTopTab = tab;
    notifyListeners();

    switch (tab) {
      case TopTab.forYou:
        if (_forYouReels.isEmpty && _forYouPosts.isEmpty && !_isLoadingForYou) {
          loadForYouFeed();
        } else if (_forYouReels.isNotEmpty) {
          ReelVideoPreloader.instance.preloadSurrounding(_forYouReels, 0);
        }
        break;
      case TopTab.following:
        if (_followingReels.isEmpty && _followingPosts.isEmpty && !_isLoadingFollowing) {
          loadFollowingFeed();
        } else if (_followingReels.isNotEmpty) {
          ReelVideoPreloader.instance.preloadSurrounding(_followingReels, 0);
        }
        break;
      case TopTab.communities:
        if (_communityReels.isEmpty && _communityPosts.isEmpty && !_isLoadingCommunities) {
          loadCommunityFeed();
        } else if (_communityReels.isNotEmpty) {
          ReelVideoPreloader.instance.preloadSurrounding(_communityReels, 0);
        }
        break;
    }
  }

  void setSubMode(SubMode mode) {
    if (_activeSubMode == mode) return;
    if (mode == SubMode.posts) {
      ReelVideoPreloader.instance.pauseAll();
      if (_activeTopTab == TopTab.forYou && _forYouPosts.isEmpty) {
        loadForYouFeed();
      }
    }
    _activeSubMode = mode;
    notifyListeners();
  }

  void setSelectedCommunityFilter(String val, {String? communityId}) {
    _selectedCommunityFilter = val;
    _selectedCommunityId = communityId;
    if (_activeTopTab != TopTab.communities) {
      _activeTopTab = TopTab.communities;
    }
    notifyListeners();
    loadCommunityFeed(force: true);
  }

  Future<void> toggleLikeReel(String id, {ReelItemModel? fallbackReel}) async {
    ReelItemModel? target;
    for (final List<ReelItemModel> list in <List<ReelItemModel>>[
      _forYouReels,
      _followingReels,
      _communityReels,
    ]) {
      final int idx = list.indexWhere((r) => r.id == id);
      if (idx != -1) {
        target = list[idx];
        break;
      }
    }
    if (target == null && fallbackReel != null) {
      target = fallbackReel;
    }
    if (target == null) {
      final bool alreadyLiked = _userLikedPostIds.contains(id);
      target = ReelItemModel(
        id: id,
        username: '@creator',
        pronounsTime: '',
        avatarAsset: '',
        videoAsset: '',
        caption: '',
        likesCount: alreadyLiked ? 1 : 0,
        commentsCount: 0,
        isLiked: alreadyLiked,
      );
    }

    final bool newLiked = !target.isLiked;
    final int newCount = newLiked
        ? target.likesCount + 1
        : (target.likesCount > 0 ? target.likesCount - 1 : 0);

    _updateReelInAllLists(id, (r) => r.copyWith(isLiked: newLiked, likesCount: newCount));
    _updatePostInAllLists(id, (p) => p.copyWith(isLiked: newLiked, likesCount: newCount));

    if (_currentUserId != null) {
      if (newLiked) {
        _userLikedPostIds.add(id);
      } else {
        _userLikedPostIds.remove(id);
      }
      _persistUserLikes();
    }

    notifyListeners();

    final bool isRealBackendId = !id.startsWith('profile_reel_') && !id.startsWith('search_reel_');
    if (_contentService != null && (id.contains('-') || isRealBackendId)) {
      try {
        if (newLiked) {
          await _contentService!.likePost(id);
        } else {
          await _contentService!.unlikePost(id);
        }
      } catch (err) {
        debugPrint('Error syncing like for reel $id: $err');
        _updateReelInAllLists(
          id,
          (r) => r.copyWith(isLiked: target!.isLiked, likesCount: target.likesCount),
        );
        _updatePostInAllLists(
          id,
          (p) => p.copyWith(isLiked: target!.isLiked, likesCount: target.likesCount),
        );
        if (_currentUserId != null) {
          if (target.isLiked) {
            _userLikedPostIds.add(id);
          } else {
            _userLikedPostIds.remove(id);
          }
          _persistUserLikes();
        }
        notifyListeners();
      }
    }
  }

  void toggleSaveReel(String id) {
    ReelItemModel? target;
    for (final List<ReelItemModel> list in <List<ReelItemModel>>[
      _forYouReels,
      _followingReels,
      _communityReels,
    ]) {
      final int i = list.indexWhere((ReelItemModel r) => r.id == id);
      if (i != -1) {
        target = list[i];
        break;
      }
    }
    final bool newSaved = !(target?.isSaved ?? false);
    _updateReelInAllLists(id, (r) => r.copyWith(isSaved: newSaved));
    notifyListeners();

    if (_contentService != null && id.contains('-')) {
      if (newSaved) {
        _contentService!.savePost(id).catchError((dynamic e) {
          debugPrint('⚠️ [HomeFeed] Save reel failed: $e');
        });
      } else {
        _contentService!.unsavePost(id).catchError((dynamic e) {
          debugPrint('⚠️ [HomeFeed] Unsave reel failed: $e');
        });
      }
    }
  }

  void toggleFollowReel(String id, {bool? isFollowing}) {
    _updateReelInAllLists(
      id,
      (ReelItemModel r) => r.copyWith(isFollowing: isFollowing ?? !r.isFollowing),
    );
    notifyListeners();
  }

  void setAuthorFollowStatus({
    required String authorId,
    required bool isFollowing,
    String? username,
  }) {
    final String cleanAuthor = authorId.trim().toLowerCase();
    final String cleanUser =
        username?.replaceAll('@', '').trim().toLowerCase() ?? '';

    void updateReels(List<ReelItemModel> list) {
      for (int i = 0; i < list.length; i++) {
        final ReelItemModel r = list[i];
        final bool matches = (r.authorId != null &&
                r.authorId!.toLowerCase() == cleanAuthor) ||
            (cleanUser.isNotEmpty &&
                r.username.replaceAll('@', '').toLowerCase() == cleanUser);
        if (matches) {
          list[i] = r.copyWith(isFollowing: isFollowing);
        }
      }
    }

    updateReels(_forYouReels);
    updateReels(_followingReels);
    updateReels(_communityReels);
    notifyListeners();
  }

  void addNewReel(ReelItemModel reel) {
    _forYouReels.insert(0, reel);
    if (_activeTopTab == TopTab.following) {
      _followingReels.insert(0, reel);
    } else if (_activeTopTab == TopTab.communities) {
      _communityReels.insert(0, reel);
    }
    notifyListeners();
  }

  void addNewPost(PostItemModel post) {
    if (post.postType.toUpperCase().trim() == 'VIDEO') return;
    _forYouPosts.insert(0, post);
    if (_activeTopTab == TopTab.following) {
      _followingPosts.insert(0, post);
    } else if (_activeTopTab == TopTab.communities) {
      _communityPosts.insert(0, post);
    }
    notifyListeners();
  }

  Future<void> toggleLikePost(String id) async {
    PostItemModel? target;
    for (final List<PostItemModel> list in <List<PostItemModel>>[
      _forYouPosts,
      _followingPosts,
      _communityPosts,
    ]) {
      final int idx = list.indexWhere((p) => p.id == id);
      if (idx != -1) {
        target = list[idx];
        break;
      }
    }
    if (target == null) return;

    final bool newLiked = !target.isLiked;
    final int newCount = newLiked
        ? target.likesCount + 1
        : (target.likesCount > 0 ? target.likesCount - 1 : 0);

    _updatePostInAllLists(id, (p) => p.copyWith(isLiked: newLiked, likesCount: newCount));
    _updateReelInAllLists(id, (r) => r.copyWith(isLiked: newLiked, likesCount: newCount));

    if (_currentUserId != null) {
      if (newLiked) {
        _userLikedPostIds.add(id);
      } else {
        _userLikedPostIds.remove(id);
      }
      _persistUserLikes();
    }

    notifyListeners();

    if (_contentService != null && id.contains('-')) {
      try {
        if (newLiked) {
          await _contentService!.likePost(id);
        } else {
          await _contentService!.unlikePost(id);
        }
      } catch (err) {
        debugPrint('Error syncing like for post $id: $err');
        _updatePostInAllLists(
          id,
          (p) => p.copyWith(isLiked: target!.isLiked, likesCount: target.likesCount),
        );
        _updateReelInAllLists(
          id,
          (r) => r.copyWith(isLiked: target!.isLiked, likesCount: target.likesCount),
        );
        if (_currentUserId != null) {
          if (target.isLiked) {
            _userLikedPostIds.add(id);
          } else {
            _userLikedPostIds.remove(id);
          }
          _persistUserLikes();
        }
        notifyListeners();
      }
    }
  }

  void toggleSavePost(String id) {
    PostItemModel? target;
    for (final List<PostItemModel> list in <List<PostItemModel>>[
      _forYouPosts,
      _followingPosts,
      _communityPosts,
    ]) {
      final int i = list.indexWhere((PostItemModel p) => p.id == id);
      if (i != -1) {
        target = list[i];
        break;
      }
    }
    final bool newSaved = !(target?.isSaved ?? false);
    _updatePostInAllLists(id, (p) => p.copyWith(isSaved: newSaved));
    notifyListeners();

    if (_contentService != null && id.contains('-')) {
      if (newSaved) {
        _contentService!.savePost(id).catchError((dynamic e) {
          debugPrint('⚠️ [HomeFeed] Save post failed: $e');
        });
      } else {
        _contentService!.unsavePost(id).catchError((dynamic e) {
          debugPrint('⚠️ [HomeFeed] Unsave post failed: $e');
        });
      }
    }
  }

  Future<bool> deletePost(String id) async {
    // Optimistically remove from all post and reel feeds
    _forYouPosts.removeWhere((PostItemModel p) => p.id == id);
    _forYouReels.removeWhere((ReelItemModel r) => r.id == id);
    _followingPosts.removeWhere((PostItemModel p) => p.id == id);
    _followingReels.removeWhere((ReelItemModel r) => r.id == id);
    _communityPosts.removeWhere((PostItemModel p) => p.id == id);
    _communityReels.removeWhere((ReelItemModel r) => r.id == id);
    notifyListeners();

    if (_contentService != null && !id.startsWith('mock_') && !id.startsWith('profile_reel_')) {
      try {
        await _contentService!.deletePost(id);
        return true;
      } catch (e) {
        debugPrint('⚠️ [HomeFeed] Delete post failed: $e');
        return false;
      }
    }
    return true;
  }
}

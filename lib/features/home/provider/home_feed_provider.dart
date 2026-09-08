import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/theme/app_images.dart';
import '../../create_post/models/create_post_models.dart';
import '../../create_post/services/media_upload_service.dart';
import '../../create_post/services/post_content_service.dart';
import '../models/post_item_model.dart';
import '../models/reel_item_model.dart';
import '../services/reel_video_preloader.dart';

enum TopTab { following, forYou, communities }
enum SubMode { reels, posts }

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
  bool _isLoadingFeed = true;

  // In-memory cache for resolved media URLs to prevent duplicate CDN fetches
  final Map<String, MediaUploadResult> _mediaCache = <String, MediaUploadResult>{};

  // Live Feed Lists — empty initially, populated only from backend API
  final List<ReelItemModel> _reels = <ReelItemModel>[];
  final List<PostItemModel> _posts = <PostItemModel>[];

  // Getters
  String? get currentUserId => _currentUserId;
  bool get isGuest => _isGuest;
  int get bottomNavIndex => _bottomNavIndex;
  TopTab get activeTopTab => _activeTopTab;
  SubMode get activeSubMode => _activeSubMode;
  String get selectedCommunityFilter => _selectedCommunityFilter;
  bool get isLoadingFeed => _isLoadingFeed;

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

    // Refresh feed to fetch latest like counts
    await loadFeed();
  }

  void _syncInMemLikedState() {
    for (int i = 0; i < _reels.length; i++) {
      final ReelItemModel r = _reels[i];
      final bool shouldBeLiked =
          _currentUserId != null && _userLikedPostIds.contains(r.id);
      if (r.isLiked != shouldBeLiked) {
        _reels[i] = r.copyWith(isLiked: shouldBeLiked);
      }
    }
    for (int i = 0; i < _posts.length; i++) {
      final PostItemModel p = _posts[i];
      final bool shouldBeLiked =
          _currentUserId != null && _userLikedPostIds.contains(p.id);
      if (p.isLiked != shouldBeLiked) {
        _posts[i] = p.copyWith(isLiked: shouldBeLiked);
      }
    }
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
    if (_activeTopTab == TopTab.following) {
      final List<ReelItemModel> following =
          _reels.where((r) => r.isFollowing).toList();
      return following.isNotEmpty ? following : _reels;
    } else if (_activeTopTab == TopTab.communities) {
      final List<ReelItemModel> communityReels = _reels
          .where((r) => r.tags.any((t) => t.toLowerCase().contains('community')))
          .toList();
      return communityReels.isNotEmpty ? communityReels : _reels;
    }
    return _reels;
  }

  List<PostItemModel> get posts => List<PostItemModel>.unmodifiable(
      _posts.where((p) => p.postType.toUpperCase().trim() != 'VIDEO'));

  bool get isFollowingEmpty => false;

  void updateServices({
    PostContentService? contentService,
    MediaUploadService? mediaService,
  }) {
    if (contentService != null) _contentService = contentService;
    if (mediaService != null) _mediaService = mediaService;
  }

  // ── Load Feed from Content Service ─────────────────────────────────────────
  Future<void> loadFeed() async {
    if (_contentService == null) {
      _isLoadingFeed = false;
      notifyListeners();
      return;
    }

    final bool hadData = _reels.isNotEmpty || _posts.isNotEmpty;
    if (!hadData) {
      _isLoadingFeed = true;
      notifyListeners();
    }

    try {
      // 1. Fetch Trending Reels (VIDEO only)
      final List<PostResponseModel> trendingPosts =
          await _contentService!.getTrendingPosts();

      final List<ReelItemModel> liveReels = <ReelItemModel>[];
      for (final PostResponseModel post in trendingPosts) {
        String? videoUrl;
        String? thumbnailUrl;

        if (post.mediaRefs.isNotEmpty && _mediaService != null) {
          final String mediaId = post.mediaRefs.first;
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

        liveReels.add(
          ReelItemModel(
            id: post.id,
            authorId: post.authorId,
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
            durationText: (post.duration != null && post.duration!.isNotEmpty)
                ? post.duration!
                : '0:30',
          ),
        );
      }

      // 2. Fetch General Feed Posts (TEXT, PHOTO, VIDEO)
      final List<PostResponseModel> feedPosts =
          await _contentService!.getFeedPosts();

      final List<PostItemModel> livePosts = <PostItemModel>[];
      for (final PostResponseModel post in feedPosts) {
        final String postType = post.type.toUpperCase().trim();

        // ── Video Posts Handling ──────────────────────────────────────────
        // Video posts belong exclusively to Reels and must NEVER appear
        // as naked text posts in the Posts feed.
        if (postType == 'VIDEO') {
          if (!liveReels.any((r) => r.id == post.id)) {
            String? videoUrl;
            String? thumbnailUrl;

            if (post.mediaRefs.isNotEmpty && _mediaService != null) {
              final String mediaId = post.mediaRefs.first;
              MediaUploadResult? media = _mediaCache[mediaId];
              if (media == null) {
                try {
                  media = await _mediaService!.getMediaStatus(mediaId);
                  _mediaCache[mediaId] = media;
                } catch (e) {
                  debugPrint('⚠️ [HomeFeed] Could not resolve video post media $mediaId: $e');
                }
              }
              videoUrl = media?.url ?? media?.downloadUrl;
              thumbnailUrl = media?.thumbnailUrl;
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

            liveReels.add(
              ReelItemModel(
                id: post.id,
                authorId: post.authorId,
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
                durationText: (post.duration != null && post.duration!.isNotEmpty)
                    ? post.duration!
                    : '0:30',
              ),
            );
          }
          // Do NOT add to livePosts
          continue;
        }

        // ── Text & Photo Posts ────────────────────────────────────────────
        String? imageUrl;

        if (post.mediaRefs.isNotEmpty && _mediaService != null) {
          final String mediaId = post.mediaRefs.first;
          MediaUploadResult? media = _mediaCache[mediaId];
          if (media == null) {
            try {
              media = await _mediaService!.getMediaStatus(mediaId);
              _mediaCache[mediaId] = media;
            } catch (e) {
              debugPrint('⚠️ [HomeFeed] Could not resolve post media $mediaId: $e');
            }
          }
          imageUrl = media?.url ?? media?.downloadUrl ?? media?.thumbnailUrl;
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

        livePosts.add(
          PostItemModel(
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
            isLiked: isLiked,
          ),
        );
      }

      _reels
        ..clear()
        ..addAll(liveReels);

      _posts
        ..clear()
        ..addAll(livePosts);

      if (_reels.isNotEmpty) {
        ReelVideoPreloader.instance.preloadSurrounding(_reels, 0);
      }
    } catch (e) {
      debugPrint('❌ [HomeFeedProvider] Failed to load live feed: $e');
    } finally {
      _isLoadingFeed = false;
      notifyListeners();
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

  // Increment comment count locally when comment is added
  void incrementCommentCount(String postId) {
    final int pIdx = _posts.indexWhere((p) => p.id == postId);
    if (pIdx != -1) {
      _posts[pIdx] = _posts[pIdx].copyWith(commentsCount: _posts[pIdx].commentsCount + 1);
      notifyListeners();
    }
    final int rIdx = _reels.indexWhere((r) => r.id == postId);
    if (rIdx != -1) {
      _reels[rIdx] = _reels[rIdx].copyWith(commentsCount: _reels[rIdx].commentsCount + 1);
      notifyListeners();
    }
  }

  // Actions
  void setGuestMode(bool val) {
    if (_isGuest == val) return;
    _isGuest = val;
    notifyListeners();
  }

  void setBottomNavIndex(int index) {
    if (index == 0 && _bottomNavIndex != 0) {
      _activeTopTab = TopTab.forYou;
    }
    _bottomNavIndex = index;
    notifyListeners();
  }

  void resetToHome() {
    _bottomNavIndex = 0;
    _activeTopTab = TopTab.forYou;
    _activeSubMode = SubMode.reels;
    _selectedCommunityFilter = 'All Communities';
    notifyListeners();
  }

  void setTopTab(TopTab tab) {
    _activeTopTab = tab;
    notifyListeners();
  }

  void setSubMode(SubMode mode) {
    _activeSubMode = mode;
    notifyListeners();
  }

  void setSelectedCommunityFilter(String val) {
    _selectedCommunityFilter = val;
    notifyListeners();
  }

  Future<void> toggleLikeReel(String id) async {
    final int index = _reels.indexWhere((ReelItemModel r) => r.id == id);
    if (index == -1) return;

    final ReelItemModel item = _reels[index];
    final bool newLiked = !item.isLiked;
    final int newCount = newLiked
        ? item.likesCount + 1
        : (item.likesCount > 0 ? item.likesCount - 1 : 0);

    _reels[index] = item.copyWith(isLiked: newLiked, likesCount: newCount);

    // Also sync matching item in _posts if present
    final int pIdx = _posts.indexWhere((PostItemModel p) => p.id == id);
    if (pIdx != -1) {
      _posts[pIdx] =
          _posts[pIdx].copyWith(isLiked: newLiked, likesCount: newCount);
    }

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
        debugPrint('Error syncing like for reel $id: $err');
        // Revert on error
        final int curIdx = _reels.indexWhere((ReelItemModel r) => r.id == id);
        if (curIdx != -1) {
          _reels[curIdx] = item;
        }
        final int curPIdx = _posts.indexWhere((PostItemModel p) => p.id == id);
        if (curPIdx != -1) {
          _posts[curPIdx] = _posts[curPIdx]
              .copyWith(isLiked: item.isLiked, likesCount: item.likesCount);
        }
        if (_currentUserId != null) {
          if (item.isLiked) {
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
    final int index = _reels.indexWhere((ReelItemModel r) => r.id == id);
    if (index != -1) {
      final ReelItemModel item = _reels[index];
      _reels[index] = item.copyWith(isSaved: !item.isSaved);
      notifyListeners();
    }
  }

  void toggleFollowReel(String id) {
    final int index = _reels.indexWhere((ReelItemModel r) => r.id == id);
    if (index != -1) {
      final ReelItemModel item = _reels[index];
      _reels[index] = item.copyWith(isFollowing: !item.isFollowing);
      notifyListeners();
    }
  }

  void addNewReel(ReelItemModel reel) {
    _reels.insert(0, reel);
    notifyListeners();
  }

  void addNewPost(PostItemModel post) {
    if (post.postType.toUpperCase().trim() == 'VIDEO') return;
    _posts.insert(0, post);
    notifyListeners();
  }

  Future<void> toggleLikePost(String id) async {
    final int index = _posts.indexWhere((PostItemModel p) => p.id == id);
    if (index == -1) return;

    final PostItemModel item = _posts[index];
    final bool newLiked = !item.isLiked;
    final int newCount = newLiked
        ? item.likesCount + 1
        : (item.likesCount > 0 ? item.likesCount - 1 : 0);

    _posts[index] = item.copyWith(isLiked: newLiked, likesCount: newCount);

    // Also sync matching item in _reels if present
    final int rIdx = _reels.indexWhere((ReelItemModel r) => r.id == id);
    if (rIdx != -1) {
      _reels[rIdx] =
          _reels[rIdx].copyWith(isLiked: newLiked, likesCount: newCount);
    }

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
        final int curIdx = _posts.indexWhere((PostItemModel p) => p.id == id);
        if (curIdx != -1) {
          _posts[curIdx] = item;
        }
        final int curRIdx = _reels.indexWhere((ReelItemModel r) => r.id == id);
        if (curRIdx != -1) {
          _reels[curRIdx] = _reels[curRIdx]
              .copyWith(isLiked: item.isLiked, likesCount: item.likesCount);
        }
        if (_currentUserId != null) {
          if (item.isLiked) {
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
    final int index = _posts.indexWhere((PostItemModel p) => p.id == id);
    if (index != -1) {
      final PostItemModel item = _posts[index];
      _posts[index] = item.copyWith(isSaved: !item.isSaved);
      notifyListeners();
    }
  }
}

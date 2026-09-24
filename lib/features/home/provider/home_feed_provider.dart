import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/user_relationship_cache.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_images.dart';
import '../../create_post/models/create_post_models.dart';
import '../../create_post/services/media_upload_service.dart';
import '../../create_post/services/post_content_service.dart';
import '../models/post_item_model.dart';
import '../models/reel_item_model.dart';
import '../services/reel_video_preloader.dart';
import '../../../core/utils/video_size_logger.dart';

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
  final Set<String> _userSavedPostIds = <String>{};

  bool isPostSaved(String id) => _userSavedPostIds.contains(id);
  bool isPostLiked(String id) => _userLikedPostIds.contains(id);

  bool _isGuest = false;
  int _bottomNavIndex = 0; // 0: Home, 1: Discover, 2: Create, 3: Messages, 4: Profile
  TopTab _activeTopTab = TopTab.forYou;
  SubMode _activeSubMode = SubMode.reels;
  String _selectedCommunityFilter = 'All Communities';
  String? _selectedCommunityId;

  // Tab-specific feed stores to keep tabs independent and smooth
  final List<ReelItemModel> _forYouReels = <ReelItemModel>[];
  final List<PostItemModel> _forYouPosts = <PostItemModel>[];

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
  MediaUploadService? get mediaService => _mediaService;

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
  String _prefsKeyForSaved(String userId) => 'user_saved_posts_$userId';

  /// Synchronize feed with currently authenticated user.
  /// Isolates like states per user so each account has their own likes.
  Future<void> updateUser(String? newUserId, {dynamic currentUser}) async {
    if (newUserId != null && currentUser != null) {
      try {
        final String? u = (currentUser.username as String?)?.trim();
        final String? d = (currentUser.displayName as String?)?.trim();
        final String? a = (currentUser.avatarUrl as String?)?.trim();
        final bool? h = (currentUser.hideMyLikes as bool?);
        if (u != null && u.isNotEmpty) {
          final AuthorInfo selfInfo = AuthorInfo(
            id: newUserId,
            username: u,
            displayName: (d != null && d.isNotEmpty) ? d : u,
            avatarUrl: a,
            hideMyLikes: h,
          );
          AuthorProfileCache.set(newUserId, selfInfo);
          _enrichFeedWithAuthor(selfInfo);
        }
      } catch (_) {}
    }

    if (_currentUserId == newUserId) return;
    _currentUserId = newUserId;
    if (newUserId != null && newUserId.isNotEmpty) {
      _isGuest = false;
    } else {
      _isGuest = true;
    }
    _userLikedPostIds.clear();
    _userSavedPostIds.clear();

    if (newUserId != null && newUserId.isNotEmpty) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final List<String>? savedLikes =
            prefs.getStringList(_prefsKeyForUser(newUserId));
        if (savedLikes != null) {
          _userLikedPostIds.addAll(savedLikes);
        }
        final List<String>? savedPosts =
            prefs.getStringList(_prefsKeyForSaved(newUserId));
        if (savedPosts != null) {
          _userSavedPostIds.addAll(savedPosts);
        }
      } catch (e) {
        debugPrint('⚠️ [HomeFeedProvider] Error loading user likes/saves: $e');
      }
    }

    _syncInMemLikedState();
    notifyListeners();

    // Refresh active feed to fetch latest like counts
    await loadFeed(force: true);
  }

  Future<void> _resolveAuthorsForPosts(List<PostResponseModel> posts) async {
    if (_contentService == null) return;

    final Set<String> needed = <String>{};
    for (final PostResponseModel post in posts) {
      final String? id = post.authorId?.trim();
      if (id != null && id.isNotEmpty && !AuthorProfileCache.contains(id)) {
        needed.add(id);
      }
    }

    if (needed.isEmpty) return;

    try {
      await Future.wait(
        needed.map((String id) async {
          try {
            final AuthorInfo? info = await _contentService!.getAuthorInfo(id);
            if (info != null) {
              _enrichFeedWithAuthor(info);
            }
          } catch (_) {}
        }),
      );
    } catch (_) {}
  }

  void _enrichFeedWithAuthor(AuthorInfo info) {
    final String cleanId = info.id.trim();
    final String formattedUsername =
        info.username.startsWith('@') ? info.username : '@${info.username}';

    bool changed = false;

    void updateReelList(List<ReelItemModel> list) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].authorId?.trim() == cleanId) {
          list[i] = list[i].copyWith(
            authorDisplayName: info.displayName,
            username: formattedUsername,
            avatarAsset: (info.avatarUrl != null && info.avatarUrl!.isNotEmpty)
                ? info.avatarUrl
                : list[i].avatarAsset,
          );
          changed = true;
        }
      }
    }

    void updatePostList(List<PostItemModel> list) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].authorId?.trim() == cleanId) {
          list[i] = list[i].copyWith(
            authorDisplayName: info.displayName,
            username: formattedUsername,
            avatarAsset: (info.avatarUrl != null && info.avatarUrl!.isNotEmpty)
                ? info.avatarUrl
                : list[i].avatarAsset,
          );
          changed = true;
        }
      }
    }

    updateReelList(_forYouReels);
    updateReelList(_followingReels);
    updateReelList(_communityReels);
    updatePostList(_forYouPosts);
    updatePostList(_followingPosts);
    updatePostList(_communityPosts);

    if (changed) {
      notifyListeners();
    }
  }

  void _syncInMemLikedState() {
    void syncReels(List<ReelItemModel> list) {
      for (int i = 0; i < list.length; i++) {
        final ReelItemModel r = list[i];
        final bool shouldBeLiked = _userLikedPostIds.contains(r.id);
        final bool shouldBeSaved = _userSavedPostIds.contains(r.id);
        if (r.isLiked != shouldBeLiked || r.isSaved != shouldBeSaved) {
          list[i] = r.copyWith(
            isLiked: shouldBeLiked,
            isSaved: shouldBeSaved,
          );
        }
      }
    }

    void syncPosts(List<PostItemModel> list) {
      for (int i = 0; i < list.length; i++) {
        final PostItemModel p = list[i];
        final bool shouldBeLiked = _userLikedPostIds.contains(p.id);
        final bool shouldBeSaved = _userSavedPostIds.contains(p.id);
        if (p.isLiked != shouldBeLiked || p.isSaved != shouldBeSaved) {
          list[i] = p.copyWith(
            isLiked: shouldBeLiked,
            isSaved: shouldBeSaved,
          );
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

  Future<void> _persistUserSaved() async {
    if (_currentUserId == null || _currentUserId!.isEmpty) return;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _prefsKeyForSaved(_currentUserId!),
        _userSavedPostIds.toList(),
      );
    } catch (e) {
      debugPrint('⚠️ [HomeFeedProvider] Error saving user saves: $e');
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
    // Only PHOTO, IMAGE, or TEXT are allowed in the posts feed
    if (t != 'PHOTO' && t != 'IMAGE' && t != 'TEXT') return false;

    final String? img = p.postImageUrl?.toLowerCase();
    if (img != null &&
        (img.endsWith('.mp4') ||
            img.endsWith('.mov') ||
            img.endsWith('.webm') ||
            img.endsWith('.mkv') ||
            img.contains('/videos/') ||
            img.contains('/video/'))) {
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
      final MediaUploadResult? cached = _mediaCache[ref];
      if (cached != null) {
        final String? u = (cached.url ?? cached.downloadUrl)?.toLowerCase();
        if (u != null &&
            (u.endsWith('.mp4') ||
                u.endsWith('.mov') ||
                u.endsWith('.webm') ||
                u.endsWith('.mkv') ||
                u.contains('/videos/') ||
                u.contains('/video/'))) {
          return true;
        }
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
  ReelItemModel _buildReelItem(PostResponseModel post) {
    String? videoUrl;
    String? thumbnailUrl;

    if (post.mediaRefs.isNotEmpty) {
      final String mediaId = post.mediaRefs.first.trim();
      if (mediaId.startsWith('http://') || mediaId.startsWith('https://')) {
        // mediaRef is already a full CDN/HTTP URL → both video and thumb are safe.
        videoUrl = mediaId;
        thumbnailUrl = mediaId;
      } else {
        // mediaRef is a raw UUID from the upload step.
        // Build the HLS playlist URL for ExoPlayer.
        final String clean = mediaId
            .replaceAll(RegExp(r'^/+'), '')
            .replaceAll(RegExp(r'^media/'), '');
        videoUrl = '${AppConfig.cdnUrl}/videos/processed/$clean/master.m3u8';
        if (post.authorId != null && post.authorId!.isNotEmpty) {
          thumbnailUrl = '${AppConfig.cdnUrl}/images/original/${post.authorId}/$clean.jpg';
        } else {
          thumbnailUrl = '${AppConfig.cdnUrl}/videos/processed/$clean/thumbnail.jpg';
        }
      }
    }

    // Prefer the backend-supplied postImageUrl (verified CDN URL) as thumbnail.
    if ((thumbnailUrl == null || thumbnailUrl.isEmpty) &&
        post.postImageUrl != null &&
        post.postImageUrl!.isNotEmpty) {
      thumbnailUrl = post.postImageUrl;
    }

    if ((thumbnailUrl == null || thumbnailUrl.isEmpty) &&
        videoUrl != null &&
        videoUrl.contains('/videos/processed/')) {
      thumbnailUrl = videoUrl.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumbnail.jpg');
    }

    final bool isLiked = _userLikedPostIds.contains(post.id) || post.isLiked;
    if (isLiked) {
      _userLikedPostIds.add(post.id);
    }
    final bool isSaved = _userSavedPostIds.contains(post.id) || post.isSaved;
    if (isSaved) {
      _userSavedPostIds.add(post.id);
    }

    final AuthorInfo? cachedAuthor =
        (post.authorId != null) ? AuthorProfileCache.get(post.authorId!) : null;

    final String? rawReelDisplayName = (cachedAuthor != null && cachedAuthor.displayName.isNotEmpty)
        ? cachedAuthor.displayName
        : ((post.authorDisplayName != null && post.authorDisplayName!.trim().isNotEmpty)
            ? post.authorDisplayName!.trim()
            : null);

    final String resolvedReelDisplayName = rawReelDisplayName ??
        ((cachedAuthor != null && cachedAuthor.username.isNotEmpty)
            ? cachedAuthor.username
            : ((post.authorName != null && post.authorName!.trim().isNotEmpty)
                ? post.authorName!.trim()
                : (post.authorId != null && post.authorId!.length >= 6
                    ? 'User ${post.authorId!.substring(0, 6)}'
                    : 'Creator')));

    final String resolvedUsername = (cachedAuthor != null && cachedAuthor.username.isNotEmpty)
        ? (cachedAuthor.username.startsWith('@') ? cachedAuthor.username : '@${cachedAuthor.username}')
        : ((post.authorName != null && post.authorName!.trim().isNotEmpty)
            ? (post.authorName!.trim().startsWith('@') ? post.authorName!.trim() : '@${post.authorName!.trim()}')
            : (rawReelDisplayName != null
                ? '@${rawReelDisplayName.toLowerCase().replaceAll(' ', '_')}'
                : (post.authorId != null && post.authorId!.length >= 6
                    ? '@user_${post.authorId!.substring(0, 6)}'
                    : (post.id.length >= 6 ? '@user_${post.id.substring(0, 6)}' : '@creator'))));

    final String resolvedAvatar = (post.authorAvatar != null && post.authorAvatar!.isNotEmpty)
        ? post.authorAvatar!
        : ((cachedAuthor?.avatarUrl != null && cachedAuthor!.avatarUrl!.isNotEmpty)
            ? cachedAuthor.avatarUrl!
            : AppImages.defaultAvatar);

    return ReelItemModel(
      id: post.id,
      authorId: post.authorId,
      authorDisplayName: resolvedReelDisplayName,
      username: resolvedUsername,
      pronounsTime: _formatTime(post.createdAt),
      avatarAsset: resolvedAvatar,
      videoAsset: '',
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      caption: post.body.isNotEmpty ? post.body : post.caption,
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      viewsCount: post.viewsCount,
      isLiked: isLiked,
      isSaved: isSaved,
      allowComments: post.allowComments,
      allowDownloads: post.allowDownloads,
      hideLikes: post.hideLikes || (cachedAuthor?.hideMyLikes == true),
      visibility: post.visibility,
      tags: post.tags,
      communityId: post.communityId,
      durationText: (post.duration != null && post.duration!.isNotEmpty)
          ? post.duration!
          : '0:30',
    );
  }

  PostItemModel _buildPostItem(PostResponseModel post) {
    String? imageUrl = post.postImageUrl;
    bool isActuallyVideo = false;

    if (imageUrl == null || imageUrl.isEmpty) {
      if (post.mediaRefs.isNotEmpty) {
        for (final String rawRef in post.mediaRefs) {
          final String ref = rawRef.trim();
          if (ref.isEmpty) continue;
          final String lower = ref.toLowerCase();
          final bool isVideoFile = lower.endsWith('.mp4') ||
              lower.endsWith('.mov') ||
              lower.endsWith('.webm') ||
              lower.endsWith('.mkv') ||
              lower.contains('/videos/') ||
              lower.contains('/video/');
          if (isVideoFile) {
            isActuallyVideo = true;
            continue;
          }

          if (ref.startsWith('http://') ||
              ref.startsWith('https://') ||
              ref.startsWith('assets/')) {
            imageUrl = ref;
            break;
          } else if (post.authorId != null && post.authorId!.isNotEmpty) {
            final String clean = ref
                .replaceAll(RegExp(r'^/+'), '')
                .replaceAll(RegExp(r'^media/'), '');
            imageUrl =
                '${AppConfig.cdnUrl}/images/original/${post.authorId}/$clean.jpg';
            break;
          } else if (AppConfig.baseUrl.isNotEmpty) {
            final String clean = ref
                .replaceAll(RegExp(r'^/+'), '')
                .replaceAll(RegExp(r'^media/'), '');
            imageUrl =
                '${AppConfig.baseUrl.replaceAll(RegExp(r"/+$"), "")}/media/$clean';
            break;
          }
        }
      }
    }

    if (imageUrl != null && imageUrl.isNotEmpty) {
      final String trimmed = imageUrl.trim();
      if (!trimmed.startsWith('http://') &&
          !trimmed.startsWith('https://') &&
          !trimmed.startsWith('assets/')) {
        final String clean = trimmed
            .replaceAll(RegExp(r'^/+'), '')
            .replaceAll(RegExp(r'^media/'), '');
        if (post.authorId != null && post.authorId!.isNotEmpty) {
          imageUrl =
              '${AppConfig.cdnUrl}/images/original/${post.authorId}/$clean.jpg';
        } else {
          final String base = AppConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
          imageUrl = '$base/media/$clean';
        }
      }
    }

    final bool isLiked = _userLikedPostIds.contains(post.id) || post.isLiked;
    if (isLiked) {
      _userLikedPostIds.add(post.id);
    }
    final bool isSaved = _userSavedPostIds.contains(post.id) || post.isSaved;
    if (isSaved) {
      _userSavedPostIds.add(post.id);
    }

    final AuthorInfo? cachedAuthor =
        (post.authorId != null) ? AuthorProfileCache.get(post.authorId!) : null;

    final String? rawPostDisplayName = (cachedAuthor != null && cachedAuthor.displayName.isNotEmpty)
        ? cachedAuthor.displayName
        : ((post.authorDisplayName != null && post.authorDisplayName!.trim().isNotEmpty)
            ? post.authorDisplayName!.trim()
            : null);

    final String resolvedPostDisplayName = rawPostDisplayName ??
        ((cachedAuthor != null && cachedAuthor.username.isNotEmpty)
            ? cachedAuthor.username
            : ((post.authorName != null && post.authorName!.trim().isNotEmpty)
                ? post.authorName!.trim()
                : (post.authorId != null && post.authorId!.length >= 6
                    ? 'User ${post.authorId!.substring(0, 6)}'
                    : 'Creator')));

    final String resolvedPostUsername = (cachedAuthor != null && cachedAuthor.username.isNotEmpty)
        ? (cachedAuthor.username.startsWith('@') ? cachedAuthor.username : '@${cachedAuthor.username}')
        : ((post.authorName != null && post.authorName!.trim().isNotEmpty)
            ? (post.authorName!.trim().startsWith('@') ? post.authorName!.trim() : '@${post.authorName!.trim()}')
            : (rawPostDisplayName != null
                ? '@${rawPostDisplayName.toLowerCase().replaceAll(' ', '_')}'
                : (post.authorId != null && post.authorId!.length >= 6
                    ? '@user_${post.authorId!.substring(0, 6)}'
                    : (post.id.length >= 6 ? '@user_${post.id.substring(0, 6)}' : '@creator'))));

    final String resolvedPostAvatar = (post.authorAvatar != null && post.authorAvatar!.isNotEmpty)
        ? post.authorAvatar!
        : ((cachedAuthor?.avatarUrl != null && cachedAuthor!.avatarUrl!.isNotEmpty)
            ? cachedAuthor.avatarUrl!
            : AppImages.defaultAvatar);

    final bool isFinalVideo = isActuallyVideo ||
        post.type.toUpperCase() == 'VIDEO' ||
        post.type.toUpperCase() == 'REEL';

    final String normalizedType;
    if (isFinalVideo) {
      normalizedType = 'VIDEO';
    } else if (post.type.isNotEmpty) {
      final String ut = post.type.toUpperCase().trim();
      normalizedType = (ut == 'PHOTO' || ut == 'IMAGE') ? 'PHOTO' : (ut == 'TEXT' ? 'TEXT' : ut);
    } else {
      normalizedType = (imageUrl != null && imageUrl.isNotEmpty) ? 'PHOTO' : 'TEXT';
    }

    return PostItemModel(
      id: post.id,
      authorId: post.authorId,
      authorDisplayName: resolvedPostDisplayName,
      username: resolvedPostUsername,
      pronounsTime: _formatTime(post.createdAt),
      avatarAsset: resolvedPostAvatar,
      content: post.body.isNotEmpty ? post.body : post.caption,
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      viewsCount: post.viewsCount,
      postImageUrl: imageUrl,
      postType: normalizedType,
      communityId: post.communityId,
      isLiked: isLiked,
      isSaved: isSaved,
      allowComments: post.allowComments,
      allowDownloads: post.allowDownloads,
      hideLikes: post.hideLikes || (cachedAuthor?.hideMyLikes == true),
      visibility: post.visibility,
    );
  }

  // ── Unified Post & Reel Parser (used by Following & Community feeds) ───────
  _FeedBatch _processPosts(List<PostResponseModel> rawPosts) {
    final List<ReelItemModel> parsedReels = <ReelItemModel>[];
    final List<PostItemModel> parsedPosts = <PostItemModel>[];

    for (final PostResponseModel post in rawPosts) {
      if (post.isDeleted) {
        continue;
      }
      if (!PostVisibilityFilter.canViewPost(
        visibility: post.visibility,
        authorId: post.authorId,
        authorUsername: post.authorName,
        currentUserId: _currentUserId,
        isGuest: _isGuest,
      )) {
        continue;
      }

      final bool isVideo = _isReelOrVideo(post);

      if (isVideo) {
        parsedReels.add(_buildReelItem(post));
      } else {
        final PostItemModel item = _buildPostItem(post);
        final String itemType = item.postType.toUpperCase().trim();
        if (itemType == 'VIDEO' || itemType == 'REEL') {
          parsedReels.add(_buildReelItem(post));
        } else if ((itemType == 'PHOTO' || itemType == 'IMAGE' || itemType == 'TEXT') &&
            _isValidPostItem(item)) {
          parsedPosts.add(item);
        }
      }
    }

    for (final ReelItemModel r in parsedReels) {
      if (r.videoUrl != null && r.videoUrl!.isNotEmpty) {
        VideoSizeLogger.logFeedVideoSize(
          id: r.id,
          title: r.username.isNotEmpty ? '@${r.username}' : r.caption,
          videoUrl: r.videoUrl,
          stage: 'Feed API Fetched',
        );
      }
    }

    return _FeedBatch(reels: parsedReels, posts: parsedPosts);
  }

  // ── 1. Load For You Feed ─────────────────────────────────────────────────
  // Logged-in: GET /feed/for-you (personalized, with Bearer token)
  // Guest:     GET /posts/trending (no auth required)
  Future<void> loadForYouFeed({bool force = false}) async {
    if (_contentService == null) {
      _isLoadingForYou = false;
      notifyListeners();
      return;
    }

    if (!force && (_forYouReels.isNotEmpty || _forYouPosts.isNotEmpty)) {
      _isLoadingForYou = false;
      return;
    }

    _isLoadingForYou = true;
    notifyListeners();

    try {
      final bool isAuthenticated =
          !_isGuest && _currentUserId != null && _currentUserId!.isNotEmpty;

      List<PostResponseModel> rawPosts = <PostResponseModel>[];

      if (isAuthenticated) {
        // Logged-in: ONLY call GET /feed/for-you
        try {
          rawPosts = await _contentService!.getForYouFeed();
        } catch (_) {}
      } else {
        // Guest: ONLY call GET /posts/trending
        try {
          rawPosts = await _contentService!.getTrendingPosts();
        } catch (_) {}
      }

      if (rawPosts.isNotEmpty) {
        await _resolveAuthorsForPosts(rawPosts);
        final _FeedBatch batch = _processPosts(rawPosts);

        _forYouReels
          ..clear()
          ..addAll(batch.reels);

        _forYouPosts
          ..clear()
          ..addAll(batch.posts);

        if (_forYouReels.isNotEmpty && _activeTopTab == TopTab.forYou) {
          ReelVideoPreloader.instance.preloadSurrounding(_forYouReels, 0);
        }
      }
    } catch (_) {
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

      // Pre-resolve missing authors before building feed items
      await _resolveAuthorsForPosts(rawPosts);

      for (final PostResponseModel p in rawPosts) {
        UserRelationshipCache.add(
          userId: p.authorId,
          username: p.authorName,
        );
      }

      final _FeedBatch batch = _processPosts(rawPosts);

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

  // ── 3. Load Community Feed (All Communities -> GET /posts; Filtered -> GET /posts?communityId=:id) ──
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
        debugPrint(
            '🏘️ [HomeFeed] Fetching posts for community: $_selectedCommunityId (GET ${ApiEndpoints.postsByCommunity(_selectedCommunityId!)})');
        rawPosts = await _contentService!.getPostsByCommunity(
          _selectedCommunityId!,
        );
      } else {
        // "All Communities" -> Always call GET /posts directly
        debugPrint(
            '🏘️ [HomeFeed] Fetching All Communities posts (GET ${ApiEndpoints.posts})');
        rawPosts = await _contentService!.getFeedPosts();
      }

      // Pre-resolve missing authors before building feed items
      await _resolveAuthorsForPosts(rawPosts);

      final _FeedBatch batch = _processPosts(rawPosts);

      _communityReels
        ..clear()
        ..addAll(batch.reels);

      _communityPosts
        ..clear()
        ..addAll(batch.posts);

      debugPrint('🏘️ [HomeFeed] Populated Community Feed: ${_communityReels.length} reels, ${_communityPosts.length} posts');

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
    if (_contentService != null &&
        postId.isNotEmpty &&
        !postId.startsWith('mock_') &&
        !postId.startsWith('profile_reel_')) {
      _contentService!.recordView(postId);
      _updateReelInAllLists(postId, (r) => r.copyWith(viewsCount: r.viewsCount + 1));
      _updatePostInAllLists(postId, (p) => p.copyWith(viewsCount: p.viewsCount + 1));
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
      ReelVideoPreloader.instance.setFeedVisible(false);
      ReelVideoPreloader.instance.pauseAll();
      ReelVideoPreloader.instance.muteAll();
    } else {
      ReelVideoPreloader.instance.setFeedVisible(true);
    }
    if (index == 0 && _bottomNavIndex != 0) {
      _activeTopTab = TopTab.forYou;
    }
    _bottomNavIndex = index;
    notifyListeners();
  }

  void resetToHome() {
    ReelVideoPreloader.instance.setFeedVisible(true);
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
          loadCommunityFeed(force: true);
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
      } else if (_activeTopTab == TopTab.communities && _communityPosts.isEmpty) {
        loadCommunityFeed(force: true);
      }
    } else if (mode == SubMode.reels) {
      if (_activeTopTab == TopTab.communities && _communityReels.isEmpty) {
        loadCommunityFeed(force: true);
      }
    }
    _activeSubMode = mode;
    notifyListeners();
  }

  void setSelectedCommunityFilter(String val, {String? communityId}) {
    _selectedCommunityFilter = val;
    final bool isAllCommunities =
        val.trim().toLowerCase() == 'all communities' || val.trim().isEmpty;
    if (isAllCommunities) {
      _selectedCommunityId = null;
    } else {
      _selectedCommunityId =
          (communityId != null && communityId.trim().isNotEmpty)
              ? communityId.trim()
              : null;
      if (_selectedCommunityId == null) {
        try {
          final dynamic cached = CacheManager.instance.get('all_communities');
          if (cached is List) {
            for (final dynamic item in cached) {
              if (item is Map &&
                  (item['name']?.toString().toLowerCase() ==
                          val.toLowerCase() ||
                      item['title']?.toString().toLowerCase() ==
                          val.toLowerCase())) {
                _selectedCommunityId =
                    item['id']?.toString() ?? item['_id']?.toString();
                break;
              }
            }
          }
        } catch (_) {}
      }
    }
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
    final bool alreadyLiked = _userLikedPostIds.contains(id);
    final bool newLiked = !alreadyLiked;

    target ??= ReelItemModel(
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

    final int baseCount = target.likesCount;
    final int newCount = newLiked
        ? (alreadyLiked ? baseCount : baseCount + 1)
        : (alreadyLiked ? (baseCount > 0 ? baseCount - 1 : 0) : baseCount);

    _updateReelInAllLists(id, (r) => r.copyWith(isLiked: newLiked, likesCount: newCount));
    _updatePostInAllLists(id, (p) => p.copyWith(isLiked: newLiked, likesCount: newCount));

    if (newLiked) {
      _userLikedPostIds.add(id);
    } else {
      _userLikedPostIds.remove(id);
    }
    if (_currentUserId != null) {
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

  void toggleSaveReel(String id, {ReelItemModel? fallbackReel}) {
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
    if (target == null && fallbackReel != null) {
      target = fallbackReel;
    }
    final bool currentSaved = target != null ? target.isSaved : _userSavedPostIds.contains(id);
    final bool newSaved = !currentSaved;

    _updateReelInAllLists(id, (r) => r.copyWith(isSaved: newSaved));
    _updatePostInAllLists(id, (p) => p.copyWith(isSaved: newSaved));

    if (_currentUserId != null) {
      if (newSaved) {
        _userSavedPostIds.add(id);
      } else {
        _userSavedPostIds.remove(id);
      }
      _persistUserSaved();
    }

    notifyListeners();

    final bool isRealBackendId = !id.startsWith('profile_reel_') &&
        !id.startsWith('search_reel_') &&
        !id.startsWith('mock_');
    if (_contentService != null && (id.contains('-') || isRealBackendId)) {
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

  Future<void> toggleLikePost(String id, {PostItemModel? fallbackPost}) async {
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
    if (target == null && fallbackPost != null) {
      target = fallbackPost;
    }
    final bool alreadyLiked = _userLikedPostIds.contains(id);
    final bool newLiked = !alreadyLiked;

    target ??= PostItemModel(
        id: id,
        username: '@creator',
        pronounsTime: '',
        avatarAsset: '',
        content: '',
        likesCount: alreadyLiked ? 1 : 0,
        commentsCount: 0,
        isLiked: alreadyLiked,
      );

    final int baseCount = target.likesCount;
    final int newCount = newLiked
        ? (alreadyLiked ? baseCount : baseCount + 1)
        : (alreadyLiked ? (baseCount > 0 ? baseCount - 1 : 0) : baseCount);

    _updatePostInAllLists(id, (p) => p.copyWith(isLiked: newLiked, likesCount: newCount));
    _updateReelInAllLists(id, (r) => r.copyWith(isLiked: newLiked, likesCount: newCount));

    if (newLiked) {
      _userLikedPostIds.add(id);
    } else {
      _userLikedPostIds.remove(id);
    }
    if (_currentUserId != null) {
      _persistUserLikes();
    }

    notifyListeners();

    final bool isRealBackendId = !id.startsWith('profile_reel_') &&
        !id.startsWith('search_reel_') &&
        !id.startsWith('mock_');
    if (_contentService != null && (id.contains('-') || isRealBackendId)) {
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
        if (target.isLiked) {
          _userLikedPostIds.add(id);
        } else {
          _userLikedPostIds.remove(id);
        }
        if (_currentUserId != null) {
          _persistUserLikes();
        }
        notifyListeners();
      }
    }
  }

  void toggleSavePost(String id, {PostItemModel? fallbackPost}) {
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
    if (target == null && fallbackPost != null) {
      target = fallbackPost;
    }
    final bool currentSaved = _userSavedPostIds.contains(id);
    final bool newSaved = !currentSaved;

    _updatePostInAllLists(id, (p) => p.copyWith(isSaved: newSaved));
    _updateReelInAllLists(id, (r) => r.copyWith(isSaved: newSaved));

    if (newSaved) {
      _userSavedPostIds.add(id);
    } else {
      _userSavedPostIds.remove(id);
    }
    if (_currentUserId != null) {
      _persistUserSaved();
    }

    notifyListeners();

    final bool isRealBackendId = !id.startsWith('profile_reel_') &&
        !id.startsWith('search_reel_') &&
        !id.startsWith('mock_');
    if (_contentService != null && (id.contains('-') || isRealBackendId)) {
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
    DeletedPostsRegistry.markDeleted(id);
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

// Profile Provider — manages fetching and updating User Profile via GET/PATCH /users/:id.

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_images.dart';
import '../../create_post/models/create_post_models.dart';
import '../../create_post/services/post_content_service.dart';
import '../../home/models/post_item_model.dart';
import '../../home/models/reel_item_model.dart';
import '../../profile_setup/models/community_model.dart';
import '../../profile_setup/models/profile_models.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required ApiClient client}) : _client = client;

  final ApiClient _client;

  UserProfile? _profile;
  bool _isBusy = false;
  String? _error;
  String? _cachedUserId;

  List<PostItemModel> _userPosts = <PostItemModel>[];
  List<ReelItemModel> _userReels = <ReelItemModel>[];
  List<CommunityModel> _userCommunities = <CommunityModel>[];
  bool _isLoadingContent = false;

  List<PostItemModel> _likedPosts = <PostItemModel>[];
  List<ReelItemModel> _likedReels = <ReelItemModel>[];
  bool _isLoadingLiked = false;

  List<PostItemModel> _savedPosts = <PostItemModel>[];
  List<ReelItemModel> _savedReels = <ReelItemModel>[];
  bool _isLoadingSaved = false;

  UserProfile? get profile => _profile;
  bool get isBusy => _isBusy;
  String? get error => _error;
  bool get hasProfile => _profile != null;

  List<PostItemModel> get userPosts => _userPosts;
  List<ReelItemModel> get userReels => _userReels;
  List<CommunityModel> get userCommunities => _userCommunities;
  bool get isLoadingContent => _isLoadingContent;

  List<PostItemModel> get likedPosts => _likedPosts;
  List<ReelItemModel> get likedReels => _likedReels;
  bool get isLoadingLiked => _isLoadingLiked;

  List<PostItemModel> get savedPosts => _savedPosts;
  List<ReelItemModel> get savedReels => _savedReels;
  bool get isLoadingSaved => _isLoadingSaved;

  String get displayName => _profile?.displayName ?? 'Ash Mercado';
  String get username => _profile?.username ?? 'ashinorbit';
  String get bio =>
      _profile?.bio ??
      'Film nerd, softball catcher, chronically making playlists.';
  String get avatarUrl =>
      _profile?.avatarUrl ?? 'https://picsum.photos/seed/ash/400';
  String get pronounsFormatted => _profile?.formattedPronouns ?? 'she / they';
  List<String> get pronouns =>
      _profile?.pronouns ?? const <String>['she/her', 'they/them'];

  String get postsCount {
    final int total = _userPosts.length + _userReels.length;
    if (total > 0) return '$total';
    if (_profile?.postsCount != null && (_profile!.postsCount ?? 0) > 0) {
      return '${_profile!.postsCount}';
    }
    return '0';
  }

  String get followersCount =>
      _profile?.followersCount != null ? '${_profile!.followersCount}' : '0';
  String get followingCount =>
      _profile?.followingCount != null ? '${_profile!.followingCount}' : '0';

  List<String> get interests => _profile?.interests ?? const <String>[];
  bool get isPrivate => _profile?.isPrivate ?? false;
  bool get showInDiscover => _profile?.showInDiscover ?? true;
  String get allowMessagesFrom => _profile?.allowMessagesFrom ?? 'everyone';
  String get allowMessagesFromLabel =>
      formatPrivacyLabel(_profile?.allowMessagesFrom);
  bool get hideMyLikes => _profile?.hideMyLikes ?? false;
  String get profileVisibility => _profile?.profileVisibility ?? 'everyone';
  String get profileVisibilityLabel =>
      formatPrivacyLabel(_profile?.profileVisibility);
  bool get notifyOnLike => _profile?.notifyOnLike ?? true;
  bool get notifyOnComment => _profile?.notifyOnComment ?? true;
  bool get notifyOnFollow => _profile?.notifyOnFollow ?? true;
  bool get notifyOnMessage => _profile?.notifyOnMessage ?? true;

  String get allowCommentsFrom => _profile?.allowCommentsFrom ?? 'everyone';
  String get allowCommentsFromLabel =>
      formatPrivacyLabel(_profile?.allowCommentsFrom);
  bool get showActivityStatus => _profile?.showActivityStatus ?? true;
  bool get sendReadReceipts => _profile?.sendReadReceipts ?? true;
  bool get notifyOnFollowRequests => _profile?.notifyOnFollowRequests ?? true;
  bool get notifyOnCommunityPosts => _profile?.notifyOnCommunityPosts ?? true;
  bool get notifyOnAnnouncementsFeatures =>
      _profile?.notifyOnAnnouncementsFeatures ?? true;
  bool get notifyOnSafetyModerationUpdates =>
      _profile?.notifyOnSafetyModerationUpdates ?? true;

  static String formatPrivacyLabel(String? val) {
    if (val == null || val.isEmpty) return 'Everyone';
    final String lower = val.toLowerCase().trim();
    if (lower.contains('everyone')) return 'Everyone';
    if (lower.contains('nobody')) return 'Nobody';
    if (lower.contains('mutual')) return 'Mutual follows';
    if (lower.contains('follow')) return 'People you follow';
    return 'Everyone';
  }

  // ── GET /users/:id ─────────────────────────────────────────────────────────

  Future<void> fetchProfile(String userId) async {
    if (userId.isEmpty) return;

    final bool userChanged = _cachedUserId != userId;
    if (userChanged) {
      _cachedUserId = userId;
      // Try restoring from CacheManager immediately so UI renders in 0 microseconds
      final dynamic cachedProfile =
          CacheManager.instance.get('profile_details_$userId');
      if (cachedProfile is Map<String, dynamic>) {
        try {
          _profile = UserProfile.fromJson(cachedProfile);
        } catch (_) {}
      } else {
        _profile = null;
        _userPosts.clear();
        _userReels.clear();
        _userCommunities.clear();
      }
    }

    // Only mark as busy if there's no profile data yet
    if (_profile == null) {
      _isBusy = true;
      notifyListeners();
    }
    _error = null;

    // Batch call: fetch profile details, communities, and user posts concurrently
    await Future.wait(<Future<void>>[
      _fetchProfileDetails(userId),
      fetchUserCommunities(userId),
      fetchUserContent(userId),
    ]);
  }

  Future<void> _fetchProfileDetails(String userId) async {
    try {
      if (AppConfig.useMockApi) {
        _profile = UserProfile(
          id: userId,
          displayName: 'Ash Mercado',
          username: 'ashinorbit',
          bio: 'Film nerd, softball catcher, chronically making playlists.',
          avatarUrl: 'https://picsum.photos/seed/ash/400',
          pronouns: const <String>['she/her', 'they/them'],
          pronounsPrivate: false,
        );
      } else {
        debugPrint(
            '🚀 [ProfileProvider] Fetching profile for user: $userId (GET /users/$userId)');
        final dynamic data = await _client.get(ApiEndpoints.user(userId));
        debugPrint('📥 [ProfileProvider] Profile data received: $data');
        if (data is Map<String, dynamic>) {
          CacheManager.instance.put(
            'profile_details_$userId',
            data,
            ttl: const Duration(days: 7),
          );
          _profile = UserProfile.fromJson(data);
        }
      }
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      debugPrint('⚠️ [ProfileProvider] Fetch profile API error: ${e.message}');
    } catch (e) {
      _error = 'Failed to load profile.';
      debugPrint('⚠️ [ProfileProvider] Fetch profile generic error: $e');
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> fetchUserCommunities(String userId,
      {bool forceRefresh = false}) async {
    if (userId.isEmpty) return;

    if (forceRefresh) {
      CacheManager.instance.remove(ApiEndpoints.userCommunities(userId));
      CacheManager.instance.remove(ApiEndpoints.userCommunitiesAlt(userId));
    }

    try {
      debugPrint(
          '🚀 [ProfileProvider] Fetching user communities (GET ${ApiEndpoints.userCommunities(userId)}, forceRefresh: $forceRefresh)');
      dynamic data;
      try {
        data = await _client.get(
          ApiEndpoints.userCommunities(userId),
          useCache: !forceRefresh,
        );
      } catch (e) {
        debugPrint(
            '⚠️ [ProfileProvider] Failed primary endpoint, trying alt: $e');
        data = await _client.get(
          ApiEndpoints.userCommunitiesAlt(userId),
          useCache: !forceRefresh,
        );
      }
      debugPrint('📥 [ProfileProvider] User communities response: $data');

      List<dynamic> rawList = <dynamic>[];
      if (data is List) {
        rawList = data;
      } else if (data is Map<String, dynamic>) {
        if (data['data'] is List) {
          rawList = data['data'] as List<dynamic>;
        } else if (data['communities'] is List) {
          rawList = data['communities'] as List<dynamic>;
        } else if (data['items'] is List) {
          rawList = data['items'] as List<dynamic>;
        }
      }

      final List<CommunityModel> communities = <CommunityModel>[];
      for (final dynamic item in rawList) {
        if (item is Map<String, dynamic>) {
          final Map<String, dynamic> commMap =
              (item['community'] is Map<String, dynamic>)
                  ? item['community'] as Map<String, dynamic>
                  : item;
          communities.add(
              CommunityModel.fromJson(commMap).copyWith(isJoined: true));
        } else if (item is String) {
          communities
              .add(CommunityModel(id: item, name: item, isJoined: true));
        }
      }

      _userCommunities = communities;
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Could not fetch user communities: $e');
    }
  }

  Future<_ContentBatch> _processPosts(
    List<PostResponseModel> posts, {
    String? fallbackAuthorId,
    bool markSaved = false,
  }) async {
    final List<PostItemModel> userPostsList = <PostItemModel>[];
    final List<ReelItemModel> userReelsList = <ReelItemModel>[];

    for (final PostResponseModel post in posts) {
      String? mediaUrl;
      String? thumbnailUrl;

      if (post.mediaRefs.isNotEmpty) {
        final String mediaId = post.mediaRefs.first;
        try {
          final dynamic mediaData =
              await _client.get(ApiEndpoints.mediaStatus(mediaId));
          if (mediaData is Map<String, dynamic>) {
            mediaUrl = mediaData['url'] as String? ??
                mediaData['downloadUrl'] as String?;
            thumbnailUrl = mediaData['thumbnailUrl'] as String?;
          }
        } catch (e) {
          debugPrint('⚠️ [ProfileProvider] Could not resolve media $mediaId: $e');
        }
      }

      final String type = post.type.toUpperCase().trim();
      final String authorUsername =
          post.authorName ?? _profile?.username ?? 'you';
      final String formattedUsername = authorUsername.startsWith('@')
          ? authorUsername
          : '@$authorUsername';
      final String avatar = (post.authorAvatar != null &&
              post.authorAvatar!.isNotEmpty)
          ? post.authorAvatar!
          : ((_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
              ? _profile!.avatarUrl!
              : AppImages.user1);

      if (type == 'VIDEO') {
        userReelsList.add(
          ReelItemModel(
            id: post.id,
            authorId: post.authorId ?? fallbackAuthorId ?? _cachedUserId,
            authorDisplayName: post.authorDisplayName,
            username: formattedUsername,
            pronounsTime: (post.createdAt != null && post.createdAt!.isNotEmpty)
                ? _formatTime(post.createdAt)
                : 'just now',
            avatarAsset: avatar,
            videoAsset: '',
            videoUrl: mediaUrl,
            thumbnailUrl: thumbnailUrl,
            caption: post.body.isNotEmpty ? post.body : post.caption,
            likesCount: post.likesCount,
            commentsCount: post.commentsCount,
            isLiked: post.isLiked,
            isSaved: markSaved || post.isSaved,
            tags: post.tags,
            durationText:
                (post.duration != null && post.duration!.isNotEmpty)
                    ? post.duration!
                    : '0:30',
          ),
        );
      } else {
        // PHOTO or TEXT
        userPostsList.add(
          PostItemModel(
            id: post.id,
            authorId: post.authorId ?? fallbackAuthorId ?? _cachedUserId,
            username: formattedUsername,
            pronounsTime: (post.createdAt != null && post.createdAt!.isNotEmpty)
                ? _formatTime(post.createdAt)
                : 'just now',
            avatarAsset: avatar,
            content: post.body.isNotEmpty ? post.body : post.caption,
            likesCount: post.likesCount,
            commentsCount: post.commentsCount,
            isLiked: post.isLiked,
            isSaved: markSaved || post.isSaved,
            postImageUrl: mediaUrl,
            postType: type,
          ),
        );
      }
    }

    return _ContentBatch(posts: userPostsList, reels: userReelsList);
  }

  Future<void> fetchUserContent(String userId) async {
    if (userId.isEmpty) return;

    _isLoadingContent = true;
    notifyListeners();

    try {
      final PostContentService service = PostContentService(_client);
      final List<PostResponseModel> posts =
          await service.getPostsByAuthor(userId);
      final _ContentBatch batch =
          await _processPosts(posts, fallbackAuthorId: userId);

      _userPosts = batch.posts;
      _userReels = batch.reels;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Error fetching user content: $e');
    } finally {
      _isLoadingContent = false;
      notifyListeners();
    }
  }

  /// List User's Liked Posts. GET /users/me/likes
  Future<void> fetchLikedPosts({bool force = false}) async {
    if (!force && (_likedPosts.isNotEmpty || _likedReels.isNotEmpty)) return;
    _isLoadingLiked = true;
    notifyListeners();

    try {
      final PostContentService service = PostContentService(_client);
      final List<PostResponseModel> posts = await service.getLikedPosts();
      final _ContentBatch batch = await _processPosts(posts);

      _likedPosts = batch.posts;
      _likedReels = batch.reels;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Error fetching liked posts: $e');
    } finally {
      _isLoadingLiked = false;
      notifyListeners();
    }
  }

  /// List User's Saved Posts. GET /users/me/saved
  Future<void> fetchSavedPosts({bool force = false}) async {
    if (!force && (_savedPosts.isNotEmpty || _savedReels.isNotEmpty)) return;
    _isLoadingSaved = true;
    notifyListeners();

    try {
      final PostContentService service = PostContentService(_client);
      final List<PostResponseModel> posts = await service.getSavedPosts();
      final _ContentBatch batch = await _processPosts(posts, markSaved: true);

      _savedPosts = batch.posts;
      _savedReels = batch.reels;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Error fetching saved posts: $e');
    } finally {
      _isLoadingSaved = false;
      notifyListeners();
    }
  }

  /// Delete own Post or Video Post. DELETE /posts/:id
  Future<bool> deletePost(String postId) async {
    _userPosts.removeWhere((PostItemModel p) => p.id == postId);
    _userReels.removeWhere((ReelItemModel r) => r.id == postId);
    _likedPosts.removeWhere((PostItemModel p) => p.id == postId);
    _likedReels.removeWhere((ReelItemModel r) => r.id == postId);
    _savedPosts.removeWhere((PostItemModel p) => p.id == postId);
    _savedReels.removeWhere((ReelItemModel r) => r.id == postId);
    notifyListeners();

    try {
      final PostContentService service = PostContentService(_client);
      await service.deletePost(postId);
      return true;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Error deleting post: $e');
      return false;
    }
  }

  static String _formatTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return 'just now';
    try {
      final DateTime dt = DateTime.parse(dateStr);
      final Duration diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'just now';
    } catch (_) {
      return 'just now';
    }
  }

  void addUserPost(PostItemModel post) {
    _userPosts.insert(0, post);
    notifyListeners();
  }

  void addUserReel(ReelItemModel reel) {
    _userReels.insert(0, reel);
    notifyListeners();
  }

  // ── PATCH /users/:id ───────────────────────────────────────────────────────

  Future<bool> updateProfile(
    String userId, {
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? avatarBase64,
    List<String>? pronouns,
    bool? pronounsPrivate,
    List<String>? interests,
    bool? isPrivate,
    bool? showInDiscover,
    String? allowMessagesFrom,
    bool? hideMyLikes,
    String? profileVisibility,
    String? allowCommentsFrom,
    bool? showActivityStatus,
    bool? sendReadReceipts,
    bool? notifyOnLike,
    bool? notifyOnComment,
    bool? notifyOnFollow,
    bool? notifyOnMessage,
    bool? notifyOnFollowRequests,
    bool? notifyOnCommunityPosts,
    bool? notifyOnAnnouncementsFeatures,
    bool? notifyOnSafetyModerationUpdates,
  }) async {
    if (userId.isEmpty) return false;

    _isBusy = true;
    _error = null;
    notifyListeners();

    final Map<String, dynamic> payload = <String, dynamic>{};
    if (displayName != null) payload['displayName'] = displayName.trim();
    if (username != null) payload['username'] = username.trim();
    if (bio != null) payload['bio'] = bio.trim();
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      payload['avatarBase64'] = avatarBase64;
    } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
      payload['avatarUrl'] = avatarUrl.trim();
    }
    if (pronouns != null) payload['pronouns'] = pronouns;
    if (pronounsPrivate != null) payload['pronounsPrivate'] = pronounsPrivate;
    if (interests != null) payload['interests'] = interests;
    if (isPrivate != null) payload['isPrivate'] = isPrivate;
    if (showInDiscover != null) payload['showInDiscover'] = showInDiscover;
    if (allowMessagesFrom != null) {
      payload['allowMessagesFrom'] = _normalizePrivacy(allowMessagesFrom);
    }
    if (allowCommentsFrom != null) {
      payload['allowCommentsFrom'] = _normalizePrivacy(allowCommentsFrom);
    }
    if (hideMyLikes != null) payload['hideMyLikes'] = hideMyLikes;
    if (profileVisibility != null) {
      payload['profileVisibility'] = _normalizePrivacy(profileVisibility);
    }
    if (showActivityStatus != null) {
      payload['showActivityStatus'] = showActivityStatus;
    }
    if (sendReadReceipts != null) {
      payload['sendReadReceipts'] = sendReadReceipts;
    }
    if (notifyOnLike != null) payload['notifyOnLike'] = notifyOnLike;
    if (notifyOnComment != null) payload['notifyOnComment'] = notifyOnComment;
    if (notifyOnFollow != null) payload['notifyOnFollow'] = notifyOnFollow;
    if (notifyOnMessage != null) payload['notifyOnMessage'] = notifyOnMessage;
    if (notifyOnFollowRequests != null) {
      payload['notifyOnFollowRequests'] = notifyOnFollowRequests;
    }
    if (notifyOnCommunityPosts != null) {
      payload['notifyOnCommunityPosts'] = notifyOnCommunityPosts;
    }
    if (notifyOnAnnouncementsFeatures != null) {
      payload['notifyOnAnnouncementsFeatures'] = notifyOnAnnouncementsFeatures;
    }
    if (notifyOnSafetyModerationUpdates != null) {
      payload['notifyOnSafetyModerationUpdates'] =
          notifyOnSafetyModerationUpdates;
    }

    if (payload.isEmpty) {
      _isBusy = false;
      notifyListeners();
      return true;
    }

    try {
      if (!AppConfig.useMockApi) {
        debugPrint(
            '🚀 [ProfileProvider] Updating profile for: $userId (PATCH /users/$userId)\n   Payload: $payload');
        final dynamic data = await _client.patch(
          ApiEndpoints.user(userId),
          body: payload,
        );
        debugPrint('📥 [ProfileProvider] Profile updated: $data');
        final UserProfile updated =
            UserProfile.fromJson(data as Map<String, dynamic>);
        _profile = (_profile ?? UserProfile(id: userId)).merge(updated);
      } else {
        _profile = (_profile ?? UserProfile(id: userId)).merge(
          UserProfile(
            id: userId,
            displayName: displayName,
            username: username,
            bio: bio,
            avatarUrl: avatarUrl,
            pronouns: pronouns,
            pronounsPrivate: pronounsPrivate,
            interests: interests,
            isPrivate: isPrivate,
            showInDiscover: showInDiscover,
            allowMessagesFrom: allowMessagesFrom,
            allowCommentsFrom: allowCommentsFrom,
            hideMyLikes: hideMyLikes,
            profileVisibility: profileVisibility,
            showActivityStatus: showActivityStatus,
            sendReadReceipts: sendReadReceipts,
            notifyOnLike: notifyOnLike,
            notifyOnComment: notifyOnComment,
            notifyOnFollow: notifyOnFollow,
            notifyOnMessage: notifyOnMessage,
            notifyOnFollowRequests: notifyOnFollowRequests,
            notifyOnCommunityPosts: notifyOnCommunityPosts,
            notifyOnAnnouncementsFeatures: notifyOnAnnouncementsFeatures,
            notifyOnSafetyModerationUpdates: notifyOnSafetyModerationUpdates,
          ),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to update profile.';
      notifyListeners();
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String _normalizePrivacy(String val) {
    val = val.toLowerCase().trim();
    if (val.contains('everyone')) return 'everyone';
    if (val.contains('nobody')) return 'nobody';
    if (val.contains('mutual')) return 'mutual';
    if (val.contains('follow')) return 'following';
    return val;
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}

class _ContentBatch {
  const _ContentBatch({required this.posts, required this.reels});
  final List<PostItemModel> posts;
  final List<ReelItemModel> reels;
}

// Profile Provider — manages fetching and updating User Profile via GET/PATCH /users/:id.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/user_relationship_cache.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_images.dart';
import '../../create_post/models/create_post_models.dart';
import '../../create_post/services/post_content_service.dart';
import '../../home/models/post_item_model.dart';
import '../../home/models/reel_item_model.dart';
import '../../profile_setup/models/community_model.dart';
import '../../profile_setup/models/profile_models.dart';
import '../../profile_setup/profile_setup_service.dart';
import '../models/user_relationship_models.dart';
import '../services/user_relationship_service.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({
    required ApiClient client,
    UserRelationshipService? relationshipService,
  })  : _client = client,
        _relationshipService = relationshipService ?? UserRelationshipService(client);

  final ApiClient _client;
  final UserRelationshipService _relationshipService;

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
  bool _hasFetchedLiked = false;
  bool _hasFetchedSaved = false;

  List<BlockedAccountItem> _blockedAccounts = <BlockedAccountItem>[];
  bool _isLoadingBlocked = false;

  List<RestrictedAccountItem> _restrictedAccounts = <RestrictedAccountItem>[];
  bool _isLoadingRestricted = false;

  List<MutedAccountItem> _mutedAccounts = <MutedAccountItem>[];
  bool _isLoadingMuted = false;

  List<FollowRequestItem> _followRequests = <FollowRequestItem>[];
  bool _isLoadingFollowRequests = false;

  List<UserRelationItem> _followers = <UserRelationItem>[];
  List<UserRelationItem> _following = <UserRelationItem>[];
  final Set<String> _followingUserIds = <String>{};
  final Set<String> _followingUsernames = <String>{};
  bool _isLoadingRelations = false;

  Set<String> get followingUserIds => Set<String>.unmodifiable(_followingUserIds);
  Set<String> get followingUsernames => Set<String>.unmodifiable(_followingUsernames);

  bool isFollowingUser({String? userId, String? username}) {
    if (userId != null && userId.trim().isNotEmpty) {
      final String cleanId = userId.trim().toLowerCase();
      if (_followingUserIds.contains(cleanId)) return true;
    }
    if (username != null && username.trim().isNotEmpty) {
      final String cleanUsername =
          username.replaceAll('@', '').trim().toLowerCase();
      if (_followingUsernames.contains(cleanUsername)) return true;
    }
    return false;
  }

  void addFollowedUser({required String userId, String? username}) {
    if (userId.trim().isNotEmpty) {
      _followingUserIds.add(userId.trim().toLowerCase());
    }
    if (username != null && username.trim().isNotEmpty) {
      _followingUsernames.add(username.replaceAll('@', '').trim().toLowerCase());
    }
    UserRelationshipCache.add(userId: userId, username: username);
    notifyListeners();
  }

  void removeFollowedUser({required String userId, String? username}) {
    if (userId.trim().isNotEmpty) {
      _followingUserIds.remove(userId.trim().toLowerCase());
    }
    if (username != null && username.trim().isNotEmpty) {
      _followingUsernames.remove(username.replaceAll('@', '').trim().toLowerCase());
    }
    UserRelationshipCache.remove(userId: userId, username: username);
    notifyListeners();
  }

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
  bool get hasFetchedLiked => _hasFetchedLiked;

  List<PostItemModel> get savedPosts => _savedPosts;
  List<ReelItemModel> get savedReels => _savedReels;
  bool get isLoadingSaved => _isLoadingSaved;
  bool get hasFetchedSaved => _hasFetchedSaved;

  bool isPostLiked(String id) {
    if (_likedPosts.any((PostItemModel p) => p.id == id && p.isLiked)) return true;
    if (_likedReels.any((ReelItemModel r) => r.id == id && r.isLiked)) return true;
    if (_userPosts.any((PostItemModel p) => p.id == id && p.isLiked)) return true;
    if (_userReels.any((ReelItemModel r) => r.id == id && r.isLiked)) return true;
    if (_savedPosts.any((PostItemModel p) => p.id == id && p.isLiked)) return true;
    if (_savedReels.any((ReelItemModel r) => r.id == id && r.isLiked)) return true;
    return false;
  }

  bool isPostSaved(String id) {
    if (_savedPosts.any((PostItemModel p) => p.id == id && p.isSaved)) return true;
    if (_savedReels.any((ReelItemModel r) => r.id == id && r.isSaved)) return true;
    if (_userPosts.any((PostItemModel p) => p.id == id && p.isSaved)) return true;
    if (_userReels.any((ReelItemModel r) => r.id == id && r.isSaved)) return true;
    if (_likedPosts.any((PostItemModel p) => p.id == id && p.isSaved)) return true;
    if (_likedReels.any((ReelItemModel r) => r.id == id && r.isSaved)) return true;
    return false;
  }

  List<BlockedAccountItem> get blockedAccounts => _blockedAccounts;
  bool get isLoadingBlocked => _isLoadingBlocked;

  List<RestrictedAccountItem> get restrictedAccounts => _restrictedAccounts;
  bool get isLoadingRestricted => _isLoadingRestricted;

  List<MutedAccountItem> get mutedAccounts => _mutedAccounts;
  bool get isLoadingMuted => _isLoadingMuted;

  List<FollowRequestItem> get followRequests => _followRequests;
  bool get isLoadingFollowRequests => _isLoadingFollowRequests;

  List<UserRelationItem> get followers => _followers;
  List<UserRelationItem> get following => _following;
  bool get isLoadingRelations => _isLoadingRelations;

  UserRelationshipService get relationshipService => _relationshipService;

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

  String get followersCount {
    final int? profileCount = _profile?.followersCount;
    if (_followers.length > (profileCount ?? 0)) {
      return '${_followers.length}';
    }
    if (profileCount != null && profileCount > 0) {
      return '$profileCount';
    }
    if (_followers.isNotEmpty) {
      return '${_followers.length}';
    }
    return '${profileCount ?? 0}';
  }

  String get followingCount {
    final int? profileCount = _profile?.followingCount;
    if (_following.length > (profileCount ?? 0)) {
      return '${_following.length}';
    }
    if (profileCount != null && profileCount > 0) {
      return '$profileCount';
    }
    if (_following.isNotEmpty) {
      return '${_following.length}';
    }
    return '${profileCount ?? 0}';
  }

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
        _likedPosts.clear();
        _likedReels.clear();
        _savedPosts.clear();
        _savedReels.clear();
        _hasFetchedLiked = false;
        _hasFetchedSaved = false;
      }
    }

    // Only mark as busy if there's no profile data yet
    if (_profile == null) {
      _isBusy = true;
      notifyListeners();
    }
    _error = null;

    // Batch call: fetch profile details, communities, user posts, followers, following, and relationships concurrently
    await Future.wait(<Future<void>>[
      _fetchProfileDetails(userId),
      fetchUserCommunities(userId),
      fetchUserContent(userId),
      loadFollowers(userId),
      loadFollowing(userId),
      loadBlockedAccounts(),
      loadRestrictedAccounts(),
      loadMutedAccounts(),
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
          if (_profile != null) {
            AuthorProfileCache.set(
              _profile!.id,
              AuthorInfo(
                id: _profile!.id,
                username: _profile!.username ?? '',
                displayName: _profile!.displayName ?? '',
                avatarUrl: _profile!.avatarUrl,
                hideMyLikes: _profile!.hideMyLikes,
              ),
            );
          }
          try {
            if (data['showActivityStatus'] is bool) {
              SharedPreferences.getInstance().then((SharedPreferences prefs) {
                prefs.setBool('privacy_show_activity_$userId', data['showActivityStatus'] as bool);
              });
            }
            if (data['sendReadReceipts'] is bool) {
              SharedPreferences.getInstance().then((SharedPreferences prefs) {
                prefs.setBool('privacy_read_receipts_$userId', data['sendReadReceipts'] as bool);
              });
            }
          } catch (_) {}
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

  /// Checks if a community is joined by checking the user's active communities.
  bool isCommunityJoined({String? id, String? name}) {
    if (id != null && id.isNotEmpty) {
      if (_userCommunities.any((CommunityModel c) => c.id == id)) return true;
    }
    if (name != null && name.isNotEmpty) {
      final String clean = name.trim().toLowerCase();
      if (_userCommunities.any((CommunityModel c) => c.name.trim().toLowerCase() == clean)) {
        return true;
      }
    }
    return false;
  }

  /// Dynamically joins a community and updates the profile's joined communities.
  Future<void> joinCommunity(String communityId, {String? name}) async {
    try {
      final ProfileSetupService setupService = ProfileSetupService(_client);
      String targetId = communityId;
      if (targetId.isEmpty && name != null && name.isNotEmpty) {
        final List<CommunityModel> allComms = await setupService.getCommunities();
        final CommunityModel match = allComms.firstWhere(
          (CommunityModel c) => c.name.trim().toLowerCase() == name.trim().toLowerCase(),
          orElse: () => const CommunityModel(id: '', name: '', description: ''),
        );
        targetId = match.id;
      }
      if (targetId.isNotEmpty) {
        await setupService.joinCommunity(targetId);
      }
      if (!_userCommunities.any((CommunityModel c) =>
          (targetId.isNotEmpty && c.id == targetId) ||
          (name != null && c.name.trim().toLowerCase() == name.trim().toLowerCase()))) {
        _userCommunities.add(CommunityModel(
          id: targetId,
          name: name ?? '',
          description: '',
          isJoined: true,
        ));
      }
      if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
        await fetchUserCommunities(_cachedUserId!, forceRefresh: true);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to join community: $e');
    }
  }

  /// Dynamically leaves a community and removes it from the profile's joined communities.
  Future<void> leaveCommunity(String communityId, {String? name}) async {
    try {
      final ProfileSetupService setupService = ProfileSetupService(_client);
      String targetId = communityId;
      if (targetId.isEmpty && name != null && name.isNotEmpty) {
        final CommunityModel match = _userCommunities.firstWhere(
          (CommunityModel c) => c.name.trim().toLowerCase() == name.trim().toLowerCase(),
          orElse: () => const CommunityModel(id: '', name: '', description: ''),
        );
        targetId = match.id;
      }
      if (targetId.isNotEmpty) {
        await setupService.leaveCommunity(targetId);
      }
      _userCommunities.removeWhere((CommunityModel c) =>
          (targetId.isNotEmpty && c.id == targetId) ||
          (name != null && c.name.trim().toLowerCase() == name.trim().toLowerCase()));
      if (_cachedUserId != null && _cachedUserId!.isNotEmpty) {
        await fetchUserCommunities(_cachedUserId!, forceRefresh: true);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to leave community: $e');
    }
  }

  /// Removes or updates a reel in liked reels when unliked
  void removeLikedReel(String id) {
    _likedReels.removeWhere((ReelItemModel r) => r.id == id);
    _likedPosts.removeWhere((PostItemModel p) => p.id == id);
    notifyListeners();
  }

  void updateLikedReel(String id, {required bool isLiked, required int likesCount, ReelItemModel? fallbackReel}) {
    // 1. Update _userReels
    final int urIndex = _userReels.indexWhere((ReelItemModel r) => r.id == id);
    if (urIndex != -1) {
      _userReels[urIndex] = _userReels[urIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
    }
    // 2. Update _userPosts
    final int upIndex = _userPosts.indexWhere((PostItemModel p) => p.id == id);
    if (upIndex != -1) {
      _userPosts[upIndex] = _userPosts[upIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
    }
    // 3. Update _likedReels
    final int rIndex = _likedReels.indexWhere((ReelItemModel r) => r.id == id);
    if (rIndex != -1) {
      if (!isLiked) {
        _likedReels.removeAt(rIndex);
      } else {
        _likedReels[rIndex] = _likedReels[rIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
      }
    } else if (isLiked) {
      if (urIndex != -1) {
        _likedReels.insert(0, _userReels[urIndex]);
      } else if (fallbackReel != null) {
        _likedReels.insert(0, fallbackReel.copyWith(isLiked: true, likesCount: likesCount));
      }
    }
    // 4. Update _likedPosts
    final int pIndex = _likedPosts.indexWhere((PostItemModel p) => p.id == id);
    if (pIndex != -1) {
      if (!isLiked) {
        _likedPosts.removeAt(pIndex);
      } else {
        _likedPosts[pIndex] = _likedPosts[pIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
      }
    }
    // 5. Update _savedPosts & _savedReels if present
    final int spIndex = _savedPosts.indexWhere((PostItemModel p) => p.id == id);
    if (spIndex != -1) {
      _savedPosts[spIndex] = _savedPosts[spIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
    }
    final int srIndex = _savedReels.indexWhere((ReelItemModel r) => r.id == id);
    if (srIndex != -1) {
      _savedReels[srIndex] = _savedReels[srIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
    }
    notifyListeners();
  }

  void updateLikedPost(String id, {required bool isLiked, required int likesCount, PostItemModel? fallbackPost}) {
    // 1. Update _userPosts
    final int upIndex = _userPosts.indexWhere((PostItemModel p) => p.id == id);
    if (upIndex != -1) {
      _userPosts[upIndex] = _userPosts[upIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
    }
    // 2. Update _userReels
    final int urIndex = _userReels.indexWhere((ReelItemModel r) => r.id == id);
    if (urIndex != -1) {
      _userReels[urIndex] = _userReels[urIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
    }
    // 3. Update _likedPosts
    final int pIndex = _likedPosts.indexWhere((PostItemModel p) => p.id == id);
    if (pIndex != -1) {
      if (!isLiked) {
        _likedPosts.removeAt(pIndex);
      } else {
        _likedPosts[pIndex] = _likedPosts[pIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
      }
    } else if (isLiked) {
      if (upIndex != -1) {
        _likedPosts.insert(0, _userPosts[upIndex]);
      } else if (fallbackPost != null) {
        _likedPosts.insert(0, fallbackPost.copyWith(isLiked: true, likesCount: likesCount));
      }
    }
    // 4. Update _likedReels
    final int rIndex = _likedReels.indexWhere((ReelItemModel r) => r.id == id);
    if (rIndex != -1) {
      if (!isLiked) {
        _likedReels.removeAt(rIndex);
      } else {
        _likedReels[rIndex] = _likedReels[rIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
      }
    }
    // 5. Update _savedPosts & _savedReels if present
    final int spIndex = _savedPosts.indexWhere((PostItemModel p) => p.id == id);
    if (spIndex != -1) {
      _savedPosts[spIndex] = _savedPosts[spIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
    }
    final int srIndex = _savedReels.indexWhere((ReelItemModel r) => r.id == id);
    if (srIndex != -1) {
      _savedReels[srIndex] = _savedReels[srIndex].copyWith(isLiked: isLiked, likesCount: likesCount);
    }
    notifyListeners();
  }

  void updateSavedPost(String id, {required bool isSaved, PostItemModel? fallbackPost}) {
    // 1. Update _userPosts
    final int upIndex = _userPosts.indexWhere((PostItemModel p) => p.id == id);
    if (upIndex != -1) {
      _userPosts[upIndex] = _userPosts[upIndex].copyWith(isSaved: isSaved);
    }
    // 2. Update _savedPosts
    final int spIndex = _savedPosts.indexWhere((PostItemModel p) => p.id == id);
    if (spIndex != -1) {
      if (!isSaved) {
        _savedPosts.removeAt(spIndex);
      } else {
        _savedPosts[spIndex] = _savedPosts[spIndex].copyWith(isSaved: isSaved);
      }
    } else if (isSaved) {
      if (upIndex != -1) {
        _savedPosts.insert(0, _userPosts[upIndex].copyWith(isSaved: true));
      } else if (fallbackPost != null) {
        _savedPosts.insert(0, fallbackPost.copyWith(isSaved: true));
      }
    }
    // 3. Update _likedPosts
    final int lpIndex = _likedPosts.indexWhere((PostItemModel p) => p.id == id);
    if (lpIndex != -1) {
      _likedPosts[lpIndex] = _likedPosts[lpIndex].copyWith(isSaved: isSaved);
    }
    notifyListeners();
  }

  void updateSavedReel(String id, {required bool isSaved, ReelItemModel? fallbackReel}) {
    // 1. Update _userReels
    final int urIndex = _userReels.indexWhere((ReelItemModel r) => r.id == id);
    if (urIndex != -1) {
      _userReels[urIndex] = _userReels[urIndex].copyWith(isSaved: isSaved);
    }
    // 2. Update _savedReels
    final int srIndex = _savedReels.indexWhere((ReelItemModel r) => r.id == id);
    if (srIndex != -1) {
      if (!isSaved) {
        _savedReels.removeAt(srIndex);
      } else {
        _savedReels[srIndex] = _savedReels[srIndex].copyWith(isSaved: isSaved);
      }
    } else if (isSaved) {
      if (urIndex != -1) {
        _savedReels.insert(0, _userReels[urIndex].copyWith(isSaved: true));
      } else if (fallbackReel != null) {
        _savedReels.insert(0, fallbackReel.copyWith(isSaved: true));
      }
    }
    // 3. Update _likedReels
    final int lrIndex = _likedReels.indexWhere((ReelItemModel r) => r.id == id);
    if (lrIndex != -1) {
      _likedReels[lrIndex] = _likedReels[lrIndex].copyWith(isSaved: isSaved);
    }
    notifyListeners();
  }

  void updatePostCommentCount(String id, int count) {
    final int upIndex = _userPosts.indexWhere((PostItemModel p) => p.id == id);
    if (upIndex != -1) {
      _userPosts[upIndex] = _userPosts[upIndex].copyWith(commentsCount: count);
    }
    final int urIndex = _userReels.indexWhere((ReelItemModel r) => r.id == id);
    if (urIndex != -1) {
      _userReels[urIndex] = _userReels[urIndex].copyWith(commentsCount: count);
    }
    final int spIndex = _savedPosts.indexWhere((PostItemModel p) => p.id == id);
    if (spIndex != -1) {
      _savedPosts[spIndex] = _savedPosts[spIndex].copyWith(commentsCount: count);
    }
    final int lpIndex = _likedPosts.indexWhere((PostItemModel p) => p.id == id);
    if (lpIndex != -1) {
      _likedPosts[lpIndex] = _likedPosts[lpIndex].copyWith(commentsCount: count);
    }
    notifyListeners();
  }

  Future<_ContentBatch> _processPosts(
    List<PostResponseModel> posts, {
    String? fallbackAuthorId,
    bool markSaved = false,
    bool markLiked = false,
  }) async {
    final List<PostItemModel> userPostsList = <PostItemModel>[];
    final List<ReelItemModel> userReelsList = <ReelItemModel>[];

    for (final PostResponseModel post in posts) {
      if (post.isDeleted) continue;

      final String type = post.type.toUpperCase().trim();
      final bool isVideo = type == 'VIDEO' ||
          type == 'REEL' ||
          (post.duration != null && post.duration!.isNotEmpty) ||
          post.mediaRefs.any((String r) {
            final String l = r.toLowerCase();
            return l.endsWith('.mp4') ||
                l.endsWith('.mov') ||
                l.endsWith('.webm') ||
                l.contains('/videos/');
          });

      String? mediaUrl;
      String? thumbnailUrl;

      if (isVideo) {
        if (post.mediaRefs.isNotEmpty) {
          final String firstRef = post.mediaRefs.first.trim();
          if (firstRef.startsWith('http://') || firstRef.startsWith('https://')) {
            // Already a full CDN/HTTP URL
            mediaUrl = firstRef;
            thumbnailUrl = post.postImageUrl?.isNotEmpty == true ? post.postImageUrl : firstRef;
          } else {
            // Raw UUID — build CDN HLS URL directly (no extra API call per video)
            final String clean = firstRef
                .replaceAll(RegExp(r'^/+'), '')
                .replaceAll(RegExp(r'^media/'), '');
            mediaUrl = '${AppConfig.cdnUrl}/videos/processed/$clean/master.m3u8';
            thumbnailUrl = (post.postImageUrl != null && post.postImageUrl!.isNotEmpty)
                ? post.postImageUrl
                : '${AppConfig.cdnUrl}/videos/processed/$clean/thumbnail.jpg';
          }
        } else if (post.postImageUrl != null && post.postImageUrl!.isNotEmpty) {
          mediaUrl = post.postImageUrl;
          thumbnailUrl = post.postImageUrl;
        }
      } else {
        // Photo or Text post: prefer post.postImageUrl, then resolve mediaRefs to image CDN URL
        if (post.postImageUrl != null && post.postImageUrl!.isNotEmpty) {
          mediaUrl = post.postImageUrl;
          thumbnailUrl = post.postImageUrl;
        } else if (post.mediaRefs.isNotEmpty) {
          final String firstRef = post.mediaRefs.first.trim();
          if (firstRef.startsWith('http://') ||
              firstRef.startsWith('https://') ||
              firstRef.startsWith('assets/')) {
            mediaUrl = firstRef;
            thumbnailUrl = firstRef;
          } else {
            final String clean = firstRef
                .replaceAll(RegExp(r'^/+'), '')
                .replaceAll(RegExp(r'^media/'), '');
            final String effectiveAuthor =
                post.authorId ?? fallbackAuthorId ?? _cachedUserId ?? '';
            if (effectiveAuthor.isNotEmpty) {
              mediaUrl =
                  '${AppConfig.cdnUrl}/images/original/$effectiveAuthor/$clean.jpg';
            } else {
              mediaUrl = '${AppConfig.cdnUrl}/images/original/$clean.jpg';
            }
            thumbnailUrl = mediaUrl;
          }
        }
      }

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

      if (isVideo) {
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
            viewsCount: post.viewsCount,
            isLiked: markLiked || post.isLiked || isPostLiked(post.id),
            isSaved: markSaved || post.isSaved || isPostSaved(post.id),
            allowComments: post.allowComments,
            allowDownloads: post.allowDownloads,
            hideLikes: post.hideLikes,
            tags: post.tags,
            communityId: post.communityId,
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
            authorDisplayName: post.authorDisplayName,
            username: formattedUsername,
            pronounsTime: (post.createdAt != null && post.createdAt!.isNotEmpty)
                ? _formatTime(post.createdAt)
                : 'just now',
            avatarAsset: avatar,
            content: post.body.isNotEmpty ? post.body : post.caption,
            likesCount: post.likesCount,
            commentsCount: post.commentsCount,
            viewsCount: post.viewsCount,
            isLiked: markLiked || post.isLiked || isPostLiked(post.id),
            isSaved: markSaved || post.isSaved || isPostSaved(post.id),
            allowComments: post.allowComments,
            allowDownloads: post.allowDownloads,
            hideLikes: post.hideLikes,
            postImageUrl: mediaUrl,
            postType: type,
            communityId: post.communityId,
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
    if (!force && _hasFetchedLiked && (_likedPosts.isNotEmpty || _likedReels.isNotEmpty)) {
      return;
    }
    // Only show full loading state if we haven't loaded items yet
    if (_likedPosts.isEmpty && _likedReels.isEmpty) {
      _isLoadingLiked = true;
      notifyListeners();
    }

    try {
      final PostContentService service = PostContentService(_client);
      final List<PostResponseModel> posts = await service.getLikedPosts();
      final _ContentBatch batch = await _processPosts(posts, markLiked: true);

      _likedPosts = batch.posts;
      _likedReels = batch.reels;
      _hasFetchedLiked = true;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Error fetching liked posts: $e');
    } finally {
      _isLoadingLiked = false;
      _hasFetchedLiked = true;
      notifyListeners();
    }
  }

  /// List User's Saved Posts. GET /users/me/saved
  Future<void> fetchSavedPosts({bool force = false}) async {
    if (!force && _hasFetchedSaved && (_savedPosts.isNotEmpty || _savedReels.isNotEmpty)) {
      return;
    }
    // Only show full loading state if we haven't loaded items yet
    if (_savedPosts.isEmpty && _savedReels.isEmpty) {
      _isLoadingSaved = true;
      notifyListeners();
    }

    try {
      final PostContentService service = PostContentService(_client);
      final List<PostResponseModel> posts = await service.getSavedPosts();
      final _ContentBatch batch = await _processPosts(posts, markSaved: true);

      _savedPosts = batch.posts;
      _savedReels = batch.reels;
      _hasFetchedSaved = true;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Error fetching saved posts: $e');
    } finally {
      _isLoadingSaved = false;
      _hasFetchedSaved = true;
      notifyListeners();
    }
  }

  /// Delete own Post or Video Post. DELETE /posts/:id
  Future<bool> deletePost(String postId) async {
    DeletedPostsRegistry.markDeleted(postId);
    _userPosts.removeWhere((PostItemModel p) => p.id == postId);
    _userReels.removeWhere((ReelItemModel r) => r.id == postId);
    _likedPosts.removeWhere((PostItemModel p) => p.id == postId);
    _likedReels.removeWhere((ReelItemModel r) => r.id == postId);
    _savedPosts.removeWhere((PostItemModel p) => p.id == postId);
    _savedReels.removeWhere((ReelItemModel r) => r.id == postId);
    if (_profile != null && (_profile!.postsCount ?? 0) > 0) {
      _profile = _profile!.copyWith(postsCount: _profile!.postsCount! - 1);
    }
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
      if (_profile != null) {
        AuthorProfileCache.set(
          _profile!.id,
          AuthorInfo(
            id: _profile!.id,
            username: _profile!.username ?? '',
            displayName: _profile!.displayName ?? '',
            avatarUrl: _profile!.avatarUrl,
            hideMyLikes: _profile!.hideMyLikes,
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

  bool isBlocked(String? key) {
    if (key == null || key.trim().isEmpty) return false;
    final String clean = key.trim().toLowerCase().replaceAll('@', '');
    return _blockedAccounts.any((BlockedAccountItem a) =>
        a.userId.toLowerCase() == clean ||
        a.username.toLowerCase().replaceAll('@', '') == clean);
  }

  bool isRestricted(String? key) {
    if (key == null || key.trim().isEmpty) return false;
    final String clean = key.trim().toLowerCase().replaceAll('@', '');
    return _restrictedAccounts.any((RestrictedAccountItem a) =>
        a.userId.toLowerCase() == clean ||
        a.username.toLowerCase().replaceAll('@', '') == clean);
  }

  bool isMuted(String? key) {
    if (key == null || key.trim().isEmpty) return false;
    final String clean = key.trim().toLowerCase().replaceAll('@', '');
    return _mutedAccounts.any((MutedAccountItem a) =>
        a.userId.toLowerCase() == clean ||
        a.username.toLowerCase().replaceAll('@', '') == clean);
  }

  // ── Blocked Accounts Management ───────────────────────────────────────────

  Future<void> loadBlockedAccounts({bool forceRefresh = false}) async {
    _isLoadingBlocked = true;
    notifyListeners();
    try {
      _blockedAccounts = await _relationshipService.getBlockedAccounts();
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to load blocked accounts: $e');
    } finally {
      _isLoadingBlocked = false;
      notifyListeners();
    }
  }

  Future<bool> blockUser(
    String userId, {
    String? username,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final bool success = await _relationshipService.blockUser(userId);
      if (success) {
        final String effectiveUsername = username ?? 'user';
        if (!_blockedAccounts.any((BlockedAccountItem a) => a.userId == userId)) {
          _blockedAccounts.insert(
            0,
            BlockedAccountItem(
              userId: userId,
              username: effectiveUsername,
              displayName: displayName ?? effectiveUsername,
              avatarUrl: avatarUrl,
              blockedAt: DateTime.now(),
            ),
          );
        }
        _followers.removeWhere((UserRelationItem r) => r.userId == userId);
        _following.removeWhere((UserRelationItem r) => r.userId == userId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to block user $userId: $e');
      return false;
    }
  }

  Future<bool> unblockUser(String userId) async {
    try {
      final bool success = await _relationshipService.unblockUser(userId);
      if (success) {
        _blockedAccounts.removeWhere((BlockedAccountItem a) => a.userId == userId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to unblock user $userId: $e');
      return false;
    }
  }

  // ── Restricted Accounts Management ─────────────────────────────────────────

  Future<void> loadRestrictedAccounts({bool forceRefresh = false}) async {
    _isLoadingRestricted = true;
    notifyListeners();
    try {
      _restrictedAccounts = await _relationshipService.getRestrictedAccounts();
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to load restricted accounts: $e');
    } finally {
      _isLoadingRestricted = false;
      notifyListeners();
    }
  }

  Future<bool> restrictUser(
    String userId, {
    String? username,
    String? displayName,
    String? avatarUrl,
  }) async {
    try {
      final bool success = await _relationshipService.restrictUser(userId);
      if (success) {
        final String effectiveUsername = username ?? 'user';
        if (!_restrictedAccounts.any((RestrictedAccountItem a) => a.userId == userId)) {
          _restrictedAccounts.insert(
            0,
            RestrictedAccountItem(
              userId: userId,
              username: effectiveUsername,
              displayName: displayName ?? effectiveUsername,
              avatarUrl: avatarUrl,
              restrictedAt: DateTime.now(),
            ),
          );
        }
        notifyListeners();
        // Immediately fetch all restricted accounts from API to stay in sync
        loadRestrictedAccounts(forceRefresh: true).ignore();
      }
      return success;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to restrict user $userId: $e');
      return false;
    }
  }

  Future<bool> unrestrictUser(String userId) async {
    try {
      final bool success = await _relationshipService.unrestrictUser(userId);
      if (success) {
        _restrictedAccounts.removeWhere((RestrictedAccountItem a) => a.userId == userId);
        notifyListeners();
        // Immediately fetch all restricted accounts from API to stay in sync
        loadRestrictedAccounts(forceRefresh: true).ignore();
      }
      return success;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to unrestrict user $userId: $e');
      return false;
    }
  }

  // ── Muted Accounts Management ─────────────────────────────────────────────

  Future<void> loadMutedAccounts({bool forceRefresh = false}) async {
    _isLoadingMuted = true;
    notifyListeners();
    try {
      _mutedAccounts = await _relationshipService.getMutedAccounts();
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to load muted accounts: $e');
    } finally {
      _isLoadingMuted = false;
      notifyListeners();
    }
  }

  Future<bool> muteUser(
    String userId, {
    String? username,
    String? displayName,
    String? avatarUrl,
    String scope = 'posts',
    int durationHours = 8,
  }) async {
    try {
      final bool success = await _relationshipService.muteUser(
        userId,
        scope: scope,
        durationHours: durationHours,
      );
      if (success) {
        final String effectiveUsername = username ?? 'user';
        if (!_mutedAccounts.any((MutedAccountItem a) => a.userId == userId)) {
          _mutedAccounts.insert(
            0,
            MutedAccountItem(
              userId: userId,
              username: effectiveUsername,
              displayName: displayName ?? effectiveUsername,
              avatarUrl: avatarUrl,
              mutedUntil: DateTime.now().add(Duration(hours: durationHours)),
              scope: scope,
            ),
          );
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to mute user $userId: $e');
      return false;
    }
  }

  Future<bool> unmuteUser(String userId) async {
    try {
      final bool success = await _relationshipService.unmuteUser(userId);
      if (success) {
        _mutedAccounts.removeWhere((MutedAccountItem a) => a.userId == userId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to unmute user $userId: $e');
      return false;
    }
  }

  // ── Follow Requests Management ────────────────────────────────────────────

  Future<void> loadFollowRequests({bool forceRefresh = false}) async {
    _isLoadingFollowRequests = true;
    notifyListeners();
    try {
      _followRequests = await _relationshipService.getFollowRequests();
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to load follow requests: $e');
    } finally {
      _isLoadingFollowRequests = false;
      notifyListeners();
    }
  }

  Future<bool> acceptFollowRequest(String requestId) async {
    try {
      final bool success = await _relationshipService.acceptFollowRequest(requestId);
      if (success) {
        _followRequests.removeWhere((FollowRequestItem r) => r.id == requestId || r.userId == requestId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to accept follow request $requestId: $e');
      return false;
    }
  }

  Future<bool> rejectFollowRequest(String requestId) async {
    try {
      final bool success = await _relationshipService.rejectFollowRequest(requestId);
      if (success) {
        _followRequests.removeWhere((FollowRequestItem r) => r.id == requestId || r.userId == requestId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to reject follow request $requestId: $e');
      return false;
    }
  }

  // ── Followers & Following Operations ──────────────────────────────────────

  Future<List<UserRelationItem>> loadFollowers([String? userId]) async {
    final String targetId = (userId != null && userId.isNotEmpty)
        ? userId
        : (_profile?.id ?? _cachedUserId ?? '');
    if (targetId.isEmpty) return _followers;

    _isLoadingRelations = true;
    notifyListeners();
    try {
      final List<UserRelationItem> items =
          await _relationshipService.getFollowers(targetId);
      _followers = items;
      if (_profile != null && (userId == null || userId == _profile!.id)) {
        final int current = _profile!.followersCount ?? 0;
        final int updated = items.length > current ? items.length : current;
        _profile = _profile!.copyWith(followersCount: updated);
      }
      return items;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to load followers for $targetId: $e');
      return <UserRelationItem>[];
    } finally {
      _isLoadingRelations = false;
      notifyListeners();
    }
  }

  Future<List<UserRelationItem>> loadFollowing([String? userId]) async {
    final String targetId = (userId != null && userId.isNotEmpty)
        ? userId
        : (_profile?.id ?? _cachedUserId ?? '');
    if (targetId.isEmpty) return _following;

    _isLoadingRelations = true;
    notifyListeners();
    try {
      final List<UserRelationItem> items =
          await _relationshipService.getFollowing(targetId);
      _following = items;
      for (final UserRelationItem u in items) {
        if (u.userId.trim().isNotEmpty) {
          _followingUserIds.add(u.userId.trim().toLowerCase());
        }
        if (u.username.trim().isNotEmpty) {
          _followingUsernames.add(u.username.replaceAll('@', '').trim().toLowerCase());
        }
      }
      UserRelationshipCache.sync(ids: _followingUserIds, usernames: _followingUsernames);
      if (_profile != null) {
        final int current = _profile!.followingCount ?? 0;
        final int updated = items.length > current ? items.length : current;
        _profile = _profile!.copyWith(followingCount: updated);
      }
      return items;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to load following for $userId: $e');
      return <UserRelationItem>[];
    } finally {
      _isLoadingRelations = false;
      notifyListeners();
    }
  }

  Future<bool> followUser(String userId, {String? username}) async {
    try {
      final bool success = await _relationshipService.followUser(userId);
      if (success) {
        if (userId.trim().isNotEmpty) {
          _followingUserIds.add(userId.trim().toLowerCase());
        }
        if (username != null && username.trim().isNotEmpty) {
          _followingUsernames.add(username.replaceAll('@', '').trim().toLowerCase());
        }
        UserRelationshipCache.add(userId: userId, username: username);
        final int idx = _following.indexWhere(
            (UserRelationItem u) => u.userId.toLowerCase() == userId.toLowerCase());
        if (idx != -1) {
          _following[idx] = _following[idx].copyWith(isFollowing: true);
        } else {
          _following.insert(
            0,
            UserRelationItem(
              userId: userId,
              username: username ?? 'user',
              displayName: username ?? 'User',
              isFollowing: true,
            ),
          );
        }
        final int fIdx = _followers.indexWhere(
            (UserRelationItem u) => u.userId.toLowerCase() == userId.toLowerCase());
        if (fIdx != -1) {
          _followers[fIdx] = _followers[fIdx].copyWith(isFollowing: true);
        }
        // If current profile is loaded, increment followingCount
        if (_profile != null) {
          final int cur = _profile!.followingCount ?? _following.length;
          _profile = _profile!.copyWith(
            followingCount: cur + 1,
          );
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to follow user $userId: $e');
      rethrow;
    }
  }

  Future<bool> unfollowUser(String userId, {String? username}) async {
    try {
      final bool success = await _relationshipService.unfollowUser(userId);
      if (success) {
        if (userId.trim().isNotEmpty) {
          _followingUserIds.remove(userId.trim().toLowerCase());
        }
        if (username != null && username.trim().isNotEmpty) {
          _followingUsernames.remove(username.replaceAll('@', '').trim().toLowerCase());
        }
        UserRelationshipCache.remove(userId: userId, username: username);
        _following.removeWhere(
            (UserRelationItem u) => u.userId.toLowerCase() == userId.toLowerCase());
        final int fIdx = _followers.indexWhere(
            (UserRelationItem u) => u.userId.toLowerCase() == userId.toLowerCase());
        if (fIdx != -1) {
          _followers[fIdx] = _followers[fIdx].copyWith(isFollowing: false);
        }
        if (_profile != null) {
          final int cur = _profile!.followingCount ?? _following.length + 1;
          final int count = cur - 1;
          _profile = _profile!.copyWith(
            followingCount: count > 0 ? count : 0,
          );
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to unfollow user $userId: $e');
      rethrow;
    }
  }

  Future<bool> removeFollower(String userId) async {
    try {
      final bool success = await _relationshipService.removeFollower(userId);
      if (success) {
        _followers.removeWhere((UserRelationItem u) => u.userId == userId);
        if (_profile != null) {
          final int cur = _profile!.followersCount ?? _followers.length + 1;
          final int count = cur - 1;
          _profile = _profile!.copyWith(
            followersCount: count > 0 ? count : 0,
          );
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('⚠️ [ProfileProvider] Failed to remove follower $userId: $e');
      rethrow;
    }
  }
}

class _ContentBatch {
  const _ContentBatch({required this.posts, required this.reels});
  final List<PostItemModel> posts;
  final List<ReelItemModel> reels;
}

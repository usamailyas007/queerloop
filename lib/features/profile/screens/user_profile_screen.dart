import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/cache/user_relationship_cache.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../auth/auth_provider.dart';
import '../../create_post/models/create_post_models.dart';
import '../../discover/models/discover_models.dart';
import '../../discover/services/discover_service.dart';
import '../../messages/models/message_models.dart';
import '../../messages/provider/messages_provider.dart';
import '../../messages/screens/chat_screen.dart';
import '../../profile_setup/models/community_model.dart';
import '../../profile_setup/models/profile_models.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../home/models/post_item_model.dart';
import '../../home/models/reel_item_model.dart';
import '../../home/provider/home_feed_provider.dart';
import '../../home/services/reel_video_preloader.dart';
import '../../home/screens/single_post_view_screen.dart';
import '../../home/widgets/comments_bottom_sheet.dart';
import '../../home/widgets/post_feed_card.dart';
import '../models/user_relationship_models.dart';
import '../provider/profile_provider.dart';
import '../services/user_relationship_service.dart';
import '../widgets/profile_feed_tabs_widget.dart';
import '../widgets/profile_header_stats_widget.dart';
import '../widgets/profile_media_grid_widget.dart';
import '../widgets/user_profile_options_bottom_sheet.dart';
import 'followers_following_screen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    this.userId,
    this.username = 'rowankeeps',
    this.name = 'Rowan',
    this.avatarAsset = AppImages.user1,
    this.isPrivate = false,
    super.key,
  });

  final String? userId;
  final String username;
  final String name;
  final String avatarAsset;
  final bool isPrivate;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _selectedTabIndex = 0; // Default: Posts
  bool _isRequested = false; // Default: Not requested (shows Follow initially)
  bool _isFollowing = false; // Default: Not following (shows Follow initially)
  bool _isLoading = false;
  bool _isStartingChat = false;
  bool _isFollowActionBusy = false;
  String? _resolvedUserId;
  UserProfile? _profile;
  List<PostResponseModel> _authorPosts = <PostResponseModel>[];
  List<PostResponseModel> _authorTextPosts = <PostResponseModel>[];
  List<ReelItemModel> _authorReels = <ReelItemModel>[];
  Map<String, String> _postImageUrls = <String, String>{};
  List<CommunityModel> _userCommunities = <CommunityModel>[];
  int? _followersCount;
  int? _followingCount;

  String? get _effectiveUserId {
    if (_profile?.id != null && _profile!.id.trim().isNotEmpty) {
      return _profile!.id.trim();
    }
    if (_resolvedUserId != null && _resolvedUserId!.trim().isNotEmpty) {
      return _resolvedUserId!.trim();
    }
    if (widget.userId != null && widget.userId!.trim().isNotEmpty) {
      return widget.userId!.trim();
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    ReelVideoPreloader.instance.setFeedVisible(false);
    ReelVideoPreloader.instance.pauseAll();
    ReelVideoPreloader.instance.muteAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReelVideoPreloader.instance.pauseAll();
      if (mounted) {
        context.read<MessagesProvider>().loadBlockedUsers();
        context.read<ProfileProvider>().loadBlockedAccounts();
      }
    });
    if (widget.userId != null && widget.userId!.trim().isNotEmpty) {
      _fetchUserProfile(widget.userId!.trim());
    } else if (widget.username.trim().isNotEmpty) {
      _resolveUserByUsername(widget.username);
    }
  }

  bool _isReelPost(PostResponseModel post) {
    final String type = post.type.toUpperCase().trim();
    if (type == 'VIDEO' || type == 'REEL') return true;
    for (final String ref in post.mediaRefs) {
      final String lower = ref.toLowerCase();
      if (lower.endsWith('.mp4') ||
          lower.endsWith('.mov') ||
          lower.endsWith('.webm') ||
          lower.contains('video')) {
        return true;
      }
    }
    return false;
  }

  Future<List<ReelItemModel>> _convertPostsToReels(
    List<PostResponseModel> reelPosts, {
    required ApiClient client,
    required String fallbackAvatar,
    required String fallbackUsername,
  }) async {
    final List<ReelItemModel> reels = <ReelItemModel>[];
    for (final PostResponseModel post in reelPosts) {
      String? videoUrl;
      String? thumbUrl;

      if (post.mediaRefs.isNotEmpty) {
        final String firstRef = post.mediaRefs.first.trim();
        if (firstRef.startsWith('http://') || firstRef.startsWith('https://')) {
          // Already a full CDN/HTTP URL
          videoUrl = firstRef;
          thumbUrl = post.postImageUrl?.isNotEmpty == true ? post.postImageUrl : firstRef;
        } else {
          // Raw UUID from upload — build HLS URL directly (same as For You feed, no extra API call)
          final String clean = firstRef
              .replaceAll(RegExp(r'^/+'), '')
              .replaceAll(RegExp(r'^media/'), '');
          videoUrl = '${AppConfig.cdnUrl}/videos/processed/$clean/master.m3u8';
          // Use backend-supplied postImageUrl as thumbnail (already verified CDN URL)
          thumbUrl = (post.postImageUrl != null && post.postImageUrl!.isNotEmpty)
              ? post.postImageUrl
              : '${AppConfig.cdnUrl}/videos/processed/$clean/thumbnail.jpg';
        }
      }

      final String authorUsername =
          post.authorName ?? _profile?.username ?? fallbackUsername;
      final String formattedUsername = authorUsername.startsWith('@')
          ? authorUsername
          : '@$authorUsername';
      final String avatar = (post.authorAvatar != null &&
              post.authorAvatar!.isNotEmpty)
          ? post.authorAvatar!
          : ((_profile?.avatarUrl != null && _profile!.avatarUrl!.isNotEmpty)
              ? _profile!.avatarUrl!
              : fallbackAvatar);

      reels.add(
        ReelItemModel(
          id: post.id,
          authorId: post.authorId ?? _effectiveUserId,
          authorDisplayName: post.authorDisplayName ?? _profile?.displayName,
          username: formattedUsername,
          pronounsTime: (post.createdAt != null && post.createdAt!.isNotEmpty)
              ? post.createdAt!
              : 'just now',
          avatarAsset: avatar,
          videoAsset: '',
          videoUrl: videoUrl,
          thumbnailUrl: thumbUrl,
          caption: post.body.isNotEmpty ? post.body : post.caption,
          likesCount: post.likesCount,
          commentsCount: post.commentsCount,
          viewsCount: post.viewsCount,
          isLiked: post.isLiked,
          isSaved: post.isSaved,
          allowComments: post.allowComments,
          allowDownloads: post.allowDownloads,
          hideLikes: _profile?.hideMyLikes ?? false,
          tags: post.tags,
          communityId: post.communityId,
          durationText: (post.duration != null && post.duration!.isNotEmpty)
              ? post.duration!
              : '0:30',
        ),
      );
    }
    return reels;
  }

  Future<void> _resolveUserByUsername(String rawUsername) async {
    final String cleanUsername = rawUsername.replaceAll('@', '').trim();
    if (cleanUsername.isEmpty) return;
    try {
      final DiscoverService discover =
          DiscoverService(context.read<ApiClient>());
      final MultiTabSearchResults results = await discover.search(
        query: cleanUsername,
        tab: 'people',
      );
      if (results.people.isNotEmpty) {
        final DiscoverPerson person = results.people.firstWhere(
          (DiscoverPerson p) =>
              p.username.replaceAll('@', '').toLowerCase() ==
              cleanUsername.toLowerCase(),
          orElse: () => results.people.first,
        );
        if (person.id != null && person.id!.trim().isNotEmpty && mounted) {
          setState(() {
            _resolvedUserId = person.id!.trim();
          });
          _fetchUserProfile(person.id!.trim());
        }
      }
    } catch (e) {
      debugPrint('⚠️ [UserProfile] Could not resolve username to id: $e');
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    setState(() {
      _isLoading = true;
    });

    final ApiClient client = context.read<ApiClient>();
    final AuthProvider auth = context.read<AuthProvider>();
    final ProfileProvider profileProvider = context.read<ProfileProvider>();
    final UserRelationshipService relService = UserRelationshipService(client);

    // 1. Fetch user profile
    UserProfile? loadedProfile;
    try {
      debugPrint('🚀 [UserProfile] Calling GET ${ApiEndpoints.user(userId)}');
      final dynamic data = await client.get(ApiEndpoints.user(userId));
      debugPrint('📥 [UserProfile] User profile response: $data');

      if (data is Map<String, dynamic>) {
        loadedProfile = UserProfile.fromJson(data);
        AuthorProfileCache.set(
          loadedProfile.id,
          AuthorInfo(
            id: loadedProfile.id,
            username: loadedProfile.username ?? '',
            displayName: loadedProfile.displayName ?? '',
            avatarUrl: loadedProfile.avatarUrl,
            hideMyLikes: loadedProfile.hideMyLikes,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ [UserProfile] Failed to fetch user profile: $e');
      if (widget.username.trim().isNotEmpty && _resolvedUserId == null) {
        _resolveUserByUsername(widget.username);
      }
    }

    // 2. Fetch followers & following in parallel for accurate relationship data
    List<UserRelationItem> followersList = <UserRelationItem>[];
    List<UserRelationItem> followingList = <UserRelationItem>[];
    try {
      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        relService.getFollowers(userId),
        relService.getFollowing(userId),
      ]);
      followersList = results[0] as List<UserRelationItem>;
      followingList = results[1] as List<UserRelationItem>;
    } catch (e) {
      debugPrint('⚠️ [UserProfile] Could not fetch followers/following: $e');
    }

    // 3. Check privacy before fetching author posts
    final String? curUserId = auth.userId ?? profileProvider.profile?.id;
    final String? curUsername = profileProvider.profile?.username ?? auth.user?.displayName;
    final bool isGuest = auth.isGuest;

    final bool isOwnProfile = (curUserId != null &&
            curUserId.isNotEmpty &&
            userId == curUserId) ||
        (curUsername != null &&
            curUsername.isNotEmpty &&
            widget.username.replaceAll('@', '').toLowerCase() ==
                curUsername.replaceAll('@', '').toLowerCase());

    final bool isFollowedInCache = profileProvider.isFollowingUser(
      userId: loadedProfile?.id ?? userId,
      username: loadedProfile?.username ?? widget.username,
    );

    final bool amIFollower = curUserId != null &&
        curUserId.isNotEmpty &&
        followersList.any((UserRelationItem f) => f.userId == curUserId);

    final bool isCurrentlyFollowing = isFollowedInCache ||
        amIFollower ||
        loadedProfile?.isFollowing == true ||
        loadedProfile?.relationship == 'following';

    final bool isPrivateAccount = (loadedProfile?.isPrivate ?? false) ||
        widget.isPrivate ||
        widget.username.contains('kit.lumen');

    final bool shouldHideContent = isPrivateAccount && !isOwnProfile && !isCurrentlyFollowing;

    // 3. Fetch author posts ONLY if user is not private (or viewer is following / is own profile)
    List<PostResponseModel> allPosts = <PostResponseModel>[];
    if (!shouldHideContent) {
      try {
        debugPrint('🚀 [UserProfile] Calling GET ${ApiEndpoints.postsByAuthor(userId)}');
        final dynamic postsData =
            await client.get(ApiEndpoints.postsByAuthor(userId));
        List<dynamic> rawList = <dynamic>[];
        if (postsData is List) {
          rawList = postsData;
        } else if (postsData is Map<String, dynamic>) {
          if (postsData['data'] is List) {
            rawList = postsData['data'] as List<dynamic>;
          } else if (postsData['posts'] is List) {
            rawList = postsData['posts'] as List<dynamic>;
          } else if (postsData['items'] is List) {
            rawList = postsData['items'] as List<dynamic>;
          } else if (postsData['results'] is List) {
            rawList = postsData['results'] as List<dynamic>;
          }
        }
        allPosts = rawList
            .whereType<Map<String, dynamic>>()
            .map(PostResponseModel.fromJson)
            .where((PostResponseModel p) => !p.isDeleted)
            .toList();
      } catch (e) {
        debugPrint('⚠️ [UserProfile] Could not fetch author posts: $e');
      }

      allPosts = allPosts.where((PostResponseModel p) {
        return PostVisibilityFilter.canViewPost(
          visibility: p.visibility,
          authorId: p.authorId ?? userId,
          authorUsername: p.authorName ?? widget.username,
          currentUserId: curUserId,
          currentUsername: curUsername,
          isGuest: isGuest,
          isFollowing: isCurrentlyFollowing,
        );
      }).toList();
    } else {
      debugPrint('🔒 [UserProfile] User $userId is private and not followed; skipping post fetch.');
    }

    // Separate posts into text/photo posts vs video reels
    final List<PostResponseModel> textPosts =
        allPosts.where((PostResponseModel p) => !_isReelPost(p)).toList();
    final List<PostResponseModel> reelPosts =
        allPosts.where((PostResponseModel p) => _isReelPost(p)).toList();

    // Convert reel posts to ReelItemModel
    final List<ReelItemModel> convertedReels = await _convertPostsToReels(
      reelPosts,
      client: client,
      fallbackAvatar: widget.avatarAsset,
      fallbackUsername: widget.username,
    );

    // Resolve post image URLs for text/photo posts
    final Map<String, String> postImages = <String, String>{};
    for (final PostResponseModel post in textPosts) {
      if (post.postImageUrl != null && post.postImageUrl!.isNotEmpty) {
        postImages[post.id] = post.postImageUrl!;
      } else if (post.mediaRefs.isNotEmpty) {
        final String firstRef = post.mediaRefs.first.trim();
        if (firstRef.startsWith('http://') ||
            firstRef.startsWith('https://') ||
            firstRef.startsWith('assets/')) {
          postImages[post.id] = firstRef;
        } else {
          final String clean = firstRef
              .replaceAll(RegExp(r'^/+'), '')
              .replaceAll(RegExp(r'^media/'), '');
          final String author = post.authorId ?? _effectiveUserId ?? userId;
          if (author.isNotEmpty) {
            postImages[post.id] =
                '${AppConfig.cdnUrl}/images/original/$author/$clean.jpg';
          } else {
            postImages[post.id] =
                '${AppConfig.cdnUrl}/images/original/$clean.jpg';
          }
        }
      }
    }

    // 4. Fetch user communities
    List<CommunityModel> comms = <CommunityModel>[];
    try {
      dynamic commData;
      try {
        commData = await client.get(ApiEndpoints.userCommunities(userId));
      } catch (e) {
        commData = await client.get(ApiEndpoints.userCommunitiesAlt(userId));
      }
      List<dynamic> rawCommList = <dynamic>[];
      if (commData is List) {
        rawCommList = commData;
      } else if (commData is Map<String, dynamic>) {
        if (commData['data'] is List) {
          rawCommList = commData['data'] as List<dynamic>;
        } else if (commData['communities'] is List) {
          rawCommList = commData['communities'] as List<dynamic>;
        }
      }
      for (final dynamic item in rawCommList) {
        if (item is Map<String, dynamic>) {
          final Map<String, dynamic> m =
              (item['community'] is Map<String, dynamic>)
                  ? item['community'] as Map<String, dynamic>
                  : item;
          comms.add(CommunityModel.fromJson(m).copyWith(isJoined: true));
        } else if (item is String) {
          comms.add(CommunityModel(id: item, name: item, isJoined: true));
        }
      }
    } catch (e) {
      debugPrint('⚠️ [UserProfile] Could not fetch user communities: $e');
    }

    if (!mounted) return;

    final int calculatedFollowers = (loadedProfile?.followersCount != null &&
            loadedProfile!.followersCount! > followersList.length)
        ? loadedProfile.followersCount!
        : followersList.length;

    final int calculatedFollowing = (loadedProfile?.followingCount != null &&
            loadedProfile!.followingCount! > followingList.length)
        ? loadedProfile.followingCount!
        : followingList.length;

    setState(() {
      if (loadedProfile != null) {
        _profile = loadedProfile;
      }
      _authorPosts = allPosts;
      _authorTextPosts = textPosts;
      _authorReels = convertedReels;
      _postImageUrls = postImages;
      _userCommunities = comms;
      _followersCount = calculatedFollowers;
      _followingCount = calculatedFollowing;
      _isFollowing = isCurrentlyFollowing;
      _isRequested = loadedProfile?.isPending == true ||
          loadedProfile?.relationship == 'pending';
      _isLoading = false;
    });
  }

  Future<void> _handleFollowToggle({required bool isPrivateAccount}) async {
    final String? targetId = _effectiveUserId;
    if (targetId == null || targetId.isEmpty || _isFollowActionBusy) return;

    final String? myId = context.read<AuthProvider>().userId;
    if (myId != null && myId.isNotEmpty && targetId == myId) {
      debugPrint('⚠️ [UserProfileScreen] Prevented attempt to follow yourself.');
      return;
    }

    final ProfileProvider profileProvider =
        context.read<ProfileProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    setState(() => _isFollowActionBusy = true);

    try {
      if (_isFollowing || _isRequested) {
        await profileProvider.unfollowUser(targetId, username: _profile?.username ?? widget.username);
        if (mounted) {
          setState(() {
            _isFollowing = false;
            _isRequested = false;
            if (_followersCount != null && _followersCount! > 0) {
              _followersCount = _followersCount! - 1;
            }
            if (_profile != null && _profile!.followersCount != null) {
              final int c = (_profile!.followersCount ?? 1) - 1;
              _profile = _profile!.copyWith(followersCount: c > 0 ? c : 0);
            }
          });
          AppSnackBar.show(
            context,
            messenger: messenger,
            title: 'Unfollowed',
            subtitle:
                'You are no longer following @${_profile?.username ?? widget.username}',
          );
        }
      } else {
        await profileProvider.followUser(targetId, username: _profile?.username ?? widget.username);
        if (mounted) {
          setState(() {
            if (isPrivateAccount) {
              _isRequested = true;
              _isFollowing = false;
            } else {
              _isFollowing = true;
              _isRequested = false;
              _followersCount = (_followersCount ?? 0) + 1;
              if (_profile != null) {
                final int c = (_profile!.followersCount ?? 0) + 1;
                _profile = _profile!.copyWith(followersCount: c);
              }
            }
          });
          AppSnackBar.showSuccess(
            context,
            messenger: messenger,
            title: isPrivateAccount ? 'Request sent' : 'Following',
            subtitle: isPrivateAccount
                ? 'Follow request sent to @${_profile?.username ?? widget.username}'
                : 'You are now following @${_profile?.username ?? widget.username}',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ [UserProfileScreen] Follow error: $e');
    } finally {
      if (mounted) setState(() => _isFollowActionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPrivateAccount =
        _profile?.isPrivate ?? (widget.isPrivate || widget.username.contains('kit.lumen'));
    final String currentUsername = _profile?.username ?? widget.username;
    final String currentName = _profile?.displayName ?? widget.name;
    final String currentAvatar = _profile?.avatarUrl ?? widget.avatarAsset;
    final String currentBio = _profile?.bio ??
        (isPrivateAccount
            ? 'Private account.'
            : (widget.userId != null ? '' : 'Documenting recovery, one honest video at a time.'));
    final String currentPronouns = _profile?.formattedPronouns ??
        (isPrivateAccount ? 'he / him' : '');

    final AuthProvider auth = context.watch<AuthProvider>();
    final ProfileProvider profile = context.watch<ProfileProvider>();
    final MessagesProvider msgProvider = context.watch<MessagesProvider>();
    final String? myId = auth.userId;
    final String? myName = auth.user?.displayName;
    final bool isOwnProfile = (myId != null &&
            myId.isNotEmpty &&
            _effectiveUserId == myId) ||
        (myName != null &&
            myName.isNotEmpty &&
            widget.username.replaceAll('@', '').toLowerCase() ==
                myName.replaceAll('@', '').toLowerCase());

    final bool isUserBlocked = msgProvider.isBlocked(_effectiveUserId) ||
        msgProvider.isBlocked(currentUsername) ||
        profile.blockedAccounts.any((BlockedAccountItem b) =>
            (b.userId.isNotEmpty && b.userId == _effectiveUserId) ||
            b.username.toLowerCase() ==
                currentUsername.replaceAll('@', '').toLowerCase());

    final bool shouldShowPrivateScreen =
        isPrivateAccount && !isOwnProfile && !_isFollowing;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar (Back chevron < + Username + 3-dots Menu) ────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.12)
                              : context.themeBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: context.themeIcon,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            currentUsername.startsWith('@')
                                ? currentUsername
                                : '@$currentUsername',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: context.themeTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          if (isPrivateAccount) ...<Widget>[
                            const SizedBox(width: 6),
                            SvgPicture.asset(
                              AppIcons.password,
                              width: 14,
                              height: 14,
                              colorFilter: ColorFilter.mode(
                                context.themeIconMuted,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 3-dots Options Menu -> Opens UserProfileOptionsBottomSheet
                  GestureDetector(
                    onTap: () {
                      UserProfileOptionsBottomSheet.show(
                        context,
                        username: currentUsername,
                        userId: _effectiveUserId,
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.12)
                              : context.themeBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: context.themeIcon,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Profile Body ─────────────────────────────────────
            Expanded(
              child: _isLoading && _profile == null
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gradientPink,
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                      children: <Widget>[
                        // Profile Header & Stats Widget
                        ProfileHeaderStatsWidget(
                          avatarAsset: currentAvatar,
                          name: currentName,
                          bio: currentBio,
                          postsCount: '${_profile?.postsCount != null && _profile!.postsCount! > 0 ? _profile!.postsCount : _authorPosts.length}',
                          followersCount: '${_followersCount ?? _profile?.followersCount ?? 0}',
                          followingCount: '${_followingCount ?? _profile?.followingCount ?? 0}',
                          onFollowersTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => FollowersFollowingScreen(
                                  initialTabIndex: 0,
                                  userId: _effectiveUserId,
                                  username: currentUsername,
                                ),
                              ),
                            );
                          },
                          onFollowingTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => FollowersFollowingScreen(
                                  initialTabIndex: 1,
                                  userId: _effectiveUserId,
                                  username: currentUsername,
                                ),
                              ),
                            );
                          },
                          pronounsPill: currentPronouns,
                          pronounsList: _profile?.pronouns ??
                              (isPrivateAccount
                                  ? const <String>[]
                                  : const <String>[]),
                          identityList: const <String>[],
                          interestsList:
                              _profile?.interests ?? const <String>[],
                          communitiesList: _userCommunities,
                    actionButtons: isOwnProfile
                        ? Row(
                            children: <Widget>[
                              Expanded(
                                child: AppOutlineButton(
                                  text: 'Edit Profile',
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                ),
                              ),
                            ],
                          )
                        : (isUserBlocked
                            ? Row(
                                children: <Widget>[
                                  Expanded(
                                    child: AppOutlineButton(
                                      text: 'Unblock',
                                      onPressed: () async {
                                        final String? tId = _effectiveUserId;
                                        if (tId != null && tId.isNotEmpty) {
                                          await profile.unblockUser(tId);
                                          await msgProvider.unblockUser(tId, username: currentUsername);
                                        } else {
                                          await msgProvider.unblockUser(currentUsername, username: currentUsername);
                                        }
                                        if (!mounted) return;
                                        setState(() {});
                                        AppSnackBar.showSuccess(
                                          this.context,
                                          title: 'Unblocked',
                                          subtitle:
                                              '@${currentUsername.replaceAll('@', '')} has been unblocked.',
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: <Widget>[
                        Expanded(
                          child: _isFollowing
                              ? AppOutlineButton(
                                  text: _isFollowActionBusy ? '...' : 'Following',
                                  onPressed: () => _handleFollowToggle(
                                    isPrivateAccount: isPrivateAccount,
                                  ),
                                )
                              : (_isRequested
                                  ? GestureDetector(
                                      onTap: () => _handleFollowToggle(
                                        isPrivateAccount: isPrivateAccount,
                                      ),
                                      child: Container(
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: context.themeCardBackground,
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.card),
                                          border: Border.all(
                                            color: AppColors.gradientCyan,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            const Icon(
                                              Icons.access_time_rounded,
                                              color: AppColors.gradientCyan,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Requested',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                color: AppColors.gradientCyan,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : AppGradientButton(
                                      text: _isFollowActionBusy ? '...' : 'Follow',
                                      onPressed: () => _handleFollowToggle(
                                        isPrivateAccount: isPrivateAccount,
                                      ),
                                    )),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppOutlineButton(
                            text: _isStartingChat ? 'Loading...' : 'Message',
                            onPressed: _isStartingChat
                                ? () {}
                                : () async {
                                    final ScaffoldMessengerState messenger =
                                        ScaffoldMessenger.of(context);
                                    final NavigatorState navigator =
                                        Navigator.of(context);
                                    final MessagesProvider provider =
                                        context.read<MessagesProvider>();
                                    final ApiClient apiClient =
                                        context.read<ApiClient>();
                                    final AuthProvider auth =
                                        context.read<AuthProvider>();

                                    setState(() {
                                      _isStartingChat = true;
                                    });

                                    try {
                                      String? targetId = _effectiveUserId;

                                      // If targetId is still not resolved, attempt resolution now
                                      if (targetId == null || targetId.isEmpty) {
                                        final String cleanUsername = widget
                                            .username
                                            .replaceAll('@', '')
                                            .trim();
                                        if (cleanUsername.isNotEmpty) {
                                          try {
                                            final DiscoverService discover =
                                                DiscoverService(apiClient);
                                            final MultiTabSearchResults results =
                                                await discover.search(
                                              query: cleanUsername,
                                              tab: 'people',
                                            );
                                            if (results.people.isNotEmpty) {
                                              final DiscoverPerson person =
                                                  results.people.firstWhere(
                                                (DiscoverPerson p) =>
                                                    p.username
                                                        .replaceAll('@', '')
                                                        .toLowerCase() ==
                                                    cleanUsername.toLowerCase(),
                                                orElse: () =>
                                                    results.people.first,
                                              );
                                              targetId = person.id;
                                              if (mounted && targetId != null) {
                                                setState(() {
                                                  _resolvedUserId = targetId;
                                                });
                                              }
                                            }
                                          } catch (_) {}
                                        }
                                      }

                                      if (targetId == null || targetId.trim().isEmpty) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Cannot start conversation: User ID not found.',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }

                                      final String cleanTargetId =
                                          targetId.trim();
                                      final String? myId = auth.userId;
                                      if (myId != null &&
                                          cleanTargetId == myId) {
                                        messenger.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'You cannot start a conversation with yourself.',
                                            ),
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                        return;
                                      }

                                      ConversationModel? conv;
                                      String? errorText;
                                      try {
                                        conv = await provider
                                            .startConversation(cleanTargetId);
                                      } on ApiException catch (e) {
                                        errorText = e.message.isNotEmpty
                                            ? e.message
                                            : 'This user is not accepting messages from you.';
                                      } catch (e) {
                                        errorText =
                                            'Unable to start conversation right now.';
                                      }

                                      if (conv == null) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              errorText ??
                                                  'This user is not accepting messages from you.',
                                            ),
                                            duration:
                                                const Duration(seconds: 3),
                                            backgroundColor:
                                                Colors.redAccent.shade700,
                                          ),
                                        );
                                        return;
                                      }

                                      final String currentUsername = (_profile?.username != null &&
                                              _profile!.username!.trim().isNotEmpty)
                                          ? _profile!.username!.trim()
                                          : widget.username.replaceAll('@', '').trim();
                                      final String currentName = (_profile?.displayName != null &&
                                              _profile!.displayName!.trim().isNotEmpty)
                                          ? _profile!.displayName!.trim()
                                          : widget.name.trim();
                                      final String currentAvatar = (_profile?.avatarUrl != null &&
                                              _profile!.avatarUrl!.trim().isNotEmpty)
                                          ? _profile!.avatarUrl!.trim()
                                          : widget.avatarAsset.trim();

                                      final ConversationModel enrichedConv = conv.copyWith(
                                        username: currentUsername.isNotEmpty && currentUsername != 'User'
                                            ? currentUsername
                                            : conv.username,
                                        displayName: currentName.isNotEmpty ? currentName : conv.displayName,
                                        avatarUrl: currentAvatar.startsWith('http') ? currentAvatar : conv.avatarUrl,
                                        avatarAsset: currentAvatar.isNotEmpty ? currentAvatar : conv.avatarAsset,
                                        participantId: cleanTargetId,
                                      );

                                      provider.updateConversation(enrichedConv);

                                      navigator.push<void>(
                                        MaterialPageRoute<void>(
                                          builder: (_) => ChatScreen(
                                            conversation: enrichedConv,
                                          ),
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          _isStartingChat = false;
                                        });
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    )),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── If Private Account & Not Following -> Show Centered Private Placeholder ──
                  if (shouldShowPrivateScreen) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: context.themeCardBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: context.themeBorder,
                              ),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                AppIcons.password,
                                width: 26,
                                height: 26,
                                colorFilter: ColorFilter.mode(
                                  context.themeIcon,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'This account is private',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: context.themeTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              "$currentName approves followers one by one. You'll get a notification if your request is accepted.",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.themeTextSecondary,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ]

                  // ── If Public Account OR Already Following -> Show Feed Tabs & Media Grid ───────
                  else ...<Widget>[
                    ProfileFeedTabsWidget(
                      selectedIndex: _selectedTabIndex,
                      isOwnProfile: isOwnProfile,
                      onTabSelected: (int index) {
                        setState(() => _selectedTabIndex = index);
                        if (index == 2) {
                          context.read<ProfileProvider>().fetchSavedPosts();
                        } else if (index == 3) {
                          context.read<ProfileProvider>().fetchLikedPosts();
                        }
                      },
                    ),

                    // Tab 0: Posts Feed Cards (Photos and Text only)
                    if (_selectedTabIndex == 0) ...<Widget>[
                      if (_authorTextPosts.isNotEmpty) ...<Widget>[
                        for (final PostResponseModel post in _authorTextPosts) ...<Widget>[
                          Builder(
                            builder: (BuildContext ctx) {
                              final PostItemModel postItem = PostItemModel(
                                id: post.id,
                                authorId: post.authorId,
                                authorDisplayName: (post.authorDisplayName != null &&
                                        post.authorDisplayName!.isNotEmpty)
                                    ? post.authorDisplayName!
                                    : currentName,
                                username: (post.authorName != null &&
                                        post.authorName!.isNotEmpty)
                                    ? (post.authorName!.startsWith('@')
                                        ? post.authorName!
                                        : '@${post.authorName}')
                                    : (currentUsername.startsWith('@')
                                        ? currentUsername
                                        : '@$currentUsername'),
                                pronounsTime: post.createdAt ?? 'recently',
                                avatarAsset: (post.authorAvatar != null &&
                                        post.authorAvatar!.isNotEmpty)
                                    ? post.authorAvatar!
                                    : currentAvatar,
                                content: post.body,
                                likesCount: post.likesCount,
                                commentsCount: post.commentsCount,
                                postImageUrl: _postImageUrls[post.id] ??
                                    (post.postImageUrl != null && post.postImageUrl!.isNotEmpty
                                        ? post.postImageUrl
                                        : (post.mediaRefs.isNotEmpty
                                            ? (post.mediaRefs.first.startsWith('http') || post.mediaRefs.first.startsWith('assets/')
                                                ? post.mediaRefs.first
                                                : '${AppConfig.cdnUrl}/images/original/${post.authorId ?? _effectiveUserId ?? ''}/${post.mediaRefs.first.replaceAll(RegExp(r"^/+"), "").replaceAll(RegExp(r"^media/"), "")}.jpg')
                                            : null)),
                                postType: post.type,
                                communityId: post.communityId,
                                isLiked: context.watch<HomeFeedProvider>().isPostLiked(post.id) || post.isLiked,
                                isSaved: context.watch<HomeFeedProvider>().isPostSaved(post.id) || post.isSaved,
                                allowComments: post.allowComments,
                                allowDownloads: post.allowDownloads,
                                hideLikes: _profile?.hideMyLikes ?? false,
                              );
                              return PostFeedCard(
                                post: postItem,
                                isFollowing: _isFollowing,
                                onFollowToggle: () => _handleFollowToggle(
                                  isPrivateAccount: widget.isPrivate,
                                ),
                                onCardTap: () async {
                                  final HomeFeedProvider hFeed = context.read<HomeFeedProvider>();
                                  await Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) => SinglePostViewScreen(
                                        postId: post.id,
                                        initialPost: postItem,
                                      ),
                                    ),
                                  );
                                  if (!mounted) return;
                                  setState(() {
                                    final int idx = _authorTextPosts.indexWhere((PostResponseModel p) => p.id == post.id);
                                    if (idx != -1) {
                                      _authorTextPosts[idx] = _authorTextPosts[idx].copyWith(
                                        isLiked: hFeed.isPostLiked(post.id),
                                        isSaved: hFeed.isPostSaved(post.id),
                                      );
                                    }
                                  });
                                },
                                onLikeToggle: () {
                                  final int idx = _authorTextPosts
                                      .indexWhere((PostResponseModel p) => p.id == post.id);
                                  if (idx != -1) {
                                    final bool currentLiked =
                                        context.read<HomeFeedProvider>().isPostLiked(post.id) ||
                                        _authorTextPosts[idx].isLiked;
                                    final bool newLiked = !currentLiked;
                                    final int newCount = newLiked
                                        ? _authorTextPosts[idx].likesCount + 1
                                        : (_authorTextPosts[idx].likesCount > 0
                                            ? _authorTextPosts[idx].likesCount - 1
                                            : 0);
                                    setState(() {
                                      _authorTextPosts[idx] =
                                          _authorTextPosts[idx].copyWith(
                                        isLiked: newLiked,
                                        likesCount: newCount,
                                      );
                                    });
                                    context.read<HomeFeedProvider>().toggleLikePost(
                                      post.id,
                                      fallbackPost: postItem.copyWith(
                                        isLiked: newLiked,
                                        likesCount: newCount,
                                      ),
                                    );
                                    context.read<ProfileProvider>().updateLikedPost(
                                      post.id,
                                      isLiked: newLiked,
                                      likesCount: newCount,
                                      fallbackPost: postItem.copyWith(
                                        isLiked: newLiked,
                                        likesCount: newCount,
                                      ),
                                    );
                                  }
                                },
                                onSaveToggle: () {
                                  final int idx = _authorTextPosts
                                      .indexWhere((PostResponseModel p) => p.id == post.id);
                                  if (idx != -1) {
                                    final bool currentSaved =
                                        context.read<HomeFeedProvider>().isPostSaved(post.id) ||
                                        _authorTextPosts[idx].isSaved;
                                    final bool newSaved = !currentSaved;
                                    setState(() {
                                      _authorTextPosts[idx] =
                                          _authorTextPosts[idx].copyWith(
                                        isSaved: newSaved,
                                      );
                                    });
                                    context.read<HomeFeedProvider>().toggleSavePost(
                                      post.id,
                                      fallbackPost: postItem.copyWith(isSaved: newSaved),
                                    );
                                    context.read<ProfileProvider>().updateSavedPost(
                                      post.id,
                                      isSaved: newSaved,
                                      fallbackPost: postItem.copyWith(isSaved: newSaved),
                                    );
                                  }
                                },
                                onOpenComments: () {
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) => CommentsBottomSheet(
                                      totalComments: post.commentsCount,
                                      postId: post.id,
                                      postAuthorId: post.authorId,
                                      communityId: post.communityId,
                                      allowComments: post.allowComments,
                                      onCommentAdded: () {
                                        context.read<HomeFeedProvider>().incrementCommentCount(post.id);
                                        setState(() {
                                          final int idx = _authorTextPosts.indexWhere((PostResponseModel p) => p.id == post.id);
                                          if (idx != -1) {
                                            _authorTextPosts[idx] = _authorTextPosts[idx].copyWith(
                                              commentsCount: _authorTextPosts[idx].commentsCount + 1,
                                            );
                                          }
                                        });
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ] else ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                          child: Center(
                            child: Text(
                              'No posts yet.',
                              style: TextStyle(
                                color: context.themeTextMuted,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],

                    // Tab 1: Reels Grid
                    if (_selectedTabIndex == 1)
                      ProfileMediaGridWidget(
                        showPlayCounts: true,
                        customReels: _authorReels,
                        emptyTitle: 'No reels yet',
                        emptySubtitle: 'This user has not shared any reels yet.',
                      ),

                    // Tab 2: Saved Grid (Only on own profile)
                    if (_selectedTabIndex == 2 && isOwnProfile)
                      ProfileMediaGridWidget(
                        showPlayCounts: false,
                        customReels: profile.savedReels,
                        emptyTitle: 'No saved reels yet',
                        emptySubtitle: 'Reels you save will appear here.',
                        emptyIcon: Icons.bookmark_border_rounded,
                      ),

                    // Tab 3: Liked Grid (Only on own profile)
                    if (_selectedTabIndex == 3 && isOwnProfile)
                      ProfileMediaGridWidget(
                        showPlayCounts: false,
                        customReels: profile.likedReels,
                        emptyTitle: 'No liked reels yet',
                        emptySubtitle: 'Reels you like will appear here.',
                        emptyIcon: Icons.favorite_border_rounded,
                      ),
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

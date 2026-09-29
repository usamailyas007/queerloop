import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/cache/user_relationship_cache.dart';
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
import '../../create_post/services/post_content_service.dart';
import '../../discover/models/discover_models.dart';
import '../../discover/services/discover_service.dart';
import '../../messages/models/message_models.dart';
import '../../messages/provider/messages_provider.dart';
import '../../messages/screens/chat_screen.dart';
import '../../profile_setup/models/community_model.dart';
import '../../profile_setup/models/profile_models.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../home/models/post_item_model.dart';
import '../../home/models/reel_item_model.dart';
import '../../home/provider/home_feed_provider.dart';
import '../../home/services/reel_video_preloader.dart';
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
    this.avatarAsset = AppImages.defaultAvatar,
    this.isPrivate = false,
    this.initialReel,
    this.initialPost,
    super.key,
  });

  final String? userId;
  final String username;
  final String name;
  final String avatarAsset;
  final bool isPrivate;
  final ReelItemModel? initialReel;
  final PostItemModel? initialPost;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _selectedTabIndex = 0; // Default: Posts
  bool _isRequested = false; // Default: Not requested (shows Follow initially)
  bool _isFollowing = false; // Default: Not following (shows Follow initially)
  bool _isLoading = true;
  bool _isFetchingProfile = false;
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
    // Do not pre-populate posts or reels so that full profile loads cleanly
    // with shimmer loading first, matching reel author profile navigation.
    ReelVideoPreloader.instance.setFeedVisible(false);
    ReelVideoPreloader.instance.pauseAll();
    ReelVideoPreloader.instance.muteAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReelVideoPreloader.instance.pauseAll();
      if (mounted) {
        context.read<MessagesProvider>().loadBlockedUsers();
        context.read<ProfileProvider>().loadBlockedAccounts();
        final String? curUserId = context.read<AuthProvider>().userId;
        final String? myName = context.read<AuthProvider>().user?.displayName;
        final bool isOwn = (curUserId != null &&
                curUserId.isNotEmpty &&
                (_effectiveUserId == curUserId || widget.userId == curUserId)) ||
            (myName != null &&
                myName.isNotEmpty &&
                widget.username.replaceAll('@', '').toLowerCase() ==
                    myName.replaceAll('@', '').toLowerCase());
        if (isOwn) {
          context.read<ProfileProvider>().fetchSavedPosts();
          context.read<ProfileProvider>().fetchLikedPosts();
        }
      }
    });

    String? resolvedId = (widget.userId != null && widget.userId!.trim().isNotEmpty)
        ? widget.userId!.trim()
        : null;

    if (resolvedId == null && widget.username.trim().isNotEmpty) {
      final AuthorInfo? cached = AuthorProfileCache.getByName(widget.username);
      if (cached != null && cached.id.isNotEmpty) {
        resolvedId = cached.id;
        _resolvedUserId = cached.id;
      }
    }

    if (resolvedId != null) {
      _fetchUserProfile(resolvedId);
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
          lower.endsWith('.m3u8') ||
          lower.contains('/videos/processed/')) {
        return true;
      }
    }
    return false;
  }

  String _resolveCommentRule(String? postRule) {
    final String pRule = (postRule ?? '').trim().toLowerCase();
    final String aRule = (_profile?.allowCommentsFrom ?? '').trim().toLowerCase();
    if (aRule == 'nobody' || pRule == 'nobody') return 'nobody';
    if (aRule == 'mutual' || pRule == 'mutual') return 'mutual';
    if (aRule == 'following' || pRule == 'following' || aRule.contains('you follow') || pRule.contains('you follow')) {
      return 'following';
    }
    if (aRule.contains('follower') || pRule.contains('follower')) return 'followers';
    if (aRule.isNotEmpty && aRule != 'everyone') return aRule;
    if (pRule.isNotEmpty && pRule != 'everyone') return pRule;
    return 'everyone';
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
          if (post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty) {
            thumbUrl = post.thumbnailUrl;
          } else if (firstRef.contains('/videos/processed/')) {
            thumbUrl = firstRef.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg');
          } else if (post.postImageUrl != null &&
              post.postImageUrl!.isNotEmpty &&
              !post.postImageUrl!.endsWith('.mp4') &&
              !post.postImageUrl!.endsWith('.m3u8')) {
            thumbUrl = post.postImageUrl;
          }
        } else {
          // Raw UUID from upload — build HLS URL directly (same as For You feed, no extra API call)
          final String clean = firstRef
              .replaceAll(RegExp(r'^/+'), '')
              .replaceAll(RegExp(r'^media/'), '');
          videoUrl = '${AppConfig.cdnUrl}/videos/processed/$clean/master.m3u8';
          thumbUrl = (post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty)
              ? post.thumbnailUrl
              : (post.postImageUrl != null &&
                      post.postImageUrl!.isNotEmpty &&
                      !post.postImageUrl!.endsWith('.mp4') &&
                      !post.postImageUrl!.endsWith('.m3u8'))
                  ? post.postImageUrl
                  : '${AppConfig.cdnUrl}/videos/processed/$clean/thumb.0000000.jpg';
        }
      }

      final String authorUsername =
          post.authorName ?? _profile?.username ?? fallbackUsername;
      final String formattedUsername = authorUsername.startsWith('@')
          ? authorUsername
          : '@$authorUsername';
      final String? profileAvatar = (_profile?.avatarUrl != null &&
              _profile!.avatarUrl!.trim().isNotEmpty)
          ? _profile!.avatarUrl!.trim()
          : null;
      final String avatar = (post.authorAvatar != null &&
              post.authorAvatar!.trim().isNotEmpty)
          ? post.authorAvatar!.trim()
          : (profileAvatar ?? AppImages.defaultAvatar);

      final String resolvedAllowCommentsFrom = _resolveCommentRule(post.allowCommentsFrom);
      final bool resolvedIsAuthorPrivate =
          post.isAuthorPrivate || (_profile?.isPrivate ?? false) || widget.isPrivate;

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
          likesCount: PostInteractionRegistry.getLikeCount(post.id, fallback: post.likesCount),
          commentsCount: CommentCountRegistry.getOr(post.id, post.commentsCount),
          viewsCount: post.viewsCount,
          isLiked: PostInteractionRegistry.isLiked(post.id, fallback: post.isLiked),
          isSaved: PostInteractionRegistry.isSaved(post.id, fallback: post.isSaved),
          allowComments: post.allowComments,
          allowDownloads: post.allowDownloads,
          isAuthorPrivate: resolvedIsAuthorPrivate,
          allowCommentsFrom: resolvedAllowCommentsFrom,
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
        if (person.id != null &&
            person.id!.trim().isNotEmpty &&
            person.id!.trim() != _resolvedUserId &&
            mounted) {
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
    if (_isFetchingProfile) return;
    _isFetchingProfile = true;
    setState(() {
      _isLoading = true;
    });

    final ApiClient client = context.read<ApiClient>();
    final AuthProvider auth = context.read<AuthProvider>();
    final ProfileProvider profileProvider = context.read<ProfileProvider>();
    final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
    final UserRelationshipService relService = UserRelationshipService(client);

    // 1. Fetch user profile
    UserProfile? loadedProfile;
    try {
      debugPrint('🚀 [UserProfile] Calling GET ${ApiEndpoints.user(userId)}');
      final dynamic data = await client.get(ApiEndpoints.user(userId));
      debugPrint('📥 [UserProfile] User profile response: $data');

      if (data is Map<String, dynamic>) {
        loadedProfile = UserProfile.fromJson(data);
        final bool isPriv = loadedProfile.isPrivate ?? false;
        final String commentRule = loadedProfile.allowCommentsFrom ?? 'everyone';
        AuthorProfileCache.set(
          loadedProfile.id,
          AuthorInfo(
            id: loadedProfile.id,
            username: loadedProfile.username ?? '',
            displayName: loadedProfile.displayName ?? '',
            avatarUrl: loadedProfile.avatarUrl,
            hideMyLikes: loadedProfile.hideMyLikes,
            isPrivate: isPriv,
            allowCommentsFrom: commentRule,
          ),
        );
        UserRelationshipCache.markPrivate(
          loadedProfile.id,
          username: loadedProfile.username,
          isPrivate: isPriv,
        );
      }
    } catch (e) {
      debugPrint('❌ [UserProfile] Failed to fetch user profile: $e');
      if (widget.userId == null && widget.username.trim().isNotEmpty && _resolvedUserId == null) {
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

    // 3. Check follow status for relationship indicators
    final String? curUserId = auth.userId ?? profileProvider.profile?.id;

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

    if (isCurrentlyFollowing) {
      UserRelationshipCache.add(
        userId: loadedProfile?.id ?? userId,
        username: loadedProfile?.username ?? widget.username,
      );
    } else {
      UserRelationshipCache.remove(
        userId: loadedProfile?.id ?? userId,
        username: loadedProfile?.username ?? widget.username,
      );
    }

    final bool isAuthorFollowingMe = curUserId != null &&
        curUserId.isNotEmpty &&
        followingList.any((UserRelationItem f) => f.userId == curUserId);
    if (isAuthorFollowingMe) {
      UserRelationshipCache.addFollower(
        userId: loadedProfile?.id ?? userId,
        username: loadedProfile?.username ?? widget.username,
      );
    } else {
      UserRelationshipCache.removeFollower(
        userId: loadedProfile?.id ?? userId,
        username: loadedProfile?.username ?? widget.username,
      );
    }

    final String? myName = auth.user?.displayName;
    final bool isOwn = (curUserId != null &&
            curUserId.isNotEmpty &&
            (userId == curUserId || loadedProfile?.id == curUserId)) ||
        (myName != null &&
            myName.isNotEmpty &&
            widget.username.replaceAll('@', '').toLowerCase() ==
                myName.replaceAll('@', '').toLowerCase());

    final String? pVis = loadedProfile?.profileVisibility?.toLowerCase();
    final bool isPrivateProfile = (loadedProfile?.isPrivate ?? false) ||
        (pVis != null && (pVis.contains('nobody') || pVis.contains('private'))) ||
        widget.isPrivate;

    final bool shouldRestrictPrivatePosts =
        isPrivateProfile && !isOwn && !isCurrentlyFollowing;

    // 3. Fetch author posts - ensure both video reels and photo posts are fetched,
    // even if the user is private or posts have followers-only visibility.
    final List<PostResponseModel> allPosts = <PostResponseModel>[];
    if (!shouldRestrictPrivatePosts) {
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
          } else if (postsData['data'] is Map) {
            final Map d = postsData['data'] as Map;
            if (d['posts'] is List) {
              rawList = d['posts'] as List<dynamic>;
            } else if (d['items'] is List) {
              rawList = d['items'] as List<dynamic>;
            } else if (d['results'] is List) {
              rawList = d['results'] as List<dynamic>;
            }
          } else if (postsData['posts'] is List) {
            rawList = postsData['posts'] as List<dynamic>;
          } else if (postsData['items'] is List) {
            rawList = postsData['items'] as List<dynamic>;
          } else if (postsData['results'] is List) {
            rawList = postsData['results'] as List<dynamic>;
          }
        }
        for (final dynamic item in rawList) {
          if (item is Map) {
            try {
              final Map<String, dynamic> rawMap = Map<String, dynamic>.from(item);
              final dynamic nested = rawMap['post'] ?? rawMap['item'] ?? rawMap['savedPost'];
              final Map<String, dynamic> typed = (nested is Map)
                  ? Map<String, dynamic>.from(nested)
                  : rawMap;
              final PostResponseModel parsed = PostResponseModel.fromJson(typed);
              if (!parsed.isDeleted && !allPosts.any((PostResponseModel p) => p.id == parsed.id)) {
                allPosts.add(parsed);
              }
            } catch (e) {
              debugPrint('⚠️ [UserProfile] Error parsing post: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [UserProfile] Could not fetch author posts via postsByAuthor: $e');
      }

      // Fallback/enrich from global feed /posts (Content Service) only for non-private or followed accounts
      try {
        final PostContentService contentService = PostContentService(client);
        final List<PostResponseModel> feedPosts = await contentService.getFeedPosts();
        final String cleanUserId = userId.trim().toLowerCase();
        final String cleanUsername = widget.username.replaceAll('@', '').trim().toLowerCase();

        for (final PostResponseModel p in feedPosts) {
          final String? pAuthorId = p.authorId?.trim().toLowerCase();
          final String? pAuthorName = p.authorName?.replaceAll('@', '').trim().toLowerCase();
          final bool isMatch = (pAuthorId != null && pAuthorId == cleanUserId) ||
              (pAuthorName != null && pAuthorName == cleanUsername);
          if (isMatch && !p.isDeleted) {
            if (!allPosts.any((PostResponseModel existing) => existing.id == p.id)) {
              allPosts.add(p);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ [UserProfile] Fallback getFeedPosts error: $e');
      }

      // Also enrich from in-memory HomeFeedProvider posts and reels if present
      try {
        final String cleanUserId = userId.trim().toLowerCase();
        final String cleanUsername = widget.username.replaceAll('@', '').trim().toLowerCase();

      for (final PostItemModel p in homeFeed.posts) {
        final String? pAuthorId = p.authorId?.trim().toLowerCase();
        final String pUsername = p.username.replaceAll('@', '').trim().toLowerCase();
        if ((pAuthorId == cleanUserId || pUsername == cleanUsername) &&
            !allPosts.any((PostResponseModel existing) => existing.id == p.id)) {
          allPosts.add(
            PostResponseModel(
              id: p.id,
              authorId: p.authorId,
              authorName: p.username,
              authorDisplayName: p.authorDisplayName,
              authorAvatar: p.avatarAsset,
              caption: p.content,
              type: p.postType.isNotEmpty ? p.postType : 'PHOTO',
              postImageUrl: p.postImageUrl,
              likesCount: p.likesCount,
              commentsCount: p.commentsCount,
              isLiked: p.isLiked,
              isSaved: p.isSaved,
              allowComments: p.allowComments,
              allowDownloads: p.allowDownloads,
            ),
          );
        }
      }

      for (final ReelItemModel r in homeFeed.reels) {
        final String? rAuthorId = r.authorId?.trim().toLowerCase();
        final String rUsername = r.username.replaceAll('@', '').trim().toLowerCase();
        if ((rAuthorId == cleanUserId || rUsername == cleanUsername) &&
            !allPosts.any((PostResponseModel existing) => existing.id == r.id)) {
          allPosts.add(
            PostResponseModel(
              id: r.id,
              authorId: r.authorId,
              authorName: r.username,
              authorDisplayName: r.authorDisplayName,
              authorAvatar: r.avatarAsset,
              caption: r.caption,
              type: 'VIDEO',
              mediaRefs: (r.videoUrl != null && r.videoUrl!.isNotEmpty)
                  ? <String>[r.videoUrl!]
                  : const <String>[],
              thumbnailUrl: r.thumbnailUrl,
              likesCount: r.likesCount,
              commentsCount: r.commentsCount,
              viewsCount: r.viewsCount,
              isLiked: r.isLiked,
              isSaved: r.isSaved,
              allowComments: r.allowComments,
              allowDownloads: r.allowDownloads,
              duration: r.durationText,
            ),
          );
        }
      }
    } catch (_) {}
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
      if (post.postImageUrl != null && post.postImageUrl!.trim().isNotEmpty) {
        postImages[post.id] = post.postImageUrl!.trim();
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
          final bool hasExt = clean.toLowerCase().endsWith('.jpg') ||
              clean.toLowerCase().endsWith('.jpeg') ||
              clean.toLowerCase().endsWith('.png') ||
              clean.toLowerCase().endsWith('.webp');
          final String filename = hasExt ? clean : '$clean.jpg';
          final String author = post.authorId ?? _effectiveUserId ?? userId;
          if (author.isNotEmpty) {
            postImages[post.id] =
                '${AppConfig.cdnUrl}/images/original/$author/$filename';
          } else {
            postImages[post.id] =
                '${AppConfig.cdnUrl}/images/original/$filename';
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
      if (shouldRestrictPrivatePosts) {
        _authorPosts = <PostResponseModel>[];
        _authorTextPosts = <PostResponseModel>[];
        _authorReels = <ReelItemModel>[];
      } else {
        _authorPosts = allPosts.isNotEmpty ? allPosts : _authorPosts;
        _authorTextPosts = textPosts.isNotEmpty ? textPosts : _authorTextPosts;
        _authorReels = convertedReels.isNotEmpty
            ? convertedReels
            : (_authorReels.isNotEmpty
                ? _authorReels
                : (widget.initialReel != null
                    ? <ReelItemModel>[widget.initialReel!]
                    : <ReelItemModel>[]));
      }
      _postImageUrls = <String, String>{..._postImageUrls, ...postImages};
      _userCommunities = comms;
      _followersCount = calculatedFollowers;
      _followingCount = calculatedFollowing;
      _isFollowing = isCurrentlyFollowing;
      _isRequested = loadedProfile?.isPending == true ||
          loadedProfile?.relationship == 'pending';
      _isLoading = false;
    });
    _isFetchingProfile = false;
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
    final String? profVis = _profile?.profileVisibility?.toLowerCase();
    final bool isPrivateAccount = (_profile != null)
        ? (_profile!.isPrivate == true ||
            (profVis != null &&
                (profVis.contains('nobody') || profVis.contains('private'))))
        : (widget.isPrivate || widget.username.contains('kit.lumen'));
    final String currentUsername = _profile?.username ?? widget.username;
    final String currentName = _profile?.displayName ?? widget.name;
    final String currentAvatar = (_profile != null)
        ? ((_profile!.avatarUrl != null && _profile!.avatarUrl!.trim().isNotEmpty)
            ? _profile!.avatarUrl!.trim()
            : AppImages.defaultAvatar)
        : ((widget.avatarAsset.isNotEmpty && widget.avatarAsset != AppImages.user1)
            ? widget.avatarAsset
            : AppImages.defaultAvatar);
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

    final String cleanUsernameOnly =
        currentUsername.replaceAll('@', '').trim().toLowerCase();
    final bool isUserBlocked = msgProvider.isBlocked(_effectiveUserId) ||
        msgProvider.isBlocked(currentUsername) ||
        profile.isBlocked(_effectiveUserId) ||
        profile.isBlocked(currentUsername) ||
        profile.blockedAccounts.any((BlockedAccountItem b) =>
            (b.userId.isNotEmpty &&
                (b.userId == _effectiveUserId || b.userId == widget.userId)) ||
            b.username.replaceAll('@', '').trim().toLowerCase() ==
                cleanUsernameOnly);

    final bool shouldShowPrivateScreen = isPrivateAccount &&
        !isOwnProfile &&
        !_isFollowing;

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
              child: _isLoading && _profile == null && _authorReels.isEmpty && _authorTextPosts.isEmpty
                  ? const _FullProfileShimmerSkeleton()
                  : ListenableBuilder(
                      listenable: Listenable.merge(<Listenable>[
                        PostInteractionRegistry.notifier,
                        CommentCountRegistry.notifier,
                      ]),
                      builder: (BuildContext context, _) {
                        return ListView(
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
                          identityList: isOwnProfile ? profile.identities : const <String>[],
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
                                        final String cleanTarget =
                                            currentUsername.replaceAll('@', '').trim().toLowerCase();
                                        final BlockedAccountItem? blockedMatch =
                                            profile.blockedAccounts.cast<BlockedAccountItem?>().firstWhere(
                                          (BlockedAccountItem? b) =>
                                              b != null &&
                                              ((b.userId.isNotEmpty &&
                                                      (b.userId == _effectiveUserId ||
                                                          b.userId == widget.userId)) ||
                                                  b.username
                                                          .replaceAll('@', '')
                                                          .trim()
                                                          .toLowerCase() ==
                                                      cleanTarget),
                                          orElse: () => null,
                                        );
                                        final String tId = blockedMatch?.userId ??
                                            _effectiveUserId ??
                                            widget.userId ??
                                            currentUsername;

                                        await profile.unblockUser(tId, username: currentUsername);
                                        await msgProvider.unblockUser(tId, username: currentUsername);
                                        if (!mounted) return;
                                        setState(() {});
                                        AppSnackBar.showSuccess(
                                          this.context,
                                          title: 'Unblocked',
                                          subtitle:
                                              '@$cleanTarget has been unblocked.',
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
                          context.read<ProfileProvider>().fetchSavedPosts(force: true);
                        } else if (index == 3) {
                          context.read<ProfileProvider>().fetchLikedPosts(force: true);
                        }
                      },
                    ),

                    // Tab 0: Posts Feed Cards (Photos and Text only)
                    if (_selectedTabIndex == 0) ...<Widget>[
                      if (_isLoading && _authorTextPosts.isEmpty) ...<Widget>[
                        const _ProfilePostsFeedShimmer(),
                      ] else if (_authorTextPosts.isNotEmpty) ...<Widget>[
                        for (final PostResponseModel post in _authorTextPosts) ...<Widget>[
                          Builder(
                            builder: (BuildContext ctx) {
                              final bool isPostItemLiked = PostInteractionRegistry.isLiked(post.id, fallback: post.isLiked);
                              final bool isPostItemSaved = PostInteractionRegistry.isSaved(post.id, fallback: post.isSaved);
                              final int postItemLikes = PostInteractionRegistry.getLikeCount(post.id, fallback: post.likesCount);
                              final int effectiveCommentsCount = CommentCountRegistry.getOr(post.id, post.commentsCount);
                              final PostItemModel postItem = PostItemModel(
                                id: post.id,
                                authorId: post.authorId ?? _effectiveUserId,
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
                                likesCount: postItemLikes,
                                commentsCount: effectiveCommentsCount,
                                postImageUrl: _postImageUrls[post.id] ??
                                    (post.postImageUrl != null && post.postImageUrl!.isNotEmpty
                                        ? post.postImageUrl
                                        : (post.mediaRefs.isNotEmpty
                                            ? (post.mediaRefs.first.startsWith('http') || post.mediaRefs.first.startsWith('assets/')
                                                ? post.mediaRefs.first
                                                : '${AppConfig.cdnUrl}/images/original/${post.authorId ?? _effectiveUserId ?? ''}/${post.mediaRefs.first.replaceAll(RegExp(r"^/+"), "").replaceAll(RegExp(r"^media/"), "").replaceAll(RegExp(r"\.(jpg|jpeg|png|webp)$", caseSensitive: false), "")}.jpg')
                                            : null)),
                                postType: post.type,
                                communityId: post.communityId,
                                isLiked: isPostItemLiked,
                                isSaved: isPostItemSaved,
                                allowComments: post.allowComments,
                                allowDownloads: post.allowDownloads,
                                allowCommentsFrom: (post.allowCommentsFrom.isNotEmpty && post.allowCommentsFrom != 'everyone')
                                    ? post.allowCommentsFrom
                                    : (_profile?.allowCommentsFrom ?? post.allowCommentsFrom),
                                isAuthorPrivate: post.isAuthorPrivate || (_profile?.isPrivate ?? false) || isPrivateAccount,
                                hideLikes: _profile?.hideMyLikes ?? false,
                              );
                              return PostFeedCard(
                                post: postItem,
                                isFollowing: _isFollowing,
                                onFollowToggle: () => _handleFollowToggle(
                                  isPrivateAccount: widget.isPrivate,
                                ),
                                onCardTap: () {
                                  PostFeedCard.openFullscreen(context, postItem);
                                },
                                onLikeToggle: () {
                                  final int idx = _authorTextPosts
                                      .indexWhere((PostResponseModel p) => p.id == post.id);
                                  if (idx != -1) {
                                    final bool currentLiked =
                                        PostInteractionRegistry.isLiked(post.id, fallback: _authorTextPosts[idx].isLiked);
                                    final bool newLiked = !currentLiked;
                                    final int currentCount = PostInteractionRegistry.getLikeCount(post.id, fallback: _authorTextPosts[idx].likesCount);
                                    final int newCount = newLiked
                                        ? currentCount + 1
                                        : (currentCount > 0
                                            ? currentCount - 1
                                            : 0);
                                    PostInteractionRegistry.setLiked(post.id, newLiked, newCount: newCount);
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
                                      explicitLiked: newLiked,
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
                                        PostInteractionRegistry.isSaved(post.id, fallback: _authorTextPosts[idx].isSaved);
                                    final bool newSaved = !currentSaved;
                                    PostInteractionRegistry.setSaved(post.id, newSaved);
                                    setState(() {
                                      _authorTextPosts[idx] =
                                          _authorTextPosts[idx].copyWith(
                                        isSaved: newSaved,
                                      );
                                    });
                                    context.read<HomeFeedProvider>().toggleSavePost(
                                      post.id,
                                      fallbackPost: postItem.copyWith(isSaved: newSaved),
                                      explicitSaved: newSaved,
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
                                      totalComments: CommentCountRegistry.getOr(post.id, post.commentsCount),
                                      postId: post.id,
                                      postAuthorId: post.authorId ?? _effectiveUserId,
                                      communityId: post.communityId,
                                      allowComments: post.allowComments,
                                      allowCommentsFrom: (_profile?.allowCommentsFrom != null &&
                                              _profile!.allowCommentsFrom!.trim().isNotEmpty &&
                                              _profile!.allowCommentsFrom != 'everyone')
                                          ? _profile!.allowCommentsFrom!
                                          : ((post.allowCommentsFrom.isNotEmpty && post.allowCommentsFrom != 'everyone')
                                              ? post.allowCommentsFrom
                                              : (_profile?.allowCommentsFrom ?? 'everyone')),
                                      authorUsername: post.authorName ?? currentUsername,
                                      onCommentAdded: () {
                                        CommentCountRegistry.increment(post.id);
                                        context.read<HomeFeedProvider>().incrementCommentCount(post.id);
                                        try {
                                          context.read<ProfileProvider>().incrementCommentCount(post.id);
                                        } catch (_) {}
                                        setState(() {
                                          final int idx = _authorTextPosts.indexWhere((PostResponseModel p) => p.id == post.id);
                                          if (idx != -1) {
                                            _authorTextPosts[idx] = _authorTextPosts[idx].copyWith(
                                              commentsCount: CommentCountRegistry.getOr(post.id, _authorTextPosts[idx].commentsCount + 1),
                                            );
                                          }
                                        });
                                      },
                                      onCommentDeleted: (int deletedCount, int remainingCount) {
                                        CommentCountRegistry.set(post.id, remainingCount);
                                        context.read<HomeFeedProvider>().setCommentCount(post.id, remainingCount);
                                        try {
                                          context.read<ProfileProvider>().updatePostCommentCount(post.id, remainingCount);
                                        } catch (_) {}
                                        setState(() {
                                          final int idx = _authorTextPosts.indexWhere((PostResponseModel p) => p.id == post.id);
                                          if (idx != -1) {
                                            _authorTextPosts[idx] = _authorTextPosts[idx].copyWith(
                                              commentsCount: remainingCount,
                                            );
                                          }
                                        });
                                      },
                                      onCommentCountChanged: (int count) {
                                        CommentCountRegistry.set(post.id, count);
                                        context.read<HomeFeedProvider>().setCommentCount(post.id, count);
                                        try {
                                          context.read<ProfileProvider>().updatePostCommentCount(post.id, count);
                                        } catch (_) {}
                                        setState(() {
                                          final int idx = _authorTextPosts.indexWhere((PostResponseModel p) => p.id == post.id);
                                          if (idx != -1) {
                                            _authorTextPosts[idx] = _authorTextPosts[idx].copyWith(
                                              commentsCount: count,
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
                        isLoading: _isLoading && _authorReels.isEmpty,
                        showPlayCounts: true,
                        customReels: _authorReels,
                        emptyTitle: 'No reels yet',
                        emptySubtitle: 'This user has not shared any reels yet.',
                      ),

                    // Tab 2: Saved Grid & Posts (Only on own profile)
                    if (_selectedTabIndex == 2 && isOwnProfile) ...<Widget>[
                      if ((!profile.hasFetchedSaved || profile.isLoadingSaved) &&
                          profile.savedReels.isEmpty &&
                          profile.savedPosts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gradientPink,
                            ),
                          ),
                        )
                      else if (profile.savedReels.isEmpty && profile.savedPosts.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 24,
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.bookmark_border_rounded,
                                size: 44,
                                color: context.isDarkMode ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No saved posts yet',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Posts and reels you save will appear here.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  color: context.themeTextMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...<Widget>[
                        if (profile.savedReels.isNotEmpty)
                          ProfileMediaGridWidget(
                            customReels: profile.savedReels,
                            showPlayCounts: true,
                            emptyTitle: 'No saved reels yet',
                            emptySubtitle: 'Reels you save will appear here.',
                            emptyIcon: Icons.bookmark_border_rounded,
                          ),
                        if (profile.savedPosts.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          for (final PostItemModel post in profile.savedPosts)
                            Builder(
                              builder: (BuildContext ctx) {
                                final bool isLiked = PostInteractionRegistry.isLiked(post.id, fallback: post.isLiked);
                                final bool isSaved = PostInteractionRegistry.isSaved(post.id, fallback: post.isSaved);
                                final int effectiveLikes = PostInteractionRegistry.getLikeCount(post.id, fallback: post.likesCount);
                                final int effectiveComments =
                                    CommentCountRegistry.getOr(post.id, post.commentsCount);
                                final PostItemModel resolvedPost = post.copyWith(
                                  isLiked: isLiked,
                                  isSaved: isSaved,
                                  likesCount: effectiveLikes,
                                  commentsCount: effectiveComments,
                                );

                                return PostFeedCard(
                                  post: resolvedPost,
                                  isProfileScreen: true,
                                  onCardTap: () {
                                    PostFeedCard.openFullscreen(context, resolvedPost, isProfileScreen: true);
                                  },
                                  onLikeToggle: () {
                                    final bool currentLiked =
                                        PostInteractionRegistry.isLiked(post.id, fallback: post.isLiked);
                                    final bool newLiked = !currentLiked;
                                    final int currentCount = PostInteractionRegistry.getLikeCount(post.id, fallback: post.likesCount);
                                    final int newCount = post.hasLikeCount
                                        ? (newLiked
                                            ? currentCount + 1
                                            : (currentCount > 0 ? currentCount - 1 : 0))
                                        : currentCount;
                                    PostInteractionRegistry.setLiked(post.id, newLiked, newCount: newCount);
                                    context.read<ProfileProvider>().updateLikedPost(
                                      post.id,
                                      isLiked: newLiked,
                                      likesCount: newCount,
                                      fallbackPost: post.copyWith(isLiked: newLiked, likesCount: newCount),
                                    );
                                    context.read<HomeFeedProvider>().toggleLikePost(
                                      post.id,
                                      fallbackPost: post.copyWith(isLiked: newLiked, likesCount: newCount),
                                      explicitLiked: newLiked,
                                    );
                                  },
                                  onSaveToggle: () {
                                    final bool currentSaved =
                                        PostInteractionRegistry.isSaved(post.id, fallback: post.isSaved);
                                    final bool newSaved = !currentSaved;
                                    PostInteractionRegistry.setSaved(post.id, newSaved);
                                    context.read<ProfileProvider>().updateSavedPost(
                                      post.id,
                                      isSaved: newSaved,
                                      fallbackPost: post.copyWith(isSaved: newSaved),
                                    );
                                    context.read<HomeFeedProvider>().toggleSavePost(
                                      post.id,
                                      fallbackPost: post.copyWith(isSaved: newSaved),
                                      explicitSaved: newSaved,
                                    );
                                  },
                                  onOpenComments: () {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => CommentsBottomSheet(
                                        totalComments: effectiveComments,
                                        postId: post.id,
                                        postAuthorId: post.authorId ?? _effectiveUserId,
                                        communityId: post.communityId,
                                        allowComments: post.allowComments,
                                        allowCommentsFrom: (post.allowCommentsFrom.isNotEmpty && post.allowCommentsFrom != 'everyone')
                                            ? post.allowCommentsFrom
                                            : (_profile?.allowCommentsFrom ?? post.allowCommentsFrom),
                                        authorUsername: post.username.isNotEmpty ? post.username : currentUsername,
                                        onCommentAdded: () {
                                          CommentCountRegistry.increment(post.id);
                                          context.read<HomeFeedProvider>().incrementCommentCount(post.id);
                                          context.read<ProfileProvider>().updatePostCommentCount(
                                            post.id,
                                            CommentCountRegistry.getOr(post.id, effectiveComments + 1),
                                          );
                                        },
                                        onCommentDeleted: (int deletedCount, int remainingCount) {
                                          CommentCountRegistry.set(post.id, remainingCount);
                                          context.read<HomeFeedProvider>().setCommentCount(post.id, remainingCount);
                                          context.read<ProfileProvider>().updatePostCommentCount(
                                            post.id,
                                            remainingCount,
                                          );
                                        },
                                        onCommentCountChanged: (int count) {
                                          CommentCountRegistry.set(post.id, count);
                                          context.read<HomeFeedProvider>().setCommentCount(post.id, count);
                                          context.read<ProfileProvider>().updatePostCommentCount(
                                            post.id,
                                            count,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                        ],
                      ],
                    ],

                    // Tab 3: Liked Grid & Posts (Only on own profile)
                    if (_selectedTabIndex == 3 && isOwnProfile) ...<Widget>[
                      if ((!profile.hasFetchedLiked || profile.isLoadingLiked) &&
                          profile.likedReels.isEmpty &&
                          profile.likedPosts.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gradientPink,
                            ),
                          ),
                        )
                      else if (profile.likedReels.isEmpty && profile.likedPosts.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 40,
                            horizontal: 24,
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                Icons.favorite_border_rounded,
                                size: 44,
                                color: context.isDarkMode ? Colors.white30 : Colors.black26,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No liked posts yet',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Posts and reels you like will appear here.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.caption.copyWith(
                                  color: context.themeTextMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...<Widget>[
                        if (profile.likedReels.isNotEmpty)
                          ProfileMediaGridWidget(
                            customReels: profile.likedReels,
                            showPlayCounts: true,
                            emptyTitle: 'No liked reels yet',
                            emptySubtitle: 'Reels you like will appear here.',
                            emptyIcon: Icons.favorite_border_rounded,
                          ),
                        if (profile.likedPosts.isNotEmpty) ...<Widget>[
                          const SizedBox(height: AppSpacing.md),
                          for (final PostItemModel post in profile.likedPosts)
                            Builder(
                              builder: (BuildContext ctx) {
                                final bool isLiked = PostInteractionRegistry.isLiked(post.id, fallback: post.isLiked);
                                final bool isSaved = PostInteractionRegistry.isSaved(post.id, fallback: post.isSaved);
                                final int effectiveLikes = PostInteractionRegistry.getLikeCount(post.id, fallback: post.likesCount);
                                final int effectiveComments =
                                    CommentCountRegistry.getOr(post.id, post.commentsCount);
                                final PostItemModel resolvedPost = post.copyWith(
                                  isLiked: isLiked,
                                  isSaved: isSaved,
                                  likesCount: effectiveLikes,
                                  commentsCount: effectiveComments,
                                );

                                return PostFeedCard(
                                  post: resolvedPost,
                                  isProfileScreen: true,
                                  onCardTap: () {
                                    PostFeedCard.openFullscreen(context, resolvedPost, isProfileScreen: true);
                                  },
                                  onLikeToggle: () {
                                    final bool currentLiked =
                                        PostInteractionRegistry.isLiked(post.id, fallback: post.isLiked);
                                    final bool newLiked = !currentLiked;
                                    final int currentCount = PostInteractionRegistry.getLikeCount(post.id, fallback: post.likesCount);
                                    final int newCount = post.hasLikeCount
                                        ? (newLiked
                                            ? currentCount + 1
                                            : (currentCount > 0 ? currentCount - 1 : 0))
                                        : currentCount;
                                    PostInteractionRegistry.setLiked(post.id, newLiked, newCount: newCount);
                                    context.read<ProfileProvider>().updateLikedPost(
                                      post.id,
                                      isLiked: newLiked,
                                      likesCount: newCount,
                                      fallbackPost: post.copyWith(isLiked: newLiked, likesCount: newCount),
                                    );
                                    context.read<HomeFeedProvider>().toggleLikePost(
                                      post.id,
                                      fallbackPost: post.copyWith(isLiked: newLiked, likesCount: newCount),
                                      explicitLiked: newLiked,
                                    );
                                  },
                                  onSaveToggle: () {
                                    final bool currentSaved =
                                        PostInteractionRegistry.isSaved(post.id, fallback: post.isSaved);
                                    final bool newSaved = !currentSaved;
                                    PostInteractionRegistry.setSaved(post.id, newSaved);
                                    context.read<ProfileProvider>().updateSavedPost(
                                      post.id,
                                      isSaved: newSaved,
                                      fallbackPost: post.copyWith(isSaved: newSaved),
                                    );
                                    context.read<HomeFeedProvider>().toggleSavePost(
                                      post.id,
                                      fallbackPost: post.copyWith(isSaved: newSaved),
                                      explicitSaved: newSaved,
                                    );
                                  },
                                  onOpenComments: () {
                                    showModalBottomSheet<void>(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (_) => CommentsBottomSheet(
                                        totalComments: effectiveComments,
                                        postId: post.id,
                                        postAuthorId: post.authorId ?? _effectiveUserId,
                                        communityId: post.communityId,
                                        allowComments: post.allowComments,
                                        allowCommentsFrom: (post.allowCommentsFrom.isNotEmpty && post.allowCommentsFrom != 'everyone')
                                            ? post.allowCommentsFrom
                                            : (_profile?.allowCommentsFrom ?? post.allowCommentsFrom),
                                        authorUsername: post.username.isNotEmpty ? post.username : currentUsername,
                                        onCommentAdded: () {
                                          CommentCountRegistry.increment(post.id);
                                          context.read<HomeFeedProvider>().incrementCommentCount(post.id);
                                          context.read<ProfileProvider>().updatePostCommentCount(
                                            post.id,
                                            CommentCountRegistry.getOr(post.id, effectiveComments + 1),
                                          );
                                        },
                                        onCommentDeleted: (int deletedCount, int remainingCount) {
                                          CommentCountRegistry.set(post.id, remainingCount);
                                          context.read<HomeFeedProvider>().setCommentCount(post.id, remainingCount);
                                          context.read<ProfileProvider>().updatePostCommentCount(
                                            post.id,
                                            remainingCount,
                                          );
                                        },
                                        onCommentCountChanged: (int count) {
                                          CommentCountRegistry.set(post.id, count);
                                          context.read<HomeFeedProvider>().setCommentCount(post.id, count);
                                          context.read<ProfileProvider>().updatePostCommentCount(
                                            post.id,
                                            count,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                        ],
                      ],
                    ],
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                ],
              );
            },
          ),
        ),
          ],
        ),
      ),
    );
  }
}

class _FullProfileShimmerSkeleton extends StatelessWidget {
  const _FullProfileShimmerSkeleton();

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        physics: const NeverScrollableScrollPhysics(),
        children: <Widget>[
          const SizedBox(height: 12),
          // Avatar + Stats row
          Row(
            children: <Widget>[
              const ShimmerBox(width: 80, height: 80, isCircle: true),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const <Widget>[
                    Column(
                      children: <Widget>[
                        ShimmerBox(width: 32, height: 18, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 44, height: 12, borderRadius: 4),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        ShimmerBox(width: 32, height: 18, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 54, height: 12, borderRadius: 4),
                      ],
                    ),
                    Column(
                      children: <Widget>[
                        ShimmerBox(width: 32, height: 18, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 54, height: 12, borderRadius: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name and bio
          const ShimmerBox(width: 140, height: 16, borderRadius: 4),
          const SizedBox(height: 8),
          const ShimmerBox(width: 240, height: 12, borderRadius: 4),
          const SizedBox(height: 6),
          const ShimmerBox(width: 180, height: 12, borderRadius: 4),
          const SizedBox(height: 20),
          // Action buttons (Follow & Message)
          Row(
            children: const <Widget>[
              Expanded(
                child: ShimmerBox(height: 42, borderRadius: 24),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ShimmerBox(height: 42, borderRadius: 24),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Tabs row
          Row(
            children: const <Widget>[
              Expanded(
                child: Center(
                  child: ShimmerBox(width: 80, height: 28, borderRadius: 8),
                ),
              ),
              Expanded(
                child: Center(
                  child: ShimmerBox(width: 80, height: 28, borderRadius: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Media grid skeleton
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: 6,
            itemBuilder: (BuildContext context, int index) =>
                const ShimmerBox(borderRadius: 12),
          ),
        ],
      ),
    );
  }
}

class _ProfilePostsFeedShimmer extends StatelessWidget {
  const _ProfilePostsFeedShimmer();

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return AppShimmer(
      child: Column(
        children: List<Widget>.generate(2, (int index) {
          return Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: const <Widget>[
                    ShimmerBox(width: 40, height: 40, isCircle: true),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ShimmerBox(width: 110, height: 14, borderRadius: 4),
                        SizedBox(height: 6),
                        ShimmerBox(width: 60, height: 10, borderRadius: 4),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const ShimmerBox(width: double.infinity, height: 220, borderRadius: 12),
                const SizedBox(height: 12),
                const ShimmerBox(width: 180, height: 12, borderRadius: 4),
              ],
            ),
          );
        }),
      ),
    );
  }
}

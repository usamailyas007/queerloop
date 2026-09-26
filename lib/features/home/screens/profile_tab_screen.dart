import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../auth/auth_provider.dart';
import '../../profile/provider/profile_provider.dart';
import '../../notifications/provider/notifications_provider.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../profile/screens/followers_following_screen.dart';
import '../../profile/screens/notifications_screen.dart';
import '../../profile/screens/settings_screen.dart';
import '../../profile/widgets/profile_feed_tabs_widget.dart';
import '../../profile/widgets/profile_header_stats_widget.dart';
import '../../profile/widgets/profile_media_grid_widget.dart';
import '../provider/home_feed_provider.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/post_feed_card.dart';
import '../models/post_item_model.dart';
import '../services/reel_video_preloader.dart';

class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({this.showBackButton = false, super.key});

  final bool showBackButton;

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  int _selectedTabIndex = 0; // Default: Posts

  @override
  void initState() {
    super.initState();
    ReelVideoPreloader.instance.setFeedVisible(false);
    ReelVideoPreloader.instance.pauseAll();
    ReelVideoPreloader.instance.muteAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReelVideoPreloader.instance.pauseAll();
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    final String? userId = context.read<AuthProvider>().userId;
    if (userId != null && userId.isNotEmpty) {
      final ProfileProvider profile = context.read<ProfileProvider>();
      await profile.fetchProfile(userId);
      if (!mounted) return;
      // Fetch following and followers so all screens know our relationships
      profile.loadFollowing(userId);
      profile.loadFollowers(userId);
      // Preload saved and liked posts in the background so tabs load instantly without flash
      profile.fetchSavedPosts();
      profile.fetchLikedPosts();
      if (_selectedTabIndex == 2) {
        await profile.fetchSavedPosts(force: true);
      } else if (_selectedTabIndex == 3) {
        await profile.fetchLikedPosts(force: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final ProfileProvider profileProvider = context.watch<ProfileProvider>();
    final String username = profileProvider.username;
    final String displayUsername =
        username.startsWith('@') ? username : '@$username';

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  if (widget.showBackButton) ...<Widget>[
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.only(right: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
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
                  ],
                  Text(
                    displayUsername,
                    style: AppTextStyles.titleLarge.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SvgPicture.asset(
                    AppIcons.password,
                    width: 14,
                    height: 14,
                    colorFilter: ColorFilter.mode(
                      context.themeTextSecondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  const Spacer(),

                  // Bell Icon (Notifications) -> Opens NotificationsScreen
                  Consumer<NotificationsProvider>(
                    builder: (BuildContext context, NotificationsProvider notifProvider, _) {
                      final int unread = notifProvider.unreadCount;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: <Widget>[
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : context.themeBorder,
                                  width: 1.1,
                                ),
                              ),
                              child: Center(
                                child: SvgPicture.asset(
                                  AppIcons.bell,
                                  width: 18,
                                  height: 18,
                                  colorFilter: ColorFilter.mode(
                                    context.themeTextPrimary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            if (unread > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradientButton,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: context.themeBackground,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Text(
                                    unread > 99 ? '99+' : '$unread',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Settings Icon -> Opens Settings
                  GestureDetector(
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : context.themeBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          AppIcons.settings,
                          width: 18,
                          height: 18,
                          colorFilter: ColorFilter.mode(
                            context.themeTextPrimary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Profile Body ─────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadProfile,
                color: AppColors.gradientPink,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: <Widget>[
                    // Profile Header & Stats Widget with Dynamic API Data
                    ProfileHeaderStatsWidget(
                      avatarAsset: (profileProvider.avatarUrl.isNotEmpty)
                          ? profileProvider.avatarUrl
                          : (context.watch<AuthProvider>().user?.avatarUrl ?? ''),
                      name: profileProvider.displayName,
                      bio: profileProvider.bio,
                      pronounsPill: profileProvider.pronounsFormatted,
                      pronounsList: profileProvider.pronouns,
                      interestsList: profileProvider.interests,
                      communitiesList: profileProvider.userCommunities,
                      identityList: profileProvider.identities,
                      postsCount: profileProvider.postsCount,
                      followersCount: profileProvider.followersCount,
                      followingCount: profileProvider.followingCount,
                      onFollowersTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const FollowersFollowingScreen(
                              initialTabIndex: 0,
                            ),
                          ),
                        );
                      },
                      onFollowingTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const FollowersFollowingScreen(
                              initialTabIndex: 1,
                            ),
                          ),
                        );
                      },
                      actionButtons: Row(
                        children: <Widget>[
                          Expanded(
                            child: AppOutlineButton(
                              text: 'Edit profile',
                              onPressed: () async {
                                await Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => const EditProfileScreen(),
                                  ),
                                );
                                _loadProfile();
                              },
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppOutlineButton(
                              text: 'Share profile',
                              onPressed: () {
                                final String handle = profileProvider.username;
                                final String name = profileProvider.displayName;
                                SharePlus.instance.share(
                                  ShareParams(
                                    text:
                                        'Check out @$handle on QueerLoop+! https://queerloop.app/profile/$handle',
                                    subject:
                                        'QueerLoop+ Profile - $name (@$handle)',
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  // Profile Feed Tabs (Posts, Reels, Saved, Liked)
                  ProfileFeedTabsWidget(
                    selectedIndex: _selectedTabIndex,
                    isOwnProfile: true,
                    onTabSelected: (int index) {
                      if (index == 2) {
                        context.read<ProfileProvider>().fetchSavedPosts();
                      } else if (index == 3) {
                        context.read<ProfileProvider>().fetchLikedPosts();
                      }
                      setState(() => _selectedTabIndex = index);
                    },
                  ),

                  // Tab 0: Posts (Photo & Text)
                  if (_selectedTabIndex == 0) ...<Widget>[
                    if (profileProvider.userPosts.isEmpty)
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
                              Icons.article_outlined,
                              size: 44,
                              color: isDark ? Colors.white30 : Colors.black26,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No posts yet',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Photos and text updates you share will appear here.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                color: context.themeTextMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...profileProvider.userPosts.map(
                        (post) {
                          final bool isLiked = context.watch<HomeFeedProvider>().isPostLiked(post.id) || post.isLiked;
                          final bool isSaved = context.watch<HomeFeedProvider>().isPostSaved(post.id) || post.isSaved;
                          final PostItemModel resolvedPost = post.copyWith(
                            isLiked: isLiked,
                            isSaved: isSaved,
                            hideLikes: profileProvider.hideMyLikes,
                          );

                          return PostFeedCard(
                            post: resolvedPost,
                            onCardTap: () {
                              PostFeedCard.openFullscreen(context, resolvedPost);
                            },
                            onLikeToggle: () {
                              final bool currentLiked =
                                  context.read<HomeFeedProvider>().isPostLiked(post.id) || post.isLiked;
                              final bool newLiked = !currentLiked;
                              final int newCount = post.hasLikeCount
                                  ? (newLiked
                                      ? post.likesCount + 1
                                      : (post.likesCount > 0 ? post.likesCount - 1 : 0))
                                  : post.likesCount;
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
                                  context.read<HomeFeedProvider>().isPostSaved(post.id) || post.isSaved;
                              final bool newSaved = !currentSaved;
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
                                totalComments: post.commentsCount,
                                postId: post.id,
                                postAuthorId: post.authorId ??
                                    context.read<AuthProvider>().userId ??
                                    context.read<ProfileProvider>().profile?.id,
                                communityId: post.communityId,
                                allowComments: post.allowComments,
                                allowCommentsFrom: post.allowCommentsFrom,
                                authorUsername: post.authorName ??
                                    context.read<ProfileProvider>().username,
                                onCommentAdded: () {
                                  context.read<HomeFeedProvider>().incrementCommentCount(post.id);
                                  context.read<ProfileProvider>().updatePostCommentCount(
                                    post.id,
                                    post.commentsCount + 1,
                                  );
                                },
                                onCommentDeleted: (int deletedCount, int remainingCount) {
                                  context.read<HomeFeedProvider>().setCommentCount(post.id, remainingCount);
                                  context.read<ProfileProvider>().updatePostCommentCount(
                                    post.id,
                                    remainingCount,
                                  );
                                },
                                onCommentCountChanged: (int count) {
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

                  // Tab 1: Reels Grid (Video posts)
                  if (_selectedTabIndex == 1)
                    ProfileMediaGridWidget(
                      customReels: profileProvider.userReels,
                      showPlayCounts: true,
                    ),

                  // Tab 2: Saved Grid & Posts
                  if (_selectedTabIndex == 2) ...<Widget>[
                    if ((!profileProvider.hasFetchedSaved ||
                            profileProvider.isLoadingSaved) &&
                        profileProvider.savedReels.isEmpty &&
                        profileProvider.savedPosts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gradientPink,
                          ),
                        ),
                      )
                    else if (profileProvider.savedReels.isEmpty &&
                        profileProvider.savedPosts.isEmpty)
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
                              color: isDark ? Colors.white30 : Colors.black26,
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
                      if (profileProvider.savedReels.isNotEmpty)
                        ProfileMediaGridWidget(
                          customReels: profileProvider.savedReels,
                          showPlayCounts: true,
                          emptyTitle: 'No saved reels yet',
                          emptySubtitle: 'Reels you save will appear here.',
                          emptyIcon: Icons.bookmark_border_rounded,
                        ),
                      if (profileProvider.savedPosts.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        ...profileProvider.savedPosts.map(
                          (post) {
                            final bool isLiked = context.watch<HomeFeedProvider>().isPostLiked(post.id) || post.isLiked;
                            final bool isSaved = context.watch<HomeFeedProvider>().isPostSaved(post.id) || post.isSaved;
                            final PostItemModel resolvedPost = post.copyWith(isLiked: isLiked, isSaved: isSaved);

                            return PostFeedCard(
                              post: resolvedPost,
                              onCardTap: () {
                                PostFeedCard.openFullscreen(context, resolvedPost);
                              },
                              onLikeToggle: () {
                                final bool currentLiked =
                                    context.read<HomeFeedProvider>().isPostLiked(post.id) || post.isLiked;
                                final bool newLiked = !currentLiked;
                                final int newCount = post.hasLikeCount
                                    ? (newLiked
                                        ? post.likesCount + 1
                                        : (post.likesCount > 0 ? post.likesCount - 1 : 0))
                                    : post.likesCount;
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
                                    context.read<HomeFeedProvider>().isPostSaved(post.id) || post.isSaved;
                                final bool newSaved = !currentSaved;
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
                                  totalComments: post.commentsCount,
                                  postId: post.id,
                                  postAuthorId: post.authorId ??
                                      context.read<AuthProvider>().userId ??
                                      context.read<ProfileProvider>().profile?.id,
                                  communityId: post.communityId,
                                  allowComments: post.allowComments,
                                  allowCommentsFrom: post.allowCommentsFrom,
                                  authorUsername: post.authorName ??
                                      context.read<ProfileProvider>().username,
                                  onCommentAdded: () {
                                    context.read<HomeFeedProvider>().incrementCommentCount(post.id);
                                    context.read<ProfileProvider>().updatePostCommentCount(
                                      post.id,
                                      post.commentsCount + 1,
                                    );
                                  },
                                  onCommentDeleted: (int deletedCount, int remainingCount) {
                                    context.read<HomeFeedProvider>().setCommentCount(post.id, remainingCount);
                                    context.read<ProfileProvider>().updatePostCommentCount(
                                      post.id,
                                      remainingCount,
                                    );
                                  },
                                  onCommentCountChanged: (int count) {
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

                  // Tab 3: Liked Grid & Posts
                  if (_selectedTabIndex == 3) ...<Widget>[
                    if ((!profileProvider.hasFetchedLiked ||
                            profileProvider.isLoadingLiked) &&
                        profileProvider.likedReels.isEmpty &&
                        profileProvider.likedPosts.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gradientPink,
                          ),
                        ),
                      )
                    else if (profileProvider.likedReels.isEmpty &&
                        profileProvider.likedPosts.isEmpty)
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
                              color: isDark ? Colors.white30 : Colors.black26,
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
                      if (profileProvider.likedReels.isNotEmpty)
                        ProfileMediaGridWidget(
                          customReels: profileProvider.likedReels,
                          showPlayCounts: true,
                          emptyTitle: 'No liked reels yet',
                          emptySubtitle: 'Reels you like will appear here.',
                          emptyIcon: Icons.favorite_border_rounded,
                        ),
                      if (profileProvider.likedPosts.isNotEmpty) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        ...profileProvider.likedPosts.map(
                          (post) {
                            final bool isLiked = context.watch<HomeFeedProvider>().isPostLiked(post.id) || post.isLiked;
                            final bool isSaved = context.watch<HomeFeedProvider>().isPostSaved(post.id) || post.isSaved;
                            final PostItemModel resolvedPost = post.copyWith(isLiked: isLiked, isSaved: isSaved);

                            return PostFeedCard(
                              post: resolvedPost,
                              onCardTap: () {
                                PostFeedCard.openFullscreen(context, resolvedPost);
                              },
                              onLikeToggle: () {
                                final bool currentLiked =
                                    context.read<HomeFeedProvider>().isPostLiked(post.id) || post.isLiked;
                                final bool newLiked = !currentLiked;
                                final int newCount = post.hasLikeCount
                                    ? (newLiked
                                        ? post.likesCount + 1
                                        : (post.likesCount > 0 ? post.likesCount - 1 : 0))
                                    : post.likesCount;
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
                                    context.read<HomeFeedProvider>().isPostSaved(post.id) || post.isSaved;
                                final bool newSaved = !currentSaved;
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
                                  totalComments: post.commentsCount,
                                  postId: post.id,
                                  postAuthorId: post.authorId ??
                                      context.read<AuthProvider>().userId ??
                                      context.read<ProfileProvider>().profile?.id,
                                  communityId: post.communityId,
                                  allowComments: post.allowComments,
                                  allowCommentsFrom: post.allowCommentsFrom,
                                  authorUsername: post.authorName ??
                                      context.read<ProfileProvider>().username,
                                  onCommentAdded: () {
                                    context.read<HomeFeedProvider>().incrementCommentCount(post.id);
                                    context.read<ProfileProvider>().updatePostCommentCount(
                                      post.id,
                                      post.commentsCount + 1,
                                    );
                                  },
                                  onCommentDeleted: (int deletedCount, int remainingCount) {
                                    context.read<HomeFeedProvider>().setCommentCount(post.id, remainingCount);
                                    context.read<ProfileProvider>().updatePostCommentCount(
                                      post.id,
                                      remainingCount,
                                    );
                                  },
                                  onCommentCountChanged: (int count) {
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

                  // Extra Bottom Safety Clearance for Floating Nav Bar
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
}

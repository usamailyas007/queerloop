import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_follow_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_provider.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/post_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../screens/profile_tab_screen.dart';
import 'safety_bottom_sheet.dart';

class PostFeedCard extends StatelessWidget {
  const PostFeedCard({
    required this.post,
    required this.onLikeToggle,
    required this.onSaveToggle,
    required this.onOpenComments,
    this.isFollowing = false,
    this.onFollowToggle,
    super.key,
  });

  final PostItemModel post;
  final VoidCallback onLikeToggle;
  final VoidCallback onSaveToggle;
  final VoidCallback onOpenComments;
  final bool isFollowing;
  final VoidCallback? onFollowToggle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = context.isDarkMode;

    final AuthProvider auth = context.read<AuthProvider>();
    final ProfileProvider profileProvider = context.read<ProfileProvider>();
    final String? currentUserId = auth.userId ?? profileProvider.profile?.id;
    final String? authorId = post.authorId;
    final String myUsername = (auth.user?.displayName ?? profileProvider.username)
        .replaceAll('@', '')
        .trim()
        .toLowerCase();
    final String postUsername =
        post.username.replaceAll('@', '').trim().toLowerCase();
    final bool isCurrentUser = (authorId != null &&
            currentUserId != null &&
            authorId.trim().toLowerCase() ==
                currentUserId.trim().toLowerCase()) ||
        (myUsername.isNotEmpty && postUsername == myUsername);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: context.themeBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Header Row (Avatar + Handle + Pronouns/Time) ──
          GestureDetector(
            onTap: () {
              if (isCurrentUser) {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ProfileTabScreen(),
                  ),
                );
              } else {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => UserProfileScreen(
                      userId: post.authorId,
                      username: post.username.replaceAll('@', ''),
                      name: post.username.replaceAll('@', '').split('.').first,
                      avatarAsset: post.avatarAsset,
                    ),
                  ),
                );
              }
            },
            child: Row(
              children: <Widget>[
                ClipOval(
                  child: (post.avatarAsset.startsWith('http://') ||
                          post.avatarAsset.startsWith('https://'))
                      ? Image.network(
                          post.avatarAsset,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Image.asset(
                            AppImages.user1,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          post.avatarAsset.trim().startsWith('assets/')
                              ? post.avatarAsset.trim()
                              : AppImages.user1,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Image.asset(
                            AppImages.user1,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        post.username,
                        style: TextStyle(
                          color: context.themeTextPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        post.pronounsTime,
                        style: TextStyle(
                          color: context.themeTextMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isCurrentUser && onFollowToggle != null) ...<Widget>[
                  const SizedBox(width: 8),
                  AppFollowButton(
                    isFollowing: isFollowing,
                    onTap: onFollowToggle!,
                  ),
                ] else if (isCurrentUser) ...<Widget>[
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: context.themeIconMuted,
                      size: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: context.themeBorder),
                    ),
                    color: context.themeCardBackground,
                    onSelected: (String value) {
                      if (value == 'delete') {
                        _confirmDeletePost(context);
                      }
                    },
                    itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'delete',
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Delete Post',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // ── Content Body Text ─────────────────────────────────────────────
          Text(
            post.content,
            style: TextStyle(
              color: context.themeTextPrimary,
              fontSize: 14,
              height: 1.4,
            ),
          ),

          // ── Optional Post Attached Image ──────────────────────────────────
          if (post.postImageUrl != null &&
              post.postImageUrl!.trim().isNotEmpty &&
              (post.postImageUrl!.startsWith('http://') ||
                  post.postImageUrl!.startsWith('https://'))) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                post.postImageUrl!.trim(),
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 220,
                    width: double.infinity,
                    color: context.isDarkMode ? Colors.white10 : Colors.black12,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (_, _, _) => ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    AppImages.searchResult1,
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ] else if (post.postImageAsset != null &&
              post.postImageAsset!.trim().isNotEmpty) ...<Widget>[
            if (post.postImageAsset!.trim().startsWith('http://') ||
                post.postImageAsset!.trim().startsWith('https://')) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  post.postImageAsset!.trim(),
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppImages.searchResult1,
                      width: double.infinity,
                      height: 220,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ] else if (post.postImageAsset!.trim().startsWith('assets/')) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  post.postImageAsset!.trim(),
                  width: double.infinity,
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      AppImages.forYouImg,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Bottom Action Row (Like + Comment + Save + Safety Badge) ─────
          Row(
            children: <Widget>[
              // Like Action (liked-logo.png / unlike-logo.png)
              GestureDetector(
                onTap: onLikeToggle,
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      post.isLiked ? AppIcons.likedLogo : AppIcons.unlikeLogo,
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.likesCount > 1000 ? '${(post.likesCount / 1000).toStringAsFixed(1)}K' : post.likesCount}',
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Comment Action (Opens Comments Bottom Sheet)
              GestureDetector(
                onTap: onOpenComments,
                child: Row(
                  children: <Widget>[
                    SvgPicture.asset(
                      AppIcons.comment,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        context.themeTextSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${post.commentsCount}',
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 20),

              // Save Action
              GestureDetector(
                onTap: onSaveToggle,
                child: SvgPicture.asset(
                  AppIcons.save,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    post.isSaved
                        ? AppColors.gradientCyan
                        : context.themeTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),

              const Spacer(),

              // Safety Badge Pill
              GestureDetector(
                onTap: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext context) {
                      return SafetyBottomSheet(
                        username: post.username,
                        postId: post.id,
                        authorId: post.authorId ?? post.username,
                        communityId: post.communityId,
                        isReel: false,
                        isCreator: isCurrentUser,
                      );
                    },
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: context.themeBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SvgPicture.asset(
                        AppIcons.safety,
                        width: 14,
                        height: 14,
                        colorFilter: const ColorFilter.mode(
                          AppColors.gradientCyan,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.homeSafety,
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeletePost(BuildContext context) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: ctx.themeCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ctx.themeBorder),
        ),
        title: Text(
          'Delete Post',
          style: TextStyle(
            color: ctx.themeTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this post? This action cannot be undone.',
          style: TextStyle(color: ctx.themeTextSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.themeTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final ProfileProvider profile = context.read<ProfileProvider>();
      final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
      final bool ok1 = await profile.deletePost(post.id);
      final bool ok2 = await homeFeed.deletePost(post.id);
      if (context.mounted) {
        if (ok1 || ok2) {
          AppSnackBar.showSuccess(
            context,
            title: 'Post Deleted',
            subtitle: 'Your post was successfully deleted.',
          );
        } else {
          AppSnackBar.show(
            context,
            title: 'Error',
            subtitle: 'Failed to delete post. Please try again.',
            type: SnackBarType.error,
          );
        }
      }
    }
  }
}

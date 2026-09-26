import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
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
import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../../../core/services/media_download_service.dart';
import '../screens/post_fullscreen_image_viewer_screen.dart';
import '../screens/profile_tab_screen.dart';
import '../screens/reels_feed_view.dart';
import '../../create_post/models/create_post_models.dart';
import '../../../core/cache/user_relationship_cache.dart';
import '../../discover/provider/discover_provider.dart';
import 'safety_bottom_sheet.dart';
import 'send_to_bottom_sheet.dart';
import 'share_this_post_bottom_sheet.dart';

class PostFeedCard extends StatelessWidget {
  const PostFeedCard({
    required this.post,
    required this.onLikeToggle,
    required this.onSaveToggle,
    required this.onOpenComments,
    this.isFollowing = false,
    this.onFollowToggle,
    this.onCardTap,
    this.onPostDeleted,
    super.key,
  });

  final PostItemModel post;
  final VoidCallback onLikeToggle;
  final VoidCallback onSaveToggle;
  final VoidCallback onOpenComments;
  final bool isFollowing;
  final VoidCallback? onFollowToggle;
  final VoidCallback? onCardTap;
  final VoidCallback? onPostDeleted;

  static void openFullscreen(BuildContext context, PostItemModel post) {
    final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
    final ProfileProvider profile = context.read<ProfileProvider>();
    final bool isLiked = homeFeed.isPostLiked(post.id) || profile.isPostLiked(post.id) || post.isLiked;
    final bool isSaved = homeFeed.isPostSaved(post.id) || profile.isPostSaved(post.id) || post.isSaved;
    final int commentsCount = homeFeed.getCommentCount(post.id) ?? profile.getCommentCount(post.id) ?? post.commentsCount;
    final int likesCount = post.likesCount;
    final PostItemModel resolvedPost = post.copyWith(
      isLiked: isLiked,
      isSaved: isSaved,
      likesCount: likesCount,
      commentsCount: commentsCount,
    );

    final bool isVideo = post.videoUrl != null ||
        post.postType.toUpperCase() == 'VIDEO' ||
        post.postType.toLowerCase() == 'reel';
    if (isVideo) {
      final String clean = post.videoUrl ?? post.postImageUrl ?? '';
      final ReelItemModel reel = ReelItemModel(
        id: post.id,
        authorId: post.authorId,
        authorDisplayName: post.authorDisplayName ?? post.username,
        username: post.username,
        pronounsTime: post.pronounsTime,
        avatarAsset: post.avatarAsset,
        videoAsset: '',
        videoUrl: clean.startsWith('http') ? clean : post.postImageUrl,
        thumbnailUrl: (post.postImageUrl != null &&
                post.postImageUrl!.startsWith('http'))
            ? post.postImageUrl
            : (clean.startsWith('http') ? clean : null),
        caption: post.content,
        likesCount: likesCount,
        commentsCount: commentsCount,
        isLiked: isLiked,
        isSaved: isSaved,
        hideLikes: post.hideLikes,
        communityId: post.communityId,
      );
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext routeContext) => Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: <Widget>[
                ReelsFeedView(
                  initialPage: 0,
                  customReels: <ReelItemModel>[reel],
                  hasBottomBar: false,
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(routeContext).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => PostFullscreenImageViewerScreen(post: resolvedPost),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = context.isDarkMode;

    final AuthProvider auth = context.read<AuthProvider>();
    final ProfileProvider profileProvider = context.watch<ProfileProvider>();
    final HomeFeedProvider homeFeed = context.watch<HomeFeedProvider>();
    final bool effectiveLiked =
        homeFeed.isPostLiked(post.id) || profileProvider.isPostLiked(post.id) || post.isLiked;
    final bool effectiveSaved =
        homeFeed.isPostSaved(post.id) || profileProvider.isPostSaved(post.id) || post.isSaved;
    final int effectiveLikesCount = (!post.isLiked && effectiveLiked)
        ? (post.likesCount > 0 ? post.likesCount + 1 : 1)
        : (post.isLiked && !effectiveLiked
            ? (post.likesCount > 0 ? post.likesCount - 1 : 0)
            : post.likesCount);
    final int effectiveCommentsCount =
        homeFeed.getCommentCount(post.id) ?? profileProvider.getCommentCount(post.id) ?? post.commentsCount;

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

    final AuthorInfo? cachedAuthor =
        (authorId != null && authorId.isNotEmpty) ? AuthorProfileCache.get(authorId) : null;
    final bool authorHidesLikes = post.hideLikes || (cachedAuthor?.hideMyLikes == true);
    final bool myProfileHidesLikes = profileProvider.hideMyLikes;
    final bool shouldHideLikes = !isCurrentUser &&
        (authorHidesLikes ||
            (authorId != null &&
                currentUserId != null &&
                authorId.trim().toLowerCase() == currentUserId.trim().toLowerCase() &&
                myProfileHidesLikes));

    final Widget card = Container(
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
                      name: (post.authorDisplayName != null &&
                              post.authorDisplayName!.trim().isNotEmpty)
                          ? post.authorDisplayName!.trim()
                          : post.username.replaceAll('@', '').split('.').first,
                      avatarAsset: post.avatarAsset,
                      initialPost: post,
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
                      Row(
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              (post.authorDisplayName != null &&
                                      post.authorDisplayName!.trim().isNotEmpty)
                                  ? post.authorDisplayName!.trim()
                                  : post.username,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: context.themeTextPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (post.authorDisplayName != null &&
                              post.authorDisplayName!.trim().isNotEmpty &&
                              post.authorDisplayName!.trim().toLowerCase() !=
                                  post.username
                                      .replaceAll('@', '')
                                      .trim()
                                      .toLowerCase()) ...<Widget>[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                post.username,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.themeTextMuted,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
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
                ],
                const SizedBox(width: 4),
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
                    if (value == 'download') {
                      final String raw = post.videoUrl ?? post.postImageUrl ?? post.postImageAsset ?? '';
                      final String resolved = _resolveImageUrl(raw);
                      MediaDownloadService.downloadMedia(
                        context: context,
                        mediaUrl: resolved.isNotEmpty ? resolved : raw,
                        title: post.username,
                        authorId: post.authorId,
                        isVideo: post.videoUrl != null,
                        allowDownloads: post.allowDownloads,
                        isCreator: isCurrentUser,
                      );
                    } else if (value == 'share') {
                      _openShareBottomSheet(context);
                    } else if (value == 'delete') {
                      _confirmDeletePost(context);
                    }
                  },
                  itemBuilder: (BuildContext ctx) => <PopupMenuEntry<String>>[
                    if ((post.postImageUrl != null || post.postImageAsset != null || post.videoUrl != null) &&
                        post.allowDownloads)
                      PopupMenuItem<String>(
                        value: 'download',
                        child: Row(
                          children: <Widget>[
                            Icon(
                              Icons.download_rounded,
                              color: context.themeIcon,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Download',
                              style: TextStyle(
                                color: context.themeTextPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    PopupMenuItem<String>(
                      value: 'share',
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.share_outlined,
                            color: context.themeIcon,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Share',
                            style: TextStyle(
                              color: context.themeTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentUser)
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
            ),
          ),

          // ── Content Body Text ─────────────────────────────────────────────
          if (post.content.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Text(
              post.content,
              style: TextStyle(
                color: context.themeTextPrimary,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ],

          // ── Optional Post Attached Image ──────────────────────────────────
          if (post.postType.toUpperCase().trim() != 'TEXT' &&
              post.postImageUrl != null &&
              post.postImageUrl!.trim().isNotEmpty) ...<Widget>[
            _buildAttachedImage(context, post.postImageUrl!),
          ] else if (post.postType.toUpperCase().trim() != 'TEXT' &&
              post.postImageAsset != null &&
              post.postImageAsset!.trim().isNotEmpty) ...<Widget>[
            _buildAttachedImage(context, post.postImageAsset!),
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Bottom Action Row (Like + Comment + Save + Safety Badge) ─────
          Row(
            children: <Widget>[
              GestureDetector(
                onTap: onLikeToggle,
                child: Row(
                  children: <Widget>[
                    Image.asset(
                      effectiveLiked ? AppIcons.likedLogo : AppIcons.unlikeLogo,
                      width: 22,
                      height: 22,
                    ),
                    if (!shouldHideLikes && post.hasLikeCount && effectiveLikesCount > 0) ...<Widget>[
                      const SizedBox(width: 6),
                      Text(
                        '${effectiveLikesCount > 1000 ? '${(effectiveLikesCount / 1000).toStringAsFixed(1)}K' : effectiveLikesCount}',
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              if (post.allowComments) ...<Widget>[
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
                        '$effectiveCommentsCount',
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(width: 20),

              // Share Action
              GestureDetector(
                onTap: () => _openShareBottomSheet(context),
                child: SvgPicture.asset(
                  AppIcons.share,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    context.themeTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
              ),

              const SizedBox(width: 20),

              // Save Action
              GestureDetector(
                onTap: onSaveToggle,
                child: Icon(
                  effectiveSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  size: 22,
                  color: effectiveSaved
                      ? AppColors.gradientCyan
                      : context.themeTextSecondary,
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

    return GestureDetector(
      onTap: onCardTap ?? () => openFullscreen(context, post),
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }

  void _openShareBottomSheet(BuildContext context) {
    final AuthProvider auth = context.read<AuthProvider>();
    final String? currentUserId = auth.userId;
    final String? authorId = post.authorId;
    final bool isCurrentUser = authorId != null &&
        currentUserId != null &&
        authorId.trim().toLowerCase() == currentUserId.trim().toLowerCase();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => ShareThisPostBottomSheet(
        post: post,
        postId: post.id,
        postAuthor: post.username,
        postThumbnail: post.postImageUrl ?? post.postImageAsset,
        mediaUrl: post.videoUrl ?? post.postImageUrl ?? post.postImageAsset,
        allowDownloads: post.allowDownloads,
        onOpenMoreSendTo: () {
          Navigator.pop(ctx);
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SendToBottomSheet(
              postId: post.id,
              postAuthor: post.username,
              postThumbnail: post.postImageUrl ?? post.postImageAsset,
              postCaption: post.content,
            ),
          );
        },
        onOpenReportSafety: () {
          Navigator.pop(ctx);
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => SafetyBottomSheet(
              username: post.username,
              postId: post.id,
              authorId: post.authorId ?? post.username,
              communityId: post.communityId,
              isReel: false,
              isCreator: isCurrentUser,
            ),
          );
        },
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
      DeletedPostsRegistry.markDeleted(post.id);
      try {
        context.read<DiscoverProvider>().notifyPostDeleted(post.id);
      } catch (_) {}
      onPostDeleted?.call();
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

  String _resolveImageUrl(String rawUrl) {
    final String clean = rawUrl.trim();
    if (clean.isEmpty) return '';
    if (clean.startsWith('assets/') ||
        clean.startsWith('http://') ||
        clean.startsWith('https://')) {
      if (clean.contains('/videos/processed/') && clean.endsWith('/master.m3u8')) {
        return clean.replaceAll('/master.m3u8', '/thumb.0000000.jpg');
      }
      if (clean.contains('/videos/processed/') && clean.endsWith('/thumbnail.jpg')) {
        return clean.replaceAll('/thumbnail.jpg', '/thumb.0000000.jpg');
      }
      return clean;
    }
    final String cleanId = clean
        .replaceAll(RegExp(r'^/+'), '')
        .replaceAll(RegExp(r'^media/'), '');

    final bool isVid = post.postType.toUpperCase() == 'VIDEO' ||
        post.postType.toLowerCase() == 'reel' ||
        clean.contains('video') ||
        clean.contains('/videos/');

    if (isVid) {
      return '${AppConfig.cdnUrl}/videos/processed/$cleanId/thumb.0000000.jpg';
    }

    if (post.authorId != null && post.authorId!.isNotEmpty) {
      return '${AppConfig.cdnUrl}/images/original/${post.authorId}/$cleanId.jpg';
    }
    return '${AppConfig.cdnUrl}/images/original/$cleanId.jpg';
  }

  Widget _buildAttachedImage(BuildContext context, String rawUrl) {
    final String clean = rawUrl.trim();
    if (clean.isEmpty) return const SizedBox.shrink();

    final Widget imageWidget;
    if (clean.startsWith('assets/')) {
      imageWidget = Image.asset(
        clean,
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: double.infinity,
          height: 220,
          color: context.isDarkMode ? Colors.white10 : Colors.black12,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white24,
              size: 36,
            ),
          ),
        ),
      );
    } else if (!clean.startsWith('http://') &&
        !clean.startsWith('https://') &&
        File(clean).existsSync()) {
      imageWidget = Image.file(
        File(clean),
        width: double.infinity,
        height: 220,
        fit: BoxFit.cover,
      );
    } else {
      final String networkUrl = _resolveImageUrl(clean);

      imageWidget = Image.network(
        networkUrl,
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.gradientPink,
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => Container(
          width: double.infinity,
          height: 220,
          color: context.isDarkMode ? Colors.white10 : Colors.black12,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white24,
              size: 36,
            ),
          ),
        ),
      );
    }

    final bool isPhoto = post.postType.toUpperCase() == 'PHOTO';
    final bool isVideo = !isPhoto &&
        (post.postType.toUpperCase() == 'VIDEO' ||
            post.postType.toLowerCase() == 'reel' ||
            (post.postImageUrl != null &&
                (post.postImageUrl!.endsWith('.mp4') ||
                    post.postImageUrl!.endsWith('.m3u8') ||
                    post.postImageUrl!.contains('video') ||
                    post.postImageUrl!.contains('/videos/'))) ||
            clean.endsWith('.mp4') ||
            clean.endsWith('.m3u8') ||
            clean.contains('video') ||
            clean.contains('/videos/'));

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: GestureDetector(
        onTap: () => openFullscreen(context, post),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              imageWidget,
              if (isVideo)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white70, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 34,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/widgets/app_follow_button.dart';
import '../../../core/widgets/app_user_avatar.dart';
import '../../auth/auth_provider.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/post_item_model.dart';
import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../../../core/services/media_download_service.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/safety_bottom_sheet.dart';
import '../widgets/send_to_bottom_sheet.dart';
import '../widgets/share_this_post_bottom_sheet.dart';
import 'profile_tab_screen.dart';

class PostFullscreenImageViewerScreen extends StatefulWidget {
  const PostFullscreenImageViewerScreen({
    required this.post,
    this.heroTag,
    super.key,
  });

  final PostItemModel post;
  final String? heroTag;

  @override
  State<PostFullscreenImageViewerScreen> createState() =>
      _PostFullscreenImageViewerScreenState();
}

class _PostFullscreenImageViewerScreenState
    extends State<PostFullscreenImageViewerScreen>
    with SingleTickerProviderStateMixin {
  late PostItemModel _post;
  bool _showOverlay = true;

  // Double-tap heart animation
  late AnimationController _heartAnimController;
  late Animation<double> _heartScaleAnim;
  bool _showDoubleTapHeart = false;

  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _post = widget.post;

    _heartAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _heartScaleAnim = Tween<double>(begin: 0.5, end: 1.3).animate(
      CurvedAnimation(
        parent: _heartAnimController,
        curve: Curves.elasticOut,
      ),
    );

    // Record view if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        context.read<HomeFeedProvider>().recordView(_post.id);
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _heartAnimController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _toggleOverlay() {
    setState(() {
      _showOverlay = !_showOverlay;
    });
  }

  void _onDoubleTap() {
    if (!_post.isLiked) {
      _handleLikeToggle();
    }
    setState(() => _showDoubleTapHeart = true);
    _heartAnimController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _showDoubleTapHeart = false);
      }
    });
  }

  void _handleLikeToggle() {
    final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
    final ProfileProvider profile = context.read<ProfileProvider>();

    final bool newLiked = !_post.isLiked;
    final int newCount =
        newLiked ? _post.likesCount + 1 : (_post.likesCount > 0 ? _post.likesCount - 1 : 0);

    setState(() {
      _post = _post.copyWith(
        isLiked: newLiked,
        likesCount: newCount,
      );
    });

    try {
      homeFeed.toggleLikePost(_post.id);
      profile.updateLikedPost(_post.id, isLiked: newLiked, likesCount: newCount);
    } catch (_) {}
  }

  void _handleSaveToggle() {
    final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
    final bool newSaved = !_post.isSaved;

    setState(() {
      _post = _post.copyWith(isSaved: newSaved);
    });

    try {
      homeFeed.toggleSavePost(_post.id);
    } catch (_) {}
  }

  void _handleOpenComments() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentsBottomSheet(
        postId: _post.id,
        postAuthorId: _post.authorId,
        totalComments: _post.commentsCount,
        onCommentAdded: () {
          setState(() {
            _post = _post.copyWith(commentsCount: _post.commentsCount + 1);
          });
          try {
            context.read<HomeFeedProvider>().incrementCommentCount(_post.id);
          } catch (_) {}
        },
      ),
    );
  }

  void _handleOpenShare() {
    final ReelItemModel reelEquivalent = ReelItemModel(
      id: _post.id,
      authorId: _post.authorId,
      username: _post.username,
      pronounsTime: _post.pronounsTime,
      avatarAsset: _post.avatarAsset,
      videoAsset: '',
      videoUrl: '',
      thumbnailUrl: _post.postImageUrl,
      caption: _post.content,
      likesCount: _post.likesCount,
      commentsCount: _post.commentsCount,
      isLiked: _post.isLiked,
      isSaved: _post.isSaved,
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return ShareThisPostBottomSheet(
          post: _post,
          reel: reelEquivalent,
          postId: _post.id,
          postAuthor: _post.username,
          postThumbnail: _post.postImageUrl ?? _post.postImageAsset,
          mediaUrl: _post.videoUrl ?? _post.postImageUrl ?? _post.postImageAsset,
          allowDownloads: _post.allowDownloads,
          onOpenMoreSendTo: () {
            Navigator.pop(ctx);
            _handleOpenSendTo(reelEquivalent);
          },
          onOpenReportSafety: () {
            Navigator.pop(ctx);
            _handleOpenSafety();
          },
        );
      },
    );
  }

  void _handleDownload() {
    final AuthProvider auth = context.read<AuthProvider>();
    final bool isCreator = (_post.authorId != null &&
        auth.userId != null &&
        _post.authorId!.toLowerCase() == auth.userId!.toLowerCase());
    MediaDownloadService.downloadMedia(
      context: context,
      mediaUrl: _post.videoUrl ?? _post.postImageUrl ?? _post.postImageAsset,
      title: _post.username,
      isVideo: _post.videoUrl != null,
      allowDownloads: _post.allowDownloads,
      isCreator: isCreator,
    );
  }

  void _handleOpenSendTo(ReelItemModel reel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SendToBottomSheet(reel: reel),
    );
  }

  Future<void> _handleOpenSafety() async {
    final AuthProvider auth = context.read<AuthProvider>();
    final ProfileProvider profile = context.read<ProfileProvider>();
    final String? currentUserId = auth.userId ?? profile.profile?.id;
    final bool isCreator = _post.authorId != null &&
        currentUserId != null &&
        _post.authorId!.trim().toLowerCase() == currentUserId.trim().toLowerCase();

    final dynamic deleted = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafetyBottomSheet(
        username: _post.username,
        postId: _post.id,
        authorId: _post.authorId ?? _post.username,
        communityId: _post.communityId,
        isReel: false,
        isCreator: isCreator,
      ),
    );

    if (deleted == true && mounted) {
      Navigator.pop(context);
    }
  }

  void _navigateToAuthorProfile() {
    final AuthProvider auth = context.read<AuthProvider>();
    final String? currentUserId = auth.userId;
    final bool isCurrentUser = _post.authorId != null &&
        currentUserId != null &&
        _post.authorId!.trim().toLowerCase() == currentUserId.trim().toLowerCase();

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
            userId: _post.authorId,
            username: _post.username.replaceAll('@', ''),
            name: _post.username.replaceAll('@', '').split('.').first,
            avatarAsset: _post.avatarAsset,
          ),
        ),
      );
    }
  }

  String _resolveImageUrl(String raw) {
    final String clean = raw.trim();
    if (clean.isEmpty) return '';
    if (clean.startsWith('assets/') ||
        clean.startsWith('http://') ||
        clean.startsWith('https://')) {
      return clean;
    }
    final String cleanId = clean
        .replaceAll(RegExp(r'^/+'), '')
        .replaceAll(RegExp(r'^media/'), '');
    if (_post.authorId != null && _post.authorId!.isNotEmpty) {
      return '${AppConfig.cdnUrl}/images/original/${_post.authorId}/$cleanId.jpg';
    }
    final String base = AppConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/media/$cleanId';
  }

  @override
  Widget build(BuildContext context) {
    final ProfileProvider profileProvider = context.watch<ProfileProvider>();
    final AuthProvider authProvider = context.watch<AuthProvider>();
    final String? currentUserId = authProvider.userId;
    final bool isCurrentUser = _post.authorId != null &&
        currentUserId != null &&
        _post.authorId!.trim().toLowerCase() == currentUserId.trim().toLowerCase();

    final bool isFollowing = profileProvider.isFollowingUser(
      userId: _post.authorId,
      username: _post.username,
    );

    final String imageSource =
        _resolveImageUrl(_post.postImageUrl ?? _post.postImageAsset ?? '');

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // ── 1. Fullscreen Interactive Image ────────────────────────────────
          GestureDetector(
            onTap: _toggleOverlay,
            onDoubleTap: _onDoubleTap,
            child: Center(
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 1.0,
                maxScale: 4.0,
                clipBehavior: Clip.none,
                child: imageSource.isEmpty
                    ? Image.asset(AppImages.forYouImg, fit: BoxFit.contain)
                    : imageSource.startsWith('assets/')
                        ? Image.asset(
                            imageSource,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => Image.asset(
                              AppImages.forYouImg,
                              fit: BoxFit.contain,
                            ),
                          )
                        : Image.network(
                            imageSource,
                            fit: BoxFit.contain,
                            loadingBuilder: (
                              BuildContext ctx,
                              Widget child,
                              ImageChunkEvent? progress,
                            ) {
                              if (progress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: AppColors.gradientCyan,
                                ),
                              );
                            },
                            errorBuilder: (_, _, _) => Image.asset(
                              AppImages.searchResult1,
                              fit: BoxFit.contain,
                            ),
                          ),
              ),
            ),
          ),

          // ── 2. Double-Tap Animated Heart ───────────────────────────────────
          if (_showDoubleTapHeart)
            Center(
              child: ScaleTransition(
                scale: _heartScaleAnim,
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.redAccent,
                  size: 110,
                ),
              ),
            ),

          // ── 3. Gradient Overlays for Readability ───────────────────────────
          IgnorePointer(
            ignoring: true,
            child: AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // Top shadow gradient
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Colors.black87,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Bottom shadow gradient
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 220,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: <Color>[
                            Colors.black87,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 4. Top Action Bar (Close / Back button) ────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: AnimatedOpacity(
                opacity: _showOverlay ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── 5. Right Action Bar (Reel / Facebook Style) ───────────────────
          Positioned(
            right: 14,
            bottom: 34,
            child: AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Like Button
                  _ViewerActionButton(
                    onTap: _handleLikeToggle,
                    label: '${_post.likesCount}',
                    child: Image.asset(
                      _post.isLiked ? AppIcons.likedLogo : AppIcons.unlikeLogo,
                      width: 28,
                      height: 28,
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Comment Button
                  _ViewerActionButton(
                    onTap: _handleOpenComments,
                    label: '${_post.commentsCount}',
                    child: SvgPicture.asset(
                      AppIcons.comment,
                      width: 26,
                      height: 26,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),

                  if (_post.allowDownloads) ...<Widget>[
                    const SizedBox(height: 18),

                    // Download Button
                    _ViewerActionButton(
                      onTap: _handleDownload,
                      label: 'Download',
                      child: const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),

                  // Share Button
                  _ViewerActionButton(
                    onTap: _handleOpenShare,
                    label: 'Share',
                    child: SvgPicture.asset(
                      AppIcons.share,
                      width: 26,
                      height: 26,
                      colorFilter: const ColorFilter.mode(
                        Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Save Button
                  _ViewerActionButton(
                    onTap: _handleSaveToggle,
                    label: 'Save',
                    child: SvgPicture.asset(
                      AppIcons.save,
                      width: 24,
                      height: 24,
                      colorFilter: ColorFilter.mode(
                        _post.isSaved ? AppColors.gradientCyan : Colors.white,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Safety / Report Button
                  GestureDetector(
                    onTap: _handleOpenSafety,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SvgPicture.asset(
                            AppIcons.safety,
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Safety',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 6. Bottom-Left Details (Author Info & Caption) ────────────────
          Positioned(
            left: 16,
            right: 84,
            bottom: 34,
            child: AnimatedOpacity(
              opacity: _showOverlay ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // Author Info Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      GestureDetector(
                        onTap: _navigateToAuthorProfile,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            AppUserAvatar(
                              imageAsset: _post.avatarAsset,
                              size: 40,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  _post.username,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    shadows: <Shadow>[
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _post.pronounsTime,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    shadows: <Shadow>[
                                      Shadow(
                                        color: Colors.black,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (!isCurrentUser) ...<Widget>[
                        const SizedBox(width: 12),
                        AppFollowButton(
                          isFollowing: isFollowing,
                          isOverMedia: true,
                          onTap: () async {
                            final String? targetId = _post.authorId;
                            if (targetId != null && targetId.isNotEmpty) {
                              try {
                                if (!isFollowing) {
                                  await profileProvider.followUser(
                                    targetId,
                                    username: _post.username,
                                  );
                                } else {
                                  await profileProvider.unfollowUser(
                                    targetId,
                                    username: _post.username,
                                  );
                                }
                              } catch (_) {}
                            }
                          },
                        ),
                      ],
                    ],
                  ),

                  if (_post.content.trim().isNotEmpty) ...<Widget>[
                    const SizedBox(height: 10),
                    Text(
                      _post.content,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.35,
                        shadows: <Shadow>[
                          Shadow(color: Colors.black, blurRadius: 4),
                        ],
                      ),
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Action Button Helper ───────────────────────────────────────────────────

class _ViewerActionButton extends StatelessWidget {
  const _ViewerActionButton({
    required this.child,
    required this.label,
    required this.onTap,
  });

  final Widget child;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          child,
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              shadows: <Shadow>[Shadow(color: Colors.black, blurRadius: 4)],
            ),
          ),
        ],
      ),
    );
  }
}

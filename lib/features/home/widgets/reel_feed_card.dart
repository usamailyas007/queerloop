import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_follow_button.dart';
import '../../../core/widgets/app_user_avatar.dart';
import '../../../l10n/app_localizations.dart';
import '../models/reel_item_model.dart';

class ReelFeedCard extends StatefulWidget {
  const ReelFeedCard({
    required this.reel,
    required this.onLikeToggle,
    required this.onSaveToggle,
    required this.onFollowToggle,
    required this.onOpenComments,
    required this.onOpenShare,
    required this.onOpenSafety,
    required this.onOpenFilterCommunities,
    this.showCommunityFilterTag = false,
    this.selectedCommunity = 'All Communities',
    this.isActive = true,
    this.hasBottomBar = true,
    super.key,
  });

  final ReelItemModel reel;
  final VoidCallback onLikeToggle;
  final VoidCallback onSaveToggle;
  final VoidCallback onFollowToggle;
  final VoidCallback onOpenComments;
  final VoidCallback onOpenShare;
  final VoidCallback onOpenSafety;
  final VoidCallback onOpenFilterCommunities;
  final bool showCommunityFilterTag;
  final String selectedCommunity;
  /// Whether this card is the currently visible page (controls auto-play).
  final bool isActive;
  final bool hasBottomBar;

  @override
  State<ReelFeedCard> createState() => _ReelFeedCardState();
}

class _ReelFeedCardState extends State<ReelFeedCard>
    with SingleTickerProviderStateMixin {
  // ── Video player ────────────────────────────────────────────────────────
  late VideoPlayerController _videoController;
  bool _videoInitialized = false;
  bool _isPaused = false;

  // ── Double-tap heart animation ───────────────────────────────────────────
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  bool _showDoubleTapHeart = false;

  @override
  void initState() {
    super.initState();

    // Heart animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = Tween<double>(begin: 0.5, end: 1.3).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );

    // Video
    _initVideo();
  }

  Future<void> _initVideo() async {
    final String? filePath = widget.reel.videoFilePath;
    if (filePath != null && filePath.isNotEmpty) {
      _videoController = VideoPlayerController.file(File(filePath));
    } else {
      _videoController = VideoPlayerController.asset(widget.reel.videoAsset);
    }
    await _videoController.initialize();
    _videoController.setLooping(true);
    _videoController.setVolume(1.0);
    if (mounted) {
      setState(() => _videoInitialized = true);
      if (widget.isActive) {
        _videoController.play();
      }
    }
  }

  @override
  void didUpdateWidget(ReelFeedCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_videoInitialized) return;
    if (widget.isActive && !oldWidget.isActive) {
      _videoController.play();
      setState(() => _isPaused = false);
    } else if (!widget.isActive && oldWidget.isActive) {
      _videoController.pause();
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_videoInitialized) return;
    setState(() {
      _isPaused = !_isPaused;
      _isPaused ? _videoController.pause() : _videoController.play();
    });
  }

  void _handleDoubleTap() {
    if (!widget.reel.isLiked) widget.onLikeToggle();
    setState(() => _showDoubleTapHeart = true);
    _animController.forward(from: 0.0).then((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) setState(() => _showDoubleTapHeart = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ReelItemModel item = widget.reel;
    final double viewPaddingBottom = MediaQuery.of(context).viewPadding.bottom;
    final double paddingBottom = MediaQuery.of(context).padding.bottom;
    final double systemBottomInset =
        viewPaddingBottom > paddingBottom ? viewPaddingBottom : paddingBottom;
    final double rightActionsBottom =
        (widget.hasBottomBar ? 110 : 28) + systemBottomInset;
    final double leftDetailsBottom =
        (widget.hasBottomBar ? 100 : 20) + systemBottomInset;
    final AppLocalizations l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: _handleTap,
      onDoubleTap: _handleDoubleTap,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // ── 1. Video Player (full-bleed, cover-fit) ───────────────────────
          _videoInitialized
              ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _videoController.value.size.width,
                      height: _videoController.value.size.height,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                )
              : Container(
                  color: Colors.black,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white30,
                      strokeWidth: 2,
                    ),
                  ),
                ),

          // ── 2. Top & Bottom Dark Gradient Overlay ─────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.black.withValues(alpha: 0.6),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.85),
                ],
                stops: const <double>[0.0, 0.20, 0.60, 1.0],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // ── 3. Pause Icon (shows briefly when tapped) ─────────────────────
          if (_isPaused)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.pause_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

          // ── 4. Double-Tap Heart Animation ─────────────────────────────────
          if (_showDoubleTapHeart)
            Center(
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Image.asset(AppIcons.likedLogo, width: 80, height: 80),
              ),
            ),

          // ── 5. Video Progress Bar (bottom edge, above overlay) ────────────
          if (_videoInitialized)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(
                _videoController,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: AppColors.gradientPink,
                  bufferedColor: Colors.white24,
                  backgroundColor: Colors.white12,
                ),
                padding: EdgeInsets.zero,
              ),
            ),

          // ── 6. Right Side Action Bar ───────────────────────────────────────
          Positioned(
            right: 14,
            bottom: rightActionsBottom,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Like
                _RightActionButton(
                  onTap: widget.onLikeToggle,
                  label: '${item.likesCount}',
                  child: Image.asset(
                    item.isLiked ? AppIcons.likedLogo : AppIcons.unlikeLogo,
                    width: 28,
                    height: 28,
                  ),
                ),

                const SizedBox(height: 18),

                // Comment
                _RightActionButton(
                  onTap: widget.onOpenComments,
                  label: '${item.commentsCount}',
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

                const SizedBox(height: 18),

                // Share
                _RightActionButton(
                  onTap: widget.onOpenShare,
                  label: l10n.homeShare,
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

                // Save
                _RightActionButton(
                  onTap: widget.onSaveToggle,
                  label: l10n.homeSave,
                  child: SvgPicture.asset(
                    AppIcons.save,
                    width: 24,
                    height: 24,
                    colorFilter: ColorFilter.mode(
                      item.isSaved ? AppColors.gradientCyan : Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                // Safety
                GestureDetector(
                  onTap: widget.onOpenSafety,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        SvgPicture.asset(
                          AppIcons.safety,
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.homeSafety,
                          style: const TextStyle(
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

          // ── 7. Bottom-Left Details (tags, user info, caption) ─────────────
          Positioned(
            left: 16,
            right: 80,
            bottom: leftDetailsBottom,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Tags row
                if (widget.showCommunityFilterTag) ...<Widget>[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.secondaryGradientButton,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Lesbian · community only',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: widget.onOpenFilterCommunities,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text(
                                  widget.selectedCommunity,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ] else ...<Widget>[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        if (item.tags.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Text(
                              item.tags.first,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        if (item.durationText.isNotEmpty) ...<Widget>[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SvgPicture.asset(
                                  AppIcons.play,
                                  width: 10,
                                  height: 10,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  item.durationText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],

                // User info row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    AppUserAvatar(imageAsset: item.avatarAsset, size: 38),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          item.pronounsTime,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    AppFollowButton(
                      isFollowing: item.isFollowing,
                      isOverMedia: true,
                      onTap: widget.onFollowToggle,
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Caption
                Text(
                  item.caption,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.35,
                    shadows: <Shadow>[
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Right Action Button ────────────────────────────────────────────────────

class _RightActionButton extends StatelessWidget {
  const _RightActionButton({
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

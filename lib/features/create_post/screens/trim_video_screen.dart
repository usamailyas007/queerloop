import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../models/create_post_models.dart';
import '../provider/create_post_provider.dart';
import '../widgets/media_thumbnail_widget.dart';
import 'new_post_form_screen.dart';

class TrimVideoScreen extends StatefulWidget {
  const TrimVideoScreen({super.key});

  @override
  State<TrimVideoScreen> createState() => _TrimVideoScreenState();
}

class _TrimVideoScreenState extends State<TrimVideoScreen> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final CreatePostProvider provider = context.read<CreatePostProvider>();
      _setupVideoController(provider.selectedMedia);
    });
  }

  Future<void> _setupVideoController(GalleryMediaItem? item) async {
    if (item == null) return;
    await _controller?.dispose();

    final String? filePath = item.filePath;
    final String? videoAsset = item.videoAsset;

    VideoPlayerController ctrl;
    if (filePath != null && filePath.isNotEmpty) {
      ctrl = VideoPlayerController.file(File(filePath));
    } else if (videoAsset != null && videoAsset.isNotEmpty) {
      ctrl = VideoPlayerController.asset(videoAsset);
    } else {
      ctrl = VideoPlayerController.asset('assets/videos/video1.mp4');
    }

    try {
      await ctrl.initialize();
      ctrl.setLooping(true);
      if (mounted) {
        setState(() {
          _controller = ctrl;
          _isInitialized = true;
          _isPlaying = true;
        });
        ctrl.play();
      }
    } catch (e) {
      debugPrint('Error initializing video in TrimVideoScreen: $e');
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  void _seekToTrimStart(double trimRatio, int totalDurationSeconds) {
    if (_controller == null || !_isInitialized) return;
    final int targetSec = (trimRatio * totalDurationSeconds).round();
    _controller!.seekTo(Duration(seconds: targetSec));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CreatePostProvider provider = context.watch<CreatePostProvider>();
    final GalleryMediaItem? selectedItem = provider.selectedMedia;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Top Bar (Back, Title "Trim", Done button) ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Circular Back Button <
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'Trim',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // Done Button -> Navigates to NewPostFormScreen
                  AppGradientButton(
                    text: 'Done',
                    onPressed: () {
                      _controller?.pause();
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const NewPostFormScreen(),
                        ),
                      ).then((_) {
                        if (mounted && _isPlaying) {
                          _controller?.play();
                        }
                      });
                    },
                    height: 32,
                    width: 70,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Video Preview Section ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Container(
                height: 330,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: GestureDetector(
                    onTap: _togglePlayPause,
                    child: Stack(
                      fit: StackFit.expand,
                      children: <Widget>[
                        // Video Player or Thumbnail fallback
                        if (_isInitialized && _controller != null)
                          SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controller!.value.size.width,
                                height: _controller!.value.size.height,
                                child: VideoPlayer(_controller!),
                              ),
                            ),
                          )
                        else
                          MediaThumbnailWidget(item: selectedItem),

                        // Play/Pause center overlay
                        if (!_isPlaying)
                          Center(
                            child: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),

                        // Selected duration pill badge bottom-left
                        Positioned(
                          bottom: AppSpacing.md,
                          left: AppSpacing.md,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.75),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.cut_rounded,
                                  color: AppColors.gradientCyan,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${provider.trimStartFormatted} / ${provider.totalDurationFormatted} (${provider.selectedDurationSeconds}s)',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
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
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── DRAG THE HANDLES TO TRIM Section Header ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'DRAG THE HANDLES TO TRIM',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white54,
                  letterSpacing: 1.2,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Interactive Timeline Trim Handle Strip ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _VideoTrimTimelineStrip(
                trimStart: provider.trimStart,
                trimEnd: provider.trimEnd,
                onChanged: (double start, double end) {
                  provider.setTrimRange(start, end);
                  _seekToTrimStart(start, provider.totalDurationSeconds);
                },
                item: selectedItem,
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // ── Time range counters below timeline ──────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    provider.trimStartFormatted,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gradientPink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${provider.selectedDurationSeconds}s selected',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gradientPink,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Text(
                    provider.totalDurationFormatted,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _VideoTrimTimelineStrip extends StatefulWidget {
  const _VideoTrimTimelineStrip({
    required this.trimStart,
    required this.trimEnd,
    required this.onChanged,
    required this.item,
  });

  final double trimStart;
  final double trimEnd;
  final void Function(double start, double end) onChanged;
  final GalleryMediaItem? item;

  @override
  State<_VideoTrimTimelineStrip> createState() =>
      _VideoTrimTimelineStripState();
}

class _VideoTrimTimelineStripState extends State<_VideoTrimTimelineStrip> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double width = constraints.maxWidth;
        const double stripHeight = 52;
        const double handleWidth = 14;

        final double leftPos = widget.trimStart * (width - handleWidth * 2);
        final double rightPos =
            widget.trimEnd * (width - handleWidth * 2) + handleWidth;

        return SizedBox(
          height: stripHeight,
          child: Stack(
            children: <Widget>[
              // Filmstrip background (repeat thumbnails)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: List<Widget>.generate(
                      5,
                      (int i) => Expanded(
                        child: MediaThumbnailWidget(
                          item: widget.item,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // Unselected left dim overlay
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: leftPos.clamp(0, width),
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),

              // Unselected right dim overlay
              Positioned(
                left: (rightPos + handleWidth).clamp(0, width),
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.65),
                ),
              ),

              // Selected active frame border (Pink outline)
              Positioned(
                left: leftPos,
                right: width - (rightPos + handleWidth),
                top: 0,
                bottom: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: AppColors.gradientPink,
                        width: 3,
                      ),
                    ),
                  ),
                ),
              ),

              // Left Pink Draggable Handle
              Positioned(
                left: leftPos,
                top: 0,
                bottom: 0,
                width: handleWidth,
                child: GestureDetector(
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    final double deltaRatio =
                        details.delta.dx / (width - handleWidth * 2);
                    final double newStart = (widget.trimStart + deltaRatio)
                        .clamp(0.0, widget.trimEnd - 0.05);
                    widget.onChanged(newStart, widget.trimEnd);
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.gradientPink,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(6),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ),
              ),

              // Right Pink Draggable Handle
              Positioned(
                left: rightPos,
                top: 0,
                bottom: 0,
                width: handleWidth,
                child: GestureDetector(
                  onHorizontalDragUpdate: (DragUpdateDetails details) {
                    final double deltaRatio =
                        details.delta.dx / (width - handleWidth * 2);
                    final double newEnd = (widget.trimEnd + deltaRatio)
                        .clamp(widget.trimStart + 0.05, 1.0);
                    widget.onChanged(widget.trimStart, newEnd);
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.gradientPink,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(6),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.drag_handle_rounded,
                        color: Colors.white,
                        size: 10,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

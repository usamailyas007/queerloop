import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../models/create_post_models.dart';
import '../provider/create_post_provider.dart';
import '../widgets/media_thumbnail_widget.dart';
import 'new_post_form_screen.dart';

class TrimVideoScreen extends StatelessWidget {
  const TrimVideoScreen({super.key});

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
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              ChangeNotifierProvider<CreatePostProvider>.value(
                            value: provider,
                            child: const NewPostFormScreen(),
                          ),
                        ),
                      );
                    },
                    height: 32,
                    width: 70,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Video Preview Section (Fixed ~330px height like screenshot) ──
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
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      MediaThumbnailWidget(item: selectedItem),

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
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius:
                                BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            '${provider.trimStartFormatted} / ${provider.totalDurationFormatted} selected',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
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
                },
                thumbnailAsset: selectedItem?.assetPath ?? AppImages.forYouImg,
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
                    '0:00',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    provider.selectedDurationFormatted,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gradientPink,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    provider.totalDurationFormatted,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
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
    required this.thumbnailAsset,
  });

  final double trimStart;
  final double trimEnd;
  final void Function(double start, double end) onChanged;
  final String thumbnailAsset;

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
        const double handleWidth = 10;

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
                        child: Image.asset(
                          widget.thumbnailAsset,
                          fit: BoxFit.cover,
                          height: stripHeight,
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
                  color: Colors.black.withValues(alpha: 0.6),
                ),
              ),

              // Unselected right dim overlay
              Positioned(
                left: (rightPos + handleWidth).clamp(0, width),
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.6),
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
                        .clamp(0.0, widget.trimEnd - 0.1);
                    widget.onChanged(newStart, widget.trimEnd);
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.gradientPink,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(6),
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
                        .clamp(widget.trimStart + 0.1, 1.0);
                    widget.onChanged(widget.trimStart, newEnd);
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.gradientPink,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(6),
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

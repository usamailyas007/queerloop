import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../models/create_post_models.dart';
import '../provider/create_post_provider.dart';
import '../widgets/media_thumbnail_widget.dart';
import 'new_post_form_screen.dart';

class SelectPhotoScreen extends StatelessWidget {
  const SelectPhotoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CreatePostProvider provider = context.watch<CreatePostProvider>();
    final GalleryMediaItem? selectedItem = provider.selectedMedia;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Navigation Bar ───────────────────────────────────────
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
                    'Chosee Photo',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // Next Button
                  AppGradientButton(
                    text: 'Next',
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

            const SizedBox(height: AppSpacing.xs),

            // ── Main Photo Preview Card ──────────────────────────────────
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: MediaThumbnailWidget(item: selectedItem),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Gallery Header Row ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Choose from gallery',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                        '1 selected',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => provider.pickMediaFromDevice(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_rounded,
                            color: AppColors.gradientCyan,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Photo Gallery Grid ───────────────────────────────────────
            Expanded(
              flex: 4,
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.85,
                ),
                itemCount: provider.photoGallery.length,
                itemBuilder: (BuildContext context, int index) {
                  final GalleryMediaItem item = provider.photoGallery[index];
                  final bool isSelected = selectedItem?.id == item.id;

                  return GestureDetector(
                    onTap: () => provider.selectMedia(item),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gradientPink
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppRadius.card - 2),
                        child: MediaThumbnailWidget(item: item),
                      ),
                    ),
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

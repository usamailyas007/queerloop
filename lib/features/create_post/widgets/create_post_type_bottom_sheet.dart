import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../models/create_post_models.dart';
import '../provider/create_post_provider.dart';
import '../screens/select_photo_screen.dart';
import '../screens/select_video_screen.dart';
import '../screens/write_post_screen.dart';

class CreatePostTypeBottomSheet extends StatelessWidget {
  const CreatePostTypeBottomSheet({super.key});

  static Future<void> show(BuildContext context) async {
    context.read<CreatePostProvider>().resetPostForm();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CreatePostTypeBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final CreatePostProvider provider = context.watch<CreatePostProvider>();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomSheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Header (Title + Close X)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'New Post',
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 20),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xs),

            // Subtitle
            Text(
              'Pick what you want to share. You can add a caption and set who sees it on the next screen.',
              style: AppTextStyles.authHeaderSub.copyWith(
                color: Colors.white54,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Option 1: Video
            _MediaOptionTile(
              iconPath: AppIcons.video,
              iconColor: AppColors.gradientPink,
              title: 'Video',
              subtitle: 'Upload a video from your gallery, up to 60s',
              onTap: () {
                Navigator.pop(context);
                provider.setMediaType(MediaType.video);
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SelectVideoScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Option 2: Photo
            _MediaOptionTile(
              iconPath: AppIcons.image,
              iconColor: AppColors.gradientCyan,
              title: 'Photo',
              subtitle: 'Upload one or more photos from your gallery',
              onTap: () {
                Navigator.pop(context);
                provider.setMediaType(MediaType.photo);
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const SelectPhotoScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Option 3: Text Post
            _MediaOptionTile(
              iconPath: AppIcons.textBoard,
              iconColor: AppColors.gradientPurple,
              title: 'Text Post',
              subtitle: 'Write something, add an optional image',
              onTap: () {
                Navigator.pop(context);
                provider.setMediaType(MediaType.text);
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const WritePostScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Cancel Button
            AppOutlineButton(
              text: 'Cancel',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaOptionTile extends StatelessWidget {
  const _MediaOptionTile({
    required this.iconPath,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String iconPath;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: <Widget>[
            // Icon in rounded square
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Center(
                child: SvgPicture.asset(
                  iconPath,
                  width: 22,
                  height: 22,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Text column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

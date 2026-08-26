import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../models/create_post_models.dart';

class WhoCanSeeThisBottomSheet extends StatefulWidget {
  const WhoCanSeeThisBottomSheet({
    required this.selectedVisibility,
    required this.onSelect,
    super.key,
  });

  final PostVisibility selectedVisibility;
  final ValueChanged<PostVisibility> onSelect;

  static Future<PostVisibility?> show(
    BuildContext context, {
    required PostVisibility currentVisibility,
  }) async {
    PostVisibility selected = currentVisibility;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WhoCanSeeThisBottomSheet(
        selectedVisibility: currentVisibility,
        onSelect: (PostVisibility v) => selected = v,
      ),
    );
    return selected;
  }

  @override
  State<WhoCanSeeThisBottomSheet> createState() =>
      _WhoCanSeeThisBottomSheetState();
}

class _WhoCanSeeThisBottomSheetState
    extends State<WhoCanSeeThisBottomSheet> {
  late PostVisibility _tempSelected;

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.selectedVisibility;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: context.themeBorderStrong,
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
                  'Who can see this?',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: context.themeTextPrimary,
                    fontSize: 20,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
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
                      Icons.close_rounded,
                      color: context.themeIconMuted,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xs),

            // Subtitle
            Text(
              "Set this before you post — visibility can't be changed afterwards.",
              style: AppTextStyles.authHeaderSub.copyWith(
                color: context.themeTextSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Option 1: Everyone
            _VisibilityOptionTile(
              icon: Icons.language_rounded,
              title: 'Everyone',
              subtitle: 'Anyone on QueerLoop+, including guests',
              isSelected: _tempSelected == PostVisibility.everyone,
              onTap: () {
                setState(() => _tempSelected = PostVisibility.everyone);
                widget.onSelect(PostVisibility.everyone);
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Option 2: Followers
            _VisibilityOptionTile(
              icon: Icons.person_outline_rounded,
              title: 'Followers',
              subtitle: 'Only people who follow you',
              isSelected: _tempSelected == PostVisibility.followers,
              onTap: () {
                setState(() => _tempSelected = PostVisibility.followers);
                widget.onSelect(PostVisibility.followers);
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Option 3: Community only
            _VisibilityOptionTile(
              icon: Icons.people_outline_rounded,
              title: 'Community only',
              subtitle: 'Only members of the tagged community',
              isSelected: _tempSelected == PostVisibility.communityOnly,
              onTap: () {
                setState(() => _tempSelected = PostVisibility.communityOnly);
                widget.onSelect(PostVisibility.communityOnly);
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // Done Button
            AppGradientButton(
              text: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _VisibilityOptionTile extends StatelessWidget {
  const _VisibilityOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isSelected
                ? AppColors.gradientCyan
                : context.themeBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              icon,
              color: isSelected
                  ? AppColors.gradientCyan
                  : context.themeTextSecondary,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.themeTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_rounded,
                color: AppColors.gradientCyan,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}

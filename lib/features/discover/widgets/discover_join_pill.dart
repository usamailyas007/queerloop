import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Join / Joined pill button used on community tiles.
class DiscoverJoinPill extends StatelessWidget {
  const DiscoverJoinPill({
    required this.isJoined,
    required this.onTap,
    super.key,
  });

  final bool isJoined;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md + 2,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          gradient: isJoined ? null : AppColors.secondaryGradientButton,
          color: isJoined
              ? (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.transparent)
              : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isJoined
              ? Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : context.themeBorder,
                  width: 1.2,
                )
              : null,
        ),
        child: Text(
          isJoined ? 'Joined' : 'Join',
          style: AppTextStyles.bodySmall.copyWith(
            color: isJoined
                ? (isDark ? Colors.white54 : context.themeTextPrimary)
                : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

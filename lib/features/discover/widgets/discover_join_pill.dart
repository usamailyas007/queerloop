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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          gradient: isJoined ? null : AppColors.secondaryGradientButton,
          color: isJoined ? Colors.white.withValues(alpha: 0.1) : null,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: isJoined
              ? Border.all(color: Colors.white.withValues(alpha: 0.2))
              : null,
        ),
        child: Text(
          isJoined ? 'Joined' : 'Join',
          style: AppTextStyles.bodySmall.copyWith(
            color: isJoined ? Colors.white54 : Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

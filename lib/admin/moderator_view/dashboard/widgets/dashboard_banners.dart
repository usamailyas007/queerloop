import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Small, friendly placeholder for an empty section of the dashboard.
class DashboardEmptyHint extends StatelessWidget {
  const DashboardEmptyHint({required this.icon, required this.text, super.key});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.moderatorIconMuted, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            text,
            style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
    );
  }
}

/// Shown at the top of the dashboard when there is genuinely nothing to do.
class DashboardAllClearBanner extends StatelessWidget {
  const DashboardAllClearBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.moderatorSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.moderatorBorder),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.verified_outlined, color: AppColors.gradientCyan, size: 22),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'All clear',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.moderatorTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Nothing needs your attention right now. New reports will show up here as they come in.',
                  style: TextStyle(color: AppColors.moderatorTextMuted, fontSize: 12.5, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DashboardErrorBanner extends StatelessWidget {
  const DashboardErrorBanner({required this.message, required this.onRetry, super.key});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 12)),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onRetry,
              child: const Text(
                'Retry',
                style: TextStyle(color: AppColors.moderatorPink, fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

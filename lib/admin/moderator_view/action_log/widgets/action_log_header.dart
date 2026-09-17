import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Page title + "Refresh" button for the action log.
class ActionLogHeader extends StatelessWidget {
  const ActionLogHeader({required this.onRefresh, super.key});

  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'ACTION LOG',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.gradientCyan,
                letterSpacing: 1.2,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Action log',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Every decision is permanent and attributed.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.moderatorTextMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const Spacer(),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onRefresh,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.moderatorSurfaceAlt,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.moderatorBorder),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.refresh_rounded, size: 15, color: AppColors.moderatorTextMuted),
                  SizedBox(width: 6),
                  Text(
                    'Refresh',
                    style: TextStyle(
                      color: AppColors.moderatorTextPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

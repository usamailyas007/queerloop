import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../reports/models/mod_report.dart';

/// Title + "in queue / avg response" line + "Open queue" button.
class DashboardHeaderRow extends StatelessWidget {
  const DashboardHeaderRow({required this.dashboard, required this.onOpenQueue, super.key});

  final ModDashboard dashboard;
  final VoidCallback? onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final ModDashboard d = dashboard;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Moderator dashboard',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              d.avgResponseHours == 0
                  ? '${d.inQueue} in queue'
                  : '${d.inQueue} in queue · avg response ${d.avgResponseHours.toStringAsFixed(1)}h',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.moderatorTextMuted, fontSize: 13),
            ),
          ],
        ),
        const Spacer(),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: onOpenQueue,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: <Color>[AppColors.moderatorPink, AppColors.gradientCyan]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(Icons.flag_outlined, color: AppColors.moderatorTextPrimary, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Open queue',
                    style: TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 13),
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

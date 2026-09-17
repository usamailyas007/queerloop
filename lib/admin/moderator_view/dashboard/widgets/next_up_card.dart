import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../reports/models/mod_report.dart';
import 'dashboard_banners.dart';

/// "Reports queue · next up" preview table on the dashboard.
class NextUpCard extends StatelessWidget {
  const NextUpCard({required this.dashboard, required this.onOpen, required this.onOpenQueue, super.key});

  final ModDashboard dashboard;
  final ValueChanged<ModReport> onOpen;
  final VoidCallback? onOpenQueue;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.moderatorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.moderatorBorder),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Reports queue · next up',
                      style: TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    SizedBox(height: 2),
                    Text('Oldest and most severe first', style: TextStyle(color: AppColors.moderatorTextFaint, fontSize: 12)),
                  ],
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onOpenQueue,
                    child: const Text(
                      'Open full queue →',
                      style: TextStyle(color: AppColors.moderatorPink, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.moderatorDividerLine),
          if (dashboard.nextUp.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: DashboardEmptyHint(icon: Icons.done_all_rounded, text: 'The queue is clear. Nothing is waiting for review right now.'),
            )
          else
            for (final ModReport r in dashboard.nextUp) _NextUpRow(report: r, onOpen: onOpen),
        ],
      ),
    );
  }
}

class _NextUpRow extends StatelessWidget {
  const _NextUpRow({required this.report, required this.onOpen});

  final ModReport report;
  final ValueChanged<ModReport> onOpen;

  @override
  Widget build(BuildContext context) {
    final ModReport r = report;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md - 2),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              r.displayId,
              style: const TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(r.reasonLabel, style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(r.status.label, style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: r.badge.color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
                child: Text(r.badge.label, style: TextStyle(color: r.badge.color, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onOpen(r),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.moderatorSurfaceAlt2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.moderatorButtonBorder),
                ),
                child: const Text(
                  'Review',
                  style: TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

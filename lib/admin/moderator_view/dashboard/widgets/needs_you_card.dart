import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../reports/models/mod_report.dart';
import 'dashboard_banners.dart';
import 'dashboard_card.dart';

/// "Needs you first" — reports assigned to this moderator or unassigned.
class NeedsYouCard extends StatelessWidget {
  const NeedsYouCard({required this.dashboard, required this.onOpen, super.key});

  final ModDashboard dashboard;
  final ValueChanged<ModReport> onOpen;

  @override
  Widget build(BuildContext context) {
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Needs you first',
            style: TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 2),
          const Text('Assigned to you or unassigned', style: TextStyle(color: AppColors.moderatorTextFaint, fontSize: 12)),
          const SizedBox(height: AppSpacing.lg),
          if (dashboard.needsYouFirst.isEmpty)
            const DashboardEmptyHint(
              icon: Icons.check_circle_outline_rounded,
              text: "You're all caught up — nothing is assigned to you or waiting to be picked up.",
            )
          else
            for (final ModReport r in dashboard.needsYouFirst) _NeedsItem(report: r, onOpen: onOpen),
        ],
      ),
    );
  }
}

class _NeedsItem extends StatelessWidget {
  const _NeedsItem({required this.report, required this.onOpen});

  final ModReport report;
  final ValueChanged<ModReport> onOpen;

  @override
  Widget build(BuildContext context) {
    final ModReport r = report;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => onOpen(r),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.moderatorSurfaceAlt2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.moderatorDivider),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: r.badge.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: r.badge.color.withValues(alpha: 0.4)),
                ),
                child: Text(r.badge.label, style: TextStyle(color: r.badge.color, fontWeight: FontWeight.w700, fontSize: 11)),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${r.reasonLabel} · ${r.displayId}',
                      style: const TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(r.status.label, style: const TextStyle(color: AppColors.moderatorTextFaint, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.moderatorIconMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

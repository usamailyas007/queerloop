import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../admin_icons.dart';
import '../../analytics/models/analytics_dashboard.dart';
import '../../widgets/admin_stat_card.dart';

/// Daily active / new sign-ups / posts in range / open reports stat row.
class DashboardStatCards extends StatelessWidget {
  const DashboardStatCards({required this.dash, required this.range, super.key});

  final AnalyticsDashboard? dash;
  final String range;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AdminStatCard(
            label: 'Daily active',
            value: dash?.dailyActive != null ? '${dash!.dailyActive}' : 'N/A',
            delta: range,
            deltaColor: AppColors.adminTextMuted,
            iconPath: AdminIcons.users,
            iconColor: AppColors.adminPurple,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AdminStatCard(
            label: 'New sign-ups',
            value: '${dash?.newSignups ?? 0}',
            delta: range,
            deltaColor: AppColors.adminTextMuted,
            iconPath: AdminIcons.userSingle,
            iconColor: AppColors.adminTeal,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AdminStatCard(
            label: 'Posts in range',
            value: '${dash?.postsInRange ?? 0}',
            delta: '${(dash?.videoSharePct ?? 0.0).toStringAsFixed(0)}% video',
            deltaColor: AppColors.adminTextSecondary,
            iconPath: AdminIcons.image,
            iconColor: AppColors.adminBlue,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AdminStatCard(
            label: 'Open reports',
            value: '${dash?.openReports ?? 0}',
            valueColor: AppColors.adminOrange,
            delta: 'Avg response ${(dash?.avgResponseHours ?? 0.0).toStringAsFixed(1)}h',
            deltaColor: AppColors.adminOrange,
            iconPath: AdminIcons.shield,
            iconColor: AppColors.adminOrange,
          ),
        ),
      ],
    );
  }
}

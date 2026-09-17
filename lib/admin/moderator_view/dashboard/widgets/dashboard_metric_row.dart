import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../reports/models/mod_report.dart';

/// The four "in queue / resolved today / escalated / avg response" cards.
class DashboardMetricRow extends StatelessWidget {
  const DashboardMetricRow({required this.dashboard, super.key});

  final ModDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final ModDashboard d = dashboard;
    return Row(
      children: <Widget>[
        _MetricCard(label: 'IN QUEUE', value: '${d.inQueue}', subtext: '${d.waitingOver12h} waiting over 12h'),
        const SizedBox(width: AppSpacing.md),
        _MetricCard(
          label: 'RESOLVED TODAY',
          value: '${d.resolvedToday}',
          subtext: 'You handled ${d.resolvedTodayByMe}',
        ),
        const SizedBox(width: AppSpacing.md),
        _MetricCard(
          label: 'ESCALATED',
          value: '${d.escalated}',
          subtext: d.escalated == 0 ? 'None waiting on an admin' : '${d.escalated} waiting on an admin',
        ),
        const SizedBox(width: AppSpacing.md),
        _MetricCard(
          label: 'AVG RESPONSE',
          value: d.avgResponseHours == 0 ? '—' : '${d.avgResponseHours.toStringAsFixed(1)}h',
          subtext: 'Across the last 30 days',
          valueColor: AppColors.gradientCyan,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.subtext, this.valueColor});

  final String label;
  final String value;
  final String subtext;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.moderatorSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.moderatorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.moderatorTextFaint,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: TextStyle(color: valueColor ?? AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text(subtext, style: AppTextStyles.bodySmall.copyWith(color: AppColors.moderatorTextMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

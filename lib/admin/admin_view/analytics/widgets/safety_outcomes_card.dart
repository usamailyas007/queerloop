import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../models/analytics_overview.dart';

class SafetyOutcomesCard extends StatelessWidget {
  const SafetyOutcomesCard({required this.overview, required this.range, super.key});

  final AnalyticsOverview? overview;
  final String range;

  @override
  Widget build(BuildContext context) {
    final AnalyticsOverview? o = overview;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Safety outcomes · $range',
              style: const TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (o != null) ...<Widget>[
              _Row(label: 'Reports received', value: '${o.safetyOutcomes.received}'),
              _Row(label: 'Content hidden', value: '${o.safetyOutcomes.hidden}'),
              _Row(label: 'Accounts warned', value: '${o.safetyOutcomes.warned}'),
              _Row(label: 'Accounts suspended', value: '${o.safetyOutcomes.suspended}'),
              _Row(label: 'Accounts banned', value: '${o.safetyOutcomes.banned}'),
              _Row(label: 'In queue', value: '${o.safetyOutcomes.inQueue}'),
              _Row(
                label: 'Avg response time',
                value: '${o.safetyOutcomes.avgResponseHours.toStringAsFixed(1)}h',
              ),
              _Row(
                label: 'Appeals reversed',
                value: '${o.safetyOutcomes.appealsReversed} of ${o.safetyOutcomes.appealsTotal}',
                color: AppColors.adminGreen,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13)),
          Text(
            value,
            style: TextStyle(color: color ?? AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

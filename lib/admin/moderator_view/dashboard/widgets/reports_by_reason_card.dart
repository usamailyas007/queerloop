import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../reports/models/mod_report.dart';
import 'dashboard_banners.dart';
import 'dashboard_card.dart';

/// "Reports by reason" bar-list card.
class ReportsByReasonCard extends StatelessWidget {
  const ReportsByReasonCard({required this.dashboard, super.key});

  final ModDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final ModDashboard d = dashboard;
    final int maxCount =
        d.reportsByReason.isEmpty ? 1 : d.reportsByReason.map((ReasonCount r) => r.count).reduce((int a, int b) => a > b ? a : b);
    return DashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Reports by reason',
            style: TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 2),
          const Text('Last 7 days', style: TextStyle(color: AppColors.moderatorTextFaint, fontSize: 12)),
          const SizedBox(height: 16),
          if (d.reportsByReason.isEmpty)
            const DashboardEmptyHint(icon: Icons.inbox_outlined, text: 'No reports were filed in the last 7 days.')
          else
            for (final ReasonCount r in d.reportsByReason)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          r.label,
                          style: const TextStyle(color: AppColors.moderatorTextSecondary, fontWeight: FontWeight.w500, fontSize: 13),
                        ),
                        Text(
                          '${r.count}',
                          style: const TextStyle(color: AppColors.moderatorTextMuted, fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: r.count / maxCount,
                        minHeight: 6,
                        backgroundColor: AppColors.moderatorDivider,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.moderatorPink),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

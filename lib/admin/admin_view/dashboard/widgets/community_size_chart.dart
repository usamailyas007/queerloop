import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../analytics/models/analytics_overview.dart';
import 'dashboard_chart_card.dart';

/// "Community size" chart card — a bar per community, sized relative to the
/// largest one.
class CommunitySizeChart extends StatelessWidget {
  const CommunitySizeChart({required this.overview, super.key});

  final AnalyticsOverview? overview;

  @override
  Widget build(BuildContext context) {
    final List<CommunitySizeItem> items = overview?.communitySizes ?? const <CommunitySizeItem>[];
    final int maxMembers = items.isEmpty
        ? 1
        : items.map((CommunitySizeItem e) => e.memberCount).reduce((int a, int b) => a > b ? a : b);

    return DashboardChartCard(
      title: 'Community size',
      subtitle: 'Members per group',
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.md),
        child: items.isEmpty
            ? const Center(
                child: Text(
                  'No community size data available',
                  style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    for (final CommunitySizeItem item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    color: AppColors.adminTextPrimary,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  '${item.memberCount} members',
                                  style: const TextStyle(
                                    color: AppColors.adminTextSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(5),
                              child: LinearProgressIndicator(
                                value: maxMembers > 0 ? item.memberCount / maxMembers : 0.0,
                                minHeight: 8,
                                backgroundColor: const Color(0xFF1C1824),
                                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.adminPurple),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

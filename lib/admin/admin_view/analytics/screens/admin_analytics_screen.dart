import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../admin_icons.dart';
import '../../widgets/admin_stat_card.dart';
import '../models/analytics_overview.dart';
import '../provider/analytics_provider.dart';
import '../widgets/analytics_range_pills.dart';
import '../widgets/content_mix_card.dart';
import '../widgets/safety_outcomes_card.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnalyticsProvider>().loadInitial();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AnalyticsProvider provider = context.watch<AnalyticsProvider>();
    final AnalyticsOverview? overview = provider.overview;
    final bool loading = provider.isLoadingOverview && overview == null;

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Analytics',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Overview metrics for range: ${provider.range}',
                          style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  AnalyticsRangePills(range: provider.range, onChanged: provider.setRange),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              if (loading)
                const Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.adminPink),
                    ),
                  ),
                )
              else if (provider.overviewError != null && overview == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          provider.overviewError!,
                          style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: 120,
                          child: AppOutlineButton(text: 'Retry', height: 38, onPressed: provider.fetchOverview),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: <Widget>[
                      _StatCardsRow(overview: overview, range: provider.range),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(child: ContentMixCard(overview: overview)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: SafetyOutcomesCard(overview: overview, range: provider.range)),
                          ],
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

class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow({required this.overview, required this.range});

  final AnalyticsOverview? overview;
  final String range;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: AdminStatCard(
            label: 'Retention',
            value: overview?.retention != null ? '${overview!.retention!.toStringAsFixed(0)}%' : 'N/A',
            delta: range,
            deltaColor: AppColors.adminTextMuted,
            iconPath: AdminIcons.chart,
            iconColor: AppColors.adminGreen,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AdminStatCard(
            label: 'Avg session',
            value: overview?.avgSessionDuration != null
                ? '${overview!.avgSessionDuration!.toStringAsFixed(0)}s'
                : 'N/A',
            delta: range,
            deltaColor: AppColors.adminTextMuted,
            iconPath: AdminIcons.globe,
            iconColor: AppColors.gradientCyan,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AdminStatCard(
            label: 'Posts per person',
            value: (overview?.postsPerPerson ?? 0.0).toStringAsFixed(1),
            delta: 'Average',
            deltaColor: AppColors.adminTextMuted,
            iconPath: AdminIcons.image,
            iconColor: AppColors.adminPurpleSoft,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: AdminStatCard(
            label: 'Reports per 1k posts',
            value: (overview?.reportsPer1kPosts ?? 0.0).toStringAsFixed(0),
            delta: range,
            deltaColor: AppColors.adminOrange,
            iconPath: AdminIcons.shield,
            iconColor: AppColors.adminOrange,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../analytics/models/analytics_dashboard.dart';
import '../../analytics/models/analytics_overview.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../widgets/community_size_chart.dart';
import '../widgets/daily_active_chart.dart';
import '../widgets/dashboard_range_pills.dart';
import '../widgets/dashboard_stat_cards.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // API-recognised range values — anything else falls back to the 30d default.
  static const List<String> _rangeKeys = <String>['today', '7d', '30d'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnalyticsProvider>().loadInitial();
      }
    });
  }

  int _getRangeIndex(String key) {
    final int idx = _rangeKeys.indexOf(key);
    return idx >= 0 ? idx : 2;
  }

  @override
  Widget build(BuildContext context) {
    final AnalyticsProvider provider = context.watch<AnalyticsProvider>();
    final AnalyticsDashboard? dash = provider.dashboard;
    final AnalyticsOverview? overview = provider.overview;

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Platform overview',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                            letterSpacing: -0.52,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
                            children: <TextSpan>[
                              const TextSpan(text: 'Range: '),
                              TextSpan(
                                text: provider.range,
                                style: const TextStyle(
                                  color: AppColors.adminTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  DashboardRangePills(
                    selectedIndex: _getRangeIndex(provider.range),
                    onChanged: (int index) => provider.setRange(_rangeKeys[index]),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              DashboardStatCards(dash: dash, range: provider.range),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 486,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: DailyActiveChart(
                        dash: dash,
                        range: provider.range,
                        loading: provider.isLoadingDashboard,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(flex: 2, child: CommunitySizeChart(overview: overview)),
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

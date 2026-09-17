import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../reports/models/mod_report.dart';
import '../../reports/provider/mod_reports_provider.dart';
import '../../reports_queue/screens/moderator_case_detail_review_screen.dart';
import '../widgets/dashboard_banners.dart';
import '../widgets/dashboard_header_row.dart';
import '../widgets/dashboard_metric_row.dart';
import '../widgets/needs_you_card.dart';
import '../widgets/next_up_card.dart';
import '../widgets/reports_by_reason_card.dart';

class ModeratorDashboardScreen extends StatefulWidget {
  const ModeratorDashboardScreen({this.onOpenQueue, super.key});

  final VoidCallback? onOpenQueue;

  @override
  State<ModeratorDashboardScreen> createState() =>
      _ModeratorDashboardScreenState();
}

class _ModeratorDashboardScreenState extends State<ModeratorDashboardScreen> {
  bool _reviewing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ModReportsProvider>().loadDashboard();
      }
    });
  }

  Future<void> _open(ModReport report) async {
    await context.read<ModReportsProvider>().openReport(report: report);
    if (mounted) {
      setState(() => _reviewing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewing) {
      return ModeratorCaseDetailReviewScreen(
        onBack: () {
          setState(() => _reviewing = false);
          context.read<ModReportsProvider>().refreshDashboard();
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.moderatorBackground,
      body: SafeArea(
        child: Consumer<ModReportsProvider>(
          builder: (_, ModReportsProvider provider, _) {
            final ModDashboard d = provider.dashboard;
            final bool blank = d.inQueue == 0 &&
                d.reportsByReason.isEmpty &&
                d.needsYouFirst.isEmpty &&
                d.nextUp.isEmpty;

            if (provider.isLoadingDashboard && blank) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.moderatorPink),
              );
            }

            return RefreshIndicator(
              color: AppColors.moderatorPink,
              backgroundColor: AppColors.moderatorSurface,
              onRefresh: provider.refreshDashboard,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: <Widget>[
                  DashboardHeaderRow(dashboard: d, onOpenQueue: widget.onOpenQueue),
                  if (provider.dashboardError != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    DashboardErrorBanner(
                      message: provider.dashboardError!,
                      onRetry: provider.refreshDashboard,
                    ),
                  ] else if (blank) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    const DashboardAllClearBanner(),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  DashboardMetricRow(dashboard: d),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: ReportsByReasonCard(dashboard: d)),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(child: NeedsYouCard(dashboard: d, onOpen: _open)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  NextUpCard(dashboard: d, onOpen: _open, onOpenQueue: widget.onOpenQueue),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

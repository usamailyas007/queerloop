import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../reports/models/mod_report.dart';
import '../../reports/provider/mod_reports_provider.dart';
import '../widgets/reports_queue_header.dart';
import '../widgets/reports_queue_pagination.dart';
import '../widgets/reports_queue_table.dart';
import 'moderator_case_detail_review_screen.dart';

class ModeratorReportsQueueScreen extends StatefulWidget {
  const ModeratorReportsQueueScreen({
    super.key,
    this.title = 'Reports queue',
    this.subtitle,
    this.initialStatus,
  });

  /// Heading shown above the table.
  final String title;

  /// Optional line under the title (falls back to the count summary).
  final String? subtitle;

  /// When set, the queue opens pre-filtered to this status (used by the admin
  /// "Reports" section, which lands on escalated cases).
  final ReportStatus? initialStatus;

  @override
  State<ModeratorReportsQueueScreen> createState() =>
      _ModeratorReportsQueueScreenState();
}

class _ModeratorReportsQueueScreenState
    extends State<ModeratorReportsQueueScreen> {
  bool _reviewing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final ModReportsProvider provider = context.read<ModReportsProvider>();
      if (widget.initialStatus != null) {
        provider.setStatusFilter(widget.initialStatus);
      } else {
        provider.loadQueue();
      }
    });
  }

  Future<void> _openReport(ModReport report) async {
    await context.read<ModReportsProvider>().openReport(report: report);
    if (mounted) {
      setState(() => _reviewing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewing) {
      return ModeratorCaseDetailReviewScreen(
        onBack: () => setState(() => _reviewing = false),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.moderatorBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ReportsQueueHeader(title: widget.title, subtitle: widget.subtitle),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Consumer<ModReportsProvider>(
                  builder: (_, ModReportsProvider p, _) => Container(
                    decoration: BoxDecoration(
                      color: AppColors.moderatorSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.moderatorBorder),
                    ),
                    child: Column(
                      children: <Widget>[
                        Expanded(
                          child: ReportsQueueTable(provider: p, onOpen: _openReport),
                        ),
                        const ReportsQueuePagination(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

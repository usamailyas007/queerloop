import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../admin_view/widgets/admin_table_column_header.dart';
import '../../reports/models/mod_report.dart';
import '../../reports/provider/mod_reports_provider.dart';

/// Reports table: header row + scrollable, openable body. The caller owns
/// the surrounding bordered card (so a pagination bar can share its bottom
/// edge without a double border).
class ReportsQueueTable extends StatelessWidget {
  const ReportsQueueTable({required this.provider, required this.onOpen, super.key});

  final ModReportsProvider provider;
  final ValueChanged<ModReport> onOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const _TableHeader(),
        Expanded(child: _QueueBody(provider: provider, onOpen: onOpen)),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md - 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.moderatorDivider)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 2, child: _H('CASE')),
          Expanded(flex: 3, child: _H('REASON')),
          Expanded(flex: 2, child: _H('TARGET')),
          Expanded(flex: 2, child: _H('STATUS')),
          Expanded(flex: 1, child: _H('AGE')),
          Expanded(flex: 2, child: _H('BADGE')),
          SizedBox(width: 84),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => AdminTableColumnHeader(label, color: AppColors.moderatorTextFaint);
}

class _QueueBody extends StatelessWidget {
  const _QueueBody({required this.provider, required this.onOpen});

  final ModReportsProvider provider;
  final ValueChanged<ModReport> onOpen;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingQueue && provider.reports.isEmpty) {
      return const Center(
        child: SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.moderatorPink)),
      );
    }
    if (provider.queueError != null && provider.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(provider.queueError!, style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 13)),
            const SizedBox(height: AppSpacing.md),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: provider.refreshQueue,
                child: const Text('Retry', style: TextStyle(color: AppColors.moderatorPink, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      );
    }
    if (provider.isQueueEmpty) {
      return const Center(
        child: Text('No reports match these filters.', style: TextStyle(color: AppColors.moderatorTextFaint, fontSize: 13)),
      );
    }

    return Stack(
      children: <Widget>[
        ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: provider.reports.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.moderatorRowDivider),
          itemBuilder: (_, int i) => _Row(report: provider.reports[i], onOpen: onOpen),
        ),
        if (provider.isLoadingQueue)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2, color: AppColors.moderatorPink, backgroundColor: Colors.transparent),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.report, required this.onOpen});

  final ModReport report;
  final ValueChanged<ModReport> onOpen;

  static String _age(DateTime t) {
    final Duration d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md - 2),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              report.displayId,
              style: const TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(report.reasonLabel, style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(report.targetType, style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(report.status.label, style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 13)),
          ),
          Expanded(
            flex: 1,
            child: Text(_age(report.createdAt), style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: report.badge.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: report.badge.color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  report.badge.label,
                  style: TextStyle(color: report.badge.color, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onOpen(report),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.moderatorSurfaceAlt2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.moderatorTextPrimary.withValues(alpha: 0.12)),
                  ),
                  child: const Text(
                    'Review',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

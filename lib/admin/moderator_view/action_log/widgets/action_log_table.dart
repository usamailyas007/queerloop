import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../admin_view/widgets/admin_table_column_header.dart';
import '../../reports/models/mod_report.dart';
import '../../reports/provider/mod_reports_provider.dart';

/// Action-log table: header row + filtered, scrollable body.
class ActionLogTable extends StatelessWidget {
  const ActionLogTable({
    required this.provider,
    required this.mineOnly,
    required this.myId,
    super.key,
  });

  final ModReportsProvider provider;
  final bool mineOnly;
  final String? myId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.moderatorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.moderatorBorder),
      ),
      child: Column(
        children: <Widget>[
          const _TableHeader(),
          Expanded(child: _Body(provider: provider, mineOnly: mineOnly, myId: myId)),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.moderatorDivider)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 2, child: _H('WHEN')),
          Expanded(flex: 2, child: _H('CASE')),
          Expanded(flex: 2, child: _H('MODERATOR')),
          Expanded(flex: 2, child: _H('ACTION')),
          Expanded(flex: 2, child: _H('ACCOUNT')),
          Expanded(flex: 4, child: _H('NOTE')),
        ],
      ),
    );
  }
}

class _H extends StatelessWidget {
  const _H(this.label);
  final String label;

  @override
  Widget build(BuildContext context) =>
      AdminTableColumnHeader(label, color: AppColors.moderatorTextFaint);
}

class _Body extends StatelessWidget {
  const _Body({required this.provider, required this.mineOnly, required this.myId});

  final ModReportsProvider provider;
  final bool mineOnly;
  final String? myId;

  static final DateFormat _when = DateFormat('d MMM · h:mm a');

  Color _actionColor(ModReport r) {
    return switch (r.decision) {
      ModDecision.hideContent || ModDecision.ban => AppColors.danger,
      ModDecision.warn || ModDecision.mute || ModDecision.suspend => AppColors.warning,
      ModDecision.escalate => AppColors.moderatorPurple,
      ModDecision.reversed => AppColors.moderatorGreen,
      ModDecision.noAction => AppColors.moderatorGray,
      null => AppColors.moderatorGray,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingActionLog && provider.actionLog.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.moderatorPink),
        ),
      );
    }
    if (provider.actionLogError != null && provider.actionLog.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              provider.actionLogError!,
              style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.md),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: provider.refreshActionLog,
                child: const Text(
                  'Retry',
                  style: TextStyle(color: AppColors.moderatorPink, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final List<ModReport> rows = mineOnly && myId != null
        ? provider.actionLog.where((ModReport r) => r.assignedTo == myId).toList()
        : provider.actionLog;

    if (rows.isEmpty) {
      return Center(
        child: Text(
          mineOnly ? "You haven't logged any actions yet." : 'No actions logged yet.',
          style: const TextStyle(color: AppColors.moderatorTextFaint, fontSize: 13),
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.moderatorPink,
      backgroundColor: AppColors.moderatorSurface,
      onRefresh: provider.refreshActionLog,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rows.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.moderatorRowDivider),
        itemBuilder: (_, int i) =>
            _Row(report: rows[i], myId: myId, when: _when, color: _actionColor(rows[i])),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.report,
    required this.myId,
    required this.when,
    required this.color,
  });

  final ModReport report;
  final String? myId;
  final DateFormat when;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ModReport r = report;
    final bool mine = myId != null && r.assignedTo == myId;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              when.format((r.resolvedAt ?? r.createdAt).toLocal()),
              style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              r.displayId,
              style: const TextStyle(
                color: AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              mine ? 'You' : (r.assignedTo == null ? '—' : '#${r.assignedTo!.substring(0, 8)}'),
              style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  r.decision?.title ?? r.status.label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              r.targetOwnerId == null ? '—' : '#${r.targetOwnerId!.substring(0, 8)}',
              style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              r.moderatorNote ?? '—',
              style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../reports/mod_reports_service.dart';
import '../../reports/models/mod_report.dart';
import '../../reports/provider/mod_reports_provider.dart';
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
              _Header(title: widget.title, subtitle: widget.subtitle),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.moderatorSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.moderatorBorder),
                  ),
                  child: Column(
                    children: <Widget>[
                      const _TableHeader(),
                      Expanded(
                        child: Consumer<ModReportsProvider>(
                          builder: (_, ModReportsProvider p, _) => _QueueBody(
                            provider: p,
                            onOpen: _openReport,
                          ),
                        ),
                      ),
                      const _PaginationBar(),
                    ],
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

class _Header extends StatelessWidget {
  const _Header({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ModReportsProvider provider = context.watch<ModReportsProvider>();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle ??
                  '${provider.total} total · sorted ${provider.sort.name}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.moderatorTextMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const Spacer(),
        SizedBox(
          width: 240,
          child: AppTextField(
            hintText: 'Search case ID, account, note…',
            prefixIconPath: AppIcons.searchSvg,
            fillColor: AppColors.moderatorSurfaceAlt,
            onChanged: (String v) =>
                context.read<ModReportsProvider>().setSearch(v),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _Pill(
          selected: provider.urgentOnly,
          label: 'Urgent only',
          onTap: () => context
              .read<ModReportsProvider>()
              .setUrgentOnly(!provider.urgentOnly),
        ),
        const SizedBox(width: AppSpacing.md),
        _StatusMenu(current: provider.statusFilter),
        const SizedBox(width: AppSpacing.md),
        _SortMenu(current: provider.sort),
      ],
    );
  }
}

class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.current});

  final ReportStatus? current;

  static String _label(ReportStatus? s) =>
      s == null ? 'All statuses' : s.label;

  @override
  Widget build(BuildContext context) {
    const List<ReportStatus?> options = <ReportStatus?>[
      null,
      ReportStatus.open,
      ReportStatus.inReview,
      ReportStatus.escalated,
      ReportStatus.resolved,
    ];
    return PopupMenuButton<int>(
      color: AppColors.moderatorSurfaceAlt,
      onSelected: (int i) =>
          context.read<ModReportsProvider>().setStatusFilter(options[i]),
      itemBuilder: (_) => <PopupMenuEntry<int>>[
        for (int i = 0; i < options.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Text(
              _label(options[i]),
              style: const TextStyle(color: AppColors.moderatorTextPrimary),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.moderatorSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.moderatorBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              _label(current),
              style: const TextStyle(
                color: AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const Icon(Icons.expand_more,
                size: 16, color: AppColors.moderatorTextMuted),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.moderatorChipSelected
              : AppColors.moderatorSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.moderatorBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected
                ? AppColors.moderatorTextPrimary
                : AppColors.moderatorTextMuted,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.current});

  final ModReportSort current;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ModReportSort>(
      color: AppColors.moderatorSurfaceAlt,
      onSelected: (ModReportSort s) =>
          context.read<ModReportsProvider>().setSort(s),
      itemBuilder: (_) => <PopupMenuEntry<ModReportSort>>[
        for (final ModReportSort s in ModReportSort.values)
          PopupMenuItem<ModReportSort>(
            value: s,
            child: Text(
              switch (s) {
                ModReportSort.priority => 'Priority',
                ModReportSort.oldest => 'Oldest first',
                ModReportSort.newest => 'Newest first',
              },
              style: const TextStyle(color: AppColors.moderatorTextPrimary),
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.moderatorSurfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.moderatorBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              switch (current) {
                ModReportSort.priority => 'Priority',
                ModReportSort.oldest => 'Oldest first',
                ModReportSort.newest => 'Newest first',
              },
              style: const TextStyle(
                color: AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const Icon(Icons.expand_more,
                size: 16, color: AppColors.moderatorTextMuted),
          ],
        ),
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md - 2,
      ),
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
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
          color: AppColors.moderatorTextFaint,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}

class _QueueBody extends StatelessWidget {
  const _QueueBody({required this.provider, required this.onOpen});

  final ModReportsProvider provider;
  final ValueChanged<ModReport> onOpen;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingQueue && provider.reports.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.moderatorPink,
          ),
        ),
      );
    }
    if (provider.queueError != null && provider.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              provider.queueError!,
              style: const TextStyle(
                color: AppColors.moderatorTextSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            GestureDetector(
              onTap: provider.refreshQueue,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: AppColors.moderatorPink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }
    if (provider.isQueueEmpty) {
      return const Center(
        child: Text(
          'No reports match these filters.',
          style: TextStyle(color: AppColors.moderatorTextFaint, fontSize: 13),
        ),
      );
    }

    return Stack(
      children: <Widget>[
        ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: provider.reports.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: AppColors.moderatorRowDivider),
          itemBuilder: (_, int i) =>
              _Row(report: provider.reports[i], onOpen: onOpen),
        ),
        if (provider.isLoadingQueue)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.moderatorPink,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.report, required this.onOpen});

  final ModReport report;
  final ValueChanged<ModReport> onOpen;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md - 2,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              report.displayId,
              style: const TextStyle(
                color: AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              report.reasonLabel,
              style: const TextStyle(
                color: AppColors.moderatorTextSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              report.targetType,
              style: const TextStyle(
                color: AppColors.moderatorTextMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              report.status.label,
              style: const TextStyle(
                color: AppColors.moderatorTextSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              _age(report.createdAt),
              style: const TextStyle(
                color: AppColors.moderatorTextMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: report.badge.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: report.badge.color.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  report.badge.label,
                  style: TextStyle(
                    color: report.badge.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: GestureDetector(
              onTap: () => onOpen(report),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.moderatorSurfaceAlt2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.moderatorTextPrimary.withValues(alpha: 0.12),
                  ),
                ),
                child: const Text(
                  'Review',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.moderatorTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _age(DateTime t) {
    final Duration d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m';
    if (d.inHours < 24) return '${d.inHours}h';
    return '${d.inDays}d';
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar();

  @override
  Widget build(BuildContext context) {
    final ModReportsProvider p = context.watch<ModReportsProvider>();
    if (p.total == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.moderatorDivider)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            'Showing ${p.rangeStart}–${p.rangeEnd} of ${p.total}',
            style: const TextStyle(
              color: AppColors.moderatorTextFaint,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          _PageBtn(label: 'Previous', enabled: p.canPrev, onTap: p.prevPage),
          const SizedBox(width: 8),
          Text(
            '${p.page} / ${p.pageCount}',
            style: const TextStyle(
              color: AppColors.moderatorTextMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          _PageBtn(label: 'Next', enabled: p.canNext, onTap: p.nextPage),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.moderatorSurfaceAlt,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.moderatorBorder),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.moderatorTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

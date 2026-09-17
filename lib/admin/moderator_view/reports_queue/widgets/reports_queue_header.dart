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

/// Title + search + urgent/status/sort filters above the reports table.
class ReportsQueueHeader extends StatelessWidget {
  const ReportsQueueHeader({required this.title, this.subtitle, super.key});

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
              subtitle ?? '${provider.total} total · sorted ${provider.sort.name}',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.moderatorTextMuted, fontSize: 13),
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
            onChanged: (String v) => context.read<ModReportsProvider>().setSearch(v),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _UrgentPill(
          selected: provider.urgentOnly,
          onTap: () => context.read<ModReportsProvider>().setUrgentOnly(!provider.urgentOnly),
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

  static String _label(ReportStatus? s) => s == null ? 'All statuses' : s.label;

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
      onSelected: (int i) => context.read<ModReportsProvider>().setStatusFilter(options[i]),
      itemBuilder: (_) => <PopupMenuEntry<int>>[
        for (int i = 0; i < options.length; i++)
          PopupMenuItem<int>(
            value: i,
            child: Text(_label(options[i]), style: const TextStyle(color: AppColors.moderatorTextPrimary)),
          ),
      ],
      child: _MenuChip(label: _label(current)),
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.current});

  final ModReportSort current;

  static String _label(ModReportSort s) => switch (s) {
        ModReportSort.priority => 'Priority',
        ModReportSort.oldest => 'Oldest first',
        ModReportSort.newest => 'Newest first',
      };

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ModReportSort>(
      color: AppColors.moderatorSurfaceAlt,
      onSelected: (ModReportSort s) => context.read<ModReportsProvider>().setSort(s),
      itemBuilder: (_) => <PopupMenuEntry<ModReportSort>>[
        for (final ModReportSort s in ModReportSort.values)
          PopupMenuItem<ModReportSort>(
            value: s,
            child: Text(_label(s), style: const TextStyle(color: AppColors.moderatorTextPrimary)),
          ),
      ],
      child: _MenuChip(label: _label(current)),
    );
  }
}

class _MenuChip extends StatelessWidget {
  const _MenuChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            label,
            style: const TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const Icon(Icons.expand_more, size: 16, color: AppColors.moderatorTextMuted),
        ],
      ),
    );
  }
}

class _UrgentPill extends StatelessWidget {
  const _UrgentPill({required this.selected, required this.onTap});

  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.moderatorChipSelected : AppColors.moderatorSurfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.moderatorBorder),
          ),
          child: Text(
            'Urgent only',
            style: TextStyle(
              color: selected ? AppColors.moderatorTextPrimary : AppColors.moderatorTextMuted,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

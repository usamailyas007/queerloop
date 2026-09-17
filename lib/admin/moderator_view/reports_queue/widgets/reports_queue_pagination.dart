import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../reports/provider/mod_reports_provider.dart';

/// Server-paginated "Showing X-Y of Z" bar under the reports table.
class ReportsQueuePagination extends StatelessWidget {
  const ReportsQueuePagination({super.key});

  @override
  Widget build(BuildContext context) {
    final ModReportsProvider p = context.watch<ModReportsProvider>();
    if (p.total == 0) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.moderatorDivider)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            'Showing ${p.rangeStart}–${p.rangeEnd} of ${p.total}',
            style: const TextStyle(color: AppColors.moderatorTextFaint, fontSize: 12),
          ),
          const Spacer(),
          _PageBtn(label: 'Previous', enabled: p.canPrev, onTap: p.prevPage),
          const SizedBox(width: 8),
          Text(
            '${p.page} / ${p.pageCount}',
            style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 8),
          _PageBtn(label: 'Next', enabled: p.canNext, onTap: p.nextPage),
        ],
      ),
    );
  }
}

class _PageBtn extends StatelessWidget {
  const _PageBtn({required this.label, required this.enabled, required this.onTap});

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
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
              style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

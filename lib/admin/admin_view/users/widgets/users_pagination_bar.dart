import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../provider/admin_users_provider.dart';

/// "Showing X-Y of Z" · Back · page numbers · Next.
class UsersPaginationBar extends StatelessWidget {
  const UsersPaginationBar({super.key});

  /// Page numbers to render; `null` marks an ellipsis gap.
  static List<int?> _window(int current, int count) {
    if (count <= 7) {
      return <int?>[for (int i = 1; i <= count; i++) i];
    }
    final Set<int> keep = <int>{1, count, current - 1, current, current + 1}..removeWhere((int p) => p < 1 || p > count);
    final List<int> sorted = keep.toList()..sort();

    final List<int?> out = <int?>[];
    int? prev;
    for (final int p in sorted) {
      if (prev != null && p - prev > 1) {
        out.add(null);
      }
      out.add(p);
      prev = p;
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AdminUsersProvider, (int, int, int, int, int, bool, bool)>(
      selector: (_, AdminUsersProvider p) => (p.page, p.pageCount, p.rangeStart, p.rangeEnd, p.total, p.canPrev, p.canNext),
      builder: (BuildContext context, _, _) {
        final AdminUsersProvider provider = context.read<AdminUsersProvider>();
        final int count = provider.pageCount;
        if (provider.total == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.adminDivider))),
          child: Row(
            children: <Widget>[
              Text(
                'Showing ${provider.rangeStart}–${provider.rangeEnd} of ${provider.total}',
                style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
              ),
              const Spacer(),
              _PageChip(label: 'Back', enabled: provider.canPrev, onTap: provider.prevPage),
              const SizedBox(width: 6),
              for (final int? p in _window(provider.page, count)) ...<Widget>[
                if (p == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('…', style: TextStyle(color: AppColors.adminTextMuted)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _PageChip(label: '$p', selected: p == provider.page, onTap: () => provider.goToPage(p)),
                  ),
              ],
              const SizedBox(width: 6),
              _PageChip(label: 'Next', enabled: provider.canNext, onTap: provider.nextPage),
            ],
          ),
        );
      },
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({required this.label, required this.onTap, this.selected = false, this.enabled = true});

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool interactive = enabled && !selected;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: selected ? AppColors.moderatorChipSelected : AppColors.adminSurfaceAlt,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: interactive ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minWidth: 34),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: selected ? Colors.transparent : AppColors.adminButtonBorder),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.adminTextPrimary : AppColors.adminTextSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

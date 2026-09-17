import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../admin_icons.dart';
import '../models/admin_user_account.dart';
import '../provider/admin_users_provider.dart';

/// Title + live stats + search field + status filter chips.
class UsersHeader extends StatelessWidget {
  const UsersHeader({
    required this.statusLabels,
    required this.statusFilters,
    required this.onSearch,
    required this.onStatusSelected,
    super.key,
  });

  final List<String> statusLabels;
  final List<AdminAccountStatus?> statusFilters;
  final ValueChanged<String> onSearch;
  final ValueChanged<int> onStatusSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Users',
                style: TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 24),
              ),
              const SizedBox(height: 4),
              Selector<AdminUsersProvider, (int, int, bool)>(
                selector: (_, AdminUsersProvider p) => (p.stats.total, p.stats.suspended, p.isLoading),
                builder: (_, (int, int, bool) data, _) {
                  final (int total, int suspended, bool loading) = data;
                  final String text = loading && total == 0
                      ? 'Loading accounts…'
                      : '$total user${total == 1 ? '' : 's'} · $suspended suspended';
                  return Text(text, style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13));
                },
              ),
            ],
          ),
        ),
        SizedBox(
          width: 240,
          child: AppTextField(
            hintText: 'Search by username or email',
            prefixIconPath: AdminIcons.search,
            fillColor: AppColors.adminSurface,
            onChanged: onSearch,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.adminSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.adminBorder),
          ),
          child: Selector<AdminUsersProvider, AdminAccountStatus?>(
            selector: (_, AdminUsersProvider p) => p.statusFilter,
            builder: (_, AdminAccountStatus? current, _) {
              final int found = statusFilters.indexOf(current);
              final int selected = found == -1 ? 0 : found;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (int i = 0; i < statusLabels.length; i++)
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => onStatusSelected(i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: selected == i ? AppColors.moderatorChipSelected : Colors.transparent,
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Text(
                            statusLabels[i],
                            style: TextStyle(
                              color: selected == i ? AppColors.adminTextPrimary : AppColors.adminTextSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

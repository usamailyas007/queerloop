import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../widgets/admin_centered_message.dart';
import '../models/admin_user_account.dart';
import '../provider/admin_users_provider.dart';
import 'user_row.dart';

/// Loading / error / empty / rows for the users table.
class UsersTableBody extends StatelessWidget {
  const UsersTableBody({required this.provider, required this.suspendOptions, super.key});

  final AdminUsersProvider provider;
  final Map<String, int> suspendOptions;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.users.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.adminPink),
        ),
      );
    }

    if (provider.error != null && provider.users.isEmpty) {
      return AdminCenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: provider.error!,
        onRetry: provider.refresh,
      );
    }

    if (provider.isEmpty) {
      return const AdminCenteredMessage(
        icon: Icons.person_search_rounded,
        message: 'No accounts match your filters',
      );
    }

    final List<AdminUserAccount> users = provider.users;
    return Stack(
      children: <Widget>[
        ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: users.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.adminRowDivider),
          itemBuilder: (_, int index) {
            final AdminUserAccount user = users[index];
            return UserRow(
              user: user,
              busy: provider.isMutating(user.id),
              suspendOptions: suspendOptions,
              onSuspend: (int days) => provider.suspendUser(user.id, days),
              onReactivate: () => provider.reactivateUser(user.id),
              onBan: () => provider.banUser(user.id),
            );
          },
        ),
        if (provider.isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2, color: AppColors.adminPink, backgroundColor: Colors.transparent),
          ),
      ],
    );
  }
}

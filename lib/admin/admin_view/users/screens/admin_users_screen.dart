import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_table_column_header.dart';
import '../models/admin_user_account.dart';
import '../provider/admin_users_provider.dart';
import '../widgets/users_header.dart';
import '../widgets/users_pagination_bar.dart';
import '../widgets/users_table_body.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const List<String> _statusLabels = <String>['All status', 'Suspended', 'Banned'];
  static const List<AdminAccountStatus?> _statusFilters = <AdminAccountStatus?>[
    null,
    AdminAccountStatus.suspended,
    AdminAccountStatus.banned,
  ];

  // label → suspend length in days, sent as `suspendDays`.
  static const Map<String, int> _suspendOptions = <String, int>{
    'Suspend · 1 day': 1,
    'Suspend · 3 days': 3,
    'Suspend · 7 days': 7,
    'Suspend · 14 days': 14,
    'Suspend · 30 days': 30,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminUsersProvider>().loadInitial();
      }
    });
  }

  void _onError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      context.read<AdminUsersProvider>().clearError();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              UsersHeader(
                statusLabels: _statusLabels,
                statusFilters: _statusFilters,
                onSearch: (String v) => context.read<AdminUsersProvider>().setSearch(v),
                onStatusSelected: (int i) => context.read<AdminUsersProvider>().setStatusFilter(_statusFilters[i]),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.adminSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.adminBorder),
                  ),
                  child: Column(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md - 2),
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.adminDivider))),
                        child: const Row(
                          children: <Widget>[
                            Expanded(flex: 3, child: AdminTableColumnHeader('ACCOUNT')),
                            Expanded(flex: 2, child: AdminTableColumnHeader('JOINED')),
                            Expanded(flex: 1, child: AdminTableColumnHeader('POSTS')),
                            Expanded(flex: 2, child: AdminTableColumnHeader('REPORTS AGAINST')),
                            Expanded(flex: 2, child: AdminTableColumnHeader('STATUS')),
                            SizedBox(width: 168),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Consumer<AdminUsersProvider>(
                          builder: (_, AdminUsersProvider provider, _) {
                            // Surface mutation / paging failures without wiping the list.
                            if (provider.error != null && provider.users.isNotEmpty) {
                              _onError(provider.error!);
                            }
                            return UsersTableBody(provider: provider, suspendOptions: _suspendOptions);
                          },
                        ),
                      ),
                      const UsersPaginationBar(),
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

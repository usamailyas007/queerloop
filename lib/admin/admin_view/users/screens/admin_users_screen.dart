import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../admin_icons.dart';
import '../models/admin_user_account.dart';
import '../provider/admin_users_provider.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  final ScrollController _scrollController = ScrollController();

  // 0: All, 1: Suspended, 2: Banned — index maps to _statusFilters below.
  static const List<String> _statusLabels = <String>[
    'All status',
    'Suspended',
    'Banned',
  ];
  static const List<AdminAccountStatus?> _statusFilters = <AdminAccountStatus?>[
    null,
    AdminAccountStatus.suspended,
    AdminAccountStatus.banned,
  ];

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
    _scrollController.addListener(_onScroll);
    // IndexedStack builds every shell tab up-front; loadInitial() no-ops until
    // this screen is first shown and actually scrolled/interacted with is fine
    // too, but preloading keeps the tab instant.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AdminUsersProvider>().loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final double threshold =
        _scrollController.position.maxScrollExtent - 320;
    if (_scrollController.position.pixels >= threshold) {
      context.read<AdminUsersProvider>().loadMore();
    }
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
              _Header(
                statusLabels: _statusLabels,
                statusFilters: _statusFilters,
                onSearch: (String v) =>
                    context.read<AdminUsersProvider>().setSearch(v),
                onStatusSelected: (int i) => context
                    .read<AdminUsersProvider>()
                    .setStatusFilter(_statusFilters[i]),
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
                      const _TableHeaderRow(),
                      Expanded(
                        child: Consumer<AdminUsersProvider>(
                          builder: (_, AdminUsersProvider provider, _) {
                            return _UsersTableBody(
                              provider: provider,
                              scrollController: _scrollController,
                              suspendOptions: _suspendOptions,
                            );
                          },
                        ),
                      ),
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

// ── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.statusLabels,
    required this.statusFilters,
    required this.onSearch,
    required this.onStatusSelected,
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
                style: TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 4),
              Selector<AdminUsersProvider, (int, int, bool)>(
                selector: (_, AdminUsersProvider p) =>
                    (p.total, p.suspendedCount, p.isLoading),
                builder: (_, (int, int, bool) data, _) {
                  final (int total, int suspended, bool loading) = data;
                  final String text = loading && total == 0
                      ? 'Loading accounts…'
                      : '$total account${total == 1 ? '' : 's'}'
                          '${suspended > 0 ? ' · $suspended suspended on screen' : ''}';
                  return Text(
                    text,
                    style: const TextStyle(
                      color: AppColors.adminTextSecondary,
                      fontSize: 13,
                    ),
                  );
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
                    GestureDetector(
                      onTap: () => onStatusSelected(i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: selected == i
                              ? AppColors.moderatorChipSelected
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          statusLabels[i],
                          style: TextStyle(
                            color: selected == i
                                ? AppColors.adminTextPrimary
                                : AppColors.adminTextSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 100,
          child: AppOutlineButton(
            text: 'Export',
            height: 40,
            onPressed: () {},
          ),
        ),
      ],
    );
  }
}

// ── Table header row ────────────────────────────────────────────────────────

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md - 2,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.adminDivider)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 3, child: _ColumnHeader('ACCOUNT')),
          Expanded(flex: 2, child: _ColumnHeader('JOINED')),
          Expanded(flex: 1, child: _ColumnHeader('POSTS')),
          Expanded(flex: 2, child: _ColumnHeader('REPORTS AGAINST')),
          Expanded(flex: 2, child: _ColumnHeader('STATUS')),
          SizedBox(width: 110),
        ],
      ),
    );
  }
}

// ── Table body: loading / error / empty / list ──────────────────────────────

class _UsersTableBody extends StatelessWidget {
  const _UsersTableBody({
    required this.provider,
    required this.scrollController,
    required this.suspendOptions,
  });

  final AdminUsersProvider provider;
  final ScrollController scrollController;
  final Map<String, int> suspendOptions;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.users.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.adminPink,
          ),
        ),
      );
    }

    if (provider.error != null && provider.users.isEmpty) {
      return _ErrorState(
        message: provider.error!,
        onRetry: provider.refresh,
      );
    }

    if (provider.isEmpty) {
      return const _EmptyState();
    }

    final int rowCount = provider.users.length;
    return RefreshIndicator(
      color: AppColors.adminPink,
      backgroundColor: AppColors.adminSurface,
      onRefresh: provider.refresh,
      child: ListView.separated(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: rowCount + 1, // +1 = footer
        separatorBuilder: (_, int i) => i < rowCount - 1
            ? Divider(height: 1, color: AppColors.adminRowDivider)
            : const SizedBox.shrink(),
        itemBuilder: (BuildContext context, int index) {
          if (index == rowCount) {
            return _ListFooter(provider: provider);
          }
          final AdminUserAccount user = provider.users[index];
          return _UserRow(
            user: user,
            suspendOptions: suspendOptions,
            onSetActive: () => provider.applyStatusLocally(
              user.id,
              AdminAccountStatus.active,
            ),
            onSuspend: (int days) => provider.applyStatusLocally(
              user.id,
              AdminAccountStatus.suspended,
              expiresAt: DateTime.now().add(Duration(days: days)),
            ),
            onBan: () => provider.applyStatusLocally(
              user.id,
              AdminAccountStatus.banned,
            ),
          );
        },
      ),
    );
  }
}

class _ListFooter extends StatelessWidget {
  const _ListFooter({required this.provider});

  final AdminUsersProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.adminPink,
            ),
          ),
        ),
      );
    }

    if (provider.error != null && provider.users.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: TextButton(
            onPressed: provider.loadMore,
            child: Text(
              'Couldn\'t load more — tap to retry',
              style: const TextStyle(color: AppColors.adminPink, fontSize: 12),
            ),
          ),
        ),
      );
    }

    if (!provider.hasMore && provider.users.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
          child: Text(
            'All ${provider.total} accounts loaded',
            style: const TextStyle(
              color: AppColors.adminTextMuted,
              fontSize: 11,
            ),
          ),
        ),
      );
    }

    return const SizedBox(height: AppSpacing.md);
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.cloud_off_rounded,
              color: AppColors.adminTextMuted, size: 32),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: 120,
            child: AppOutlineButton(
              text: 'Retry',
              height: 38,
              onPressed: onRetry,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.person_search_rounded,
              color: AppColors.adminTextMuted, size: 32),
          SizedBox(height: AppSpacing.sm),
          Text(
            'No accounts match your filters',
            style: TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.adminTextMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

// ── User row ────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.onSetActive,
    required this.onSuspend,
    required this.onBan,
    required this.suspendOptions,
  });

  final AdminUserAccount user;
  final VoidCallback onSetActive;
  final ValueChanged<int> onSuspend;
  final VoidCallback onBan;
  final Map<String, int> suspendOptions;

  static final DateFormat _joinedFormat = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (user.status) {
      AdminAccountStatus.active => ('Active', AppColors.adminTeal),
      AdminAccountStatus.suspended => (_suspendedLabel(), AppColors.adminOrange),
      AdminAccountStatus.banned => ('Banned', AppColors.adminPink),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Row(
              children: <Widget>[
                _InitialsAvatar(seed: user.handle, size: 34),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        user.handle,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.adminTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        user.secondaryLine,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.adminTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _joinedFormat.format(user.createdAt),
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${user.postCount}',
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${user.reportsAgainst}',
              style: TextStyle(
                color: user.reportsAgainst > 5
                    ? AppColors.adminPink
                    : AppColors.adminTextSecondary,
                fontWeight:
                    user.reportsAgainst > 5 ? FontWeight.w700 : FontWeight.w400,
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
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: _ManageMenu(
              onSetActive: onSetActive,
              onSuspend: onSuspend,
              onBan: onBan,
              suspendOptions: suspendOptions,
            ),
          ),
        ],
      ),
    );
  }

  String _suspendedLabel() {
    final DateTime? until = user.statusExpiresAt;
    if (until == null) {
      return 'Suspended';
    }
    final int days = until.difference(DateTime.now()).inDays;
    return days <= 0 ? 'Suspended' : 'Suspended ${days}d';
  }
}

class _ManageMenu extends StatelessWidget {
  const _ManageMenu({
    required this.onSetActive,
    required this.onSuspend,
    required this.onBan,
    required this.suspendOptions,
  });

  final VoidCallback onSetActive;
  final ValueChanged<int> onSuspend;
  final VoidCallback onBan;
  final Map<String, int> suspendOptions;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.adminSurfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.adminButtonBorder),
      ),
      onSelected: (String value) {
        if (value == 'active') {
          onSetActive();
        } else if (value == 'ban') {
          onBan();
        } else {
          onSuspend(suspendOptions[value]!);
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(
          value: 'active',
          child: Text('Active',
              style:
                  TextStyle(color: AppColors.adminTextPrimary, fontSize: 13)),
        ),
        const PopupMenuDivider(),
        for (final String option in suspendOptions.keys)
          PopupMenuItem<String>(
            value: option,
            child: Text(option,
                style: const TextStyle(
                    color: AppColors.adminTextSecondary, fontSize: 13)),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'ban',
          child: Text('Ban permanently',
              style: TextStyle(color: AppColors.adminPink, fontSize: 13)),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.adminSurfaceAlt,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.adminButtonBorder),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Manage',
                style: TextStyle(
                    color: AppColors.adminTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
            SizedBox(width: 4),
            Icon(Icons.expand_more,
                size: 16, color: AppColors.adminTextSecondary),
          ],
        ),
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.seed, required this.size});

  final String seed;
  final double size;

  static const List<Color> _palette = <Color>[
    AppColors.adminPink,
    AppColors.adminPurple,
    AppColors.adminTeal,
    AppColors.adminOrange,
  ];

  @override
  Widget build(BuildContext context) {
    final String clean = seed.replaceAll('@', '').trim();
    final String initials =
        clean.isEmpty ? '?' : clean.characters.first.toUpperCase();
    final Color bg = _palette[clean.hashCode.abs() % _palette.length];

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(color: bg.withValues(alpha: 0.5)),
      ),
      child: Text(
        initials,
        style: TextStyle(
          color: bg,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

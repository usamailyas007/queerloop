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
                            // Surface mutation / paging failures without wiping the list.
                            if (provider.error != null &&
                                provider.users.isNotEmpty) {
                              _onError(provider.error!);
                            }
                            return _UsersTableBody(
                              provider: provider,
                              suspendOptions: _suspendOptions,
                            );
                          },
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

// ── Header (title + stats + search + status filter) ─────────────────────────

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
                    (p.stats.total, p.stats.suspended, p.isLoading),
                builder: (_, (int, int, bool) data, _) {
                  final (int total, int suspended, bool loading) = data;
                  final String text = loading && total == 0
                      ? 'Loading accounts…'
                      : '$total user${total == 1 ? '' : 's'} · '
                          '$suspended suspended';
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
          child: AppOutlineButton(text: 'Export', height: 40, onPressed: () {}),
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
          SizedBox(width: 128),
        ],
      ),
    );
  }
}

// ── Table body: loading / error / empty / rows ─────────────────────────────

class _UsersTableBody extends StatelessWidget {
  const _UsersTableBody({required this.provider, required this.suspendOptions});

  final AdminUsersProvider provider;
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
      return _ErrorState(message: provider.error!, onRetry: provider.refresh);
    }

    if (provider.isEmpty) {
      return const _EmptyState();
    }

    final List<AdminUserAccount> users = provider.users;
    return Stack(
      children: <Widget>[
        ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: users.length,
          separatorBuilder: (_, _) =>
              Divider(height: 1, color: AppColors.adminRowDivider),
          itemBuilder: (_, int index) {
            final AdminUserAccount user = users[index];
            return _UserRow(
              user: user,
              busy: provider.isMutating(user.id),
              suspendOptions: suspendOptions,
              onSuspend: (int days) => provider.suspendUser(user.id, days),
              onReactivate: () => provider.reactivateUser(user.id),
            );
          },
        ),
        // Thin progress strip while a page swap / refresh is in flight.
        if (provider.isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.adminPink,
              backgroundColor: Colors.transparent,
            ),
          ),
      ],
    );
  }
}

// ── Pagination bar: Back · 1 2 3 … · Next ──────────────────────────────────

class _PaginationBar extends StatelessWidget {
  const _PaginationBar();

  /// Page numbers to render; `null` marks an ellipsis gap.
  static List<int?> _window(int current, int count) {
    if (count <= 7) {
      return <int?>[for (int i = 1; i <= count; i++) i];
    }
    final Set<int> keep = <int>{
      1,
      count,
      current - 1,
      current,
      current + 1,
    }..removeWhere((int p) => p < 1 || p > count);
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
      selector: (_, AdminUsersProvider p) => (
        p.page,
        p.pageCount,
        p.rangeStart,
        p.rangeEnd,
        p.total,
        p.canPrev,
        p.canNext,
      ),
      builder: (BuildContext context, _, _) {
        final AdminUsersProvider provider = context.read<AdminUsersProvider>();
        final int count = provider.pageCount;
        if (provider.total == 0) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.adminDivider)),
          ),
          child: Row(
            children: <Widget>[
              Text(
                'Showing ${provider.rangeStart}–${provider.rangeEnd} of ${provider.total}',
                style: const TextStyle(
                  color: AppColors.adminTextMuted,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              _PageChip(
                label: 'Back',
                enabled: provider.canPrev,
                onTap: provider.prevPage,
              ),
              const SizedBox(width: 6),
              for (final int? p in _window(provider.page, count)) ...<Widget>[
                if (p == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text('…',
                        style: TextStyle(color: AppColors.adminTextMuted)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: _PageChip(
                      label: '$p',
                      selected: p == provider.page,
                      onTap: () => provider.goToPage(p),
                    ),
                  ),
              ],
              const SizedBox(width: 6),
              _PageChip(
                label: 'Next',
                enabled: provider.canNext,
                onTap: provider.nextPage,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PageChip extends StatelessWidget {
  const _PageChip({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.enabled = true,
  });

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
        color: selected
            ? AppColors.moderatorChipSelected
            : AppColors.adminSurfaceAlt,
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
              border: Border.all(
                color: selected
                    ? Colors.transparent
                    : AppColors.adminButtonBorder,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? AppColors.adminTextPrimary
                    : AppColors.adminTextSecondary,
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

// ── Empty / error states ───────────────────────────────────────────────────

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
    required this.busy,
    required this.onSuspend,
    required this.onReactivate,
    required this.suspendOptions,
  });

  final AdminUserAccount user;
  final bool busy;
  final ValueChanged<int> onSuspend;
  final VoidCallback onReactivate;
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
            width: 128,
            child: Align(
              alignment: Alignment.centerRight,
              child: _RowAction(
                status: user.status,
                busy: busy,
                suspendOptions: suspendOptions,
                onSuspend: onSuspend,
                onReactivate: onReactivate,
              ),
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

// ── Row action: "Manage" popup (active) or "Reactivate" button (suspended) ──

class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.status,
    required this.busy,
    required this.suspendOptions,
    required this.onSuspend,
    required this.onReactivate,
  });

  final AdminAccountStatus status;
  final bool busy;
  final Map<String, int> suspendOptions;
  final ValueChanged<int> onSuspend;
  final VoidCallback onReactivate;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppColors.adminPink,
        ),
      );
    }

    if (status != AdminAccountStatus.active) {
      return _ActionPill(
        label: 'Reactivate',
        onTap: onReactivate,
        accent: AppColors.adminTeal,
      );
    }

    return PopupMenuButton<String>(
      color: AppColors.adminSurfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.adminButtonBorder),
      ),
      onSelected: (String option) {
        if (option == _banValue) {
          // Ban gets its own endpoint later — surface intent, do nothing yet.
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              const SnackBar(content: Text('Ban is not wired up yet.')),
            );
          return;
        }
        onSuspend(suspendOptions[option]!);
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        for (final String option in suspendOptions.keys)
          PopupMenuItem<String>(
            value: option,
            child: Text(
              option,
              style: const TextStyle(
                color: AppColors.adminTextSecondary,
                fontSize: 13,
              ),
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: _banValue,
          child: Text(
            'Ban permanently',
            style: TextStyle(color: AppColors.adminPink, fontSize: 13),
          ),
        ),
      ],
      child: _ActionPill(label: 'Manage', trailingIcon: Icons.expand_more),
    );
  }
}

const String _banValue = '__ban_permanently__';

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    this.onTap,
    this.trailingIcon,
    this.accent,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? trailingIcon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.adminSurfaceAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accent?.withValues(alpha: 0.5) ?? AppColors.adminButtonBorder,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: accent ?? AppColors.adminTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          if (trailingIcon != null) ...<Widget>[
            const SizedBox(width: 4),
            Icon(trailingIcon, size: 16, color: AppColors.adminTextSecondary),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return pill;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: pill,
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

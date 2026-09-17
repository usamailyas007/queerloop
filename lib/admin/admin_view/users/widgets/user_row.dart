import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_remote_avatar.dart';
import '../models/admin_user_account.dart';
import '../screens/admin_user_detail_dialog.dart';

/// One row in the users table: identity, joined date, counts, status, action.
class UserRow extends StatelessWidget {
  const UserRow({
    required this.user,
    required this.busy,
    required this.onSuspend,
    required this.onReactivate,
    required this.onBan,
    required this.suspendOptions,
    super.key,
  });

  final AdminUserAccount user;
  final bool busy;
  final ValueChanged<int> onSuspend;
  final VoidCallback onReactivate;
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => showAdminUserDetailDialog(context, user),
              child: Row(
                children: <Widget>[
                  AdminRemoteAvatar(seed: user.handle, imageUrl: user.avatarUrl, size: 34),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          user.handle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        if (user.secondaryLine.isNotEmpty)
                          Text(
                            user.secondaryLine,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(_joinedFormat.format(user.createdAt), style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13)),
          ),
          Expanded(
            flex: 1,
            child: Text('${user.postCount}', style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${user.reportsAgainst}',
              style: TextStyle(
                color: user.reportsAgainst > 5 ? AppColors.adminPink : AppColors.adminTextSecondary,
                fontWeight: user.reportsAgainst > 5 ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
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
                handle: user.handle,
                suspendOptions: suspendOptions,
                onSuspend: onSuspend,
                onReactivate: onReactivate,
                onBan: onBan,
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

/// "Manage" popup (active accounts) or "Reactivate" button (suspended/banned).
class _RowAction extends StatelessWidget {
  const _RowAction({
    required this.status,
    required this.busy,
    required this.handle,
    required this.suspendOptions,
    required this.onSuspend,
    required this.onReactivate,
    required this.onBan,
  });

  final AdminAccountStatus status;
  final bool busy;
  final String handle;
  final Map<String, int> suspendOptions;
  final ValueChanged<int> onSuspend;
  final VoidCallback onReactivate;
  final VoidCallback onBan;

  Future<void> _confirmBan(BuildContext context) async {
    final bool ok =
        await showDialog<bool>(
          context: context,
          barrierColor: Colors.black.withValues(alpha: 0.6),
          builder: (BuildContext ctx) => AlertDialog(
            backgroundColor: AppColors.adminSurfaceAlt,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(color: AppColors.adminCardBorderStrong),
            ),
            title: const Text(
              'Ban permanently?',
              style: TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w800, fontSize: 17),
            ),
            content: Text(
              '$handle will be permanently banned and blocked from signing in. You can still reactivate the account later.',
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13, height: 1.45),
            ),
            actions: <Widget>[
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Ban permanently',
                  style: TextStyle(color: AppColors.adminPink, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (ok) {
      onBan();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
      );
    }

    if (status != AdminAccountStatus.active) {
      return _ActionPill(label: 'Reactivate', onTap: onReactivate, accent: AppColors.adminTeal);
    }

    return PopupMenuButton<String>(
      color: AppColors.adminSurfaceAlt,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: AppColors.adminButtonBorder)),
      onSelected: (String option) {
        if (option == _banValue) {
          _confirmBan(context);
          return;
        }
        onSuspend(suspendOptions[option]!);
      },
      itemBuilder: (_) => <PopupMenuEntry<String>>[
        for (final String option in suspendOptions.keys)
          PopupMenuItem<String>(
            value: option,
            child: Text(option, style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13)),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: _banValue,
          child: Text('Ban permanently', style: TextStyle(color: AppColors.adminPink, fontSize: 13)),
        ),
      ],
      child: _ActionPill(label: 'Manage', trailingIcon: Icons.expand_more),
    );
  }
}

const String _banValue = '__ban_permanently__';

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.label, this.onTap, this.trailingIcon, this.accent});

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
        border: Border.all(color: accent?.withValues(alpha: 0.5) ?? AppColors.adminButtonBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(label, style: TextStyle(color: accent ?? AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 12)),
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
    return InkWell(borderRadius: BorderRadius.circular(14), onTap: onTap, child: pill);
  }
}

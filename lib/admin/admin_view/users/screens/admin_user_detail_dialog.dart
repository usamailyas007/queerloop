import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_badge.dart';
import '../../widgets/admin_kv_row.dart';
import '../../widgets/admin_remote_avatar.dart';
import '../models/admin_user_account.dart';
import '../provider/admin_users_provider.dart';
import '../widgets/admin_user_detail_chips.dart';
import '../widgets/admin_user_detail_label.dart';

/// Opens the read-only user-detail sheet for [user]. Row data is shown
/// immediately; bio / pronouns / interests are fetched from GET /users/:id.
Future<void> showAdminUserDetailDialog(
  BuildContext context,
  AdminUserAccount user,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => _AdminUserDetailDialog(user: user),
  );
}

class _AdminUserDetailDialog extends StatefulWidget {
  const _AdminUserDetailDialog({required this.user});

  final AdminUserAccount user;

  @override
  State<_AdminUserDetailDialog> createState() => _AdminUserDetailDialogState();
}

class _AdminUserDetailDialogState extends State<_AdminUserDetailDialog> {
  late final Future<UserProfileExtra?> _profile =
      context.read<AdminUsersProvider>().loadProfile(widget.user.id);

  static final DateFormat _date = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final AdminUserAccount u = widget.user;
    final (String statusLabel, Color statusColor) = switch (u.status) {
      AdminAccountStatus.active => ('Active', AppColors.adminTeal),
      AdminAccountStatus.suspended => ('Suspended', AppColors.adminOrange),
      AdminAccountStatus.banned => ('Banned', AppColors.adminPink),
    };

    return Dialog(
      backgroundColor: AppColors.adminSurface,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.adminBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _Header(user: u, statusLabel: statusLabel, statusColor: statusColor),
              const SizedBox(height: AppSpacing.lg),
              AdminKvRow('Email', u.email.isEmpty ? '—' : u.email),
              AdminKvRow('Role', _titleCase(u.role)),
              AdminKvRow('Joined', _date.format(u.createdAt)),
              AdminKvRow('Posts', '${u.postCount}'),
              AdminKvRow('Reports against', '${u.reportsAgainst}'),
              if (u.status == AdminAccountStatus.suspended &&
                  u.statusExpiresAt != null)
                AdminKvRow('Suspended until', _date.format(u.statusExpiresAt!)),
              AdminKvRow('User ID', u.id, mono: true),
              const SizedBox(height: AppSpacing.md),
              Divider(color: AppColors.adminBorder, height: 1),
              const SizedBox(height: AppSpacing.md),
              _ExtendedProfile(profile: _profile),
              const SizedBox(height: AppSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(
                      color: AppColors.adminPinkLight,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _titleCase(String s) =>
      s.isEmpty ? '—' : s[0].toUpperCase() + s.substring(1);
}

class _Header extends StatelessWidget {
  const _Header({
    required this.user,
    required this.statusLabel,
    required this.statusColor,
  });

  final AdminUserAccount user;
  final String statusLabel;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        AdminRemoteAvatar(seed: user.handle, imageUrl: user.avatarUrl, size: 52),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                user.displayName?.isNotEmpty == true
                    ? user.displayName!
                    : user.handle,
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
              Text(
                user.handle,
                style: const TextStyle(
                  color: AppColors.adminTextMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        AdminBadge(text: statusLabel, color: statusColor),
      ],
    );
  }
}

/// Bio / pronouns / interests, fetched separately from GET /users/:id.
class _ExtendedProfile extends StatelessWidget {
  const _ExtendedProfile({required this.profile});

  final Future<UserProfileExtra?> profile;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserProfileExtra?>(
      future: profile,
      builder: (_, AsyncSnapshot<UserProfileExtra?> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.adminPink,
              ),
            ),
          );
        }
        final UserProfileExtra? p = snap.data;
        if (p == null) {
          return _note('Extended profile could not be loaded.');
        }
        if (p.isHiddenProfile) {
          return _note('This account keeps its profile private.');
        }
        if (!p.hasAny) {
          return _note('No bio, pronouns or interests set.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (p.bio != null && p.bio!.isNotEmpty) ...<Widget>[
              const AdminUserDetailLabel('Bio'),
              const SizedBox(height: 4),
              Text(
                p.bio!,
                style: const TextStyle(
                  color: AppColors.adminTextSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (p.pronouns.isNotEmpty) ...<Widget>[
              const AdminUserDetailLabel('Pronouns'),
              const SizedBox(height: 6),
              AdminUserDetailChips(values: p.pronouns),
              const SizedBox(height: AppSpacing.md),
            ],
            if (p.interests.isNotEmpty) ...<Widget>[
              const AdminUserDetailLabel('Interests'),
              const SizedBox(height: 6),
              AdminUserDetailChips(values: p.interests),
            ],
          ],
        );
      },
    );
  }

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          text,
          style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 12.5),
        ),
      );
}

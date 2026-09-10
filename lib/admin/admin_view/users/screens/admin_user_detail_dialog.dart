import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_remote_avatar.dart';
import '../models/admin_user_account.dart';
import '../provider/admin_users_provider.dart';

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
              // ── Header ──────────────────────────────────────────────
              Row(
                children: <Widget>[
                  AdminRemoteAvatar(
                    seed: u.handle,
                    imageUrl: u.avatarUrl,
                    size: 52,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          u.displayName?.isNotEmpty == true
                              ? u.displayName!
                              : u.handle,
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          ),
                        ),
                        Text(
                          u.handle,
                          style: const TextStyle(
                            color: AppColors.adminTextMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Pill(label: statusLabel, color: statusColor),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Account facts (from the list row) ───────────────────
              _kv('Email', u.email.isEmpty ? '—' : u.email),
              _kv('Role', _titleCase(u.role)),
              _kv('Joined', _date.format(u.createdAt)),
              _kv('Posts', '${u.postCount}'),
              _kv('Reports against', '${u.reportsAgainst}'),
              if (u.status == AdminAccountStatus.suspended &&
                  u.statusExpiresAt != null)
                _kv('Suspended until', _date.format(u.statusExpiresAt!)),
              _kv('User ID', u.id, mono: true),

              const SizedBox(height: AppSpacing.md),
              Divider(color: AppColors.adminBorder, height: 1),
              const SizedBox(height: AppSpacing.md),

              // ── Extended profile (from /users/:id) ─────────────────
              FutureBuilder<UserProfileExtra?>(
                future: _profile,
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
                        const _Label('Bio'),
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
                        const _Label('Pronouns'),
                        const SizedBox(height: 6),
                        _Chips(values: p.pronouns),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      if (p.interests.isNotEmpty) ...<Widget>[
                        const _Label('Interests'),
                        const SizedBox(height: 6),
                        _Chips(values: p.interests),
                      ],
                    ],
                  );
                },
              ),

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

  static String _titleCase(String s) => s.isEmpty
      ? '—'
      : s[0].toUpperCase() + s.substring(1);

  Widget _kv(String k, String v, {bool mono = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 120,
              child: Text(
                k,
                style: const TextStyle(
                  color: AppColors.adminTextMuted,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontSize: mono ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _note(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.adminTextMuted,
            fontSize: 12.5,
          ),
        ),
      );
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.adminTextMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}

class _Chips extends StatelessWidget {
  const _Chips({required this.values});
  final List<String> values;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final String v in values)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.adminSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.adminBorder),
              ),
              child: Text(
                v,
                style: const TextStyle(
                  color: AppColors.adminTextSecondary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

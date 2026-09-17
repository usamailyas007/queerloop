import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_centered_message.dart';
import '../../widgets/admin_remote_avatar.dart';
import '../../widgets/admin_table_column_header.dart';
import '../models/moderator.dart';
import '../provider/moderators_provider.dart';

class ModeratorsTable extends StatelessWidget {
  const ModeratorsTable({required this.provider, super.key});

  final ModeratorsProvider provider;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        children: <Widget>[
          const _TableHeaderRow(),
          Expanded(child: _ModeratorsBody(provider: provider)),
        ],
      ),
    );
  }
}

class _ModeratorsBody extends StatelessWidget {
  const _ModeratorsBody({required this.provider});

  final ModeratorsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.moderators.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.adminPink),
        ),
      );
    }

    if (provider.error != null && provider.moderators.isEmpty) {
      return AdminCenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: provider.error!,
        onRetry: provider.refresh,
      );
    }

    if (provider.isEmpty) {
      return const AdminCenteredMessage(icon: Icons.shield_outlined, message: 'No moderators yet.');
    }

    final List<Moderator> items = provider.moderators;
    return RefreshIndicator(
      color: AppColors.adminPink,
      backgroundColor: AppColors.adminSurface,
      onRefresh: provider.refresh,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.adminRowDivider),
        itemBuilder: (BuildContext context, int index) {
          final Moderator mod = items[index];
          return _ModeratorRowTile(
            mod: mod,
            resending: provider.isResending(mod.id),
            onResend: () => _resend(context, mod),
          );
        },
      ),
    );
  }

  Future<void> _resend(BuildContext context, Moderator mod) async {
    final ModeratorsProvider p = context.read<ModeratorsProvider>();
    final String? message = await p.resendInvite(mod.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message ?? p.error ?? 'Could not re-send the invite.')));
    if (message == null) {
      p.clearError();
    }
  }
}

class _ModeratorRowTile extends StatelessWidget {
  const _ModeratorRowTile({required this.mod, required this.resending, required this.onResend});

  final Moderator mod;
  final bool resending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Row(
              children: <Widget>[
                AdminRemoteAvatar(seed: mod.name, faded: mod.pending),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        '${mod.name} · ${mod.role}',
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.adminTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        mod.email,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 11),
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
              mod.communitiesLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${mod.resolved30d}',
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              mod.avgResponseHours == null ? '—' : '${mod.avgResponseHours!.toStringAsFixed(1)}h',
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${mod.reversed}',
              style: TextStyle(
                color: mod.reversed > 0 ? AppColors.adminPink : AppColors.adminTextSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 168,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (mod.pending ? AppColors.adminOrange : AppColors.adminTeal).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (mod.pending ? AppColors.adminOrange : AppColors.adminTeal).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    mod.pending ? 'Pending' : 'Active',
                    style: TextStyle(
                      color: mod.pending ? AppColors.adminOrange : AppColors.adminTeal,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                if (mod.pending) ...<Widget>[
                  const SizedBox(width: 6),
                  _ResendButton(busy: resending, onTap: onResend),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResendButton extends StatelessWidget {
  const _ResendButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: busy ? null : onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.adminSurfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.adminButtonBorder),
          ),
          child: busy
              ? const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
                )
              : const Text(
                  'Resend',
                  style: TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 11),
                ),
        ),
      ),
    );
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md - 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.adminDivider)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 3, child: AdminTableColumnHeader('MODERATOR')),
          Expanded(flex: 2, child: AdminTableColumnHeader('COMMUNITIES')),
          Expanded(flex: 2, child: AdminTableColumnHeader('RESOLVED · 30D')),
          Expanded(flex: 2, child: AdminTableColumnHeader('AVG RESPONSE')),
          Expanded(flex: 1, child: AdminTableColumnHeader('REVERSED')),
          SizedBox(width: 168, child: AdminTableColumnHeader('STATUS')),
        ],
      ),
    );
  }
}

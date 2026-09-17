import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../../widgets/admin_delete_icon_button.dart';
import '../../widgets/admin_remote_avatar.dart';
import '../models/moderator.dart';

/// One row in the moderators table: identity, communities, stats, status,
/// resend / delete actions.
class ModeratorRowTile extends StatelessWidget {
  const ModeratorRowTile({
    required this.mod,
    required this.resending,
    required this.deleting,
    required this.onResend,
    required this.onDelete,
    super.key,
  });

  final Moderator mod;
  final bool resending;
  final bool deleting;
  final VoidCallback onResend;
  final VoidCallback onDelete;

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
            width: 210,
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
                const SizedBox(width: 6),
                if (deleting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
                  )
                else
                  AdminDeleteIconButton(
                    tooltip: 'Delete moderator',
                    onTap: () => _confirmDeleteModerator(context, mod.name, onDelete),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteModerator(BuildContext context, String name, VoidCallback onDelete) async {
  final bool ok = await showAdminConfirmDialog(
    context,
    title: 'Delete moderator permanently?',
    message: '$name will be permanently removed from the moderator roster and lose access. This cannot be undone.',
  );
  if (ok) {
    onDelete();
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

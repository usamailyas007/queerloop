import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_gradient_button.dart';
import '../../core/widgets/app_outline_button.dart';
import '../auth/provider/admin_auth_provider.dart';

/// Shows the shared "Log out?" confirmation. Resolves to `true` when the user
/// confirms, `false`/`null` otherwise.
Future<bool> showAdminLogoutDialog(BuildContext context) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (BuildContext context) => const _AdminLogoutDialog(),
  );
  return result ?? false;
}

/// Sidebar row: a "Logout" item that confirms, then signs the session out.
class SidebarLogoutButton extends StatelessWidget {
  const SidebarLogoutButton({required this.color, super.key});

  final Color color;

  Future<void> _handleTap(BuildContext context) async {
    final bool confirmed = await showAdminLogoutDialog(context);
    if (confirmed && context.mounted) {
      await context.read<AdminAuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _handleTap(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 10,
          ),
          child: Row(
            children: <Widget>[
              Icon(Icons.logout_rounded, size: 20, color: color),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminLogoutDialog extends StatelessWidget {
  const _AdminLogoutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.adminSurfaceAlt,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: AppColors.adminCardBorderStrong),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xxl,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.adminTeal.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.adminTeal.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.adminTeal,
                  size: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text(
                'Log out?',
                style: TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                "Are you sure you want to log out? You'll need to sign in "
                'again to access the dashboard.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.adminTextSecondary,
                  fontSize: 12.5,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppOutlineButton(
                      text: 'Cancel',
                      height: 44,
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppGradientButton(
                      text: 'Log out',
                      height: 44,
                      borderRadius: BorderRadius.circular(12),
                      gradient: const LinearGradient(
                        colors: <Color>[
                          AppColors.adminPink,
                          AppColors.adminPurple,
                        ],
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

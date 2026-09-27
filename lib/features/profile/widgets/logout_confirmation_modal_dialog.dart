import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../provider/profile_provider.dart';

class LogoutConfirmationModalDialog extends StatelessWidget {
  const LogoutConfirmationModalDialog({
    this.username,
    this.avatarAsset,
    required this.onConfirmLogout,
    super.key,
  });

  final String? username;
  final String? avatarAsset;
  final VoidCallback onConfirmLogout;

  static Future<void> show(
    BuildContext context, {
    String? username,
    String? avatarAsset,
    required VoidCallback onConfirmLogout,
  }) async {
    ProfileProvider? profileProvider;
    try {
      profileProvider = context.read<ProfileProvider>();
    } catch (_) {}

    final String effectiveUsername = (username != null && username.isNotEmpty)
        ? username
        : (profileProvider != null && profileProvider.username.isNotEmpty
            ? profileProvider.username
            : '@user');

    final String effectiveAvatar = (avatarAsset != null && avatarAsset.isNotEmpty)
        ? avatarAsset
        : (profileProvider != null && profileProvider.avatarUrl.isNotEmpty
            ? profileProvider.avatarUrl
            : AppImages.user1);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => LogoutConfirmationModalDialog(
        username: effectiveUsername,
        avatarAsset: effectiveAvatar,
        onConfirmLogout: onConfirmLogout,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ProfileProvider? profileProvider;
    try {
      profileProvider = context.watch<ProfileProvider>();
    } catch (_) {}

    final String resolvedUsername = (username != null && username!.isNotEmpty)
        ? username!
        : (profileProvider != null && profileProvider.username.isNotEmpty
            ? profileProvider.username
            : '@user');

    final String resolvedAvatar = (avatarAsset != null && avatarAsset!.isNotEmpty)
        ? avatarAsset!
        : (profileProvider != null && profileProvider.avatarUrl.isNotEmpty
            ? profileProvider.avatarUrl
            : AppImages.user1);

    final String cleanUsername =
        resolvedUsername.startsWith('@') ? resolvedUsername : '@$resolvedUsername';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: context.themeBorder,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.5 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Top Circular Avatar with Gradient Ring Border
            Container(
              width: 64,
              height: 64,
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradientButton,
              ),
              child: ClipOval(
                child: resolvedAvatar.startsWith('http')
                    ? Image.network(
                        resolvedAvatar,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: context.themeChipBackground,
                          child: Icon(
                            Icons.person_rounded,
                            color: context.themeIconMuted,
                            size: 32,
                          ),
                        ),
                      )
                    : Image.asset(
                        resolvedAvatar.isNotEmpty
                            ? resolvedAvatar
                            : AppImages.user1,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: context.themeChipBackground,
                          child: Icon(
                            Icons.person_rounded,
                            color: context.themeIconMuted,
                            size: 32,
                          ),
                        ),
                      ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Title: Log out of @username?
            Text(
              'Log out of $cleanUsername?',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.themeTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Subtitle Description
            Text(
              "Your posts, drafts and messages stay on your account. You'll need your password or a login code to get back in.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.themeTextSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Log Out Button
            AppGradientButton(
              text: 'Log out',
              onPressed: () {
                Navigator.pop(context);
                onConfirmLogout();
              },
            ),

            const SizedBox(height: AppSpacing.sm),

            // Cancel Button
            AppOutlineButton(
              text: 'Cancel',
              height: 48,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

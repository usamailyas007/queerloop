import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';

class DeleteChatModalDialog extends StatelessWidget {
  const DeleteChatModalDialog({
    required this.username,
    required this.onConfirmDelete,
    super.key,
  });

  final String username;
  final VoidCallback onConfirmDelete;

  static Future<void> show(
    BuildContext context, {
    required String username,
    required VoidCallback onConfirmDelete,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => DeleteChatModalDialog(
        username: username,
        onConfirmDelete: onConfirmDelete,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String cleanUsername =
        username.startsWith('@') ? username : '@$username';

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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Top trash bin icon container
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: context.themeCyanBadgeBackground,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppIcons.delete,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    AppColors.gradientCyan,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Title Delete this chat?
            Text(
              'Delete this chat?',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.themeTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Subtitle Description
            Text(
              'This only removes it from your inbox. $cleanUsername keeps their copy and can still message you — a new message brings the thread right back.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.themeTextSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Row of 2 Action Buttons (Cancel & Delete chat)
            Row(
              children: <Widget>[
                // Cancel (AppOutlineButton)
                Expanded(
                  child: AppOutlineButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Delete chat (AppGradientButton)
                Expanded(
                  child: AppGradientButton(
                    text: 'Delete chat',
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirmDelete();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

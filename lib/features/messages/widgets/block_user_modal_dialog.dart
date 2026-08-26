import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../create_post/widgets/custom_gradient_switch.dart';
import 'report_conversation_bottom_sheet.dart';

class BlockUserModalDialog extends StatefulWidget {
  const BlockUserModalDialog({
    required this.username,
    required this.onConfirmBlock,
    super.key,
  });

  final String username;
  final VoidCallback onConfirmBlock;

  static Future<void> show(
    BuildContext context, {
    required String username,
    required VoidCallback onConfirmBlock,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => BlockUserModalDialog(
        username: username,
        onConfirmBlock: onConfirmBlock,
      ),
    );
  }

  @override
  State<BlockUserModalDialog> createState() => _BlockUserModalDialogState();
}

class _BlockUserModalDialogState extends State<BlockUserModalDialog> {
  bool _alsoReport = false;

  @override
  Widget build(BuildContext context) {
    final String cleanUsername =
        widget.username.startsWith('@') ? widget.username : '@${widget.username}';

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
            // Top Circular Icon Container with Cyan Block Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: context.themeCyanBadgeBackground,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gradientCyan.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.block_rounded,
                color: AppColors.gradientCyan,
                size: 24,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Title Block @username?
            Text(
              'Block $cleanUsername?',
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
              "They won't be able to message you, find your profile or see your posts, and they're removed from your followers. They are not told.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.themeTextSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Also report this account toggle card
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: context.isDarkMode
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: context.themeBorder,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'Also report this account',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                  CustomGradientSwitch(
                    value: _alsoReport,
                    onChanged: (bool val) => setState(() => _alsoReport = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Block Gradient Button
            AppGradientButton(
              text: 'Block',
              onPressed: () {
                final ScaffoldMessengerState messenger =
                    ScaffoldMessenger.of(context);
                Navigator.pop(context);
                widget.onConfirmBlock();

                AppSnackBar.show(
                  context,
                  messenger: messenger,
                  title: '$cleanUsername blocked',
                  subtitle: 'Their posts and comments are gone from your app',
                  actionLabel: 'Undo',
                  onAction: () {
                    // Undo handler
                  },
                );

                if (_alsoReport) {
                  ReportConversationBottomSheet.show(
                    context,
                    username: widget.username,
                    onReportSubmitted: () {},
                  );
                }
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

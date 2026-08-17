import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_snackbar.dart';

class RestrictUserModalDialog extends StatelessWidget {
  const RestrictUserModalDialog({
    required this.username,
    required this.onConfirmRestrict,
    super.key,
  });

  final String username;
  final VoidCallback onConfirmRestrict;

  static Future<void> show(
    BuildContext context, {
    required String username,
    required VoidCallback onConfirmRestrict,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => RestrictUserModalDialog(
        username: username,
        onConfirmRestrict: onConfirmRestrict,
      ),
    );
  }

  Widget _buildBenefitCard({
    required String text,
    required bool isPositive,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md + 2,
        vertical: AppSpacing.md - 2,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            isPositive ? Icons.check_rounded : Icons.close_rounded,
            color: isPositive ? AppColors.gradientCyan : Colors.white38,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white70,
                fontSize: 12,
                height: 1.25,
              ),
            ),
          ),
        ],
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
          color: const Color(0xFF191622),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Top Circular Badge with Hide/Eye Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppIcons.hide,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Colors.white70,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Title: Restrict @username?
            Text(
              'Restrict $cleanUsername?',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: 6),

            // Subtitle Description
            Text(
              "A quieter option than blocking. Here's exactly what changes:",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white54,
                fontSize: 12,
                height: 1.35,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 4 Benefit Cards
            _buildBenefitCard(
              text: 'Their messages move to your requests tray silently',
              isPositive: true,
            ),
            _buildBenefitCard(
              text: 'Their comments on your posts show only to them',
              isPositive: true,
            ),
            _buildBenefitCard(
              text: "They can't see when you're active or if you've read anything",
              isPositive: true,
            ),
            _buildBenefitCard(
              text: 'They keep following you and are never told',
              isPositive: false,
            ),

            const SizedBox(height: AppSpacing.lg),

            // Restrict Button
            AppGradientButton(
              text: 'Restrict',
              onPressed: () {
                final ScaffoldMessengerState messenger =
                    ScaffoldMessenger.of(context);
                Navigator.pop(context);
                onConfirmRestrict();

                AppSnackBar.show(
                  context,
                  messenger: messenger,
                  title: '$cleanUsername restrict',
                  subtitle:
                      'Their comments only shows to them, DMs sent to the requests',
                  icon: SvgPicture.asset(
                    AppIcons.hide,
                    width: 18,
                    height: 18,
                    colorFilter: const ColorFilter.mode(
                      AppColors.gradientCyan,
                      BlendMode.srcIn,
                    ),
                  ),
                  actionLabel: 'Undo',
                );
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

import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../l10n/app_localizations.dart';

class GuestActionModalDialog extends StatelessWidget {
  const GuestActionModalDialog({
    required this.title,
    required this.subtitle,
    super.key,
    this.iconData = Icons.chat_bubble_outline_rounded,
  });

  final String title;
  final String subtitle;
  final IconData iconData;

  static void show(
    BuildContext context, {
    required String title,
    required String subtitle,
    IconData iconData = Icons.chat_bubble_outline_rounded,
  }) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: GuestActionModalDialog(
            title: title,
            subtitle: subtitle,
            iconData: iconData,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: context.themeBorder,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          // Top Right Close X Button
          Align(
            alignment: Alignment.topRight,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: AppSizes.buttonHeightSmall,
                height: AppSizes.buttonHeightSmall,
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.isDarkMode
                        ? Colors.white.withValues(alpha: 0.12)
                        : context.themeBorder,
                    width: 1.1,
                  ),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: context.themeIconMuted,
                  size: AppSizes.iconSm,
                ),
              ),
            ),
          ),

          // Center Cyan Badge Icon Container
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.themeCyanBadgeBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              iconData,
              color: AppColors.gradientCyan,
              size: AppSizes.iconMd,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              color: context.themeTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Subtitle
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.themeTextSecondary,
              height: 1.4,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // 1. Primary Reusable Button: "Create free account"
          AppGradientButton(
            text: l10n.guestCreateFreeAccountBtn,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.register);
            },
          ),

          const SizedBox(height: AppSpacing.md),

          // 2. Secondary Reusable Button: "Log in"
          AppOutlineButton(
            text: l10n.authLogIn,
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.login);
            },
          ),

          const SizedBox(height: AppSpacing.lg),

          // 3. Underlined Text Link: "Not ready? Keep browsing as guest"
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Text(
              l10n.guestNotReadyKeepBrowsing,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.themeTextSecondary,
                fontSize: 12,
                decoration: TextDecoration.underline,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

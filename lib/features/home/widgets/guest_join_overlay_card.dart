import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../l10n/app_localizations.dart';

class GuestJoinOverlayCard extends StatelessWidget {
  const GuestJoinOverlayCard({
    required this.onClose,
    super.key,
  });

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = context.isDarkMode;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.themeCardBackground.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: context.themeBorder,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.12),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header (Pink Lock Icon + Title + Close X)
          Row(
            children: <Widget>[
              const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.gradientPink,
                size: AppSizes.iconMd,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.guestJoinToLikeTitle,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.themeTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.gradientCyan,
                  size: AppSizes.iconMd,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // Subtitle
          Text(
            l10n.guestJoinToLikeSub,
            style: AppTextStyles.bodySmall.copyWith(
              color: context.themeTextSecondary,
              height: 1.35,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Reusable CTA Button: AppGradientButton
          AppGradientButton(
            text: l10n.guestCreateFreeAccountBtn,
            onPressed: () {
              Navigator.pushNamed(context, Routes.register);
            },
          ),
        ],
      ),
    );
  }
}

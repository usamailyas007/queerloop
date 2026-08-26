import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/screens/privacy_policy_screen.dart';
import '../../profile/screens/terms_of_service_screen.dart';

class GuestProfileTabScreen extends StatelessWidget {
  const GuestProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: AppSpacing.md),

              // Top Header: "GUEST"
              Text(
                l10n.guestProfileHeader,
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.themeTextMuted,
                  letterSpacing: 2.0,
                ),
              ),

              const Spacer(flex: 1),

              // Center Avatar Circle (Cyan Container)
              Center(
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: context.themeCyanBadgeBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.gradientCyan.withValues(alpha: 0.25),
                    ),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.gradientCyan,
                    size: 38,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Title: "You're browsing as Guest"
              Center(
                child: Text(
                  l10n.guestProfileTitle,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: context.themeTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Subtitle
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: Text(
                    l10n.guestProfileSub,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.themeTextSecondary,
                      height: 1.45,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // Primary Reusable Button Component: AppGradientButton
              AppGradientButton(
                text: l10n.guestCreateFreeAccountBtn,
                onPressed: () {
                  Navigator.pushNamed(context, Routes.register);
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Secondary Reusable Button Component: AppOutlineButton
              AppOutlineButton(
                text: l10n.authLogIn,
                onPressed: () {
                  Navigator.pushNamed(context, Routes.login);
                },
              ),

              const SizedBox(height: AppSpacing.xxl),

              Divider(color: context.themeDivider, height: 1),

              const SizedBox(height: AppSpacing.lg),

              // Terms & Conditions Tile
              _LegalTile(
                title: l10n.authTermsConditions,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const TermsOfServiceScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Privacy Policy Tile
              _LegalTile(
                title: l10n.authPrivacyPolicy,
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const PrivacyPolicyScreen(),
                    ),
                  );
                },
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalTile extends StatelessWidget {
  const _LegalTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: <Widget>[
          Icon(
            Icons.description_outlined,
            color: context.themeIconMuted,
            size: AppSizes.iconMd,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.themeTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: context.themeIconMuted,
            size: AppSizes.iconMd,
          ),
        ],
      ),
    );
  }
}

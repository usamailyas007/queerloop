import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../l10n/app_localizations.dart';
import '../provider/profile_setup_provider.dart';
import '../widgets/step_progress_header.dart';

class Step5YourPrivacyScreen extends StatelessWidget {
  const Step5YourPrivacyScreen({
    required this.onFinish,
    required this.onBack,
    super.key,
  });

  final VoidCallback onFinish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final ProfileSetupProvider provider = context.watch<ProfileSetupProvider>();
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Column(
            children: <Widget>[
              StepProgressHeader(
                currentStep: 5,
                totalSteps: 5,
                onBack: onBack,
                onSkip: onFinish,
              ),

              const SizedBox(height: AppSpacing.lg),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        l10n.profileStep5Title,
                        style: AppTextStyles.authHeaderTitle.copyWith(
                          color: context.themeTextPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        l10n.profileStep5Sub,
                        style: AppTextStyles.authHeaderSub.copyWith(
                          color: context.themeTextSecondary,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // ── 1. Private Account Card ────────────────────────────────
                      _PrivacyToggleCard(
                        title: l10n.profilePrivateAccount,
                        subtitle: l10n.profilePrivateAccountSub,
                        value: provider.isPrivateAccount,
                        onChanged: (bool val) =>
                            provider.togglePrivateAccount(val),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── 2. Show Me In Discover Card ───────────────────────────
                      _PrivacyToggleCard(
                        title: l10n.profileShowInDiscover,
                        subtitle: l10n.profileShowInDiscoverSub,
                        value: provider.showInDiscover,
                        onChanged: (bool val) =>
                            provider.toggleShowInDiscover(val),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── 3. Allow Messages From Card ───────────────────────────
                      _PrivacyNavCard(
                        title: l10n.profileAllowMessagesFrom,
                        valueText: provider.allowMessagesFrom,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.allowMessagesFrom,
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── 4. Hide My Likes Card ──────────────────────────────────
                      _PrivacyToggleCard(
                        title: l10n.profileHideMyLikes,
                        subtitle: l10n.profileHideMyLikesSub,
                        value: provider.hideMyLikes,
                        onChanged: (bool val) =>
                            provider.toggleHideMyLikes(val),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── 5. Profile Visibility Card ─────────────────────────────
                      _PrivacyNavCard(
                        title: l10n.profileVisibility,
                        valueText: provider.profileVisibility,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.profileVisibility,
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
              ),

              // ── Fixed Bottom CTA Button ────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.md,
                  bottom: AppSpacing.lg,
                ),
                child: AppGradientButton(
                  text: l10n.profileEnterQueerLoop,
                  onPressed: onFinish,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyToggleCard extends StatelessWidget {
  const _PrivacyToggleCard({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: TextStyle(
                    color: context.themeTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: context.themeTextMuted,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          AppSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _PrivacyNavCard extends StatelessWidget {
  const _PrivacyNavCard({
    required this.title,
    required this.valueText,
    required this.onTap,
  });

  final String title;
  final String valueText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.themeBorder),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      color: context.themeTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    valueText,
                    style: TextStyle(
                      color: context.themeTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.themeIconMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

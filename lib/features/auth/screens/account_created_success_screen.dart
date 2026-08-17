import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/success_animation_circle.dart';
import '../../../l10n/app_localizations.dart';
import '../../../app/routes.dart';

class AccountCreatedSuccessScreen extends StatelessWidget {
  const AccountCreatedSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              const Spacer(),

              // ── Animated Tick Circle (GIF Animation) ────────────────
              const SuccessAnimationCircle(size: 300),

              const SizedBox(height: AppSpacing.xxl),

              Text(
                l10n.authAccountCreatedTitle,
                style: AppTextStyles.successTitle,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.sm),

              Text(
                l10n.authAccountCreatedSub,
                style: AppTextStyles.successSub,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xxxl),

              AppGradientButton(
                text: l10n.authContinueToProfileBtn,
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.profileSetup,
                    (Route<dynamic> route) => false,
                  );
                },
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

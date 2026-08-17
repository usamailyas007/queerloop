import 'package:flutter/material.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/auth_back_button.dart';

class CodeExpiredScreen extends StatelessWidget {
  const CodeExpiredScreen({super.key, this.expiredCode});

  final String? expiredCode;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String codeStr = (expiredCode != null && expiredCode!.isNotEmpty)
        ? expiredCode!
        : '49999';

    final List<String> expiredDigits = List<String>.generate(5, (int i) {
      if (i < codeStr.length) {
        return codeStr[i];
      }
      return '9';
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: AppSpacing.md),
              const AuthBackButton(),
              const SizedBox(height: AppSpacing.xxxxl),

              // ── Red Clock Icon Header Box ─────────────────────────────
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF2C1929),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFF5252).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.access_time_rounded,
                    color: Color(0xFFFF5252),
                    size: 24,
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              Text(
                l10n.authCodeExpiredTitle,
                style: AppTextStyles.authHeaderTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.authCodeExpiredSub,
                style: AppTextStyles.authHeaderSub,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── 5 Expired Red OTP Boxes ──────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List<Widget>.generate(5, (int index) {
                  return Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B26),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        expiredDigits[index],
                        style: AppTextStyles.otpExpiredDigitText,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Code Expired Sub-text ─────────────────────────────────
              Center(
                child: Text(
                  l10n.authCodeExpiredStatus,
                  style: AppTextStyles.codeExpiredStatusText,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              AppGradientButton(
                text: l10n.authSendNewCodeBtn,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.verifyCode);
                },
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../widgets/auth_back_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(
    text: 'ash@queerloop.app',
  );

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.pushNamed(context, AppRoutes.verifyCode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: AppSpacing.md),
                const AuthBackButton(),
                const SizedBox(height: AppSpacing.xxxxl),

                // ── Pink Key Icon Header Box ─────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C1929),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gradientPink.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: SvgPicture.asset(
                      AppIcons.key,
                      width: 24,
                      height: 24,
                      colorFilter: const ColorFilter.mode(
                        AppColors.gradientPink,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                Text(
                  l10n.authResetPasswordTitle,
                  style: AppTextStyles.authHeaderTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.authResetPasswordSub,
                  style: AppTextStyles.authHeaderSub,
                ),

                const SizedBox(height: AppSpacing.xxl),

                AppTextField(
                  controller: _emailController,
                  hintText: l10n.authEmailAddress,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  prefixIconPath: AppIcons.mail,
                  onSubmitted: (_) => _submit(),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.authEnterEmailError;
                    }
                    final bool isValidEmail = RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(value.trim());
                    if (!isValidEmail) {
                      return l10n.authEnterValidEmailError;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                AppGradientButton(text: l10n.authSendCode, onPressed: _submit),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

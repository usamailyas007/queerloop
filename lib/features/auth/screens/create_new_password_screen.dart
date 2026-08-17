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

class CreateNewPasswordScreen extends StatefulWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  State<CreateNewPasswordScreen> createState() =>
      _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController =
      TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (_formKey.currentState?.validate() ?? false) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.authPasswordsDoNotMatch),
          ),
        );
        return;
      }
      Navigator.pushNamed(context, AppRoutes.passwordResetSuccess);
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
                  l10n.authCreateNewPasswordTitle,
                  style: AppTextStyles.authHeaderTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.authCreateNewPasswordSub,
                  style: AppTextStyles.authHeaderSub,
                ),

                const SizedBox(height: AppSpacing.xxl),

                AppTextField(
                  controller: _newPasswordController,
                  hintText: l10n.authNewPasswordHint,
                  isPassword: true,
                  textInputAction: TextInputAction.next,
                  prefixIconPath: AppIcons.password,
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return l10n.authEnterPasswordError;
                    }
                    if (value.length < 6) {
                      return l10n.authPasswordLengthError;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.md),

                AppTextField(
                  controller: _confirmPasswordController,
                  hintText: l10n.authConfirmPasswordHint,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  prefixIconPath: AppIcons.password,
                  onSubmitted: (_) => _submit(),
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return l10n.authEnterPasswordError;
                    }
                    if (value != _newPasswordController.text) {
                      return l10n.authPasswordsDoNotMatch;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                AppGradientButton(
                  text: l10n.authSaveNewPasswordBtn,
                  onPressed: _submit,
                ),

                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

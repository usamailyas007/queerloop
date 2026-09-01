import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_provider.dart';
import '../widgets/auth_back_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String email = _emailController.text.trim();
    final bool ok =
        await context.read<AuthProvider>().requestPasswordReset(email);
    if (ok && mounted) {
      AppSnackBar.showSuccess(
        context,
        title: 'Code Sent',
        subtitle: 'Verification code has been sent to $email',
      );
      Navigator.pushNamed(
        context,
        AppRoutes.verifyCode,
        arguments: email,
      );
    } else if (!ok && mounted) {
      final String? errorMsg = context.read<AuthProvider>().error;
      if (errorMsg != null && errorMsg.isNotEmpty) {
        AppSnackBar.showError(
          context,
          title: 'Request Failed',
          subtitle: errorMsg,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: AppSpacing.lg),
                const AuthBackButton(),
                const SizedBox(height: AppSpacing.xxxxl),

                // ── Pink Key Icon Header Box ─────────────────────────────
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2C1929)
                        : const Color(0xFFFFEBF2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.gradientPink.withValues(
                        alpha: isDark ? 0.3 : 0.2,
                      ),
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
                  style: AppTextStyles.authHeaderTitle.copyWith(
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.authResetPasswordSub,
                  style: AppTextStyles.authHeaderSub.copyWith(
                    color: context.themeTextSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                Selector<AuthProvider, bool>(
                  selector: (_, AuthProvider p) => p.isBusy,
                  builder: (_, bool busy, _) => AppTextField(
                    controller: _emailController,
                    enabled: !busy,
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
                ),

                // Error message
                Selector<AuthProvider, String?>(
                  selector: (_, AuthProvider p) => p.error,
                  builder: (_, String? error, _) {
                    if (error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(error, style: AppTextStyles.inputErrorText),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xl),

                Selector<AuthProvider, bool>(
                  selector: (_, AuthProvider p) => p.isBusy,
                  builder: (_, bool busy, _) => AppGradientButton(
                    text: l10n.authSendCode,
                    isLoading: busy,
                    onPressed: busy ? () {} : _submit,
                  ),
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

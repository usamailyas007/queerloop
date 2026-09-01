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
  String _resetTicket = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dynamic args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _resetTicket = args;
    } else if (args is Map && args['resetTicket'] != null) {
      _resetTicket = args['resetTicket'] as String;
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_newPasswordController.text != _confirmPasswordController.text) {
      AppSnackBar.showError(
        context,
        title: 'Passwords Mismatch',
        subtitle: l10n.authPasswordsDoNotMatch,
      );
      return;
    }

    final bool ok = await context.read<AuthProvider>().confirmPasswordReset(
          resetTicket: _resetTicket,
          newPassword: _newPasswordController.text,
        );

    if (ok && mounted) {
      AppSnackBar.showSuccess(
        context,
        title: 'Password Updated',
        subtitle: 'Your password has been changed successfully.',
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.passwordResetSuccess,
        (Route<dynamic> route) => route.settings.name == AppRoutes.login,
      );
    } else if (!ok && mounted) {
      final String? errorMsg = context.read<AuthProvider>().error;
      if (errorMsg != null && errorMsg.isNotEmpty) {
        AppSnackBar.showError(
          context,
          title: 'Reset Failed',
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
                  l10n.authCreateNewPasswordTitle,
                  style: AppTextStyles.authHeaderTitle.copyWith(
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  l10n.authCreateNewPasswordSub,
                  style: AppTextStyles.authHeaderSub.copyWith(
                    color: context.themeTextSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),

                Selector<AuthProvider, bool>(
                  selector: (_, AuthProvider p) => p.isBusy,
                  builder: (_, bool busy, _) => AppTextField(
                    controller: _newPasswordController,
                    enabled: !busy,
                    hintText: l10n.authNewPasswordHint,
                    isPassword: true,
                    textInputAction: TextInputAction.next,
                    prefixIconPath: AppIcons.password,
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.authEnterPasswordError;
                      }
                      if (value.length < 6) {
                        return l10n.authPasswordLengthError;
                      }
                      return null;
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                Selector<AuthProvider, bool>(
                  selector: (_, AuthProvider p) => p.isBusy,
                  builder: (_, bool busy, _) => AppTextField(
                    controller: _confirmPasswordController,
                    enabled: !busy,
                    hintText: l10n.authConfirmPasswordHint,
                    isPassword: true,
                    textInputAction: TextInputAction.done,
                    prefixIconPath: AppIcons.password,
                    onSubmitted: (_) => _submit(),
                    validator: (String? value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.authEnterPasswordError;
                      }
                      return null;
                    },
                  ),
                ),

                // Error display
                Selector<AuthProvider, String?>(
                  selector: (_, AuthProvider p) => p.error,
                  builder: (_, String? error, _) {
                    if (error == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Text(
                        error,
                        style: AppTextStyles.inputErrorText,
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.xxl),

                Selector<AuthProvider, bool>(
                  selector: (_, AuthProvider p) => p.isBusy,
                  builder: (_, bool busy, _) => AppGradientButton(
                    text: l10n.authSaveNewPasswordBtn,
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

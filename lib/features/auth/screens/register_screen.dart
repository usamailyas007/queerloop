import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_social_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_provider.dart';
import '../widgets/auth_back_button.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _agreedToTerms = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authAcceptTermsError)));
      return;
    }
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthProvider>().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushNamed(context, AppRoutes.accountCreatedSuccess);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? authError = context.watch<AuthProvider>().error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: AppSpacing.md),
                const AuthBackButton(),
                const SizedBox(height: AppSpacing.xxxlg),

                AuthHeader(
                  title: l10n.authCreateAccount,
                  subtitle: l10n.authCreateSub,
                ),

                const SizedBox(height: AppSpacing.xl),

                AppTextField(
                  controller: _emailController,
                  hintText: l10n.authEmailPlaceholder,
                  labelText: l10n.authEmail,
                  prefixIconPath: AppIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const <String>[AutofillHints.email],
                  validator: (String? val) {
                    if (val == null || val.trim().isEmpty) {
                      return l10n.authEnterEmailError;
                    }
                    if (!RegExp(
                      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                    ).hasMatch(val.trim())) {
                      return l10n.authEnterValidEmailError;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.lg),

                AppTextField(
                  controller: _passwordController,
                  hintText: l10n.authPassword,
                  labelText: l10n.authPassword,
                  prefixIconPath: AppIcons.password,
                  isPassword: true,
                  textInputAction: TextInputAction.done,
                  autofillHints: const <String>[AutofillHints.password],
                  validator: (String? val) {
                    if (val == null || val.isEmpty) {
                      return l10n.authEnterPasswordError;
                    }
                    if (val.length < 6) {
                      return l10n.authPasswordLengthError;
                    }
                    return null;
                  },
                ),

                const SizedBox(height: AppSpacing.xl),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                        });
                      },
                      child: Container(
                        width: AppSizes.checkboxSize,
                        height: AppSizes.checkboxSize,
                        decoration: BoxDecoration(
                          color: _agreedToTerms
                              ? AppColors.gradientCyan
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _agreedToTerms
                                ? AppColors.gradientCyan
                                : Colors.white38,
                            width: AppSizes.borderWidthFocused,
                          ),
                        ),
                        child: _agreedToTerms
                            ? const Icon(
                                Icons.check_rounded,
                                color: Colors.black,
                                size: AppSizes.iconXs,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: RichText(
                        textAlign: TextAlign.left,
                        text: TextSpan(
                          style: AppTextStyles.termsNormalText,
                          children: <TextSpan>[
                            TextSpan(text: l10n.authAgreeTermsPrefix),
                            TextSpan(
                              text: l10n.authTermsConditions,
                              style: AppTextStyles.termsLinkText,
                            ),
                            TextSpan(text: ' ${l10n.authAnd} \n'),
                            TextSpan(
                              text: l10n.authPrivacyPolicy,
                              style: AppTextStyles.termsLinkText,
                            ),
                            TextSpan(text: l10n.authPeriod),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.xl),

                AppGradientButton(
                  text: l10n.authSignUpEmail,
                  onPressed: _submit,
                ),

                if (authError != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  Text(authError, style: AppTextStyles.inputErrorText),
                ],

                const SizedBox(height: AppSpacing.md),

                AuthDivider(text: l10n.authOr),

                const SizedBox(height: AppSpacing.md),

                AppSocialButton(
                  text: l10n.authContinueApple,
                  iconPath: AppIcons.apple,
                  onPressed: () {},
                ),

                const SizedBox(height: AppSpacing.md),

                AppSocialButton(
                  text: l10n.authContinueGoogle,
                  iconPath: AppIcons.google,
                  onPressed: () {},
                ),

                const SizedBox(height: AppSpacing.xxxlg),

                // ── Footer Links Section ─────────────────────────────
                AuthFooterLink(
                  normalText: l10n.authJustLooking,
                  highlightedText: l10n.authBrowseAsGuest,
                  highlightGradient: AppColors.primaryGradientButton,
                  onTap: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (Route<dynamic> route) => false,
                      arguments: true,
                    );
                  },
                ),

                const SizedBox(height: AppSpacing.sm),

                AuthFooterLink(
                  normalText: l10n.authAlreadyHaveAccount,
                  highlightedText: l10n.authSignInNow,
                  highlightColor: AppColors.gradientPink,
                  onTap: () {
                    Navigator.pushNamed(context, AppRoutes.login);
                  },
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

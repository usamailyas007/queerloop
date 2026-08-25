import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_social_button.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_provider.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_header.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _staySignedIn = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<AuthProvider>().signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String? authError = context.select<AuthProvider, String?>(
      (AuthProvider provider) => provider.error,
    );
    final bool isBusy = context.select<AuthProvider, bool>(
      (AuthProvider provider) => provider.isBusy,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Scrollable content ────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPaddingHorizontal,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const SizedBox(height: AppSpacing.xxxlg),

                      AuthHeader(
                        title: l10n.authWelcomeBack,
                        subtitle: l10n.authWelcomeSub,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      AppTextField(
                        controller: _emailController,
                        enabled: !isBusy,
                        hintText: l10n.authEmailPlaceholder,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        prefixIconPath: AppIcons.mail,
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

                      const SizedBox(height: AppSpacing.md),

                      AppTextField(
                        controller: _passwordController,
                        enabled: !isBusy,
                        hintText: '•••••••••',
                        isPassword: true,
                        textInputAction: TextInputAction.done,
                        prefixIconPath: AppIcons.password,
                        onSubmitted: (_) => _submit(),
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

                      const SizedBox(height: AppSpacing.lg),

                      Row(
                        children: <Widget>[
                          AppSwitch(
                            value: _staySignedIn,
                            onChanged: (bool value) {
                              setState(() {
                                _staySignedIn = value;
                              });
                            },
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n.authStaySignedIn,
                            style: AppTextStyles.staySignedInText,
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.forgotPassword,
                              );
                            },
                            child: Text(
                              l10n.authForgotPassword,
                              style: AppTextStyles.forgotPasswordLink,
                            ),
                          ),
                        ],
                      ),

                      if (authError != null) ...<Widget>[
                        const SizedBox(height: AppSpacing.md),
                        Text(authError, style: AppTextStyles.inputErrorText),
                      ],

                      const SizedBox(height: AppSpacing.xl),

                      AppGradientButton(
                        text: l10n.authLogIn,
                        isLoading: isBusy,
                        onPressed: _submit,
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      AuthDivider(text: l10n.authOr),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Social Login Row ─────────────────────────────────
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AppSocialButton(
                              text: l10n.authApple,
                              iconPath: AppIcons.apple,
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppSocialButton(
                              text: l10n.authGoogle,
                              iconPath: AppIcons.google,
                              onPressed: () {},
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Pinned footer at bottom of screen ────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPaddingHorizontal,
                AppSpacing.md,
                AppSpacing.screenPaddingHorizontal,
                AppSpacing.xl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
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
                    normalText: l10n.authNewHere,
                    highlightedText: l10n.authCreateAnAccount,
                    highlightColor: AppColors.gradientPink,
                    onTap: () {
                      // Replace so back doesn't loop between login ↔ register
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.register,
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

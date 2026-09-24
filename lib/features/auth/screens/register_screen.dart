import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../profile/screens/privacy_policy_screen.dart';
import '../../profile/screens/terms_of_service_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_social_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile_setup/provider/profile_setup_provider.dart';
import '../auth_provider.dart';
import '../auth_service.dart';
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
  bool _isEmailLoading = false;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  bool get _isAnyBusy =>
      _isEmailLoading || _isGoogleLoading || _isAppleLoading;

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()..onTap = _navigateToTerms;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _navigateToPrivacy;
    _emailController.addListener(_clearAuthError);
    _passwordController.addListener(_clearAuthError);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().clearError();
      }
    });
  }

  void _clearAuthError() {
    final AuthProvider authProvider = context.read<AuthProvider>();
    if (authProvider.error != null) {
      authProvider.clearError();
    }
  }

  @override
  void deactivate() {
    context.read<AuthProvider>().clearError();
    super.deactivate();
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _emailController.removeListener(_clearAuthError);
    _passwordController.removeListener(_clearAuthError);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToTerms() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const TermsOfServiceScreen(),
      ),
    );
  }

  void _navigateToPrivacy() {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const PrivacyPolicyScreen(),
      ),
    );
  }

  Future<void> _submit() async {
    final AppLocalizations l10n = AppLocalizations.of(context);
    if (!_agreedToTerms) {
      AppSnackBar.showError(
        context,
        title: 'Terms Required',
        subtitle: l10n.authAcceptTermsError,
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    if (_isAnyBusy) return;

    final AuthProvider authProvider = context.read<AuthProvider>();
    authProvider.clearError();
    setState(() => _isEmailLoading = true);
    final bool ok = await authProvider.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (!ok) {
      if (mounted) {
        setState(() => _isEmailLoading = false);
        final String? errorMsg = authProvider.error;
        if (errorMsg != null && errorMsg.isNotEmpty) {
          AppSnackBar.showError(
            context,
            title: 'Sign Up Failed',
            subtitle: errorMsg,
          );
        }
      }
      return;
    }

    if (!mounted) return;
    setState(() => _isEmailLoading = false);
    Navigator.pushNamed(
      context,
      AppRoutes.verifyEmailOtp,
      arguments: _emailController.text.trim(),
    );
  }

  // ── Social Sign-In ─────────────────────────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    final AuthProvider authProvider = context.read<AuthProvider>();
    if (_isAnyBusy || authProvider.isBusy) return;

    setState(() => _isGoogleLoading = true);
    final SocialSignInResult result;
    try {
      result = await authProvider.signInWithGoogle();
    } catch (e) {
      if (mounted) setState(() => _isGoogleLoading = false);
      return;
    }

    if (!mounted) return;

    if (result.isCancelled) {
      setState(() => _isGoogleLoading = false);
      return;
    }

    if (result.accountExistsWithPassword) {
      setState(() => _isGoogleLoading = false);
      AppSnackBar.showInfo(
        context,
        title: 'Account Exists',
        subtitle: result.errorMessage ??
            'This email is already registered with a password. Please sign in.',
      );
      Navigator.pushNamed(
        context,
        AppRoutes.login,
      );
      return;
    }

    if (result.isError) {
      setState(() => _isGoogleLoading = false);
      final String? errorMsg = result.errorMessage ?? authProvider.error;
      if (errorMsg != null && errorMsg.isNotEmpty) {
        AppSnackBar.showError(
          context,
          title: 'Sign In Failed',
          subtitle: errorMsg,
        );
        authProvider.clearError();
      }
      return;
    }

    // Pre-fill profile setup provider if Google metadata exists
    if (result.displayName != null || result.photoUrl != null) {
      context.read<ProfileSetupProvider>().prefillSocialData(
        displayName: result.displayName,
        avatarUrl: result.photoUrl,
      );
    }

    // Case 1: Newly registered via Google -> Navigate to email OTP verification
    if (result.needsVerification) {
      if (result.errorMessage != null && result.errorMessage!.isNotEmpty) {
        AppSnackBar.showInfo(
          context,
          title: 'Verification Code Sent',
          subtitle: result.errorMessage!,
        );
      }
      Navigator.pushNamed(
        context,
        AppRoutes.verifyEmailOtp,
        arguments: result.email,
      ).then((_) {
        if (mounted) setState(() => _isGoogleLoading = false);
      });
      return;
    }

    // Case 2: User logged in but profile not setup yet -> Navigate to profile setup
    if (result.needsProfileSetup) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.profileSetup,
        (Route<dynamic> route) => false,
      );
      return;
    }

    // Case 3: Already registered and profile completed -> Go Home
    if (result.isSuccess) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (Route<dynamic> route) => false,
      );
    } else {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _signInWithSocial(
    Future<bool> Function() socialMethod,
  ) async {
    final AuthProvider authProvider = context.read<AuthProvider>();
    if (_isAnyBusy || authProvider.isBusy) return;

    setState(() => _isAppleLoading = true);
    final bool ok;
    try {
      ok = await socialMethod();
    } catch (e) {
      if (mounted) setState(() => _isAppleLoading = false);
      return;
    }
    if (!ok) {
      if (mounted) {
        setState(() => _isAppleLoading = false);
        final String? errorMsg = authProvider.error;
        if (errorMsg != null && errorMsg.isNotEmpty) {
          AppSnackBar.showError(
            context,
            title: 'Sign In Failed',
            subtitle: errorMsg,
          );
          authProvider.clearError();
        }
      }
      return;
    }

    if (!mounted) return;
    // Social auth — no OTP verification needed, go directly home.
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.themeBackground,
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
                          if (val.length < 8) {
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
                                      : context.themeBorderStrong,
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
                                style: AppTextStyles.termsNormalText.copyWith(
                                  color: context.themeTextSecondary,
                                ),
                                children: <TextSpan>[
                                  TextSpan(text: l10n.authAgreeTermsPrefix),
                                  TextSpan(
                                    text: l10n.authTermsConditions,
                                    style: AppTextStyles.termsLinkText,
                                    recognizer: _termsRecognizer,
                                  ),
                                  TextSpan(
                                    text: ' ${l10n.authAnd} \n',
                                    style: TextStyle(
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: l10n.authPrivacyPolicy,
                                    style: AppTextStyles.termsLinkText,
                                    recognizer: _privacyRecognizer,
                                  ),
                                  TextSpan(
                                    text: l10n.authPeriod,
                                    style: TextStyle(
                                      color: context.themeTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Sign-up button — rebuilds only when isBusy flips
                      AppGradientButton(
                        text: l10n.authSignUpEmail,
                        isLoading: _isEmailLoading,
                        onPressed: _isAnyBusy ? () {} : _submit,
                      ),

                      // ── Error banner — only this Text rebuilds on error
                      Selector<AuthProvider, String?>(
                        selector: (_, AuthProvider p) => p.error,
                        builder: (_, String? error, _) {
                          if (error == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.md),
                            child: Text(
                              error,
                              style: AppTextStyles.inputErrorText,
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.md),

                      AuthDivider(text: l10n.authOr),

                      const SizedBox(height: AppSpacing.md),

                      // ── Social Sign-up Button (platform-specific) ────────
                      // Android: Google only | iOS: Apple only
                      if (Platform.isIOS)
                        AppSocialButton(
                          text: l10n.authContinueApple,
                          iconPath: AppIcons.apple,
                          isLoading: _isAppleLoading,
                          onPressed: _isAnyBusy
                              ? () {}
                              : () => _signInWithSocial(
                                    () => context
                                        .read<AuthProvider>()
                                        .signInWithApple(),
                                  ),
                        )
                      else
                        AppSocialButton(
                          text: l10n.authContinueGoogle,
                          iconPath: AppIcons.google,
                          isLoading: _isGoogleLoading,
                          onPressed: _isAnyBusy ? () {} : _handleGoogleSignIn,
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
                    normalText: l10n.authAlreadyHaveAccount,
                    highlightedText: l10n.authSignInNow,
                    highlightColor: AppColors.gradientPink,
                    onTap: () {
                      context.read<AuthProvider>().clearError();
                      // Replace so back doesn't loop between register ↔ login
                      Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.login,
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

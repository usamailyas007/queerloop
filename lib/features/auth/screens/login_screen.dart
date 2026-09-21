import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_social_button.dart';
import '../../../core/widgets/app_switch.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../home/provider/home_feed_provider.dart';
import '../../home/screens/home_screen.dart';
import '../../home/services/reel_video_preloader.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile_setup/provider/profile_setup_provider.dart';
import '../auth_provider.dart';
import '../auth_service.dart';
import '../widgets/auth_divider.dart';
import '../widgets/auth_footer_link.dart';
import '../widgets/auth_header.dart';
import 'account_pending_deletion_screen.dart';

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
  bool _isPreloadingFeed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Submit ────────────────────────────────────────────────────────────────
  // await the provider call so we only navigate on a real success response.
  // isBusy guard inside the provider prevents double-submissions.

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final AuthProvider authProvider = context.read<AuthProvider>();
    setState(() => _isPreloadingFeed = true);
    final bool ok = await authProvider.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!ok) {
      if (mounted) {
        setState(() => _isPreloadingFeed = false);
        if (authProvider.errorCode == 'EMAIL_NOT_VERIFIED') {
          final String email = _emailController.text.trim();
          authProvider.resendEmailOtp(email);
          AppSnackBar.showInfo(
            context,
            title: 'Verification Required',
            subtitle:
                'Please verify your email address before signing in. A new verification code has been sent.',
          );
          Navigator.pushNamed(
            context,
            AppRoutes.verifyEmailOtp,
            arguments: email,
          );
          return;
        }

        if (authProvider.errorCode == 'ACCOUNT_PENDING_DELETION') {
          final dynamic errData = authProvider.errorData;
          String? restorationToken;
          String? scheduledFor;
          if (errData is Map) {
            final dynamic inner =
                (errData['data'] is Map) ? errData['data'] : errData;
            restorationToken = inner['restorationToken']?.toString();
            scheduledFor =
                (inner['deletionScheduledAt'] ?? inner['scheduledFor'])
                    ?.toString();
          }
          restorationToken ??= authProvider.pendingDeletionRestorationToken;
          scheduledFor ??= authProvider.deletionScheduledAt;

          if (restorationToken != null && restorationToken.isNotEmpty) {
            authProvider.clearError();
            Navigator.push<void>(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AccountPendingDeletionScreen(
                  restorationToken: restorationToken!,
                  scheduledFor: scheduledFor,
                ),
              ),
            );
            return;
          }
          // No restoration token — fall through to display error
        }

        final String? errorMsg = authProvider.error;
        if (errorMsg != null && errorMsg.isNotEmpty) {
          AppSnackBar.showError(
            context,
            title: 'Login Failed',
            subtitle: errorMsg,
          );
        }
      }
      return;
    }

    if (!mounted) return;
    final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
    homeFeed.resetToHome();

    // 🚀 Wait and prefetch feed + buffer initial reel video + own profile so they appear instantly!
    final String? uid = authProvider.userId;
    final List<Future<dynamic>> warmUpTasks = <Future<dynamic>>[];

    if (uid != null && uid.isNotEmpty) {
      warmUpTasks.add(
        context.read<ProfileProvider>().fetchProfile(uid).catchError((_) {}),
      );
    }

    warmUpTasks.add(() async {
      try {
        await homeFeed.loadFeed();
        if (homeFeed.reels.isNotEmpty) {
          final firstReel = homeFeed.reels.first;
          final controller =
              await ReelVideoPreloader.instance.getOrCreate(firstReel);
          if (controller != null && !controller.value.isInitialized) {
            await controller.initialize().timeout(
                  const Duration(seconds: 4),
                  onTimeout: () => controller,
                );
          }
          ReelVideoPreloader.instance.preloadSurrounding(homeFeed.reels, 0);
        }
      } catch (e) {
        debugPrint('⚠️ [Login] Pre-fetching feed failed: $e');
      }
    }());

    await Future.wait(warmUpTasks).timeout(
      const Duration(seconds: 5),
      onTimeout: () => <dynamic>[],
    );

    if (!mounted) return;
    setState(() => _isPreloadingFeed = false);
    _goHome(context);
  }

  // ── Social Sign-In helpers ─────────────────────────────────────────────────

  Future<void> _handleGoogleSignIn() async {
    final AuthProvider authProvider = context.read<AuthProvider>();
    if (authProvider.isBusy) return;

    final SocialSignInResult result = await authProvider.signInWithGoogle();

    if (!mounted) return;

    if (result.isCancelled) {
      return;
    }

    if (result.isError) {
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
      );
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

    // Case 3: Already registered and profile completed -> Preload feed and Go Home
    if (result.isSuccess) {
      final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
      homeFeed.resetToHome();
      final String? uid = authProvider.userId;
      final List<Future<dynamic>> warmUpTasks = <Future<dynamic>>[];
      if (uid != null && uid.isNotEmpty) {
        warmUpTasks.add(
          context.read<ProfileProvider>().fetchProfile(uid).catchError((_) {}),
        );
      }
      warmUpTasks.add(() async {
        try {
          await homeFeed.loadFeed();
          if (homeFeed.reels.isNotEmpty) {
            final firstReel = homeFeed.reels.first;
            final controller =
                await ReelVideoPreloader.instance.getOrCreate(firstReel);
            if (controller != null && !controller.value.isInitialized) {
              await controller.initialize().timeout(
                    const Duration(seconds: 4),
                    onTimeout: () => controller,
                  );
            }
            ReelVideoPreloader.instance.preloadSurrounding(homeFeed.reels, 0);
          }
        } catch (e) {
          debugPrint('⚠️ [Login] Social pre-fetching feed failed: $e');
        }
      }());
      await Future.wait(warmUpTasks).timeout(
        const Duration(seconds: 5),
        onTimeout: () => <dynamic>[],
      );

      if (!mounted) return;
      _goHome(context);
    }
  }

  Future<void> _signInWithSocial(
    Future<bool> Function() socialMethod,
  ) async {
    final AuthProvider authProvider = context.read<AuthProvider>();
    if (authProvider.isBusy) return;

    final bool ok = await socialMethod();
    if (!ok) {
      if (mounted) {
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
    // Warmup feed after social login
    final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
    homeFeed.resetToHome();
    final String? uid = authProvider.userId;
    final List<Future<dynamic>> warmUpTasks = <Future<dynamic>>[];
    if (uid != null && uid.isNotEmpty) {
      warmUpTasks.add(
        context.read<ProfileProvider>().fetchProfile(uid).catchError((_) {}),
      );
    }
    warmUpTasks.add(() async {
      try {
        await homeFeed.loadFeed();
        if (homeFeed.reels.isNotEmpty) {
          final firstReel = homeFeed.reels.first;
          final controller =
              await ReelVideoPreloader.instance.getOrCreate(firstReel);
          if (controller != null && !controller.value.isInitialized) {
            await controller.initialize().timeout(
                  const Duration(seconds: 4),
                  onTimeout: () => controller,
                );
          }
          ReelVideoPreloader.instance.preloadSurrounding(homeFeed.reels, 0);
        }
      } catch (e) {
        debugPrint('⚠️ [Login] Social pre-fetching feed failed: $e');
      }
    }());
    await Future.wait(warmUpTasks).timeout(
      const Duration(seconds: 5),
      onTimeout: () => <dynamic>[],
    );

    if (!mounted) return;
    _goHome(context);
  }

  /// Navigates to HomeScreen with NO transition animation.
  /// A zero-duration instant swap prevents the layout-calculation window
  /// that causes the bottom nav bar to briefly appear at the top during a
  /// standard MaterialPageRoute slide-in animation.
  static void _goHome(BuildContext context, {bool isGuest = false}) {
    Navigator.pushAndRemoveUntil<void>(
      context,
      PageRouteBuilder<void>(
        pageBuilder: (ctx, anim, anim2) => HomeScreen(isGuest: isGuest),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
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
                        title: l10n.authWelcomeBack,
                        subtitle: l10n.authWelcomeSub,
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Email field — reads isBusy via Selector so only
                      //    the enabled state triggers a rebuild here.
                      Selector<AuthProvider, bool>(
                        selector: (_, AuthProvider p) => p.isBusy,
                        builder: (_, bool busy, _) => AppTextField(
                          controller: _emailController,
                          enabled: !busy,
                          hintText: l10n.authEmailPlaceholder,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          prefixIconPath: AppIcons.mail,
                          validator: (String? value) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.authEnterEmailError;
                            }
                            if (!RegExp(
                              r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                            ).hasMatch(value.trim())) {
                              return l10n.authEnterValidEmailError;
                            }
                            return null;
                          },
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Password field
                      Selector<AuthProvider, bool>(
                        selector: (_, AuthProvider p) => p.isBusy,
                        builder: (_, bool busy, _) => AppTextField(
                          controller: _passwordController,
                          enabled: !busy,
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
                            style: AppTextStyles.staySignedInText.copyWith(
                              color: context.themeTextSecondary,
                            ),
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

                      // ── Error banner — only this Text rebuilds on error
                      Selector<AuthProvider, String?>(
                        selector: (_, AuthProvider p) => p.error,
                        builder: (_, String? error, _) {
                          if (error == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding:
                                const EdgeInsets.only(top: AppSpacing.md),
                            child:
                                Text(error, style: AppTextStyles.inputErrorText),
                          );
                        },
                      ),

                      const SizedBox(height: AppSpacing.xl),

                      // ── Login button — rebuilds when busy or preloading
                      Selector<AuthProvider, bool>(
                        selector: (_, AuthProvider p) => p.isBusy,
                        builder: (_, bool busy, _) => AppGradientButton(
                          text: l10n.authLogIn,
                          isLoading: busy || _isPreloadingFeed,
                          onPressed: (busy || _isPreloadingFeed) ? () {} : _submit,
                        ),
                      ),

                      const SizedBox(height: AppSpacing.lg),

                      AuthDivider(text: l10n.authOr),

                      const SizedBox(height: AppSpacing.lg),

                      // ── Social Login Row ─────────────────────────────────
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Selector<AuthProvider, bool>(
                              selector: (_, AuthProvider p) => p.isBusy,
                              builder: (_, bool busy, _) => AppSocialButton(
                                text: l10n.authApple,
                                iconPath: AppIcons.apple,
                                onPressed: busy
                                    ? () {}
                                    : () => _signInWithSocial(
                                          () => context
                                              .read<AuthProvider>()
                                              .signInWithApple(),
                                        ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Selector<AuthProvider, bool>(
                              selector: (_, AuthProvider p) => p.isBusy,
                              builder: (_, bool busy, _) => AppSocialButton(
                                text: l10n.authGoogle,
                                iconPath: AppIcons.google,
                                onPressed: busy ? () {} : _handleGoogleSignIn,
                              ),
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
                    onTap: () => _goHome(context, isGuest: true),
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

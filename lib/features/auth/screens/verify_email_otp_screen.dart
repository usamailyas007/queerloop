import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../auth_provider.dart';
import '../widgets/auth_back_button.dart';

class VerifyEmailOtpScreen extends StatefulWidget {
  const VerifyEmailOtpScreen({super.key});

  @override
  State<VerifyEmailOtpScreen> createState() => _VerifyEmailOtpScreenState();
}

class _VerifyEmailOtpScreenState extends State<VerifyEmailOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _timer;
  int _secondsLeft = 60;
  String _email = '';
  int _failedAttempts = 0;
  bool _dailyLimitReached = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _otpFocusNode.addListener(_onFocusChange);
    _startTimer(60);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_email.isEmpty) {
      final dynamic args = ModalRoute.of(context)?.settings.arguments;
      if (args is String && args.isNotEmpty) {
        _email = args;
      } else if (args is Map && args['email'] != null) {
        _email = args['email'] as String;
      }
    }
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _startTimer(int seconds) {
    _timer?.cancel();
    setState(() {
      _secondsLeft = seconds;
    });

    if (seconds <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _secondsLeft = 0;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _secondsLeft--;
          });
        }
      }
    });
  }

  String get _formattedTimer {
    final int minutes = _secondsLeft ~/ 60;
    final int seconds = _secondsLeft % 60;
    final String mStr = minutes.toString().padLeft(2, '0');
    final String sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpFocusNode.removeListener(_onFocusChange);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String otp = _otpController.text.trim();
    if (otp.length < 6 || _isSubmitting) return;

    if (_failedAttempts >= 5) {
      AppSnackBar.showError(
        context,
        title: 'Code Expired',
        subtitle:
            'This verification code is dead after 5 incorrect attempts. Please request a new code.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final AuthProvider auth = context.read<AuthProvider>();
    final bool ok = await auth.verifyEmailOtp(
      email: _email,
      otp: otp,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (ok) {
      _timer?.cancel();
      AppSnackBar.showSuccess(
        context,
        title: 'Email Verified',
        subtitle: 'Your email has been verified successfully.',
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.accountCreatedSuccess,
        (Route<dynamic> route) => false,
      );
    } else {
      final String? code = auth.errorCode;
      final String? errorMsg = auth.error;

      // Handle 409 already verified
      if (code == 'ALREADY_VERIFIED' ||
          (errorMsg != null && errorMsg.toLowerCase().contains('already verified'))) {
        AppSnackBar.showInfo(
          context,
          title: 'Already Verified',
          subtitle: 'This account is already verified. Please sign in.',
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (Route<dynamic> route) => false,
        );
        return;
      }

      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _otpController.clear();
        AppSnackBar.showError(
          context,
          title: 'Code Invalidation',
          subtitle:
              'You have entered the wrong code 5 times. This code is no longer valid. Please tap Resend Code.',
        );
      } else {
        AppSnackBar.showError(
          context,
          title: 'Verification Failed',
          subtitle: errorMsg ?? 'Invalid or expired verification code.',
        );
      }
    }
  }

  Future<void> _handleResend() async {
    if (_email.isEmpty || _secondsLeft > 0 || _dailyLimitReached) return;

    final AuthProvider auth = context.read<AuthProvider>();
    final bool ok = await auth.resendEmailOtp(_email);

    if (!mounted) return;

    if (ok) {
      _failedAttempts = 0;
      _otpController.clear();
      _startTimer(60);
      AppSnackBar.showSuccess(
        context,
        title: 'Code Sent',
        subtitle: 'A new 6-digit verification code has been sent to your email.',
      );
    } else {
      final String? code = auth.errorCode;
      final int? retryAfter = auth.retryAfterSeconds;

      if (code == 'OTP_DAILY_LIMIT_REACHED') {
        setState(() {
          _dailyLimitReached = true;
          _secondsLeft = 0;
        });
        _timer?.cancel();
        AppSnackBar.showError(
          context,
          title: 'Daily Limit Reached',
          subtitle:
              'You have reached the daily limit for verification codes. Please try again tomorrow.',
        );
      } else if (code == 'OTP_COOLDOWN' || retryAfter != null) {
        final int waitTime = retryAfter ?? 60;
        _startTimer(waitTime);
        AppSnackBar.showInfo(
          context,
          title: 'Please Wait',
          subtitle: 'Please wait ${waitTime}s before requesting another code.',
        );
      } else {
        AppSnackBar.showError(
          context,
          title: 'Resend Failed',
          subtitle: auth.error ?? 'Failed to resend verification code.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final String otpText = _otpController.text;
    final bool isFocused = _otpFocusNode.hasFocus;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: AppSpacing.md),
              const AuthBackButton(),
              const SizedBox(height: AppSpacing.xxl),

              // ── Header ───────────────────────────────────────────────
              Text(
                'Verify your email',
                style: AppTextStyles.authHeaderTitle.copyWith(
                  color: context.themeTextPrimary,
                  fontSize: 26,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              RichText(
                text: TextSpan(
                  text: 'We sent a 6-digit verification code to\n',
                  style: AppTextStyles.authHeaderSub.copyWith(
                    color: context.themeTextSecondary,
                    height: 1.4,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: _email.isNotEmpty ? _email : 'your email',
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(
                      text: '. Enter it to finish creating your account.',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── 6 Hidden Input Boxes Overlay ─────────────────────────
              GestureDetector(
                onTap: () {
                  _otpFocusNode.requestFocus();
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // Invisible real input
                    Opacity(
                      opacity: 0.0,
                      child: TextField(
                        controller: _otpController,
                        focusNode: _otpFocusNode,
                        keyboardType: TextInputType.number,
                        inputFormatters: <TextInputFormatter>[
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(6),
                        ],
                        onChanged: (String val) {
                          setState(() {});
                          if (val.length == 6) {
                            _submit();
                          }
                        },
                      ),
                    ),

                    // Visual 6 custom digit boxes
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List<Widget>.generate(6, (int index) {
                        final bool hasChar = index < otpText.length;
                        final bool isCurrentFocus =
                            isFocused && index == otpText.length;

                        return Container(
                          width: 48,
                          height: 54,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1B26)
                                : context.themeCardBackground,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isCurrentFocus
                                  ? AppColors.gradientCyan
                                  : (hasChar
                                      ? AppColors.gradientPink
                                      : (isDark
                                          ? const Color(0xFF2D2938)
                                          : context.themeBorder)),
                              width: isCurrentFocus ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              hasChar ? otpText[index] : '',
                              style: AppTextStyles.otpDigitText.copyWith(
                                color: context.themeTextPrimary,
                                fontSize: 20,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              if (_failedAttempts > 0 && _failedAttempts < 5) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Wrong code entered ($_failedAttempts of 5 attempts used).',
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 12.5,
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),

              // ── Submit Button ─────────────────────────────────────────
              AppGradientButton(
                text: 'Verify & Continue',
                isEnabled: otpText.length == 6 && !_isSubmitting,
                isLoading: _isSubmitting,
                onPressed: _submit,
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Resend & Timer Area ───────────────────────────────────
              Center(
                child: _dailyLimitReached
                    ? Text(
                        'Daily code limit reached. Please try again tomorrow.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: context.themeTextMuted,
                          fontSize: 13,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            "Didn't receive the code? ",
                            style: TextStyle(
                              color: context.themeTextSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (_secondsLeft > 0)
                            Text(
                              'Resend in $_formattedTimer',
                              style: const TextStyle(
                                color: AppColors.gradientCyan,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            GestureDetector(
                              onTap: _handleResend,
                              behavior: HitTestBehavior.opaque,
                              child: const Text(
                                'Resend Code',
                                style: TextStyle(
                                  color: AppColors.gradientPink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

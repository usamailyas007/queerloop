import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../l10n/app_localizations.dart';
import '../auth_provider.dart';
import '../widgets/auth_back_button.dart';

class VerifyCodeScreen extends StatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  Timer? _timer;
  int _startSeconds = 60;
  String _email = '';

  @override
  void initState() {
    super.initState();
    _otpFocusNode.addListener(_onFocusChange);
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dynamic args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && args.isNotEmpty) {
      _email = args;
    } else if (args is Map && args['email'] != null) {
      _email = args['email'] as String;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _startSeconds = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_startSeconds == 0) {
        timer.cancel();
        if (mounted) {
          setState(() {});
        }
      } else {
        if (mounted) {
          setState(() {
            _startSeconds--;
          });
        }
      }
    });
  }

  String get _formattedTimer {
    final int minutes = _startSeconds ~/ 60;
    final int seconds = _startSeconds % 60;
    final String mStr = minutes.toString().padLeft(2, '0');
    final String sStr = seconds.toString().padLeft(2, '0');
    return '$mStr:$sStr';
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() {});
    }
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
    if (otp.length < 6) return;

    final String? resetTicket =
        await context.read<AuthProvider>().verifyPasswordResetOtp(
              email: _email,
              otp: otp,
            );

    if (resetTicket != null && resetTicket.isNotEmpty && mounted) {
      _timer?.cancel();
      Navigator.pushNamed(
        context,
        AppRoutes.createNewPassword,
        arguments: <String, dynamic>{
          'email': _email,
          'resetTicket': resetTicket,
        },
      );
    }
  }

  Future<void> _handleResend() async {
    if (_email.isEmpty) return;
    final bool ok =
        await context.read<AuthProvider>().requestPasswordReset(_email);
    if (ok && mounted) {
      _startTimer();
      _otpController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('A fresh verification code was sent to $_email'),
          backgroundColor: AppColors.gradientPink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String otpText = _otpController.text;
    final bool isFocused = _otpFocusNode.hasFocus;
    final bool isDark = context.isDarkMode;

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
                l10n.authEnterYourCodeTitle,
                style: AppTextStyles.authHeaderTitle.copyWith(
                  color: context.themeTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                _email.isNotEmpty
                    ? 'We sent a 6-digit code to $_email'
                    : l10n.authEnterYourCodeSub,
                style: AppTextStyles.authHeaderSub.copyWith(
                  color: context.themeTextSecondary,
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

              // Error display
              Selector<AuthProvider, String?>(
                selector: (_, AuthProvider p) => p.error,
                builder: (_, String? error, _) {
                  if (error == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.md),
                    child: Center(
                      child: Text(
                        error,
                        style: AppTextStyles.inputErrorText,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Timer / Resend Row ───────────────────────────────────
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      l10n.authResendCodePrefix,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.themeTextMuted,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    if (_startSeconds > 0)
                      Text(
                        _formattedTimer,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gradientCyan,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: _handleResend,
                        child: Text(
                          'Resend now',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.gradientPink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              Selector<AuthProvider, bool>(
                selector: (_, AuthProvider p) => p.isBusy,
                builder: (_, bool busy, _) => AppGradientButton(
                  text: l10n.authEnterCodeBtn,
                  isLoading: busy,
                  onPressed: busy ? () {} : _submit,
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

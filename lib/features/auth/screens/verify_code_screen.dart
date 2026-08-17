import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../l10n/app_localizations.dart';
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
  int _startSeconds = 30; // 30 seconds for testing

  @override
  void initState() {
    super.initState();
    _otpFocusNode.addListener(_onFocusChange);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _startSeconds = 30; // 30 seconds for testing
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

  void _submit() {
    _timer?.cancel();
    if (_startSeconds == 0) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.codeExpired,
        arguments: _otpController.text,
      );
    } else {
      Navigator.pushNamed(context, AppRoutes.createNewPassword);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String otpText = _otpController.text;
    final bool isFocused = _otpFocusNode.hasFocus;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPaddingHorizontal,
          ),
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
                l10n.authEnterYourCodeTitle,
                style: AppTextStyles.authHeaderTitle,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.authEnterYourCodeSub,
                style: AppTextStyles.authHeaderSub,
              ),

              const SizedBox(height: AppSpacing.xxl),

              // ── Dynamic PinPut OTP Widget ─────────────────────────────
              GestureDetector(
                onTap: () => _otpFocusNode.requestFocus(),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List<Widget>.generate(5, (int index) {
                        final bool hasValue = index < otpText.length;
                        final int activeIndex = otpText.isEmpty
                            ? 0
                            : (otpText.length < 5 ? otpText.length - 1 : 4);
                        final bool isActiveBox =
                            isFocused && index == activeIndex;
                        final bool isHiddenDot =
                            hasValue && index < activeIndex;

                        return Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1B26),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isActiveBox
                                  ? AppColors.gradientPink
                                  : Colors.white.withValues(alpha: 0.12),
                              width: isActiveBox ? 1.5 : 1,
                            ),
                          ),
                          child: Center(
                            child: isHiddenDot
                                ? Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: AppColors.gradientPink,
                                      shape: BoxShape.circle,
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: AppColors.gradientPink
                                              .withValues(alpha: 0.6),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  )
                                : (hasValue
                                    ? Text(
                                        otpText[index],
                                        style: AppTextStyles.otpDigitText,
                                      )
                                    : const SizedBox.shrink()),
                          ),
                        );
                      }),
                    ),
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _otpFocusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          autofocus: true,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          onChanged: (String value) {
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Resend Code Timer Text ─────────────────────────────────
              Center(
                child: Text(
                  '${l10n.authResendCodePrefix}$_formattedTimer',
                  style: AppTextStyles.timerText,
                ),
              ),

              const SizedBox(height: AppSpacing.xxl),

              AppGradientButton(
                text: l10n.authEnterCodeBtn,
                onPressed: _submit,
              ),

              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }
}

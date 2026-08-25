// Text style tokens for both apps.

import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  static const String fontFamily = 'HankenGrotesk';

  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 22,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const TextStyle titleLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: Colors.white54,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    height: 1.2,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w600,
    color: AppColors.textInverse,
  );

  static const TextStyle authHeaderTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: Colors.white,
    letterSpacing: -0.3,
  );

  static const TextStyle authHeaderSub = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: Color(0xFF94A3B8),
    height: 1.4,
  );

  static const TextStyle authFooterText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: Colors.white54,
    fontWeight: FontWeight.w400,
  );

  static TextStyle authFooterLink({Color? color}) => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: color ?? AppColors.gradientPink,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle authDividerText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: Colors.white38,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle buttonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    color: Colors.white,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle socialButtonText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: Colors.white,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle inputFieldText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    color: Colors.white,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle inputHintText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: Color(0xFF64748B),
    fontWeight: FontWeight.w400,
  );

  static const TextStyle inputErrorText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: Color(0xFFFF4B8B),
    fontWeight: FontWeight.w400,
  );

  static const TextStyle otpDigitText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    color: Colors.white,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle otpExpiredDigitText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    color: Color(0xFFFF5252),
    fontWeight: FontWeight.w600,
  );

  static const TextStyle timerText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    color: Colors.white54,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle codeExpiredStatusText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    color: Color(0xFFFF5252),
    fontWeight: FontWeight.w400,
  );

  static const TextStyle resendCodeLinkText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: Color(0xFF00E5FF),
    fontWeight: FontWeight.w600,
  );

  static const TextStyle staySignedInText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    color: Colors.white70,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle forgotPasswordLink = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    color: AppColors.gradientPink,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle termsNormalText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    color: Colors.white70,
    fontWeight: FontWeight.w700,
    height: 1.4,
  );

  static const TextStyle termsLinkText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    color: AppColors.gradientPink,
    fontWeight: FontWeight.w700,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.gradientPink,
  );

  static const TextStyle successTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    color: Colors.white,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
  );

  static const TextStyle successSub = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: Color(0xFF94A3B8),
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle splashTagline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: Colors.white70,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
  );

  static const TextStyle splashCommunityFooter = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    color: Colors.white38,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.2,
  );

  static const TextStyle onboardingSkipText = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: Colors.white60,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle onboardingTitle = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    color: Colors.white,
    fontWeight: FontWeight.w700,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle onboardingDesc = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    color: Colors.white70,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );
}

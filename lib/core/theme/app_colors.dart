// Colour tokens for both apps.

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const Color primary = Color(0xFF2563EB);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primarySoft = Color(0xFFDBEAFE);

  static const Color accent = Color(0xFF7C3AED);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);

  static const Color background = Color(0xFF121019);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFF1F3F6);

  // Dark Surface Tokens
  static const Color cardBackground = Color(0xFF1E1B26);
  static const Color bottomSheetBackground = Color(0xFF12101A);
  static const Color bottomBarBackground = Color(0xFF1C1C24);
  static const Color chipBackground = Color(0xFF2C2738);
  static const Color cyanBadgeBackground = Color(0xFF142C38);

  static const Color sidebar = Color(0xFF111827);
  static const Color sidebarActive = Color(0xFF1F2937);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textInverse = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF94A3B8);

  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFEDF0F4);
  static const Color overlay = Color(0x14000000);

  static const Color gradientPink = Color(0xFFFF4B8B);
  static const Color gradientPurple = Color(0xFF6750A4);
  static const Color gradientCyan = Color(0xFF00E5FF);

  static const Color splashBackground = Color(0xFF0F0C16);
  static const Color splashTextMuted = Color(0xFF8E8895);

  static const LinearGradient primaryGradientButton = LinearGradient(
    colors: <Color>[gradientPink, gradientPurple, gradientCyan],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient secondaryGradientButton = LinearGradient(
    colors: <Color>[gradientCyan, gradientPurple, gradientPink],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient reverseGradientButton = secondaryGradientButton;

  static const RadialGradient splashPinkGlow = RadialGradient(
    center: Alignment(0.0, -0.15),
    radius: 0.95,
    colors: <Color>[Color(0x45FF4B8B), Color(0x00FF4B8B)],
    stops: <double>[0.0, 1.0],
  );

  static const RadialGradient splashPurpleGlow = RadialGradient(
    center: Alignment(0.0, 0.92),
    radius: 0.75,
    colors: <Color>[Color(0x386750A4), Color(0x006750A4)],
    stops: <double>[0.0, 1.0],
  );
}

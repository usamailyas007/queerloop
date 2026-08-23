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

  // ── Admin console dark palette (Figma-verified) ─────────────────────
  static const Color adminBackground = Color(0xFF18181B);
  static const Color adminSurface = Color(0xFF141119);
  static const Color adminSurfaceAlt = Color(0xFF1C1824);

  static const Color adminBorder = Color(0x17FFFFFF); // white @ ~9%
  static const Color adminDivider = Color(0x0FFFFFFF); // white @ ~6%
  static const Color adminRowDivider = Color(0x0AFFFFFF); // white @ ~4%

  static const Color adminTextPrimary = Color(0xFFF3EFF7);
  static const Color adminTextSecondary = Color(0xFF948CA3);
  static const Color adminTextMuted = Color(0xFF635C72);
  static const Color adminTextFaint = Color(0xFFA79FB8);

  static const Color adminTeal = Color(0xFF3FE0AE);
  static const Color adminGreen = Color(0xFF34D399);
  static const Color adminOrange = Color(0xFFFFB45C);
  static const Color adminPink = Color(0xFFFF3B77);
  static const Color adminPinkLight = Color(0xFFFF8080);
  static const Color adminPurple = Color(0xFF8B5CFF);
  static const Color adminPurpleSoft = Color(0xFF7C6BFF);
  static const Color adminBlue = Color(0xFF4CC9FF);

  // Const-context alpha variants (Color.withValues isn't a const function).
  static const Color adminPinkGlow = Color(0x21FF3B77); // adminPink @ 13%
  static const Color adminPinkTransparent = Color(0x00FF3B77); // adminPink @ 0%
  static const Color adminPinkFaded = Color(0x40FF3B77); // adminPink @ 25%
  static const Color adminPurpleFaded = Color(0x408B5CFF); // adminPurple @ 25%

  /// Subtle border tint on the "Today's question" highlight card. Named
  /// literally rather than semantically — its role is decorative, not a
  /// deliberate brand hue.
  static const Color adminHighlightBorder = Color(0xFFFFFF17);

  static const Color adminButtonBorder = Color(0x1FFFFFFF); // white @ ~12%
  static const Color adminDropzoneBorder = Color(0x29FFFFFF); // white @ ~16%
  static const Color adminCardBorderStrong = Color(0x2EFFFFFF); // white @ ~18%
  static const Color adminSidebarTint = Color(0x05FFFFFF); // white @ ~2%

  // ── Moderator console dark palette ──────────────────────────────────
  static const Color moderatorBackground = Color(0xFF121019);
  static const Color moderatorSurface = Color(0xFF16131D);
  static const Color moderatorSurfaceAlt = Color(0xFF191622);
  static const Color moderatorSurfaceAlt2 = Color(0xFF1D1927);
  static const Color moderatorChipSelected = Color(0xFF2C2738);
  static const Color moderatorSidebarActive = Color(0xFF231E30);

  static const Color moderatorPink = Color(0xFFFF4B8B);
  static const Color moderatorPurple = Color(0xFF9333EA);
  static const Color moderatorPurpleAccent = Color(0xFF9D4EDD);
  static const Color moderatorGreen = Color(0xFF059669);
  static const Color moderatorGray = Color(0xFF4B5563);

  static const Color moderatorTextPrimary = Colors.white;
  static const Color moderatorTextSecondary = Colors.white70;
  static const Color moderatorTextMuted = Colors.white54;
  static const Color moderatorTextFaint = Colors.white38;
  static const Color moderatorDividerLine = Colors.white10;
  static const Color moderatorIconMuted = Colors.white24;

  static const Color moderatorBorder = Color(0x14FFFFFF); // white @ ~8%
  static const Color moderatorDivider = Color(0x0FFFFFFF); // white @ ~6%
  static const Color moderatorRowDivider = Color(0x0AFFFFFF); // white @ ~4%
  static const Color moderatorButtonBorder = Color(0x1FFFFFFF); // white @ ~12%
  static const Color moderatorInputBorder = Color(0x1AFFFFFF); // white @ ~10%
}

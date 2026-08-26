import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_provider.dart';
import '../provider/splash_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final AuthProvider authProvider = context.read<AuthProvider>();
      context.read<SplashProvider>().initialize(authProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: context.themeBackground,
          gradient: isDark
              ? const RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.25,
                  colors: <Color>[
                    Color(0xFF3B162E), // Deep plum center aura
                    Color(0xFF220E1E),
                    Color(0xFF0C0A10), // Pure dark background edge
                  ],
                  stops: <double>[0.0, 0.45, 1.0],
                )
              : const RadialGradient(
                  center: Alignment(0.0, -0.2),
                  radius: 1.25,
                  colors: <Color>[
                    Color(0xFFFFF0F5), // Soft pastel pink aura
                    Color(0xFFFAFAFC),
                    Color(0xFFFFFFFF),
                  ],
                  stops: <double>[0.0, 0.45, 1.0],
                ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(flex: 3),

              // ── Center Infinity Logo (PNG with SVG fallback) ────────────
              Center(
                child: Image.asset(
                  AppImages.logo,
                  width: 140,
                  height: 70,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return SvgPicture.asset(
                      AppImages.logoSvg,
                      width: 140,
                      height: 70,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── QUEERLOOP+ Brand Name Logo (PNG with SVG fallback) ──────
              Center(
                child: Image.asset(
                  AppImages.logoName,
                  width: 240,
                  height: 48,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return SvgPicture.asset(
                      AppImages.logoNameSvg,
                      width: 240,
                      height: 48,
                      fit: BoxFit.contain,
                    );
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Tagline: "Your people, your feed, your rules." ──────────
              Text(
                l10n.splashTagline,
                style: TextStyle(
                  color: isDark ? Colors.white60 : AppColors.lightTextSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.2,
                ),
              ),

              const Spacer(flex: 3),

              // ── Bottom Section: Gradient Progress Indicator + "18+ COMMUNITY"
              Column(
                children: <Widget>[
                  // Gradient Loading Line
                  Container(
                    width: 120,
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[
                          AppColors.gradientPink,
                          AppColors.gradientCyan,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Footer Label
                  Text(
                    l10n.splashCommunityText,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : AppColors.lightTextMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

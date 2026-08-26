import 'package:flutter/material.dart';

import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// "Community Spotlight" card — pixel-perfect match to design screenshot.
class DiscoverSpotlightCard extends StatelessWidget {
  const DiscoverSpotlightCard({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? context.themeCardBackground
            : const Color(0xFFEDEDF2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0x4DB45C4D),
          width: 1.5,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // ── Image with top & bottom text overlay ──────────────────────
          Stack(
            children: <Widget>[
              Image.asset(
                AppImages.trendingBottom,
                width: double.infinity,
                height: 145,
                fit: BoxFit.cover,
              ),
              // Gradient overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              // Overlay text content over the image
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      // Top-left: THIS WEEK'S PICK cyan text
                      Text(
                        "THIS WEEK'S PICK",
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          fontSize: 11,
                        ),
                      ),
                      // Bottom-left: Drag & Nightlife white title text
                      Text(
                        'Drag & Nightlife',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Info section below image ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'Admin-curated every week. Chosen this week for its Pride showcase thread and genuinely welcoming new-performer nights.',
              style: AppTextStyles.bodySmall.copyWith(
                color: context.themeTextPrimary.withValues(
                  alpha: isDark ? 0.9 : 0.85,
                ),
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

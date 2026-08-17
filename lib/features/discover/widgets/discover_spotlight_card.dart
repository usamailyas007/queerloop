import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// "Community Spotlight" card — pixel-perfect match to design screenshot.
class DiscoverSpotlightCard extends StatelessWidget {
  const DiscoverSpotlightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                height: 140,
                fit: BoxFit.cover,
              ),
              // Dark gradient overlay for text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[
                        Colors.black.withValues(alpha: 0.4),
                        Colors.black.withValues(alpha: 0.7),
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
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      // Top-left: THIS WEEK'S PICK cyan text
                      Text(
                        "THIS WEEK'S PICK",
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.gradientCyan,
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
                          fontSize: 18,
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
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Text(
              'Admin-curated every week. Chosen this week for its Pride showcase thread and genuinely welcoming new-performer nights.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white70,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

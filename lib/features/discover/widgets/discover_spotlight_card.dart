import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../admin/admin_view/community_spotlight/models/spotlight.dart';
import '../../../admin/admin_view/community_spotlight/provider/spotlights_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// "Community Spotlight" card — pixel-perfect match to design screenshot.
class DiscoverSpotlightCard extends StatelessWidget {
  const DiscoverSpotlightCard({this.spotlight, super.key});

  final Spotlight? spotlight;

  Widget _buildCoverImage(String? imageUrl) {
    final Widget fallbackAsset = Image.asset(
      AppImages.trendingBottom,
      width: double.infinity,
      height: 145,
      fit: BoxFit.cover,
    );

    final String? src = imageUrl?.trim();
    if (src == null || src.isEmpty) {
      return fallbackAsset;
    }

    // Base64 Data URI check
    if (src.startsWith('data:image/') || src.contains(';base64,')) {
      try {
        final String base64Str = src.contains(',') ? src.split(',').last : src;
        final Uint8List bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          width: double.infinity,
          height: 145,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => fallbackAsset,
        );
      } catch (_) {
        return fallbackAsset;
      }
    }

    // HTTP/HTTPS URL check
    final Uri? parsed = Uri.tryParse(src);
    if (parsed == null ||
        !parsed.hasScheme ||
        (!parsed.isScheme('http') && !parsed.isScheme('https')) ||
        parsed.host.isEmpty) {
      return fallbackAsset;
    }

    return Image.network(
      src,
      width: double.infinity,
      height: 145,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallbackAsset,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    Spotlight? activeSpotlight = spotlight;
    if (activeSpotlight == null) {
      try {
        final SpotlightsProvider provider = context.watch<SpotlightsProvider>();
        activeSpotlight = provider.liveSpotlight;
      } catch (_) {
        // Fallback to static content if provider is not in context.
      }
    }

    final String title = (activeSpotlight?.title.isNotEmpty == true)
        ? activeSpotlight!.title
        : 'Drag & Nightlife';

    final String body = (activeSpotlight?.body.isNotEmpty == true)
        ? activeSpotlight!.body
        : 'Admin-curated every week. Chosen this week for its Pride showcase thread and genuinely welcoming new-performer nights.';

    final String? imageUrl = activeSpotlight?.imageUrl;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? context.themeCardBackground : const Color(0xFFEDEDF2),
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
              _buildCoverImage(imageUrl),
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
                      // Bottom-left: title text
                      Text(
                        title,
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
              body,
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

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

class HomeEmptyStateView extends StatelessWidget {
  const HomeEmptyStateView({
    required this.onOpenExplore,
    super.key,
  });

  final VoidCallback onOpenExplore;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // ── Stacked Photo Graphic Illustration ─────────────────────────
            SizedBox(
              width: 160,
              height: 140,
              child: Image.asset(
                AppImages.emptyHomeImg,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.image_rounded,
                    color: Colors.white54,
                    size: 64,
                  );
                },
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── Title: "Nothing here yet" ─────────────────────────────────────
            Text(
              l10n.homeEmptyTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Subtitle ─────────────────────────────────────────────────────
            Text(
              l10n.homeEmptySub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 14,
                height: 1.45,
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // ── CTA Button: "Open Explore" ──────────────────────────────────
            GestureDetector(
              onTap: onOpenExplore,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      AppColors.gradientPink,
                      AppColors.gradientCyan,
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.gradientPink.withValues(alpha: 0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Text(
                  l10n.homeOpenExploreBtn,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

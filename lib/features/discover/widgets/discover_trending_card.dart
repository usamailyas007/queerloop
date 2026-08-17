import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/discover_models.dart';

/// Single row card for a trending hashtag item.
class DiscoverTrendingCard extends StatelessWidget {
  const DiscoverTrendingCard({
    required this.item,
    required this.rankColor,
    super.key,
  });

  final TrendingItem item;
  final Color rankColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            item.rank,
            style: AppTextStyles.titleMedium.copyWith(
              color: rankColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.hashtag,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.postsCount,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white54,
                  ),
                ),
              ],
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.asset(
              item.thumbnailAsset,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}

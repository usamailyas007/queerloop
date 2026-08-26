import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class TagSearchResultItem {
  const TagSearchResultItem({
    required this.name,
    required this.postsCount,
    required this.weeklyCount,
    required this.imageAsset,
  });

  final String name;
  final String postsCount;
  final String weeklyCount;
  final String imageAsset;
}

class SearchTagTile extends StatelessWidget {
  const SearchTagTile({
    required this.tag,
    this.onTap,
    super.key,
  });

  final TagSearchResultItem tag;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: context.themeBorder,
          ),
        ),
        child: Row(
          children: <Widget>[
            // Tag image thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                tag.imageAsset,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Tag name & stats
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    tag.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${tag.postsCount} posts · ${tag.weeklyCount} this week',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.themeTextSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class TagSearchResultItem {
  const TagSearchResultItem({
    required this.name,
    this.postsCount = '0',
    this.weeklyCount = '0',
    this.imageAsset = '',
  });

  final String name;
  final String postsCount;
  final String weeklyCount;
  final String imageAsset;

  factory TagSearchResultItem.fromJson(Map<String, dynamic> json) {
    final String rawName = (json['name'] ?? json['tag'] ?? json['hashtag'] ?? '').toString();
    final String tagName = rawName.startsWith('#') ? rawName : (rawName.isNotEmpty ? '#$rawName' : '#tag');

    final int pCount = json['postsCount'] is num
        ? (json['postsCount'] as num).toInt()
        : (int.tryParse(json['postsCount']?.toString() ?? json['count']?.toString() ?? '') ?? 0);
    final String pStr = pCount > 1000
        ? '${(pCount / 1000).toStringAsFixed(1)}K'
        : (pCount > 0 ? '$pCount' : '0');

    final int wCount = json['weeklyCount'] is num
        ? (json['weeklyCount'] as num).toInt()
        : (int.tryParse(json['weeklyCount']?.toString() ?? '') ?? 0);
    final String wStr = wCount > 1000
        ? '${(wCount / 1000).toStringAsFixed(1)}K'
        : (wCount > 0 ? '$wCount' : '0');

    final String img = (json['thumbnailUrl'] ??
            json['imageUrl'] ??
            json['mediaUrl'] ??
            json['imageAsset'] ??
            '')
        .toString();

    return TagSearchResultItem(
      name: tagName,
      postsCount: pStr,
      weeklyCount: wStr,
      imageAsset: img,
    );
  }
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
            // Tag image thumbnail or icon
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 56,
                height: 56,
                child: _buildThumbnail(context),
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

  Widget _buildThumbnail(BuildContext context) {
    final String img = tag.imageAsset.trim();
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallback(context),
      );
    } else if (img.isNotEmpty) {
      return Image.asset(
        img,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _buildFallback(context),
      );
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    return Container(
      color: AppColors.gradientPink.withValues(alpha: 0.12),
      child: Center(
        child: Text(
          '#',
          style: AppTextStyles.titleLarge.copyWith(
            color: AppColors.gradientPink,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}


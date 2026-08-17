import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/discover_models.dart';

/// 3-column grid of search result post thumbnails.
class SearchPostsGrid extends StatelessWidget {
  const SearchPostsGrid({required this.results, super.key});

  final List<DiscoverSearchResult> results;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.75,
      ),
      itemCount: results.length,
      itemBuilder: (BuildContext context, int index) {
        final DiscoverSearchResult item = results[index];
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(item.imageAsset, fit: BoxFit.cover),
            if (item.viewCount != null)
              Positioned(
                bottom: AppSpacing.xs,
                left: AppSpacing.xs,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.viewCount!,
                    style: AppTextStyles.caption.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

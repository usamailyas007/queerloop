import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../models/content_post.dart';
import '../provider/content_provider.dart';
import 'content_thumb.dart';

/// Trending-posts strip below the main content grid.
class ContentTrendingSection extends StatelessWidget {
  const ContentTrendingSection({required this.provider, required this.onView, super.key});

  final ContentProvider provider;
  final ValueChanged<ContentPost> onView;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Row(
            children: <Widget>[
              Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.adminOrange),
              SizedBox(width: 6),
              Text(
                'Trending',
                style: TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (provider.isLoadingTrending && provider.trending.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
                ),
              ),
            )
          else if (provider.trending.isEmpty)
            const Text('Nothing trending right now.', style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12))
          else
            Builder(
              builder: (_) {
                final List<ContentPost> items = provider.trending.take(6).toList();
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (_, int i) => _TrendingCard(post: items[i], rank: i + 1, onTap: () => onView(items[i])),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.post, required this.rank, required this.onTap});

  final ContentPost post;
  final int rank;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    ContentThumb(post: post),
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.6), shape: BoxShape.circle),
                        child: Text(
                          '$rank',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Row(
                        children: <Widget>[
                          const Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            NumberFormat.compact().format(post.viewCount),
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${post.author.handle} · ${post.type.label}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

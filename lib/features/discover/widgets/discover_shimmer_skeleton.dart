import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_shimmer.dart';
import 'discover_section_label.dart';

/// Full-screen shimmering skeleton for the Discover Screen while data is loading.
class DiscoverShimmerSkeleton extends StatelessWidget {
  const DiscoverShimmerSkeleton({super.key});

  Widget _buildCardContainer({
    required BuildContext context,
    required Widget child,
    EdgeInsetsGeometry? padding,
    double borderRadius = 16,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? context.themeCardBackground : Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFEBEBF0),
        ),
      ),
      child: child,
    );
  }

  Widget _buildTrendingCardSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: _buildCardContainer(
        context: context,
        child: const Row(
          children: <Widget>[
            // Rank badge
            ShimmerBox(width: 30, height: 22, borderRadius: 6),
            SizedBox(width: AppSpacing.md),
            // Hashtag + Post Count
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ShimmerBox(width: 140, height: 15, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 90, height: 11, borderRadius: 4),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // Thumbnail
            ShimmerBox(width: 44, height: 44, borderRadius: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationCardSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: _buildCardContainer(
        context: context,
        borderRadius: 24,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                ShimmerBox(width: 110, height: 12, borderRadius: 4),
                ShimmerBox(width: 60, height: 12, borderRadius: 4),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            ShimmerBox(width: double.infinity, height: 18, borderRadius: 4),
            SizedBox(height: 8),
            ShimmerBox(width: 220, height: 14, borderRadius: 4),
            SizedBox(height: AppSpacing.lg),
            ShimmerBox(width: double.infinity, height: 38, borderRadius: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityTileSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: _buildCardContainer(
        context: context,
        borderRadius: 16,
        child: const Row(
          children: <Widget>[
            // Community avatar
            ShimmerBox(width: 48, height: 48, borderRadius: 14),
            SizedBox(width: AppSpacing.md),
            // Name + Description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ShimmerBox(width: 110, height: 15, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 180, height: 11, borderRadius: 4),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            // Join button pill
            ShimmerBox(width: 62, height: 32, borderRadius: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorCircleSkeleton() {
    return const Padding(
      padding: EdgeInsets.only(right: AppSpacing.lg),
      child: Column(
        children: <Widget>[
          ShimmerBox(width: 60, height: 60, isCircle: true),
          SizedBox(height: 8),
          ShimmerBox(width: 50, height: 11, borderRadius: 4),
        ],
      ),
    );
  }

  Widget _buildSpotlightCardSkeleton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: _buildCardContainer(
        context: context,
        borderRadius: 20,
        padding: EdgeInsets.zero,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Banner Image
            ShimmerBox(
              width: double.infinity,
              height: 145,
              borderRadius: 0,
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  ShimmerBox(width: 150, height: 18, borderRadius: 4),
                  SizedBox(height: 8),
                  ShimmerBox(width: double.infinity, height: 12, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 220, height: 12, borderRadius: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: <Widget>[
          // Top Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: ShimmerBox(width: 140, height: 28, borderRadius: 6),
            ),
          ),

          // Search Bar Placeholder
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: ShimmerBox(
                width: double.infinity,
                height: 48,
                borderRadius: 24,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // TRENDING NOW Header
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  ShimmerBox(width: 110, height: 14, borderRadius: 4),
                  ShimmerBox(width: 70, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // 4 Trending Cards
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) =>
                  _buildTrendingCardSkeleton(context),
              childCount: 4,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // CONVERSATION OF THE DAY
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: DiscoverSectionLabel(label: 'CONVERSATION OF THE DAY'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(
            child: _buildConversationCardSkeleton(context),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // COMMUNITIES TO EXPLORE
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: DiscoverSectionLabel(label: 'COMMUNITIES TO EXPLORE'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

          // 4 Community Tiles
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) =>
                  _buildCommunityTileSkeleton(context),
              childCount: 4,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // CREATORS TO WATCH
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: DiscoverSectionLabel(label: 'CREATORS TO WATCH'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                itemCount: 5,
                itemBuilder: (BuildContext context, int index) =>
                    _buildCreatorCircleSkeleton(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // NEW CREATORS
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: DiscoverSectionLabel(label: 'NEW CREATORS'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                itemCount: 5,
                itemBuilder: (BuildContext context, int index) =>
                    _buildCreatorCircleSkeleton(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

          // COMMUNITY SPOTLIGHT
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: DiscoverSectionLabel(label: 'COMMUNITY SPOTLIGHT'),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
          SliverToBoxAdapter(
            child: _buildSpotlightCardSkeleton(context),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xxxxxl),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../models/discover_models.dart';
import '../provider/discover_provider.dart';
import '../widgets/discover_community_tile.dart';
import '../widgets/discover_conversation_card.dart';
import '../widgets/discover_creator_circle.dart';
import '../widgets/discover_section_label.dart';
import '../widgets/discover_spotlight_card.dart';
import '../widgets/discover_static_search_bar.dart';
import '../widgets/discover_trending_card.dart';
import 'search_screen.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DiscoverProvider>(
      create: (_) => DiscoverProvider(),
      child: const _DiscoverScreenBody(),
    );
  }
}

class _DiscoverScreenBody extends StatelessWidget {
  const _DiscoverScreenBody();

  static const List<Color> _rankColors = <Color>[
    AppColors.gradientPink,
    AppColors.gradientPurple,
    AppColors.gradientCyan,
    Colors.white38,
  ];

  @override
  Widget build(BuildContext context) {
    final DiscoverProvider provider = context.watch<DiscoverProvider>();
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            // ── App Bar ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  l10n.guestDiscoverTitle,
                  style: AppTextStyles.headingMedium,
                ),
              ),
            ),

            // ── Static Search Bar ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: GestureDetector(
                  onTap: () => Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ChangeNotifierProvider<DiscoverProvider>.value(
                            value: provider,
                            child: const SearchScreen(),
                          ),
                    ),
                  ),
                  child: AbsorbPointer(
                    child: DiscoverStaticSearchBar(
                      hint: l10n.guestDiscoverSearchHint,
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // ── TRENDING NOW header ────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      l10n.guestTrendingNow,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white54,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      l10n.guestWorldwide,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white54,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

            // ── Trending List ──────────────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (BuildContext context, int index) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: DiscoverTrendingCard(
                    item: provider.trendingItems[index],
                    rankColor: _rankColors[index % _rankColors.length],
                  ),
                ),
                childCount: provider.trendingItems.length,
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.sm)),

            // ── Conversation of the Day ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: const DiscoverConversationCard(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // ── COMMUNITIES TO EXPLORE header ──────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: const DiscoverSectionLabel(
                  label: 'COMMUNITIES TO EXPLORE',
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),

            // ── Communities List ───────────────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                final DiscoverCommunity c = provider.communities[index];
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: DiscoverCommunityTile(
                    community: c,
                    isJoined: provider.isJoined(c.name),
                    onJoin: () => provider.toggleJoin(c.name),
                  ),
                );
              }, childCount: provider.communities.length),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // ── CREATORS TO WATCH ──────────────────────────────────────────
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: provider.creatorsToWatch.length,
                  itemBuilder: (BuildContext context, int index) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: DiscoverCreatorCircle(
                      creator: provider.creatorsToWatch[index],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // ── NEW CREATORS ───────────────────────────────────────────────
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: provider.newCreators.length,
                  itemBuilder: (BuildContext context, int index) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.lg),
                    child: DiscoverCreatorCircle(
                      creator: provider.newCreators[index],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),

            // ── COMMUNITY SPOTLIGHT ────────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: DiscoverSectionLabel(label: 'COMMUNITY SPOTLIGHT'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: DiscoverSpotlightCard(),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpacing.xxxxxl),
            ),
          ],
        ),
      ),
    );
  }
}

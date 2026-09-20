import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../admin/admin_view/community_spotlight/provider/spotlights_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';
import '../models/discover_models.dart';
import '../provider/cotd_provider.dart';
import '../provider/discover_provider.dart';
import '../widgets/discover_community_tile.dart';
import '../widgets/discover_conversation_card.dart';
import '../widgets/discover_creator_circle.dart';
import '../widgets/discover_section_label.dart';
import '../widgets/discover_spotlight_card.dart';
import '../widgets/discover_static_search_bar.dart';
import '../widgets/discover_trending_card.dart';
import '../../auth/auth_provider.dart';
import '../../profile/provider/profile_provider.dart';
import 'search_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final AuthProvider auth = context.read<AuthProvider>();
        final ProfileProvider profile = context.read<ProfileProvider>();
        final String? myId = auth.userId ?? profile.profile?.id;
        final String myUsername = (auth.user?.displayName ?? profile.username)
            .replaceAll('@', '')
            .trim();
        context.read<DiscoverProvider>().setCurrentUser(userId: myId, username: myUsername);
        context.read<SpotlightsProvider>().loadInitial();
        if (myId != null && myId.isNotEmpty) {
          profile.fetchUserCommunities(myId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const _DiscoverScreenBody();
  }
}

class _DiscoverScreenBody extends StatelessWidget {
  const _DiscoverScreenBody();

  static const List<Color> _rankColors = <Color>[
    AppColors.gradientPink,
    AppColors.gradientPurple,
    AppColors.gradientCyan,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    final DiscoverProvider provider = context.watch<DiscoverProvider>();
    final ProfileProvider profile = context.watch<ProfileProvider>();
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait<void>(<Future<void>>[
              context.read<DiscoverProvider>().fetchDiscoverData(refresh: true),
              context.read<CotdProvider>().refresh(),
              context.read<SpotlightsProvider>().refresh(),
            ]);
          },
          color: AppColors.gradientCyan,
          backgroundColor: context.themeCardBackground,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                    style: AppTextStyles.headingMedium.copyWith(
                      color: context.themeTextPrimary,
                    ),
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
                        builder: (_) => const SearchScreen(),
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
                        color: context.themeTextMuted,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      l10n.guestWorldwide,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.themeTextMuted,
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

            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

            // ── Conversation of the Day ────────────────────────────────────
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: DiscoverSectionLabel(label: 'CONVERSATION OF THE DAY'),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: DiscoverConversationCard(),
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

            // ── Communities List (Top 4) ───────────────────────────────────
            SliverList(
              delegate: SliverChildBuilderDelegate((
                BuildContext context,
                int index,
              ) {
                final List<DiscoverCommunity> topCommunities =
                    provider.communities.take(4).toList();
                final DiscoverCommunity c = topCommunities[index];
                final bool isJoined = profile.isCommunityJoined(id: c.id, name: c.name);
                return Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: DiscoverCommunityTile(
                    community: c,
                    isJoined: isJoined,
                    onJoin: () async {
                      if (isJoined) {
                        await profile.leaveCommunity(c.id ?? '', name: c.name);
                      } else {
                        await profile.joinCommunity(c.id ?? '', name: c.name);
                      }
                    },
                  ),
                );
              }, childCount: provider.communities.take(4).length),
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
    ),
  );
}
}


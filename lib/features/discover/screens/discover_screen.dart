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
import '../widgets/discover_shimmer_skeleton.dart';
import '../widgets/discover_spotlight_card.dart';
import '../widgets/discover_static_search_bar.dart';
import '../widgets/discover_trending_card.dart';
import '../../auth/auth_provider.dart';
import '../../home/provider/home_feed_provider.dart';
import '../../profile/provider/profile_provider.dart';
import 'search_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  bool _isRefreshing = false;

  Future<void> _handleRefresh() async {
    if (_isRefreshing) return;
    setState(() {
      _isRefreshing = true;
    });
    try {
      final AuthProvider auth = context.read<AuthProvider>();
      final ProfileProvider profile = context.read<ProfileProvider>();
      final String? myId = auth.userId ?? profile.profile?.id;
      final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
      final DiscoverProvider discover = context.read<DiscoverProvider>();

      discover.syncHomeFeedContent(posts: homeFeed.posts, reels: homeFeed.reels);

      await Future.wait<void>(<Future<void>>[
        discover.fetchDiscoverData(refresh: true),
        context.read<CotdProvider>().refresh(),
        context.read<SpotlightsProvider>().refresh(),
        if (myId != null && myId.isNotEmpty)
          profile.fetchUserCommunities(myId),
      ]);
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

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
        final DiscoverProvider discover = context.read<DiscoverProvider>();
        discover.setCurrentUser(userId: myId, username: myUsername);
        final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
        discover.syncHomeFeedContent(posts: homeFeed.posts, reels: homeFeed.reels);
        if (!discover.hasLoadedDiscoverOnce || discover.isInitialLoading) {
          discover.fetchDiscoverData();
        }
        final CotdProvider cotd = context.read<CotdProvider>();
        if (!cotd.hasLoadedOnce && !cotd.isLoading) {
          cotd.refresh();
        }
        final SpotlightsProvider spotlights = context.read<SpotlightsProvider>();
        if (!spotlights.hasLoadedOnce && !spotlights.isLoading) {
          spotlights.loadInitial();
        }
        if (myId != null && myId.isNotEmpty) {
          profile.fetchUserCommunities(myId);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _DiscoverScreenBody(
      onRefresh: _handleRefresh,
      isRefreshing: _isRefreshing,
    );
  }
}

class _DiscoverScreenBody extends StatelessWidget {
  const _DiscoverScreenBody({
    required this.onRefresh,
    required this.isRefreshing,
  });

  final RefreshCallback onRefresh;
  final bool isRefreshing;

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
    final SpotlightsProvider spotlights = context.watch<SpotlightsProvider>();
    final CotdProvider cotd = context.watch<CotdProvider>();
    final AppLocalizations l10n = AppLocalizations.of(context);

    // Wait until ALL discover data is loaded before hiding shimmer:
    // 1. Hashtags (trending items)
    // 2. Today's question (CotdProvider)
    // 3. Communities to explore
    // 4. Creators to watch
    // 5. New creators
    // 6. Community spotlight (SpotlightsProvider)
    final bool isAllDataLoaded = provider.hasLoadedDiscoverOnce &&
        !provider.isDiscoverLoading &&
        cotd.hasLoadedOnce &&
        !cotd.isLoading &&
        spotlights.hasLoadedOnce &&
        !spotlights.isLoading &&
        !isRefreshing;

    final bool showShimmer = !isAllDataLoaded;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          color: AppColors.gradientCyan,
          backgroundColor: context.themeCardBackground,
          child: showShimmer
              ? const DiscoverShimmerSkeleton()
              : CustomScrollView(
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

            if (provider.trendingItems.isNotEmpty) ...<Widget>[
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
            ],

            // ── Conversation of the Day ────────────────────────────────────
            if (cotd.currentQuestion != null) ...<Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),
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
            ],

            // ── COMMUNITIES TO EXPLORE ──────────────────────────────────────
            if (provider.communities.isNotEmpty) ...<Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: DiscoverSectionLabel(
                    label: 'COMMUNITIES TO EXPLORE',
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
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
            ],

            // ── CREATORS TO WATCH ──────────────────────────────────────────
            if (provider.creatorsToWatch.isNotEmpty) ...<Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
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
            ],

            // ── NEW CREATORS ───────────────────────────────────────────────
            if (provider.newCreators.isNotEmpty) ...<Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
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
            ],

            // ── COMMUNITY SPOTLIGHT ────────────────────────────────────────
            if (spotlights.liveSpotlight != null) ...<Widget>[
              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
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
            ],

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


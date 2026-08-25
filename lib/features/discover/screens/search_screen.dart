import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_tag_chip.dart';
import '../../home/models/post_item_model.dart';
import '../../home/widgets/comments_bottom_sheet.dart';
import '../../home/widgets/post_feed_card.dart';
import '../models/discover_models.dart';
import '../provider/discover_provider.dart';
import '../widgets/clear_search_history_dialog.dart';
import '../widgets/discover_community_tile.dart';
import '../widgets/discover_creator_circle.dart';
import '../widgets/discover_section_label.dart';
import '../widgets/search_bar_row.dart';
import '../widgets/search_person_tile.dart';
import '../widgets/search_posts_grid.dart';
import '../widgets/search_recent_tile.dart';
import '../widgets/search_tab_bar.dart';
import '../widgets/search_tag_tile.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _onFocusChange() {
    if (mounted) {
      context.read<DiscoverProvider>().setSearchFocused(_focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final DiscoverProvider provider = context.watch<DiscoverProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            SearchBarRow(
              controller: _controller,
              focusNode: _focusNode,
              onChanged: provider.setSearchQuery,
              onCancel: () {
                _controller.clear();
                provider.clearSearchQuery();
                Navigator.pop(context);
              },
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: provider.isSearching
                    ? (provider.hasResults
                        ? const _SearchResultsBody(
                            key: ValueKey<String>('results'))
                        : _NoResultsBody(
                            key: const ValueKey<String>('no-results'),
                            query: provider.searchQuery,
                          ))
                    : const _SearchIdleBody(
                        key: ValueKey<String>('idle'),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Idle State
// ─────────────────────────────────────────────────────────────────────────────
class _SearchIdleBody extends StatelessWidget {
  const _SearchIdleBody({super.key});

  @override
  Widget build(BuildContext context) {
    final DiscoverProvider provider = context.watch<DiscoverProvider>();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: <Widget>[
        // RECENT header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const DiscoverSectionLabel(label: 'RECENT'),
            GestureDetector(
              onTap: () async {
                final bool confirmed =
                    await ClearSearchHistoryDialog.show(context);
                if (confirmed) provider.clearAllRecentSearches();
              },
              child: Text(
                'Clear Search History',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.gradientPink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ...provider.recentSearches.map(
          (String q) => SearchRecentTile(
            query: q,
            onDelete: () => provider.removeRecentSearch(q),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // SUGGESTED FOR YOU
        const DiscoverSectionLabel(label: 'SUGGESTED FOR YOU'),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: provider.suggestedTags
              .map((String tag) => AppTagChip(label: tag))
              .toList(),
        ),

        const SizedBox(height: AppSpacing.xl),

        // BROWSE COMMUNITIES
        const DiscoverSectionLabel(label: 'BROWSE COMMUNITIES'),
        const SizedBox(height: AppSpacing.md),
        ...provider.communities.take(2).map(
              (DiscoverCommunity c) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: DiscoverCommunityTile(
                  community: c,
                  isJoined: provider.isJoined(c.name),
                  onJoin: () => provider.toggleJoin(c.name),
                ),
              ),
            ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Results State
// ─────────────────────────────────────────────────────────────────────────────
class _SearchResultsBody extends StatelessWidget {
  const _SearchResultsBody({super.key});

  static const List<String> _tabs = <String>[
    'All',
    'Posts',
    'Reels',
    'People',
    'Tags',
    'Communities',
  ];

  static const List<PostItemModel> _samplePosts = <PostItemModel>[
    PostItemModel(
      id: 'p1',
      username: '@theo.vance',
      pronounsTime: 'he/him · 18m',
      avatarAsset: AppImages.user1,
      content:
          'Told my grandma about Dev over the phone and she said "finally, you sounded lonely in December." Eleven months of rehearsing a speech for nothing.',
      likesCount: 5600,
      commentsCount: 311,
      postImageAsset: AppImages.searchResult3,
    ),
    PostItemModel(
      id: 'p2',
      username: '@nadia.builds',
      pronounsTime: 'she/her · 1h',
      avatarAsset: AppImages.user2,
      content:
          'Reminder that the Tuesday support call is open to anyone, camera off is normal, and nobody has to speak.',
      likesCount: 1200,
      commentsCount: 311,
    ),
  ];

  Widget _buildSectionHeader({
    required String title,
    required VoidCallback onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white54,
            letterSpacing: 1.2,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            'See all',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.gradientPink,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final DiscoverProvider provider = context.watch<DiscoverProvider>();

    return Column(
      children: <Widget>[
        SearchTabBar(
          tabs: _tabs,
          selectedIndex: provider.selectedSearchTab,
          onTabSelected: provider.setSelectedSearchTab,
        ),
        const Divider(color: Color(0xFF2A2733), height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            children: <Widget>[
              // ── Tab 0: All (Comprehensive Overview - Image 3) ──────────────
              if (provider.selectedSearchTab == 0) ...<Widget>[
                // 1. TOP POSTS Section
                _buildSectionHeader(
                  title: 'TOP POSTS',
                  onSeeAll: () => provider.setSelectedSearchTab(1),
                ),
                const SizedBox(height: AppSpacing.md),
                SearchPostsGrid(
                  results: provider.searchResults.take(3).toList(),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 2. TOP TAGS Section
                _buildSectionHeader(
                  title: 'TOP TAGS',
                  onSeeAll: () => provider.setSelectedSearchTab(4),
                ),
                const SizedBox(height: AppSpacing.md),
                ...provider.tagResults.take(2).map(
                      (TagSearchResultItem t) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: SearchTagTile(
                          tag: t,
                          onTap: () => provider.setSelectedSearchTab(4),
                        ),
                      ),
                    ),

                const SizedBox(height: AppSpacing.xl),

                // 3. PEOPLE Section
                _buildSectionHeader(
                  title: 'PEOPLE',
                  onSeeAll: () => provider.setSelectedSearchTab(3),
                ),
                const SizedBox(height: AppSpacing.md),
                ...provider.peopleResults.map(
                  (DiscoverPerson p) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: SearchPersonTile(
                      person: p,
                      isFollowing: provider.isFollowing(p.username),
                      onFollow: () => provider.toggleFollow(p.username),
                    ),
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // 4. COMMUNITIES TO EXPLORE Section
                _buildSectionHeader(
                  title: 'COMMUNITIES TO EXPLORE',
                  onSeeAll: () => provider.setSelectedSearchTab(5),
                ),
                const SizedBox(height: AppSpacing.md),
                ...provider.communities.take(3).map(
                      (DiscoverCommunity c) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: DiscoverCommunityTile(
                          community: c,
                          isJoined: provider.isJoined(c.name),
                          onJoin: () => provider.toggleJoin(c.name),
                        ),
                      ),
                    ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // ── Tab 1: Posts (Full Posts Feed - Image 2) ───────────────────
              if (provider.selectedSearchTab == 1) ...<Widget>[
                ..._samplePosts.map(
                  (PostItemModel p) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: PostFeedCard(
                      post: p,
                      onLikeToggle: () {},
                      onSaveToggle: () {},
                      onOpenComments: () {
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) =>
                              const CommentsBottomSheet(totalComments: 311),
                        );
                      },
                    ),
                  ),
                ),
              ],

              // ── Tab 2: Reels (Reels Grid) ──────────────────────────────────
              if (provider.selectedSearchTab == 2)
                SearchPostsGrid(results: provider.searchResults),

              // ── Tab 3: People ──────────────────────────────────────────────
              if (provider.selectedSearchTab == 3)
                ...provider.peopleResults.map(
                  (DiscoverPerson p) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: SearchPersonTile(
                      person: p,
                      isFollowing: provider.isFollowing(p.username),
                      onFollow: () => provider.toggleFollow(p.username),
                    ),
                  ),
                ),

              // ── Tab 4: Tags (Tags List Screen - Image 1) ───────────────────
              if (provider.selectedSearchTab == 4) ...<Widget>[
                ...provider.tagResults.map(
                  (TagSearchResultItem t) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: SearchTagTile(tag: t),
                  ),
                ),
              ],

              // ── Tab 5: Communities ─────────────────────────────────────────
              if (provider.selectedSearchTab == 5)
                ...provider.communities.map(
                  (DiscoverCommunity c) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: DiscoverCommunityTile(
                      community: c,
                      isJoined: provider.isJoined(c.name),
                      onJoin: () => provider.toggleJoin(c.name),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No Results State
// ─────────────────────────────────────────────────────────────────────────────
class _NoResultsBody extends StatelessWidget {
  const _NoResultsBody({super.key, required this.query});

  final String query;

  static const List<String> _tabs = <String>[
    'All',
    'Posts',
    'Reels',
    'People',
    'Tags',
    'Communities',
  ];

  @override
  Widget build(BuildContext context) {
    final DiscoverProvider provider = context.watch<DiscoverProvider>();

    return Column(
      children: <Widget>[
        SearchTabBar(
          tabs: _tabs,
          selectedIndex: provider.selectedSearchTab,
          onTabSelected: provider.setSelectedSearchTab,
        ),
        const Divider(color: Color(0xFF2A2733), height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: <Widget>[
              const SizedBox(height: AppSpacing.xxxl),
              // Empty icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.cardBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  child: const Icon(
                    Icons.search_off_rounded,
                    color: AppColors.gradientCyan,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'No Results Found',
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "We couldn't find what you're looking for, but\nthere's more to discover.",
                textAlign: TextAlign.center,
                style: AppTextStyles.authHeaderSub,
              ),
              const SizedBox(height: AppSpacing.xl),
              // Action buttons
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppGradientButton(
                      text: 'Explore Trending',
                      fontSize: 13,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AppOutlineButton(
                      text: 'Discover Communities',
                      fontSize: 13,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              // YOU MIGHT LIKE
              const DiscoverSectionLabel(label: 'YOU MIGHT LIKE'),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: provider.youMightLike
                    .map(
                      (DiscoverCreator c) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.lg),
                        child: DiscoverCreatorCircle(creator: c, size: 60),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

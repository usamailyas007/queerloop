import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/cache/user_relationship_cache.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_tag_chip.dart';
import '../../auth/auth_provider.dart';
import '../../home/models/post_item_model.dart';
import '../../home/models/reel_item_model.dart';
import '../../home/provider/home_feed_provider.dart';
import '../../home/screens/hashtag_posts_screen.dart';
import '../../home/widgets/comments_bottom_sheet.dart';
import '../../home/widgets/post_feed_card.dart';
import '../../profile/provider/profile_provider.dart';
import '../models/discover_models.dart';
import '../provider/discover_provider.dart';
import '../widgets/clear_search_history_dialog.dart';
import '../widgets/discover_community_tile.dart';
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
    // Reset any previous search query so returning to screen starts clean
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DiscoverProvider>().clearSearchQuery();
        _focusNode.requestFocus();
        final AuthProvider auth = context.read<AuthProvider>();
        final ProfileProvider profile = context.read<ProfileProvider>();
        final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
        final String? myId = auth.userId ?? profile.profile?.id;
        final String myUsername = (auth.user?.displayName ?? profile.username)
            .replaceAll('@', '')
            .trim();
        final DiscoverProvider disc = context.read<DiscoverProvider>();
        disc.setCurrentUser(userId: myId, username: myUsername);
        disc.syncHomeFeedContent(
          posts: <PostItemModel>[...homeFeed.posts, ...profile.userPosts],
          reels: <ReelItemModel>[...homeFeed.reels, ...profile.userReels],
        );
      }
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

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, _) {
        if (didPop) {
          context.read<DiscoverProvider>().clearSearchQuery();
        }
      },
      child: Scaffold(
      backgroundColor: context.themeBackground,
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
                    ? const _SearchResultsBody(key: ValueKey<String>('results'))
                    : _SearchIdleBody(
                        key: const ValueKey<String>('idle'),
                        onSelectQuery: (String q) {
                          _controller.text = q;
                          _controller.selection = TextSelection.fromPosition(
                            TextPosition(offset: q.length),
                          );
                          provider.setSelectedSearchTab(0);
                          provider.setSearchQuery(q);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Idle State
// ─────────────────────────────────────────────────────────────────────────────
class _SearchIdleBody extends StatelessWidget {
  const _SearchIdleBody({
    super.key,
    this.onSelectQuery,
  });

  final ValueChanged<String>? onSelectQuery;

  @override
  Widget build(BuildContext context) {
    final DiscoverProvider provider = context.watch<DiscoverProvider>();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      children: <Widget>[
        // RECENT header
        if (provider.recentSearches.isNotEmpty) ...<Widget>[
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
                    color: context.isDarkMode
                        ? AppColors.gradientPink
                        : context.themeTextPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...provider.recentSearches.map(
            (String q) => SearchRecentTile(
              query: q,
              onTap: () => onSelectQuery?.call(q),
              onDelete: () => provider.removeRecentSearch(q),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // SUGGESTED FOR YOU
        if (provider.suggestedTags.isNotEmpty) ...<Widget>[
          const DiscoverSectionLabel(label: 'SUGGESTED FOR YOU'),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: provider.suggestedTags
                .map(
                  (String tag) => AppTagChip(
                    label: tag,
                    onTap: () => onSelectQuery?.call(tag),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],

        // BROWSE COMMUNITIES
        if (provider.communities.isNotEmpty) ...<Widget>[
          const DiscoverSectionLabel(label: 'BROWSE COMMUNITIES'),
          const SizedBox(height: AppSpacing.md),
          ...provider.communities.take(2).map(
                (DiscoverCommunity c) {
                  final ProfileProvider profile = context.watch<ProfileProvider>();
                  final bool isJoined = profile.isCommunityJoined(id: c.id, name: c.name);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                },
              ),
          const SizedBox(height: AppSpacing.xl),
        ],
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

  Widget _buildSectionHeader({
    required BuildContext context,
    required String title,
    required VoidCallback onSeeAll,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            color: context.themeTextMuted,
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
        if (provider.isLoadingSearch)
          const LinearProgressIndicator(
            backgroundColor: Colors.transparent,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.gradientCyan),
            minHeight: 2,
          )
        else
          Divider(color: context.themeDivider, height: 1),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            children: <Widget>[
              // ── Tab 0: All (Comprehensive Overview) ────────────────────────
              if (provider.selectedSearchTab == 0) ...<Widget>[
                if (provider.reelsResults.isEmpty &&
                    provider.postsResults.isEmpty &&
                    provider.peopleResults.isEmpty &&
                    provider.tagResults.isEmpty &&
                    provider.communityResults.isEmpty)
                  if (provider.isLoadingSearch)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gradientCyan),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: context.themeTextMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No results found',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "We couldn't find anything matching '${provider.searchQuery}'.",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                color: context.themeTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                else ...<Widget>[
                  // 1. TOP REELS Section
                  if (provider.reelsResults.isNotEmpty) ...<Widget>[
                  _buildSectionHeader(
                    context: context,
                    title: 'TOP REELS',
                    onSeeAll: () => provider.setSelectedSearchTab(2),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SearchPostsGrid(
                    results: provider.reelsResults.take(6).toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // 2. TOP POSTS Section
                if (provider.postsResults.isNotEmpty) ...<Widget>[
                  _buildSectionHeader(
                    context: context,
                    title: 'TOP POSTS',
                    onSeeAll: () => provider.setSelectedSearchTab(1),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...provider.postsResults.take(2).map(
                    (DiscoverSearchResult res) {
                      final String img = (res.imageAsset.isNotEmpty
                              ? res.imageAsset
                              : (res.thumbnailUrl ?? ''))
                          .trim();
                      final bool isHttp =
                          img.startsWith('http://') || img.startsWith('https://');
                      final bool isAsset = img.startsWith('assets/');
                      final bool isText = res.type == 'TEXT' ||
                          (img.isEmpty && res.mediaRefs.isEmpty);
                      final String? docId = res.id?.trim();
                      final String? refId = res.refId?.trim();
                      final String effectivePostId = (docId != null && docId.isNotEmpty)
                          ? docId
                          : (refId ?? 'search_${res.caption.hashCode}');
                      PostInteractionRegistry.linkIds(<String?>[effectivePostId, docId, refId, ...res.mediaRefs]);
                      final HomeFeedProvider hf = context.watch<HomeFeedProvider>();
                      final ProfileProvider pp = context.watch<ProfileProvider>();

                      final bool isLiked = PostInteractionRegistry.isLiked(
                        effectivePostId,
                        fallback: (docId != null && docId != effectivePostId && PostInteractionRegistry.isLiked(docId)) ||
                            (refId != null && refId != effectivePostId && PostInteractionRegistry.isLiked(refId)) ||
                            res.isLiked ||
                            hf.isPostLiked(effectivePostId) ||
                            pp.isPostLiked(effectivePostId),
                      );

                      final bool isSaved = PostInteractionRegistry.isSaved(
                        effectivePostId,
                        fallback: (docId != null && docId != effectivePostId && PostInteractionRegistry.isSaved(docId)) ||
                            (refId != null && refId != effectivePostId && PostInteractionRegistry.isSaved(refId)) ||
                            res.isSaved ||
                            hf.isPostSaved(effectivePostId) ||
                            pp.isPostSaved(effectivePostId),
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: PostFeedCard(
                          post: PostItemModel(
                            id: effectivePostId,
                            authorId: res.authorId,
                            username: (res.authorUsername != null &&
                                    res.authorUsername!.trim().isNotEmpty)
                                ? res.authorUsername!.trim()
                                : '@queer_creator',
                            pronounsTime: 'they/them · recent',
                            avatarAsset: (res.authorAvatar != null &&
                                    res.authorAvatar!.trim().isNotEmpty)
                                ? res.authorAvatar!.trim()
                                : AppImages.user1,
                            content: (res.caption != null &&
                                    res.caption!.trim().isNotEmpty)
                                ? res.caption!
                                : 'Shared post',
                            likesCount: PostInteractionRegistry.getLikeCount(effectivePostId, fallback: res.likesCount ?? 0),
                            commentsCount: CommentCountRegistry.getOr(effectivePostId, res.commentsCount ?? 0),
                            viewsCount: res.viewsCount,
                            postImageUrl: (!isText && isHttp) ? img : null,
                            postImageAsset: (!isText && isAsset) ? img : null,
                            postType: isText ? 'TEXT' : (res.type ?? 'PHOTO'),
                            communityId: res.communityId,
                            isLiked: isLiked,
                            isSaved: isSaved,
                            allowComments: res.allowComments,
                            allowDownloads: res.allowDownloads,
                            allowCommentsFrom: res.allowCommentsFrom,
                            isAuthorPrivate: res.isAuthorPrivate,
                            status: res.status,
                          ),
                          onPostDeleted: () {
                            provider.notifyPostDeleted(effectivePostId);
                            if (res.id != null && res.id != effectivePostId) {
                              provider.notifyPostDeleted(res.id!);
                            }
                          },
                          onLikeToggle: () {
                            final String pid = effectivePostId;
                            if (pid.isNotEmpty) {
                              final HomeFeedProvider feedProv = context.read<HomeFeedProvider>();
                              final ProfileProvider profProv = context.read<ProfileProvider>();
                              final bool currentlyLiked = PostInteractionRegistry.isLiked(
                                pid,
                                fallback: res.isLiked || feedProv.isPostLiked(pid) || profProv.isPostLiked(pid),
                              );
                              final bool newLiked = !currentlyLiked;
                              final int curCount = PostInteractionRegistry.getLikeCount(pid, fallback: res.likesCount ?? 0);
                              final int nextCount = newLiked ? curCount + 1 : (curCount > 0 ? curCount - 1 : 0);
                              PostInteractionRegistry.setLiked(pid, newLiked, newCount: nextCount);
                              if (docId != null && docId.isNotEmpty && docId.toLowerCase() != pid.toLowerCase()) {
                                PostInteractionRegistry.setLiked(docId, newLiked, newCount: nextCount);
                              }
                              if (refId != null && refId.isNotEmpty && refId.toLowerCase() != pid.toLowerCase()) {
                                PostInteractionRegistry.setLiked(refId, newLiked, newCount: nextCount);
                              }
                              feedProv.toggleLikePost(pid, explicitLiked: newLiked);
                              try {
                                profProv.updateLikedPost(pid, isLiked: newLiked, likesCount: nextCount);
                              } catch (_) {}
                            }
                          },
                          onSaveToggle: () {
                            final String pid = effectivePostId;
                            if (pid.isNotEmpty) {
                              final HomeFeedProvider feedProv = context.read<HomeFeedProvider>();
                              final ProfileProvider profProv = context.read<ProfileProvider>();
                              final bool currentlySaved = PostInteractionRegistry.isSaved(
                                pid,
                                fallback: res.isSaved || feedProv.isPostSaved(pid) || profProv.isPostSaved(pid),
                              );
                              final bool newSaved = !currentlySaved;
                              PostInteractionRegistry.setSaved(pid, newSaved);
                              if (docId != null && docId.isNotEmpty && docId.toLowerCase() != pid.toLowerCase()) {
                                PostInteractionRegistry.setSaved(docId, newSaved);
                              }
                              if (refId != null && refId.isNotEmpty && refId.toLowerCase() != pid.toLowerCase()) {
                                PostInteractionRegistry.setSaved(refId, newSaved);
                              }
                              feedProv.toggleSavePost(pid, explicitSaved: newSaved);
                              try {
                                profProv.updateSavedPost(pid, isSaved: newSaved);
                              } catch (_) {}
                            }
                          },
                          onOpenComments: () {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CommentsBottomSheet(
                                postId: effectivePostId,
                                postAuthorId: res.authorId,
                                communityId: res.communityId,
                                totalComments: CommentCountRegistry.getOr(effectivePostId, res.commentsCount ?? 0),
                                allowComments: res.allowComments,
                                allowCommentsFrom: res.allowCommentsFrom,
                                authorUsername: res.authorUsername,
                                onCommentAdded: () {
                                  CommentCountRegistry.increment(effectivePostId);
                                  context.read<HomeFeedProvider>().incrementCommentCount(effectivePostId);
                                  try {
                                    context.read<ProfileProvider>().incrementCommentCount(effectivePostId);
                                  } catch (_) {}
                                  if (res.id != null && res.id != effectivePostId) {
                                    CommentCountRegistry.increment(res.id!);
                                    context.read<HomeFeedProvider>().incrementCommentCount(res.id!);
                                    try {
                                      context.read<ProfileProvider>().incrementCommentCount(res.id!);
                                    } catch (_) {}
                                  }
                                },
                                onCommentDeleted: (int deletedCount, int remainingCount) {
                                  CommentCountRegistry.set(effectivePostId, remainingCount);
                                  context.read<HomeFeedProvider>().setCommentCount(effectivePostId, remainingCount);
                                  try {
                                    context.read<ProfileProvider>().updatePostCommentCount(effectivePostId, remainingCount);
                                  } catch (_) {}
                                  if (res.id != null && res.id != effectivePostId) {
                                    CommentCountRegistry.set(res.id!, remainingCount);
                                    context.read<HomeFeedProvider>().setCommentCount(res.id!, remainingCount);
                                    try {
                                      context.read<ProfileProvider>().updatePostCommentCount(res.id!, remainingCount);
                                    } catch (_) {}
                                  }
                                },
                                onCommentCountChanged: (int count) {
                                  CommentCountRegistry.set(effectivePostId, count);
                                  context.read<HomeFeedProvider>().setCommentCount(effectivePostId, count);
                                  try {
                                    context.read<ProfileProvider>().updatePostCommentCount(effectivePostId, count);
                                  } catch (_) {}
                                  if (res.id != null && res.id != effectivePostId) {
                                    CommentCountRegistry.set(res.id!, count);
                                    context.read<HomeFeedProvider>().setCommentCount(res.id!, count);
                                    try {
                                      context.read<ProfileProvider>().updatePostCommentCount(res.id!, count);
                                    } catch (_) {}
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // 2. TOP TAGS Section
                if (provider.tagResults.isNotEmpty) ...<Widget>[
                  _buildSectionHeader(
                    context: context,
                    title: 'TOP TAGS',
                    onSeeAll: () => provider.setSelectedSearchTab(4),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...provider.tagResults.take(4).map(
                        (TagSearchResultItem t) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: SearchTagTile(
                            tag: t,
                            onTap: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => HashtagPostsScreen(
                                    hashtag: t.name,
                                    postsCount: '${t.postsCount} posts',
                                    rankColor: AppColors.gradientCyan,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // 3. PEOPLE Section
                if (provider.peopleResults.isNotEmpty) ...<Widget>[
                  _buildSectionHeader(
                    context: context,
                    title: 'PEOPLE',
                    onSeeAll: () => provider.setSelectedSearchTab(3),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...provider.peopleResults.take(4).map(
                    (DiscoverPerson p) {
                      final ProfileProvider profile = context.watch<ProfileProvider>();
                      final bool isFollowing = profile.isFollowingUser(userId: p.id, username: p.username) ||
                          provider.isFollowing(p.username);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: SearchPersonTile(
                          person: p,
                          isFollowing: isFollowing,
                          onFollow: () async {
                            final bool willFollow = !isFollowing;
                            provider.toggleFollow(p.username);
                            if (p.id != null && p.id!.isNotEmpty) {
                              try {
                                if (willFollow) {
                                  await profile.followUser(p.id!, username: p.username);
                                } else {
                                  await profile.unfollowUser(p.id!, username: p.username);
                                }
                              } catch (_) {}
                            }
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // 4. COMMUNITIES TO EXPLORE Section
                if (provider.communityResults.isNotEmpty) ...<Widget>[
                  _buildSectionHeader(
                    context: context,
                    title: 'COMMUNITIES TO EXPLORE',
                    onSeeAll: () => provider.setSelectedSearchTab(5),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...provider.communityResults.take(4).map(
                    (DiscoverCommunity c) {
                      final ProfileProvider profile = context.watch<ProfileProvider>();
                      final bool isJoined = profile.isCommunityJoined(id: c.id, name: c.name);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ],
            ],

              // ── Tab 1: Posts (Full Posts Feed) ─────────────────────────────
              if (provider.selectedSearchTab == 1) ...<Widget>[
                if (provider.postsResults.isEmpty)
                  if (provider.isLoadingSearch)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gradientCyan),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.article_outlined,
                              size: 48,
                              color: context.themeTextMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No posts found',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "No photo or text posts matching '${provider.searchQuery}'.",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                color: context.themeTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                else
                  ...provider.postsResults.map(
                    (DiscoverSearchResult res) {
                      final String img = (res.imageAsset.isNotEmpty
                              ? res.imageAsset
                              : (res.thumbnailUrl ?? ''))
                          .trim();
                      final bool isHttp =
                          img.startsWith('http://') || img.startsWith('https://');
                      final bool isAsset = img.startsWith('assets/');
                      final bool isText = res.type == 'TEXT' ||
                          (img.isEmpty && res.mediaRefs.isEmpty);
                      final String? docId = res.id?.trim();
                      final String? refId = res.refId?.trim();
                      final String effectivePostId = (refId != null && refId.isNotEmpty)
                          ? refId
                          : (docId ?? 'search_${res.caption.hashCode}');
                      PostInteractionRegistry.linkIds(<String?>[effectivePostId, docId, refId, ...res.mediaRefs]);
                      final HomeFeedProvider hf = context.watch<HomeFeedProvider>();
                      final ProfileProvider pp = context.watch<ProfileProvider>();

                      final bool isLiked = PostInteractionRegistry.isLiked(effectivePostId) ||
                          (docId != null && PostInteractionRegistry.isLiked(docId)) ||
                          (refId != null && PostInteractionRegistry.isLiked(refId)) ||
                          hf.isPostLiked(effectivePostId) ||
                          (docId != null && hf.isPostLiked(docId)) ||
                          (refId != null && hf.isPostLiked(refId)) ||
                          pp.isPostLiked(effectivePostId) ||
                          (docId != null && pp.isPostLiked(docId)) ||
                          (refId != null && pp.isPostLiked(refId)) ||
                          res.isLiked;

                      final bool isSaved = PostInteractionRegistry.isSaved(effectivePostId) ||
                          (docId != null && PostInteractionRegistry.isSaved(docId)) ||
                          (refId != null && PostInteractionRegistry.isSaved(refId)) ||
                          hf.isPostSaved(effectivePostId) ||
                          (docId != null && hf.isPostSaved(docId)) ||
                          (refId != null && hf.isPostSaved(refId)) ||
                          pp.isPostSaved(effectivePostId) ||
                          (docId != null && pp.isPostSaved(docId)) ||
                          (refId != null && pp.isPostSaved(refId)) ||
                          res.isSaved;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: PostFeedCard(
                          post: PostItemModel(
                            id: effectivePostId,
                            authorId: res.authorId,
                            username: (res.authorUsername != null &&
                                    res.authorUsername!.trim().isNotEmpty)
                                ? res.authorUsername!.trim()
                                : '@queer_creator',
                            pronounsTime: 'they/them · recent',
                            avatarAsset: (res.authorAvatar != null &&
                                    res.authorAvatar!.trim().isNotEmpty)
                                ? res.authorAvatar!.trim()
                                : AppImages.user1,
                            content: (res.caption != null &&
                                    res.caption!.trim().isNotEmpty)
                                ? res.caption!
                                : 'Shared post',
                            likesCount: PostInteractionRegistry.getLikeCount(effectivePostId, fallback: res.likesCount ?? 0),
                            commentsCount: CommentCountRegistry.getOr(effectivePostId, res.commentsCount ?? 0),
                            viewsCount: res.viewsCount,
                            postImageUrl: (!isText && isHttp) ? img : null,
                            postImageAsset: (!isText && isAsset) ? img : null,
                            postType: isText ? 'TEXT' : (res.type ?? 'PHOTO'),
                            communityId: res.communityId,
                            isLiked: isLiked,
                            isSaved: isSaved,
                            allowComments: res.allowComments,
                            allowDownloads: res.allowDownloads,
                            allowCommentsFrom: res.allowCommentsFrom,
                            isAuthorPrivate: res.isAuthorPrivate,
                            status: res.status,
                          ),
                          onPostDeleted: () {
                            provider.notifyPostDeleted(effectivePostId);
                            if (res.id != null && res.id != effectivePostId) {
                              provider.notifyPostDeleted(res.id!);
                            }
                          },
                          onLikeToggle: () {
                            final String pid = effectivePostId;
                            if (pid.isNotEmpty) {
                              final HomeFeedProvider feedProv = context.read<HomeFeedProvider>();
                              final ProfileProvider profProv = context.read<ProfileProvider>();
                              final bool currentlyLiked = isLiked;
                              final bool newLiked = !currentlyLiked;
                              final int curCount = PostInteractionRegistry.getLikeCount(pid, fallback: res.likesCount ?? 0);
                              final int nextCount = newLiked ? curCount + 1 : (curCount > 0 ? curCount - 1 : 0);
                              PostInteractionRegistry.setLiked(pid, newLiked, newCount: nextCount);
                              if (docId != null && docId != pid) {
                                PostInteractionRegistry.setLiked(docId, newLiked, newCount: nextCount);
                              }
                              if (refId != null && refId != pid) {
                                PostInteractionRegistry.setLiked(refId, newLiked, newCount: nextCount);
                              }
                              feedProv.toggleLikePost(pid, explicitLiked: newLiked);
                              profProv.updateLikedPost(pid, isLiked: newLiked, likesCount: nextCount);
                            }
                          },
                          onSaveToggle: () {
                            final String pid = effectivePostId;
                            if (pid.isNotEmpty) {
                              final HomeFeedProvider feedProv = context.read<HomeFeedProvider>();
                              final ProfileProvider profProv = context.read<ProfileProvider>();
                              final bool currentlySaved = isSaved;
                              final bool newSaved = !currentlySaved;
                              PostInteractionRegistry.setSaved(pid, newSaved);
                              if (docId != null && docId != pid) {
                                PostInteractionRegistry.setSaved(docId, newSaved);
                              }
                              if (refId != null && refId != pid) {
                                PostInteractionRegistry.setSaved(refId, newSaved);
                              }
                              feedProv.toggleSavePost(pid, explicitSaved: newSaved);
                              try {
                                profProv.updateSavedPost(pid, isSaved: newSaved);
                              } catch (_) {}
                            }
                          },
                          onOpenComments: () {
                            showModalBottomSheet<void>(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => CommentsBottomSheet(
                                postId: effectivePostId,
                                postAuthorId: res.authorId,
                                communityId: res.communityId,
                                totalComments: CommentCountRegistry.getOr(effectivePostId, res.commentsCount ?? 0),
                                allowComments: res.allowComments,
                                allowCommentsFrom: res.allowCommentsFrom,
                                authorUsername: res.authorUsername,
                                onCommentAdded: () {
                                  CommentCountRegistry.increment(effectivePostId);
                                  context.read<HomeFeedProvider>().incrementCommentCount(effectivePostId);
                                  try {
                                    context.read<ProfileProvider>().incrementCommentCount(effectivePostId);
                                  } catch (_) {}
                                  if (res.id != null && res.id != effectivePostId) {
                                    CommentCountRegistry.increment(res.id!);
                                    context.read<HomeFeedProvider>().incrementCommentCount(res.id!);
                                    try {
                                      context.read<ProfileProvider>().incrementCommentCount(res.id!);
                                    } catch (_) {}
                                  }
                                },
                                onCommentDeleted: (int deletedCount, int remainingCount) {
                                  CommentCountRegistry.set(effectivePostId, remainingCount);
                                  context.read<HomeFeedProvider>().setCommentCount(effectivePostId, remainingCount);
                                  try {
                                    context.read<ProfileProvider>().updatePostCommentCount(effectivePostId, remainingCount);
                                  } catch (_) {}
                                  if (res.id != null && res.id != effectivePostId) {
                                    CommentCountRegistry.set(res.id!, remainingCount);
                                    context.read<HomeFeedProvider>().setCommentCount(res.id!, remainingCount);
                                    try {
                                      context.read<ProfileProvider>().updatePostCommentCount(res.id!, remainingCount);
                                    } catch (_) {}
                                  }
                                },
                                onCommentCountChanged: (int count) {
                                  CommentCountRegistry.set(effectivePostId, count);
                                  context.read<HomeFeedProvider>().setCommentCount(effectivePostId, count);
                                  try {
                                    context.read<ProfileProvider>().updatePostCommentCount(effectivePostId, count);
                                  } catch (_) {}
                                  if (res.id != null && res.id != effectivePostId) {
                                    CommentCountRegistry.set(res.id!, count);
                                    context.read<HomeFeedProvider>().setCommentCount(res.id!, count);
                                    try {
                                      context.read<ProfileProvider>().updatePostCommentCount(res.id!, count);
                                    } catch (_) {}
                                  }
                                },
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
              ],

              // ── Tab 2: Reels (Reels Grid) ──────────────────────────────────
              if (provider.selectedSearchTab == 2) ...<Widget>[
                if (provider.reelsResults.isEmpty)
                  if (provider.isLoadingSearch)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gradientCyan),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.video_library_outlined,
                              size: 48,
                              color: context.themeTextMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No reels found',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "No reels matching '${provider.searchQuery}'.",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                color: context.themeTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                else
                  SearchPostsGrid(
                    results: provider.reelsResults,
                  ),
              ],

              // ── Tab 3: People ──────────────────────────────────────────────
              if (provider.selectedSearchTab == 3) ...<Widget>[
                if (provider.peopleResults.isEmpty)
                  if (provider.isLoadingSearch)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gradientCyan),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.people_outline_rounded,
                              size: 48,
                              color: context.themeTextMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No accounts found',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "No people matching '${provider.searchQuery}'.",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                color: context.themeTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                else
                  ...provider.peopleResults.map(
                    (DiscoverPerson p) {
                      final ProfileProvider profile = context.watch<ProfileProvider>();
                      final bool isFollowing = profile.isFollowingUser(userId: p.id, username: p.username) ||
                          provider.isFollowing(p.username);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: SearchPersonTile(
                          person: p,
                          isFollowing: isFollowing,
                          onFollow: () async {
                            final bool willFollow = !isFollowing;
                            provider.toggleFollow(p.username);
                            if (p.id != null && p.id!.isNotEmpty) {
                              try {
                                if (willFollow) {
                                  await profile.followUser(p.id!, username: p.username);
                                } else {
                                  await profile.unfollowUser(p.id!, username: p.username);
                                }
                              } catch (_) {}
                            }
                          },
                        ),
                      );
                    },
                  ),
              ],

              // ── Tab 4: Tags (Tags List Screen) ─────────────────────────────
              if (provider.selectedSearchTab == 4) ...<Widget>[
                if (provider.tagResults.isEmpty)
                  if (provider.isLoadingSearch)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gradientCyan),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.tag_rounded,
                              size: 48,
                              color: context.themeTextMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No tags found',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "No tags matching '${provider.searchQuery}'.",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                color: context.themeTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                else
                  ...provider.tagResults.map(
                    (TagSearchResultItem t) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: SearchTagTile(
                        tag: t,
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => HashtagPostsScreen(
                                hashtag: t.name,
                                postsCount: '${t.postsCount} posts',
                                rankColor: AppColors.gradientCyan,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],

              // ── Tab 5: Communities ─────────────────────────────────────────
              if (provider.selectedSearchTab == 5) ...<Widget>[
                if (provider.communityResults.isEmpty)
                  if (provider.isLoadingSearch)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.gradientCyan),
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.groups_outlined,
                              size: 48,
                              color: context.themeTextMuted,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No communities found',
                              style: AppTextStyles.titleMedium.copyWith(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "No communities matching '${provider.searchQuery}'.",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.caption.copyWith(
                                color: context.themeTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                else
                  ...provider.communityResults.map(
                    (DiscoverCommunity c) {
                      final ProfileProvider profile = context.watch<ProfileProvider>();
                      final bool isJoined = profile.isCommunityJoined(id: c.id, name: c.name);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
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
                    },
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

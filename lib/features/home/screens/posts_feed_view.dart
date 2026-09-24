import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile_setup/models/community_model.dart';
import '../../profile_setup/provider/profile_setup_provider.dart';
import '../models/post_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/filter_communities_bottom_sheet.dart';
import '../widgets/home_empty_state_view.dart';
import '../widgets/post_feed_card.dart';

class PostsFeedView extends StatelessWidget {
  const PostsFeedView({
    this.onGuestActionTriggered,
    super.key,
  });

  final VoidCallback? onGuestActionTriggered;

  void _showFilterCommunitiesSheet(
    BuildContext context,
    HomeFeedProvider provider,
  ) {
    List<CommunityModel> availableComms = const <CommunityModel>[];
    try {
      final List<CommunityModel> userComms =
          context.read<ProfileProvider>().userCommunities;
      final List<CommunityModel> allComms =
          context.read<ProfileSetupProvider>().allCommunities;

      final Map<String, CommunityModel> commMap = <String, CommunityModel>{};
      for (final CommunityModel c in userComms) {
        commMap[c.id] = c;
      }
      for (final CommunityModel c in allComms) {
        commMap.putIfAbsent(c.id, () => c);
      }
      availableComms = commMap.values.toList();
    } catch (_) {}

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FilterCommunitiesBottomSheet(
          selectedCommunity: provider.selectedCommunityFilter,
          communities: availableComms,
          onApply: (String community, String? communityId) {
            provider.setSelectedCommunityFilter(
              community,
              communityId: communityId,
            );
          },
        );
      },
    );
  }

  void _showCommentsSheet(
    BuildContext context,
    String postId,
    int totalComments, {
    String? postAuthorId,
    bool allowComments = true,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentsBottomSheet(
          postId: postId,
          postAuthorId: postAuthorId,
          totalComments: totalComments,
          allowComments: allowComments,
          onCommentAdded: () {
            context.read<HomeFeedProvider>().incrementCommentCount(postId);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeFeedProvider provider = context.watch<HomeFeedProvider>();
    final List<PostItemModel> posts = provider.posts;
    final double topPadding = MediaQuery.of(context).padding.top + 105;
    final double viewPaddingBottom = MediaQuery.of(context).viewPadding.bottom;
    final double paddingBottom = MediaQuery.of(context).padding.bottom;
    final double systemBottomInset =
        viewPaddingBottom > paddingBottom ? viewPaddingBottom : paddingBottom;
    final double bottomPadding = 100 + systemBottomInset;

    if (provider.isLoadingFeed && posts.isEmpty) {
      return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.gradientPink),
        ),
      );
    }

    final bool showCommunityFilter =
        provider.activeTopTab == TopTab.communities;

    if (posts.isEmpty) {
      return RefreshIndicator(
        color: AppColors.gradientPink,
        onRefresh: () => provider.loadFeed(),
        edgeOffset: topPadding,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Stack(
                  children: <Widget>[
                    Builder(
                      builder: (BuildContext _) {
                        final String title;
                        final String subtitle;
                        final String buttonText;
                        final VoidCallback onAction;

                        if (showCommunityFilter) {
                          title = provider.selectedCommunityFilter !=
                                  'All Communities'
                              ? 'No posts in ${provider.selectedCommunityFilter}'
                              : 'No Community Posts Yet';
                          subtitle = provider.selectedCommunityFilter !=
                                  'All Communities'
                              ? 'There are no posts in this community yet. Explore other communities or share your thoughts!'
                              : 'Join or select a community to see posts here!';
                          buttonText = 'Explore Communities';
                          onAction = () =>
                              _showFilterCommunitiesSheet(context, provider);
                        } else if (provider.activeTopTab == TopTab.following) {
                          title = 'No Following Posts Yet';
                          subtitle =
                              'Follow creators or users to see their posts in this feed.';
                          buttonText = 'Discover People';
                          onAction = () => provider.setBottomNavIndex(1);
                        } else {
                          title = 'No Posts Yet';
                          subtitle =
                              'Pull down to refresh or check back shortly!';
                          buttonText = 'Refresh Feed';
                          onAction = () => provider.loadFeed(force: true);
                        }

                        return HomeEmptyStateView(
                          title: title,
                          subtitle: subtitle,
                          buttonText: buttonText,
                          onOpenExplore: onAction,
                        );
                      },
                    ),
                    if (showCommunityFilter)
                      Positioned(
                        top: topPadding - 36,
                        left: 16,
                        child: GestureDetector(
                          onTap: () =>
                              _showFilterCommunitiesSheet(context, provider),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: AppColors.secondaryGradientButton,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: <BoxShadow>[
                                BoxShadow(
                                  color: AppColors.gradientCyan
                                      .withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                const Icon(
                                  Icons.groups_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  provider.selectedCommunityFilter,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadFeed(),
      edgeOffset: topPadding,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          top: topPadding,
          bottom: bottomPadding,
        ),
        itemCount: showCommunityFilter ? posts.length + 1 : posts.length,
        itemBuilder: (context, index) {
          if (showCommunityFilter && index == 0) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _showFilterCommunitiesSheet(context, provider),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.secondaryGradientButton,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: AppColors.gradientCyan.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.groups_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          provider.selectedCommunityFilter,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          final int postIndex = showCommunityFilter ? index - 1 : index;
          final PostItemModel item = posts[postIndex];
          final ProfileProvider profileProvider = context.watch<ProfileProvider>();
          final bool isFollowingAuthor = profileProvider.isFollowingUser(
            userId: item.authorId,
            username: item.username,
          );

          return PostFeedCard(
            post: item,
            isFollowing: isFollowingAuthor,
            onFollowToggle: () async {
              if (provider.isGuest) {
                onGuestActionTriggered?.call();
              } else {
                final String? authorId = item.authorId;
                if (authorId == null || authorId.isEmpty) return;
                if (isFollowingAuthor) {
                  await profileProvider.unfollowUser(authorId, username: item.username);
                } else {
                  await profileProvider.followUser(authorId, username: item.username);
                }
              }
            },
            onLikeToggle: () {
              if (provider.isGuest) {
                onGuestActionTriggered?.call();
              } else {
                provider.toggleLikePost(item.id);
              }
            },
            onSaveToggle: () {
              if (provider.isGuest) {
                onGuestActionTriggered?.call();
              } else {
                provider.toggleSavePost(item.id);
              }
            },
            onOpenComments: () {
              if (provider.isGuest) {
                onGuestActionTriggered?.call();
              } else {
                _showCommentsSheet(
                  context,
                  item.id,
                  item.commentsCount,
                  postAuthorId: item.authorId,
                  allowComments: item.allowComments,
                );
              }
            },
          );
        },
      ),
    );
  }
}

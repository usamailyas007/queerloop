import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile_setup/models/community_model.dart';
import '../../profile_setup/provider/profile_setup_provider.dart';
import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../services/reel_video_preloader.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/filter_communities_bottom_sheet.dart';
import '../widgets/home_empty_state_view.dart';
import '../widgets/reel_feed_card.dart';
import '../widgets/safety_bottom_sheet.dart';
import '../widgets/send_to_bottom_sheet.dart';
import '../widgets/share_this_post_bottom_sheet.dart';

/// TikTok / Instagram Reels-style smooth page snapping physics.
/// Uses a critically-damped spring (mass: 0.35, stiffness: 400.0, ratio: 1.1)
/// ensuring lightning-fast, crisp snaps with ZERO oscillation and ZERO sticking midway.
class ReelScrollPhysics extends PageScrollPhysics {
  const ReelScrollPhysics({super.parent});

  @override
  ReelScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ReelScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.35,
        stiffness: 400.0,
        ratio: 1.1,
      );
}

class ReelsFeedView extends StatefulWidget {
  const ReelsFeedView({
    this.onGuestActionTriggered,
    this.initialPage = 0,
    this.customReels,
    this.hasBottomBar = true,
    super.key,
  });

  final VoidCallback? onGuestActionTriggered;
  final int initialPage;
  final List<ReelItemModel>? customReels;
  final bool hasBottomBar;

  @override
  State<ReelsFeedView> createState() => _ReelsFeedViewState();
}

class _ReelsFeedViewState extends State<ReelsFeedView> {
  late final PageController _pageController;
  late int _activePage;

  @override
  void initState() {
    super.initState();
    _activePage = widget.initialPage;
    _pageController = PageController(initialPage: widget.initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final HomeFeedProvider provider = context.read<HomeFeedProvider>();
        final List<ReelItemModel> reels = widget.customReels ?? provider.reels;
        if (reels.isNotEmpty) {
          ReelVideoPreloader.instance.preloadSurrounding(reels, _activePage);
        }
      }
    });
  }

  @override
  void deactivate() {
    ReelVideoPreloader.instance.pauseAll();
    super.deactivate();
  }

  @override
  void dispose() {
    _pageController.dispose();
    ReelVideoPreloader.instance.pauseAll();
    super.dispose();
  }

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
          onCommentAdded: () {
            context.read<HomeFeedProvider>().incrementCommentCount(postId);
          },
        );
      },
    );
  }

  void _showShareSheet(BuildContext context, ReelItemModel reel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ShareThisPostBottomSheet(
          onOpenMoreSendTo: () {
            Navigator.pop(context);
            _showSendToSheet(context);
          },
          onOpenReportSafety: () {
            Navigator.pop(context);
            _showSafetySheet(context, reel);
          },
        );
      },
    );
  }

  void _showSendToSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const SendToBottomSheet();
      },
    );
  }

  void _showSafetySheet(BuildContext context, ReelItemModel reel) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafetyBottomSheet(
          username: reel.username,
          postId: reel.id,
          authorId: reel.authorId ?? reel.username,
          communityId: reel.communityId,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeFeedProvider provider = context.watch<HomeFeedProvider>();
    final List<ReelItemModel> reels = widget.customReels ?? provider.reels;
    final double topInset = MediaQuery.of(context).padding.top + 50;

    if (provider.isLoadingFeed && reels.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.gradientPink),
      );
    }

    if (reels.isEmpty) {
      final bool isCommunityTab = provider.activeTopTab == TopTab.communities;
      return RefreshIndicator(
        color: AppColors.gradientPink,
        backgroundColor: const Color(0xFF1E1E2E),
        edgeOffset: topInset,
        onRefresh: () => provider.loadFeed(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: constraints.maxHeight,
                child: Stack(
                  children: <Widget>[
                    HomeEmptyStateView(
                      title: isCommunityTab &&
                              provider.selectedCommunityFilter !=
                                  'All Communities'
                          ? 'No videos in ${provider.selectedCommunityFilter}'
                          : null,
                      subtitle: isCommunityTab &&
                              provider.selectedCommunityFilter !=
                                  'All Communities'
                          ? 'There are no videos in this community yet. Explore other communities or be the first to post!'
                          : null,
                      buttonText: isCommunityTab ? 'Explore Communities' : null,
                      onOpenExplore: () {
                        if (isCommunityTab) {
                          _showFilterCommunitiesSheet(context, provider);
                        } else {
                          provider.loadFeed(force: true);
                        }
                      },
                    ),
                    if (isCommunityTab)
                      Positioned(
                        top: topInset + 10,
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
      color: AppColors.gradientPink,
      backgroundColor: const Color(0xFF1E1E2E),
      displacement: 60,
      edgeOffset: topInset,
      onRefresh: () async {
        await provider.loadFeed();
        if (mounted && reels.isNotEmpty) {
          ReelVideoPreloader.instance.preloadSurrounding(reels, _activePage);
        }
      },
      child: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        physics: const ReelScrollPhysics(),
        itemCount: reels.length,
        onPageChanged: (int index) {
          setState(() => _activePage = index);
          ReelVideoPreloader.instance.preloadSurrounding(reels, index);
          if (index < reels.length) {
            provider.recordView(reels[index].id);
          }
        },
        itemBuilder: (context, index) {
          final ReelItemModel item = reels[index];
          final bool isVisuallyActive = (widget.customReels != null)
              ? (index == _activePage)
              : (index == _activePage &&
                  provider.bottomNavIndex == 0 &&
                  provider.activeSubMode == SubMode.reels);

          return ReelFeedCard(
            key: ValueKey<String>(item.id),
            reel: item,
            isActive: isVisuallyActive,
            hasBottomBar: widget.hasBottomBar,
            showCommunityFilterTag: provider.activeTopTab == TopTab.communities,
            selectedCommunity: provider.selectedCommunityFilter,
            onLikeToggle: () {
              if (provider.isGuest) {
                widget.onGuestActionTriggered?.call();
              } else {
                provider.toggleLikeReel(item.id);
              }
            },
            onSaveToggle: () {
              if (provider.isGuest) {
                widget.onGuestActionTriggered?.call();
              } else {
                provider.toggleSaveReel(item.id);
              }
            },
            onFollowToggle: () {
              if (provider.isGuest) {
                widget.onGuestActionTriggered?.call();
              } else {
                provider.toggleFollowReel(item.id);
              }
            },
            onOpenComments: () {
              if (provider.isGuest) {
                widget.onGuestActionTriggered?.call();
              } else {
                _showCommentsSheet(
                  context,
                  item.id,
                  item.commentsCount,
                  postAuthorId: item.authorId,
                );
              }
            },
            onOpenShare: () {
              if (provider.isGuest) {
                widget.onGuestActionTriggered?.call();
              } else {
                _showShareSheet(context, item);
              }
            },
            onOpenSafety: () => _showSafetySheet(context, item),
            onOpenFilterCommunities: () =>
                _showFilterCommunitiesSheet(context, provider),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showFilterCommunitiesSheet(
    BuildContext context,
    HomeFeedProvider provider,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FilterCommunitiesBottomSheet(
          selectedCommunity: provider.selectedCommunityFilter,
          onApply: (String community) {
            provider.setSelectedCommunityFilter(community);
          },
        );
      },
    );
  }

  void _showCommentsSheet(
    BuildContext context,
    String postId,
    int totalComments,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentsBottomSheet(
          postId: postId,
          totalComments: totalComments,
          onCommentAdded: () {
            context.read<HomeFeedProvider>().incrementCommentCount(postId);
          },
        );
      },
    );
  }

  void _showShareSheet(BuildContext context) {
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
            _showSafetySheet(context);
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

  void _showSafetySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return const SafetyBottomSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final HomeFeedProvider provider = context.watch<HomeFeedProvider>();
    final List<ReelItemModel> reels = widget.customReels ?? provider.reels;
    final double topInset = MediaQuery.of(context).padding.top + 50;
    if (reels.isEmpty) {
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
                child: HomeEmptyStateView(
                  onOpenExplore: () {
                    provider.setTopTab(TopTab.forYou);
                  },
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
          return ReelFeedCard(
            key: ValueKey<String>(item.id),
            reel: item,
            isActive: index == _activePage,
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
                _showCommentsSheet(context, item.id, item.commentsCount);
              }
            },
            onOpenShare: () {
              if (provider.isGuest) {
                widget.onGuestActionTriggered?.call();
              } else {
                _showShareSheet(context);
              }
            },
            onOpenSafety: () => _showSafetySheet(context),
            onOpenFilterCommunities: () =>
                _showFilterCommunitiesSheet(context, provider),
          );
        },
      ),
    );
  }
}

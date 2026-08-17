import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/filter_communities_bottom_sheet.dart';
import '../widgets/home_empty_state_view.dart';
import '../widgets/reel_feed_card.dart';
import '../widgets/safety_bottom_sheet.dart';
import '../widgets/send_to_bottom_sheet.dart';
import '../widgets/share_this_post_bottom_sheet.dart';

class ReelsFeedView extends StatefulWidget {
  const ReelsFeedView({
    this.onGuestActionTriggered,
    super.key,
  });

  final VoidCallback? onGuestActionTriggered;

  @override
  State<ReelsFeedView> createState() => _ReelsFeedViewState();
}

class _ReelsFeedViewState extends State<ReelsFeedView> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showFilterCommunitiesSheet(
      BuildContext context, HomeFeedProvider provider) {
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

  void _showCommentsSheet(BuildContext context, int totalComments) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentsBottomSheet(totalComments: totalComments);
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

    if (provider.isFollowingEmpty) {
      return HomeEmptyStateView(
        onOpenExplore: () {
          provider.setTopTab(TopTab.forYou);
        },
      );
    }

    final List<ReelItemModel> reels = provider.reels;

    return PageView.builder(
      controller: _pageController,
      scrollDirection: Axis.vertical,
      itemCount: reels.length,
      itemBuilder: (context, index) {
        final ReelItemModel item = reels[index];

        return ReelFeedCard(
          reel: item,
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
              _showCommentsSheet(context, item.commentsCount);
            }
          },
          onOpenShare: () => _showShareSheet(context),
          onOpenSafety: () => _showSafetySheet(context),
          onOpenFilterCommunities: () =>
              _showFilterCommunitiesSheet(context, provider),
        );
      },
    );
  }
}

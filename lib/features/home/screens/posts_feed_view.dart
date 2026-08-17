import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/post_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/home_empty_state_view.dart';
import '../widgets/post_feed_card.dart';

class PostsFeedView extends StatelessWidget {
  const PostsFeedView({
    this.onGuestActionTriggered,
    super.key,
  });

  final VoidCallback? onGuestActionTriggered;

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

    final List<PostItemModel> posts = provider.posts;
    final double topPadding = MediaQuery.of(context).padding.top + 105;
    final double viewPaddingBottom = MediaQuery.of(context).viewPadding.bottom;
    final double paddingBottom = MediaQuery.of(context).padding.bottom;
    final double systemBottomInset =
        viewPaddingBottom > paddingBottom ? viewPaddingBottom : paddingBottom;
    final double bottomPadding = 90 + systemBottomInset;

    return ListView.builder(
      padding: EdgeInsets.only(
        top: topPadding,
        bottom: bottomPadding,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) {
        final PostItemModel item = posts[index];

        return PostFeedCard(
          post: item,
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
              _showCommentsSheet(context, item.commentsCount);
            }
          },
        );
      },
    );
  }
}

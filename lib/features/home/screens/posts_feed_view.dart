import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
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

  void _showCommentsSheet(
      BuildContext context, String postId, int totalComments) {
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

  @override
  Widget build(BuildContext context) {
    final HomeFeedProvider provider = context.watch<HomeFeedProvider>();
    final List<PostItemModel> posts = provider.posts;
    final double topPadding = MediaQuery.of(context).padding.top + 105;
    final double viewPaddingBottom = MediaQuery.of(context).viewPadding.bottom;
    final double paddingBottom = MediaQuery.of(context).padding.bottom;
    final double systemBottomInset =
        viewPaddingBottom > paddingBottom ? viewPaddingBottom : paddingBottom;
    final double bottomPadding = 90 + systemBottomInset;

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
      onRefresh: () => provider.loadFeed(),
      edgeOffset: topPadding,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
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
                _showCommentsSheet(context, item.id, item.commentsCount);
              }
            },
          );
        },
      ),
    );
  }
}

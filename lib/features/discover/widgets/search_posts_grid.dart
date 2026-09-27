import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/models/post_item_model.dart';
import '../../home/models/reel_item_model.dart';
import '../../home/screens/reels_feed_view.dart';
import '../../home/widgets/comments_bottom_sheet.dart';
import '../../home/widgets/post_feed_card.dart';
import '../models/discover_models.dart';

/// 3-column grid of search result cards with dynamic image/video thumbnails and playback.
class SearchPostsGrid extends StatelessWidget {
  const SearchPostsGrid({
    this.results = const <DiscoverSearchResult>[],
    super.key,
  });

  final List<DiscoverSearchResult> results;

  List<ReelItemModel> _buildSearchReels() {
    return results.asMap().entries.map((MapEntry<int, DiscoverSearchResult> entry) {
      final int i = entry.key;
      final DiscoverSearchResult res = entry.value;

      final String img = (res.imageAsset.isNotEmpty ? res.imageAsset : (res.thumbnailUrl ?? '')).trim();
      final bool isVideoUrl = img.startsWith('http') &&
          (img.endsWith('.mp4') || img.endsWith('.m3u8') || img.contains('video'));

      return ReelItemModel(
        id: res.id ?? 'search_reel_$i',
        authorId: res.authorId,
        username: (res.authorUsername != null && res.authorUsername!.trim().isNotEmpty)
            ? res.authorUsername!.trim()
            : '@creator',
        pronounsTime: 'they/them · recent',
        avatarAsset: (res.authorAvatar != null && res.authorAvatar!.trim().isNotEmpty)
            ? res.authorAvatar!.trim()
            : AppImages.user1,
        videoAsset: (img.startsWith('assets/') && img.endsWith('.mp4')) ? img : '',
        videoUrl: res.videoUrl ?? (isVideoUrl ? img : (img.startsWith('http') ? img : null)),
        thumbnailUrl: res.thumbnailUrl ?? (isVideoUrl ? null : (img.startsWith('http') ? img : null)),
        caption: res.caption ?? '',
        likesCount: res.likesCount ?? 0,
        commentsCount: res.commentsCount ?? 0,
        tags: const <String>[],
      );
    }).toList();
  }

  void _openReelPlayer(BuildContext context, int initialIndex) {
    final List<ReelItemModel> searchReels = _buildSearchReels();
    if (searchReels.isEmpty) return;

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: <Widget>[
              ReelsFeedView(
                initialPage: initialIndex,
                customReels: searchReels,
                hasBottomBar: false,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPostViewer(BuildContext context, DiscoverSearchResult item) {
    final String img = (item.imageAsset.isNotEmpty ? item.imageAsset : (item.thumbnailUrl ?? '')).trim();
    final bool isHttp = img.startsWith('http://') || img.startsWith('https://');
    final bool isAsset = img.startsWith('assets/');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, ScrollController scrollController) => Container(
          decoration: BoxDecoration(
            color: ctx.themeBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: <Widget>[
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: ctx.themeBorderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              PostFeedCard(
                post: PostItemModel(
                  id: item.id ?? 'search_${item.caption.hashCode}',
                  authorId: item.authorId,
                  username: (item.authorUsername != null && item.authorUsername!.trim().isNotEmpty)
                      ? item.authorUsername!.trim()
                      : '@creator',
                  pronounsTime: 'they/them · recent',
                  avatarAsset: (item.authorAvatar != null && item.authorAvatar!.trim().isNotEmpty)
                      ? item.authorAvatar!.trim()
                      : AppImages.user1,
                  content: (item.caption != null && item.caption!.trim().isNotEmpty)
                      ? item.caption!
                      : 'Shared post',
                  likesCount: item.likesCount ?? 0,
                  commentsCount: item.commentsCount ?? 0,
                  postImageUrl: isHttp ? img : null,
                  postImageAsset: isAsset
                      ? img
                      : (!isHttp
                          ? <String>[
                              AppImages.searchResult1,
                              AppImages.searchResult2,
                              AppImages.searchResult3,
                              AppImages.searchResult4,
                              AppImages.searchResult5,
                              AppImages.searchResult6,
                            ][(item.id ?? '').hashCode.abs() % 6]
                          : null),
                  postType: item.type ?? 'PHOTO',
                  communityId: item.communityId,
                  isLiked: item.isLiked,
                ),
                onLikeToggle: () {},
                onSaveToggle: () {},
                onOpenComments: () {
                  showModalBottomSheet<void>(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => CommentsBottomSheet(
                      totalComments: item.commentsCount ?? 0,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, int index) {
    final DiscoverSearchResult item = results[index];
    if (item.isReel) {
      _openReelPlayer(context, index);
    } else {
      _openPostViewer(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: results.length,
      itemBuilder: (BuildContext context, int index) {
        final DiscoverSearchResult item = results[index];
        final bool isReel = item.isReel;
        final String countText = item.viewCount ??
            (item.likesCount != null && item.likesCount! > 0
                ? '${item.likesCount}'
                : '');

        return GestureDetector(
          onTap: () => _handleTap(context, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _buildThumbnail(item),

                // Dark gradient bottom overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.75),
                      ],
                      stops: const <double>[0.0, 0.55, 1.0],
                    ),
                  ),
                ),

                // Views count & play or heart icon
                Positioned(
                  left: 6,
                  bottom: 6,
                  right: 6,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        isReel ? Icons.play_arrow_rounded : Icons.favorite_rounded,
                        color: isReel ? Colors.white : Colors.redAccent.withValues(alpha: 0.9),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          countText.isNotEmpty
                              ? countText
                              : (isReel ? 'Watch' : 'Post'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(DiscoverSearchResult item) {
    final String url = (item.thumbnailUrl != null && item.thumbnailUrl!.trim().isNotEmpty)
        ? item.thumbnailUrl!.trim()
        : item.imageAsset.trim();

    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackContainer(item),
      );
    } else if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackContainer(item),
      );
    }
    return _fallbackContainer(item);
  }

  Widget _fallbackContainer(DiscoverSearchResult item) {
    final int hash = (item.id ?? item.caption ?? '').hashCode.abs() % 6;
    final String fallbackAsset = <String>[
      AppImages.searchResult1,
      AppImages.searchResult2,
      AppImages.searchResult3,
      AppImages.searchResult4,
      AppImages.searchResult5,
      AppImages.searchResult6,
    ][hash];

    return Image.asset(
      fallbackAsset,
      fit: BoxFit.cover,
    );
  }
}

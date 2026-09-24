import 'package:flutter/material.dart';
import '../../../core/cache/user_relationship_cache.dart';
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
    return results
        .where((res) => !DeletedPostsRegistry.isDeleted(res.id ?? ''))
        .toList()
        .asMap()
        .entries
        .map((MapEntry<int, DiscoverSearchResult> entry) {
      final int i = entry.key;
      final DiscoverSearchResult res = entry.value;

      final String img = (res.imageAsset.isNotEmpty ? res.imageAsset : (res.thumbnailUrl ?? '')).trim();
      final bool isVideoUrl = img.startsWith('http') &&
          (img.endsWith('.mp4') || img.endsWith('.m3u8') || img.contains('video') || img.contains('/videos/'));

      final String? thumb = (res.thumbnailUrl != null && res.thumbnailUrl!.isNotEmpty)
          ? res.thumbnailUrl
          : (res.videoUrl != null && res.videoUrl!.contains('/videos/processed/')
              ? res.videoUrl!.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumbnail.jpg')
              : (isVideoUrl ? null : (img.startsWith('http') ? img : null)));

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
        thumbnailUrl: thumb,
        caption: res.caption ?? '',
        likesCount: res.likesCount ?? 0,
        commentsCount: res.commentsCount ?? 0,
        viewsCount: res.viewsCount,
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
    final bool isText = item.type == 'TEXT' || (img.isEmpty && item.mediaRefs.isEmpty);

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
                  postImageUrl: (!isText && isHttp) ? img : null,
                  postImageAsset: (!isText && isAsset) ? img : null,
                  postType: isText ? 'TEXT' : (item.type ?? 'PHOTO'),
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
                      postId: item.id,
                      postAuthorId: item.authorId,
                      communityId: item.communityId,
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
    final List<DiscoverSearchResult> activeResults = results
        .where((DiscoverSearchResult r) => !DeletedPostsRegistry.isDeleted(r.id ?? ''))
        .toList();
    if (index >= activeResults.length) return;
    final DiscoverSearchResult item = activeResults[index];
    if (item.isReel) {
      _openReelPlayer(context, index);
    } else {
      _openPostViewer(context, item);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DiscoverSearchResult> activeResults = results
        .where((DiscoverSearchResult r) => !DeletedPostsRegistry.isDeleted(r.id ?? ''))
        .toList();

    if (activeResults.isEmpty) {
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
      itemCount: activeResults.length,
      itemBuilder: (BuildContext context, int index) {
        final DiscoverSearchResult item = activeResults[index];
        final bool isReel = item.isReel;
        final String countText = isReel
            ? (item.viewCount ?? '${item.viewsCount}')
            : (item.likesCount != null && item.likesCount! > 0
                ? '${item.likesCount}'
                : (item.viewCount ?? ''));

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
    if (item.isReel) {
      return Container(
        color: const Color(0xFF1E1B26),
        child: const Center(
          child: Icon(
            Icons.play_circle_outline_rounded,
            color: Colors.white38,
            size: 32,
          ),
        ),
      );
    }
    if (item.caption != null && item.caption!.isNotEmpty && item.imageAsset.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        color: const Color(0xFF231E34),
        child: Center(
          child: Text(
            item.caption!,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return Container(
      color: const Color(0xFF1E1E2C),
      child: Center(
        child: Icon(
          item.isReel ? Icons.play_arrow_rounded : Icons.image_outlined,
          color: Colors.white24,
          size: 28,
        ),
      ),
    );
  }
}

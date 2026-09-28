import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/cache/user_relationship_cache.dart';
import '../../../core/config/app_config.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/models/post_item_model.dart';
import '../../home/models/reel_item_model.dart';
import '../../home/provider/home_feed_provider.dart';
import '../../home/screens/reels_feed_view.dart';
import '../../home/widgets/post_feed_card.dart';
import '../../profile/provider/profile_provider.dart';
import '../models/discover_models.dart';

/// 3-column grid of search result cards with dynamic image/video thumbnails and playback.
class SearchPostsGrid extends StatelessWidget {
  const SearchPostsGrid({
    this.results = const <DiscoverSearchResult>[],
    super.key,
  });

  final List<DiscoverSearchResult> results;

  List<DiscoverSearchResult> _filterAndDeduplicate(List<DiscoverSearchResult> list) {
    final List<DiscoverSearchResult> unique = <DiscoverSearchResult>[];
    final Set<String> seen = <String>{};

    for (final DiscoverSearchResult item in list) {
      if (!item.isPublished) continue;
      final String id = (item.id ?? '').trim().toLowerCase();
      final String refId = (item.refId ?? '')
          .trim()
          .toLowerCase()
          .replaceAll(RegExp(r'^/+|^media/'), '');

      if (id.isNotEmpty && DeletedPostsRegistry.isDeleted(id)) continue;
      if (refId.isNotEmpty && DeletedPostsRegistry.isDeleted(refId)) continue;

      if (id.isNotEmpty && seen.contains('id:$id')) continue;
      if (refId.isNotEmpty && seen.contains('id:$refId')) continue;

      if (item.videoUrl != null && item.videoUrl!.trim().isNotEmpty) {
        final String v = item.videoUrl!.trim().toLowerCase();
        final RegExpMatch? m = RegExp(r'/videos/processed/([a-zA-Z0-9_\-]+)').firstMatch(v);
        final String vKey = m != null ? m.group(1)! : v;
        if (seen.contains('vid:$vKey')) continue;
        seen.add('vid:$vKey');
      }

      if (id.isNotEmpty) seen.add('id:$id');
      if (refId.isNotEmpty) seen.add('id:$refId');

      unique.add(item);
    }
    return unique;
  }

  List<ReelItemModel> _buildSearchReels() {
    final List<DiscoverSearchResult> validResults = _filterAndDeduplicate(results);
    return validResults.asMap().entries.map((MapEntry<int, DiscoverSearchResult> entry) {
      final int i = entry.key;
      final DiscoverSearchResult res = entry.value;

      final String img = (res.imageAsset.isNotEmpty ? res.imageAsset : (res.thumbnailUrl ?? '')).trim();
      final bool isVideoUrl = img.startsWith('http') &&
          (img.endsWith('.mp4') || img.endsWith('.m3u8') || img.contains('video') || img.contains('/videos/'));

      String? resolvedVideo = res.videoUrl;
      if (resolvedVideo == null || resolvedVideo.isEmpty) {
        if (res.mediaRefs.isNotEmpty) {
          final String m = res.mediaRefs.first.replaceAll(RegExp(r'^/+|^media/'), '').trim();
          resolvedVideo = '${AppConfig.cdnUrl}/videos/processed/$m/master.m3u8';
        } else if (res.refId != null && res.refId!.trim().isNotEmpty) {
          final String rId = res.refId!.trim().replaceAll(RegExp(r'^/+|^media/'), '');
          resolvedVideo = '${AppConfig.cdnUrl}/videos/processed/$rId/master.m3u8';
        }
      }

      final String? thumb = (res.thumbnailUrl != null && res.thumbnailUrl!.isNotEmpty)
          ? res.thumbnailUrl
          : (resolvedVideo != null && resolvedVideo.contains('/videos/processed/')
              ? resolvedVideo.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg')
              : (isVideoUrl ? null : (img.startsWith('http') ? img : null)));

      final String effectiveId = (res.refId != null && res.refId!.trim().isNotEmpty)
          ? res.refId!.trim()
          : (res.id ?? 'search_reel_$i');

      return ReelItemModel(
        id: effectiveId,
        authorId: res.authorId,
        username: (res.authorUsername != null && res.authorUsername!.trim().isNotEmpty)
            ? res.authorUsername!.trim()
            : '@creator',
        pronounsTime: 'they/them · recent',
        avatarAsset: (res.authorAvatar != null && res.authorAvatar!.trim().isNotEmpty)
            ? res.authorAvatar!.trim()
            : AppImages.user1,
        videoAsset: (img.startsWith('assets/') && img.endsWith('.mp4')) ? img : '',
        videoUrl: resolvedVideo ?? (isVideoUrl ? img : (img.startsWith('http') ? img : null)),
        thumbnailUrl: thumb,
        caption: res.caption ?? '',
        likesCount: res.likesCount ?? 0,
        commentsCount: res.commentsCount ?? 0,
        viewsCount: res.viewsCount,
        isLiked: res.isLiked,
        isSaved: res.isSaved,
        allowComments: res.allowComments,
        allowDownloads: res.allowDownloads,
        allowCommentsFrom: res.allowCommentsFrom,
        isAuthorPrivate: res.isAuthorPrivate,
        communityId: res.communityId,
        status: res.status,
        tags: const <String>[],
      );
    }).toList();
  }

  void _openReelPlayer(BuildContext context, int initialIndex) {
    final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
    final ProfileProvider profile = context.read<ProfileProvider>();
    final List<DiscoverSearchResult> validResults = _filterAndDeduplicate(results);
    final List<ReelItemModel> searchReels = _buildSearchReels().asMap().entries.map((MapEntry<int, ReelItemModel> entry) {
      final int i = entry.key;
      final ReelItemModel r = entry.value;
      final DiscoverSearchResult? res = i < validResults.length ? validResults[i] : null;
      final String? docId = res?.id?.trim();
      final String? refId = res?.refId?.trim();

      final bool liked = PostInteractionRegistry.isLiked(r.id) ||
          (docId != null && PostInteractionRegistry.isLiked(docId)) ||
          (refId != null && PostInteractionRegistry.isLiked(refId)) ||
          homeFeed.isPostLiked(r.id) ||
          (docId != null && homeFeed.isPostLiked(docId)) ||
          (refId != null && homeFeed.isPostLiked(refId)) ||
          profile.isPostLiked(r.id) ||
          (docId != null && profile.isPostLiked(docId)) ||
          (refId != null && profile.isPostLiked(refId)) ||
          r.isLiked;

      final bool saved = PostInteractionRegistry.isSaved(r.id) ||
          (docId != null && PostInteractionRegistry.isSaved(docId)) ||
          (refId != null && PostInteractionRegistry.isSaved(refId)) ||
          homeFeed.isPostSaved(r.id) ||
          (docId != null && homeFeed.isPostSaved(docId)) ||
          (refId != null && homeFeed.isPostSaved(refId)) ||
          profile.isPostSaved(r.id) ||
          (docId != null && profile.isPostSaved(docId)) ||
          (refId != null && profile.isPostSaved(refId)) ||
          r.isSaved;

      final int likes = PostInteractionRegistry.getLikeCount(r.id, fallback: r.likesCount);
      final int comments = CommentCountRegistry.getOr(r.id, r.commentsCount);
      return r.copyWith(
        isLiked: liked,
        isSaved: saved,
        likesCount: likes,
        commentsCount: comments,
      );
    }).toList();
    if (searchReels.isEmpty) return;

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => Scaffold(
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
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(routeContext).pop(),
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
    final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
    final ProfileProvider profile = context.read<ProfileProvider>();
    final String img = (item.imageAsset.isNotEmpty ? item.imageAsset : (item.thumbnailUrl ?? '')).trim();
    final bool isHttp = img.startsWith('http://') || img.startsWith('https://');
    final bool isAsset = img.startsWith('assets/');
    final bool isText = item.type == 'TEXT' || (img.isEmpty && item.mediaRefs.isEmpty);
    final String? docId = item.id?.trim();
    final String? refId = item.refId?.trim();
    final String postId = (refId != null && refId.isNotEmpty)
        ? refId
        : (docId ?? 'search_${item.caption.hashCode}');

    final bool isLiked = PostInteractionRegistry.isLiked(postId) ||
        (docId != null && PostInteractionRegistry.isLiked(docId)) ||
        (refId != null && PostInteractionRegistry.isLiked(refId)) ||
        homeFeed.isPostLiked(postId) ||
        (docId != null && homeFeed.isPostLiked(docId)) ||
        (refId != null && homeFeed.isPostLiked(refId)) ||
        profile.isPostLiked(postId) ||
        (docId != null && profile.isPostLiked(docId)) ||
        (refId != null && profile.isPostLiked(refId)) ||
        item.isLiked;

    final bool isSaved = PostInteractionRegistry.isSaved(postId) ||
        (docId != null && PostInteractionRegistry.isSaved(docId)) ||
        (refId != null && PostInteractionRegistry.isSaved(refId)) ||
        homeFeed.isPostSaved(postId) ||
        (docId != null && homeFeed.isPostSaved(docId)) ||
        (refId != null && homeFeed.isPostSaved(refId)) ||
        profile.isPostSaved(postId) ||
        (docId != null && profile.isPostSaved(docId)) ||
        (refId != null && profile.isPostSaved(refId)) ||
        item.isSaved;

    final int likesCount = PostInteractionRegistry.getLikeCount(postId, fallback: item.likesCount ?? 0);
    final int commentsCount = CommentCountRegistry.getOr(postId, item.commentsCount ?? 0);

    final PostItemModel post = PostItemModel(
      id: postId,
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
      likesCount: likesCount,
      commentsCount: commentsCount,
      viewsCount: item.viewsCount,
      postImageUrl: (!isText && isHttp) ? img : null,
      postImageAsset: (!isText && isAsset) ? img : null,
      postType: isText ? 'TEXT' : (item.type ?? 'PHOTO'),
      communityId: item.communityId,
      isLiked: isLiked,
      isSaved: isSaved,
      allowComments: item.allowComments,
      allowDownloads: item.allowDownloads,
      allowCommentsFrom: item.allowCommentsFrom,
      isAuthorPrivate: item.isAuthorPrivate,
      status: item.status,
    );

    PostFeedCard.openFullscreen(context, post);
  }

  void _handleTap(BuildContext context, int index) {
    final List<DiscoverSearchResult> activeResults = _filterAndDeduplicate(results);
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
    final List<DiscoverSearchResult> activeResults = _filterAndDeduplicate(results);

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
        // Wrap in ListenableBuilder so count updates reactively when liked/unliked
        return ListenableBuilder(
          listenable: PostInteractionRegistry.notifier,
          builder: (BuildContext ctx, _) {
            final String postId = (item.refId != null && item.refId!.trim().isNotEmpty)
                ? item.refId!.trim()
                : (item.id ?? '');
            final int views = PostInteractionRegistry.getViewsCount(
              postId,
              fallback: item.viewsCount > 0
                  ? item.viewsCount
                  : (int.tryParse(item.viewCount ?? '') ?? 0),
            );
            final String countText = views > 0
                ? (views >= 1000000
                    ? '${(views / 1000000).toStringAsFixed(1)}M'
                    : (views >= 1000
                        ? '${(views / 1000).toStringAsFixed(1)}K'
                        : '$views'))
                : (item.viewCount != null && item.viewCount!.isNotEmpty && item.viewCount != '0'
                    ? item.viewCount!
                    : '0');

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

                // Views count & view/play icon
                Positioned(
                  left: 6,
                  bottom: 6,
                  right: 6,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        isReel ? Icons.play_arrow_rounded : Icons.visibility_outlined,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 14,
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          countText,
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
          }, // end ListenableBuilder builder
        ); // end ListenableBuilder
      },
    );
  }

  Widget _buildThumbnail(DiscoverSearchResult item) {
    String url = (item.thumbnailUrl != null && item.thumbnailUrl!.trim().isNotEmpty)
        ? item.thumbnailUrl!.trim()
        : item.imageAsset.trim();

    if (url.contains('/videos/processed/') && url.endsWith('/thumbnail.jpg')) {
      url = url.replaceAll('/thumbnail.jpg', '/thumb.0000000.jpg');
    } else if (url.contains('/videos/processed/') && url.endsWith('/master.m3u8')) {
      url = url.replaceAll('/master.m3u8', '/thumb.0000000.jpg');
    } else if (item.isReel &&
        item.videoUrl != null &&
        item.videoUrl!.contains('/videos/processed/') &&
        (url.isEmpty || url.endsWith('.mp4') || url.endsWith('.m3u8'))) {
      url = item.videoUrl!.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg');
    }

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

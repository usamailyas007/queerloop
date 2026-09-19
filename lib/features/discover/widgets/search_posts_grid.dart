import 'package:flutter/material.dart';

import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/models/reel_item_model.dart';
import '../../home/screens/reels_feed_view.dart';
import '../models/discover_models.dart';

/// 3-column grid of search result reel cards with dynamic image/video thumbnails and playback.
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

      final String img = res.imageAsset.trim();
      final bool isVideoUrl = img.startsWith('http') &&
          (img.endsWith('.mp4') || img.endsWith('.m3u8') || img.contains('video'));

      return ReelItemModel(
        id: res.id ?? 'search_reel_$i',
        authorId: res.authorId,
        username: res.authorUsername ?? '@creator',
        pronounsTime: 'they/them · recent',
        avatarAsset: (res.authorAvatar != null && res.authorAvatar!.isNotEmpty)
            ? res.authorAvatar!
            : AppImages.user1,
        videoAsset: (!img.startsWith('http') && img.endsWith('.mp4')) ? img : '',
        videoUrl: isVideoUrl ? img : (img.startsWith('http') ? img : null),
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
        final String countText = item.viewCount ??
            (item.likesCount != null ? '${item.likesCount}' : '');

        return GestureDetector(
          onTap: () => _openReelPlayer(context, index),
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
                      stops: const <double>[0.0, 0.6, 1.0],
                    ),
                  ),
                ),

                // Views count & play icon
                Positioned(
                  left: 6,
                  bottom: 6,
                  right: 6,
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          countText.isNotEmpty ? countText : 'Watch',
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
    final String img = item.imageAsset.trim();
    if (img.startsWith('http://') || img.startsWith('https://')) {
      return Image.network(
        img,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackContainer(),
      );
    } else if (img.isNotEmpty) {
      return Image.asset(
        img,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _fallbackContainer(),
      );
    }
    return _fallbackContainer();
  }

  Widget _fallbackContainer() {
    return Container(
      color: const Color(0xFF1E1B26),
      child: const Center(
        child: Icon(
          Icons.videocam_rounded,
          color: Colors.white24,
          size: 28,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/models/reel_item_model.dart';
import '../../home/screens/reels_feed_view.dart';
import '../models/discover_models.dart';

/// 3-column grid of search result reel cards with rounded corners and instant video playback.
class SearchPostsGrid extends StatelessWidget {
  const SearchPostsGrid({
    this.results = const <DiscoverSearchResult>[],
    super.key,
  });

  final List<DiscoverSearchResult> results;

  static const List<String> _videoAssets = <String>[
    'assets/videos/video1.mp4',
    'assets/videos/video2.mp4',
    'assets/videos/video3.mp4',
    'assets/videos/video2.mp4',
    'assets/videos/video3.mp4',
    'assets/videos/video1.mp4',
  ];

  static const List<String> _viewCounts = <String>[
    '12.4K',
    '8.9K',
    '4.2K',
    '19.1K',
    '6.7K',
    '22.5K',
  ];

  List<ReelItemModel> _buildSearchReels() {
    final List<String> captions = <String>[
      'Six months post-op. Read the caption before you comment 🤍 #transjoy #recovery',
      'Quick binder fit check! Finding community in unexpected places ✨ #lgbtq',
      'Late night thoughts about chosen family & pride 🏳️‍⚧️ #chosenfamily #pride',
      'Outfit check for the weekend rally! 💫 #queerfashion #transjoy',
      'Throwback to last month with the best people ❤️ #chosenfamily',
      'Daily reminder that you are valid and loved 🏳️‍🌈 #support #lgbtq',
    ];

    final int count = results.isNotEmpty ? results.length : _videoAssets.length;

    return List<ReelItemModel>.generate(count, (int i) {
      final String video = _videoAssets[i % _videoAssets.length];
      final String caption = captions[i % captions.length];

      return ReelItemModel(
        id: 'search_reel_$i',
        username: '@queer_creator',
        pronounsTime: 'they/them · 2h',
        avatarAsset: AppImages.user1,
        videoAsset: video,
        caption: caption,
        likesCount: 1500 + (i * 420),
        commentsCount: 65 + (i * 15),
        tags: const <String>['#transjoy', '#chosenfamily', '#queer'],
      );
    });
  }

  void _openReelPlayer(BuildContext context, int initialIndex) {
    final List<ReelItemModel> searchReels = _buildSearchReels();

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
    final int itemCount = results.isNotEmpty ? results.length : _videoAssets.length;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.72,
      ),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        final String videoPath = _videoAssets[index % _videoAssets.length];
        final String countText = _viewCounts[index % _viewCounts.length];

        return GestureDetector(
          onTap: () => _openReelPlayer(context, index),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                _SearchVideoThumbnailWidget(
                  key: ValueKey<String>('search_vid_${index}_$videoPath'),
                  videoAsset: videoPath,
                ),

                // Dark gradient bottom overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),

                // Bottom play icon and view count badge
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        countText,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
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
}

class _SearchVideoThumbnailWidget extends StatefulWidget {
  const _SearchVideoThumbnailWidget({
    required this.videoAsset,
    super.key,
  });

  final String videoAsset;

  @override
  State<_SearchVideoThumbnailWidget> createState() =>
      _SearchVideoThumbnailWidgetState();
}

class _SearchVideoThumbnailWidgetState
    extends State<_SearchVideoThumbnailWidget> {
  VideoPlayerController? _controller;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.videoAsset);
    _controller!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initialized && _controller != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _controller!.value.size.width,
            height: _controller!.value.size.height,
            child: VideoPlayer(_controller!),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF1E1B26),
      child: const Center(
        child: Icon(
          Icons.videocam_rounded,
          color: Colors.white24,
          size: 26,
        ),
      ),
    );
  }
}

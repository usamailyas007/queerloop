import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../home/models/reel_item_model.dart';
import '../../home/screens/reels_feed_view.dart';

class ProfileMediaGridWidget extends StatelessWidget {
  const ProfileMediaGridWidget({
    this.videos = const <String>[
      'assets/videos/video1.mp4',
      'assets/videos/video2.mp4',
      'assets/videos/video3.mp4',
      'assets/videos/video2.mp4',
      'assets/videos/video3.mp4',
      'assets/videos/video1.mp4',
    ],
    this.customReels,
    this.showPlayCounts = true,
    this.emptyTitle,
    this.emptySubtitle,
    this.emptyIcon,
    super.key,
  });

  final List<String> videos;
  final List<ReelItemModel>? customReels;
  final bool showPlayCounts;
  final String? emptyTitle;
  final String? emptySubtitle;
  final IconData? emptyIcon;

  List<ReelItemModel> _buildProfileReels() {
    final List<String> captions = <String>[
      'Six months post-op. Read the caption before you comment 🤍 #transjoy #recovery',
      'Quick binder fit check! Finding community in unexpected places ✨ #lgbtq',
      'Late night thoughts about chosen family & pride 🏳️‍⚧️ #chosenfamily #pride',
      'Outfit check for the weekend rally! 💫 #queerfashion #transjoy',
      'Throwback to last month with the best people ❤️ #chosenfamily',
      'Daily reminder that you are valid and loved 🏳️‍🌈 #support #lgbtq',
    ];

    return List<ReelItemModel>.generate(videos.length, (int i) {
      final String video = videos[i % videos.length];
      final String caption = captions[i % captions.length];

      return ReelItemModel(
        id: 'profile_reel_$i',
        username: '@ashinorbit',
        pronounsTime: 'she/they · just now',
        avatarAsset: AppImages.user1,
        videoAsset: video,
        caption: caption,
        likesCount: 1200 + (i * 350),
        commentsCount: 48 + (i * 12),
        tags: const <String>['#transjoy', '#chosenfamily', '#queer'],
      );
    });
  }

  void _openReelPlayer(
      BuildContext context, int initialIndex, List<ReelItemModel> reelsList) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: <Widget>[
              // Fullscreen interactive video reel player
              ReelsFeedView(
                initialPage: initialIndex,
                customReels: reelsList,
                hasBottomBar: false,
              ),

              // Top back button
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
                        border: Border.all(
                          color: Colors.white24,
                        ),
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

  static String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    if (customReels != null) {
      final List<ReelItemModel> reelList = customReels!;

      if (reelList.isEmpty) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                emptyIcon ?? Icons.video_collection_outlined,
                size: 44,
                color: Colors.white30,
              ),
              const SizedBox(height: 12),
              Text(
                emptyTitle ?? 'No reels yet',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle ?? 'Videos you create will be showcased here.',
                textAlign: TextAlign.center,
                style: AppTextStyles.caption.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        );
      }

      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: reelList.length,
        itemBuilder: (BuildContext context, int index) {
          final ReelItemModel item = reelList[index];

          return GestureDetector(
            onTap: () => _openReelPlayer(context, index, reelList),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (item.thumbnailUrl != null &&
                      item.thumbnailUrl!.isNotEmpty)
                    Image.network(
                      item.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFF1E1B26),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_outline_rounded,
                            color: Colors.white38,
                            size: 32,
                          ),
                        ),
                      ),
                    )
                  else if (item.videoAsset.isNotEmpty)
                    _VideoAssetThumbnailWidget(
                      key: ValueKey<String>(
                          'thumb_${index}_${item.videoAsset}'),
                      videoAsset: item.videoAsset,
                    )
                  else
                    Container(
                      color: const Color(0xFF1E1B26),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_outline_rounded,
                          color: Colors.white38,
                          size: 32,
                        ),
                      ),
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
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),

                  if (showPlayCounts)
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _formatCount(item.likesCount > 0 ? item.likesCount : 0),
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

    final List<ReelItemModel> defaultReels = _buildProfileReels();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: videos.length,
      itemBuilder: (BuildContext context, int index) {
        final String videoPath = videos[index % videos.length];

        return GestureDetector(
          onTap: () => _openReelPlayer(context, index, defaultReels),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                // Real Video Frame Thumbnail
                _VideoAssetThumbnailWidget(
                  key: ValueKey<String>('thumb_${index}_$videoPath'),
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
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),

                if (showPlayCounts)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          index == 0
                              ? '12.4K'
                              : (index == 1 ? '8.9K' : '4.2K'),
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

class _VideoAssetThumbnailWidget extends StatefulWidget {
  const _VideoAssetThumbnailWidget({
    required this.videoAsset,
    super.key,
  });

  final String videoAsset;

  @override
  State<_VideoAssetThumbnailWidget> createState() =>
      _VideoAssetThumbnailWidgetState();
}

class _VideoAssetThumbnailWidgetState
    extends State<_VideoAssetThumbnailWidget> {
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
          size: 28,
        ),
      ),
    );
  }
}

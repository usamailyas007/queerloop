import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../models/create_post_models.dart';
import '../provider/create_post_provider.dart';
import '../widgets/media_thumbnail_widget.dart';
import 'trim_video_screen.dart';

class SelectVideoScreen extends StatefulWidget {
  const SelectVideoScreen({super.key});

  @override
  State<SelectVideoScreen> createState() => _SelectVideoScreenState();
}

class _SelectVideoScreenState extends State<SelectVideoScreen> {
  VideoPlayerController? _controller;
  String? _currentMediaId;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final CreatePostProvider provider = context.read<CreatePostProvider>();
      _setupVideoController(provider.selectedMedia);
      provider.loadDeviceVideos().then((_) {
        if (mounted && provider.selectedMedia != null) {
          _setupVideoController(provider.selectedMedia);
        }
      });
    });
  }

  Future<void> _setupVideoController(GalleryMediaItem? item) async {
    if (item == null) return;
    if (_currentMediaId == item.id && _controller != null && _isInitialized) return;

    _currentMediaId = item.id;

    final String? filePath = item.filePath;
    final String? videoAsset = item.videoAsset;

    VideoPlayerController newCtrl;
    if (filePath != null && filePath.isNotEmpty) {
      newCtrl = VideoPlayerController.file(File(filePath));
    } else if (videoAsset != null && videoAsset.isNotEmpty) {
      if (videoAsset.startsWith('assets/')) {
        newCtrl = VideoPlayerController.asset(videoAsset);
      } else {
        newCtrl = VideoPlayerController.file(File(videoAsset));
      }
    } else {
      return;
    }

    try {
      await newCtrl.initialize();
      newCtrl.setLooping(true);

      final VideoPlayerController? oldCtrl = _controller;
      if (mounted) {
        setState(() {
          _controller = newCtrl;
          _isInitialized = true;
          _isPlaying = true;
        });
        newCtrl.play();
      } else {
        await newCtrl.dispose();
      }
      await oldCtrl?.dispose();
    } catch (e) {
      debugPrint('Error initializing real device video: $e');
    }
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _controller!.pause();
        _isPlaying = false;
      } else {
        _controller!.play();
        _isPlaying = true;
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final CreatePostProvider provider = context.watch<CreatePostProvider>();
    final GalleryMediaItem? selectedItem = provider.selectedMedia;

    if (selectedItem != null && selectedItem.id != _currentMediaId) {
      _currentMediaId = selectedItem.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _setupVideoController(selectedItem);
        }
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Navigation Bar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  // Circular Back Button <
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // Title
                  Text(
                    'New Video',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  // Next Button
                  AppGradientButton(
                    text: 'Next',
                    isEnabled: selectedItem != null,
                    onPressed: () {
                      _controller?.pause();
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const TrimVideoScreen(),
                        ),
                      ).then((_) {
                        if (mounted && _isPlaying) {
                          _controller?.play();
                        }
                      });
                    },
                    height: 32,
                    width: 70,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xs),

            // ── Main Video Preview Card (Instantly Plays Selected Video) ──
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Container(
                    color: const Color(0xFF1E1B26),
                    child: GestureDetector(
                      onTap: _togglePlayPause,
                      child: Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          // Real Video Player or Thumbnail
                          if (_isInitialized && _controller != null)
                            SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width: _controller!.value.size.width,
                                  height: _controller!.value.size.height,
                                  child: VideoPlayer(_controller!),
                                ),
                              ),
                            )
                          else if (selectedItem != null)
                            MediaThumbnailWidget(item: selectedItem)
                          else
                            const Center(
                              child: Text(
                                'Select a video from your gallery below',
                                style: TextStyle(color: Colors.white54),
                              ),
                            ),

                          // Dark gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Colors.black.withValues(alpha: 0.3),
                                  Colors.transparent,
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),

                          // Center play/pause button overlay
                          if (_isInitialized && !_isPlaying)
                            Center(
                              child: Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 36,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Gallery Header Row ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Recents',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                        size: 20,
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      if (provider.videoGallery.isNotEmpty)
                        Text(
                          '${provider.videoGallery.length} selected',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () async {
                          await provider.pickMediaFromDevice(true);
                          if (mounted && provider.selectedMedia != null) {
                            _setupVideoController(provider.selectedMedia);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_rounded,
                            color: AppColors.gradientCyan,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Real Video Gallery Thumbnails Grid ───────────────────────
            Expanded(
              flex: 4,
              child: provider.isLoadingDeviceVideos && provider.videoGallery.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.gradientPink,
                        ),
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: provider.videoGallery.length,
                      itemBuilder: (BuildContext context, int index) {
                        final GalleryMediaItem item =
                            provider.videoGallery[index];
                        final bool isSelected =
                            selectedItem?.id == item.id;

                        return GestureDetector(
                          onTap: () {
                            provider.selectMedia(item);
                            _setupVideoController(item);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            decoration: BoxDecoration(
                              borderRadius:
                                  BorderRadius.circular(AppRadius.card),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.gradientPink
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppRadius.card - 2,
                              ),
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  // Real thumbnail from device
                                  MediaThumbnailWidget(item: item),

                                  // Play icon top-left
                                  Positioned(
                                    top: 4,
                                    left: 4,
                                    child: SvgPicture.asset(
                                      AppIcons.play,
                                      width: 12,
                                      height: 12,
                                      colorFilter: const ColorFilter.mode(
                                        Colors.white,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),

                                  // Real duration badge bottom-right
                                  if (item.duration.isNotEmpty)
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 4,
                                          vertical: 1,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.65),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          item.duration,
                                          style: AppTextStyles.caption
                                              .copyWith(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

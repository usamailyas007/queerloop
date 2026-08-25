import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import '../models/create_post_models.dart';

/// Helper widget to safely render media previews.
class MediaThumbnailWidget extends StatelessWidget {
  const MediaThumbnailWidget({
    required this.item,
    super.key,
    this.fit = BoxFit.cover,
  });

  final GalleryMediaItem? item;
  final BoxFit fit;

  static bool isImageFilePath(String? path) {
    if (path == null || path.isEmpty) return false;
    final String lower = path.toLowerCase();
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.bmp');
  }

  @override
  Widget build(BuildContext context) {
    if (item == null) {
      return _fallbackPlaceholder();
    }

    // 1. Direct memory thumbnail bytes from device gallery
    final Uint8List? bytes = item!.thumbnailBytes;
    if (bytes != null && bytes.isNotEmpty) {
      return Image.memory(
        bytes,
        fit: fit,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => _fallbackPlaceholder(),
      );
    }

    // 2. If AssetEntity is present without preloaded bytes, load async
    if (item!.assetEntity != null) {
      return FutureBuilder<Uint8List?>(
        future: item!.assetEntity!.thumbnailDataWithSize(
          const ThumbnailSize.square(250),
          format: ThumbnailFormat.jpeg,
          quality: 85,
        ),
        builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
          if (snapshot.hasData &&
              snapshot.data != null &&
              snapshot.data!.isNotEmpty) {
            return Image.memory(
              snapshot.data!,
              fit: fit,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) =>
                  _fallbackPlaceholder(),
            );
          }
          return _fallbackPlaceholder();
        },
      );
    }

    // 3. Local device image file (not video)
    final String? filePath = item!.filePath;
    if (filePath != null && isImageFilePath(filePath)) {
      final File file = File(filePath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: fit,
          errorBuilder:
              (BuildContext context, Object error, StackTrace? stackTrace) {
            if (item!.assetPath.isNotEmpty) {
              return Image.asset(item!.assetPath, fit: fit);
            }
            return _fallbackPlaceholder();
          },
        );
      }
    }

    // 4. Video file without preloaded bytes -> render first frame of video
    if (item!.isVideo && filePath != null && filePath.isNotEmpty) {
      return _VideoFileThumbnail(filePath: filePath, fit: fit);
    }

    // 5. Asset path fallback if provided
    if (item!.assetPath.isNotEmpty) {
      return Image.asset(
        item!.assetPath,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallbackPlaceholder(),
      );
    }

    return _fallbackPlaceholder();
  }

  Widget _fallbackPlaceholder() {
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

class _VideoFileThumbnail extends StatefulWidget {
  const _VideoFileThumbnail({required this.filePath, required this.fit});

  final String filePath;
  final BoxFit fit;

  @override
  State<_VideoFileThumbnail> createState() => _VideoFileThumbnailState();
}

class _VideoFileThumbnailState extends State<_VideoFileThumbnail> {
  VideoPlayerController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initThumbnail();
  }

  Future<void> _initThumbnail() async {
    try {
      final VideoPlayerController ctrl =
          VideoPlayerController.file(File(widget.filePath));
      await ctrl.initialize();
      if (mounted) {
        setState(() {
          _controller = ctrl;
          _ready = true;
        });
      } else {
        await ctrl.dispose();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready && _controller != null) {
      return SizedBox.expand(
        child: FittedBox(
          fit: widget.fit,
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

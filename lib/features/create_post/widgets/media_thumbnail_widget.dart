import 'dart:io';

import 'package:flutter/material.dart';

import '../models/create_post_models.dart';

/// Helper widget to safely render media previews.
/// Automatically handles device files (.jpg/.png) vs video (.mp4) vs asset images safely.
class MediaThumbnailWidget extends StatelessWidget {
  const MediaThumbnailWidget({
    required this.item,
    super.key,
    this.fit = BoxFit.cover,
  });

  final GalleryMediaItem? item;
  final BoxFit fit;

  static bool isImageFilePath(String? path) {
    if (path == null) return false;
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
      return const SizedBox.shrink();
    }

    final String? filePath = item!.filePath;
    if (filePath != null && isImageFilePath(filePath)) {
      return Image.file(
        File(filePath),
        fit: fit,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          return Image.asset(item!.assetPath, fit: fit);
        },
      );
    }

    return Image.asset(item!.assetPath, fit: fit);
  }
}

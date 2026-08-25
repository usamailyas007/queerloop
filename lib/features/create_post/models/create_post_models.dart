import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

enum MediaType { video, photo, text }

enum PostVisibility { everyone, followers, communityOnly }

class GalleryMediaItem {
  const GalleryMediaItem({
    required this.id,
    this.assetPath = '',
    this.videoAsset,
    this.isVideo = false,
    this.duration = '',
    this.durationSeconds = 0,
    this.filePath,
    this.thumbnailBytes,
    this.assetEntity,
  });

  final String id;
  final String assetPath;
  final String? videoAsset;
  final bool isVideo;
  final String duration;
  final int durationSeconds;
  final String? filePath;
  final Uint8List? thumbnailBytes;
  final AssetEntity? assetEntity;
}

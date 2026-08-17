enum MediaType { video, photo, text }

enum PostVisibility { everyone, followers, communityOnly }

class GalleryMediaItem {
  const GalleryMediaItem({
    required this.id,
    required this.assetPath,
    this.isVideo = false,
    this.duration = '',
    this.durationSeconds = 0,
    this.filePath,
  });

  final String id;
  final String assetPath;
  final bool isVideo;
  final String duration;
  final int durationSeconds;
  final String? filePath;
}

class ReelItemModel {
  const ReelItemModel({
    required this.id,
    this.authorId,
    this.authorDisplayName,
    required this.username,
    required this.pronounsTime,
    required this.avatarAsset,
    this.videoAsset = '',
    this.videoFilePath,
    this.videoUrl,
    this.thumbnailUrl,
    required this.caption,
    required this.likesCount,
    required this.commentsCount,
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowing = false,
    this.tags = const <String>[],
    this.durationText = '',
    this.communityId,
    this.allowDownloads = true,
  });

  final String id;
  final String? authorId;
  final String? authorDisplayName;
  final String username;
  final String pronounsTime;
  final String avatarAsset;
  final String videoAsset;
  final String? videoFilePath;
  final String? videoUrl;
  final String? thumbnailUrl;
  final String caption;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowing;
  final List<String> tags;
  final String durationText;
  final String? communityId;
  final bool allowDownloads;

  ReelItemModel copyWith({
    String? authorId,
    String? authorDisplayName,
    String? username,
    String? pronounsTime,
    String? avatarAsset,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowing,
    bool? allowDownloads,
    int? likesCount,
    int? commentsCount,
    String? videoUrl,
    String? thumbnailUrl,
    String? caption,
    List<String>? tags,
    String? durationText,
    String? communityId,
  }) {
    return ReelItemModel(
      id: id,
      authorId: authorId ?? this.authorId,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      username: username ?? this.username,
      pronounsTime: pronounsTime ?? this.pronounsTime,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      videoAsset: videoAsset,
      videoFilePath: videoFilePath,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowing: isFollowing ?? this.isFollowing,
      tags: tags ?? this.tags,
      durationText: durationText ?? this.durationText,
      communityId: communityId ?? this.communityId,
      allowDownloads: allowDownloads ?? this.allowDownloads,
    );
  }
}

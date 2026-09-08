class ReelItemModel {
  const ReelItemModel({
    required this.id,
    this.authorId,
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
  });

  final String id;
  final String? authorId;
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

  ReelItemModel copyWith({
    String? authorId,
    bool? isLiked,
    bool? isSaved,
    bool? isFollowing,
    int? likesCount,
    int? commentsCount,
    String? videoUrl,
    String? thumbnailUrl,
  }) {
    return ReelItemModel(
      id: id,
      authorId: authorId ?? this.authorId,
      username: username,
      pronounsTime: pronounsTime,
      avatarAsset: avatarAsset,
      videoAsset: videoAsset,
      videoFilePath: videoFilePath,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      caption: caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowing: isFollowing ?? this.isFollowing,
      tags: tags,
      durationText: durationText,
    );
  }
}

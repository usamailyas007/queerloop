class ReelItemModel {
  const ReelItemModel({
    required this.id,
    required this.username,
    required this.pronounsTime,
    required this.avatarAsset,
    required this.mediaAsset,
    required this.caption,
    required this.soundTitle,
    required this.likesCount,
    required this.commentsCount,
    this.isLiked = false,
    this.isSaved = false,
    this.isFollowing = false,
    this.tags = const <String>[],
    this.durationText = '0:18 / 0:47',
  });

  final String id;
  final String username;
  final String pronounsTime;
  final String avatarAsset;
  final String mediaAsset;
  final String caption;
  final String soundTitle;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;
  final bool isFollowing;
  final List<String> tags;
  final String durationText;

  ReelItemModel copyWith({
    bool? isLiked,
    bool? isSaved,
    bool? isFollowing,
    int? likesCount,
  }) {
    return ReelItemModel(
      id: id,
      username: username,
      pronounsTime: pronounsTime,
      avatarAsset: avatarAsset,
      mediaAsset: mediaAsset,
      caption: caption,
      soundTitle: soundTitle,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isFollowing: isFollowing ?? this.isFollowing,
      tags: tags,
      durationText: durationText,
    );
  }
}

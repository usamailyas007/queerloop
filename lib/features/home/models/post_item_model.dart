class PostItemModel {
  const PostItemModel({
    required this.id,
    required this.username,
    required this.pronounsTime,
    required this.avatarAsset,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    this.postImageAsset,
    this.isLiked = false,
    this.isSaved = false,
  });

  final String id;
  final String username;
  final String pronounsTime;
  final String avatarAsset;
  final String content;
  final int likesCount;
  final int commentsCount;
  final String? postImageAsset;
  final bool isLiked;
  final bool isSaved;

  PostItemModel copyWith({
    bool? isLiked,
    bool? isSaved,
    int? likesCount,
  }) {
    return PostItemModel(
      id: id,
      username: username,
      pronounsTime: pronounsTime,
      avatarAsset: avatarAsset,
      content: content,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      postImageAsset: postImageAsset,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

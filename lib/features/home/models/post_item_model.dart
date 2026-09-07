class PostItemModel {
  const PostItemModel({
    required this.id,
    this.authorId,
    required this.username,
    required this.pronounsTime,
    required this.avatarAsset,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    this.postImageAsset,
    this.postImageUrl,
    this.postType = 'TEXT',
    this.isLiked = false,
    this.isSaved = false,
  });

  final String id;
  final String? authorId;
  final String username;
  final String pronounsTime;
  final String avatarAsset;
  final String content;
  final int likesCount;
  final int commentsCount;
  final String? postImageAsset;
  final String? postImageUrl;
  final String postType;
  final bool isLiked;
  final bool isSaved;

  PostItemModel copyWith({
    String? authorId,
    bool? isLiked,
    bool? isSaved,
    int? likesCount,
    int? commentsCount,
    String? postImageUrl,
    String? postType,
  }) {
    return PostItemModel(
      id: id,
      authorId: authorId ?? this.authorId,
      username: username,
      pronounsTime: pronounsTime,
      avatarAsset: avatarAsset,
      content: content,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      postImageAsset: postImageAsset,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      postType: postType ?? this.postType,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

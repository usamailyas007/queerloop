class PostItemModel {
  const PostItemModel({
    required this.id,
    this.authorId,
    this.authorDisplayName,
    required this.username,
    required this.pronounsTime,
    required this.avatarAsset,
    required this.content,
    required this.likesCount,
    required this.commentsCount,
    this.postImageAsset,
    this.postImageUrl,
    this.postType = 'TEXT',
    this.communityId,
    this.isLiked = false,
    this.isSaved = false,
    this.allowComments = true,
    this.allowDownloads = true,
    this.hideLikes = false,
    this.viewsCount = 0,
    this.visibility,
  });

  final String id;
  final String? authorId;
  final String? authorDisplayName;
  final String username;
  final String pronounsTime;
  final String avatarAsset;
  final String content;
  final int likesCount;
  final int commentsCount;
  final String? postImageAsset;
  final String? postImageUrl;
  final String postType;
  final String? communityId;
  final bool isLiked;
  final bool isSaved;
  final bool allowComments;
  final bool allowDownloads;
  final bool hideLikes;
  final int viewsCount;
  final String? visibility;

  String? get videoUrl => (postType.toUpperCase() == 'VIDEO' ||
          postType.toLowerCase() == 'reel' ||
          (postImageUrl != null &&
              (postImageUrl!.endsWith('.mp4') ||
                  postImageUrl!.endsWith('.m3u8') ||
                  postImageUrl!.contains('video') ||
                  postImageUrl!.contains('/videos/'))))
      ? postImageUrl
      : null;

  PostItemModel copyWith({
    String? authorId,
    String? authorDisplayName,
    String? username,
    String? pronounsTime,
    String? avatarAsset,
    String? content,
    bool? isLiked,
    bool? isSaved,
    bool? allowComments,
    bool? allowDownloads,
    bool? hideLikes,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    String? postImageAsset,
    String? postImageUrl,
    String? postType,
    String? communityId,
    String? visibility,
  }) {
    return PostItemModel(
      id: id,
      authorId: authorId ?? this.authorId,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      username: username ?? this.username,
      pronounsTime: pronounsTime ?? this.pronounsTime,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      content: content ?? this.content,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      postImageAsset: postImageAsset ?? this.postImageAsset,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      postType: postType ?? this.postType,
      communityId: communityId ?? this.communityId,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      allowComments: allowComments ?? this.allowComments,
      allowDownloads: allowDownloads ?? this.allowDownloads,
      hideLikes: hideLikes ?? this.hideLikes,
      visibility: visibility ?? this.visibility,
    );
  }
}

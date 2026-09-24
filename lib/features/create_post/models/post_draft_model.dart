import 'create_post_models.dart';

class PostDraft {
  const PostDraft({
    required this.id,
    required this.mediaType,
    required this.caption,
    required this.createdAt,
    this.mediaPath,
    this.thumbnailPath,
    this.communityId,
    this.communityName,
    this.allowComments = true,
    this.allowSharing = true,
    this.isAgeRestricted = false,
    this.taggedUsers = const <String>[],
    this.mediaUrl,
    this.uploadedMediaId,
    this.thumbnailUrl,
  });

  final String id;
  final MediaType mediaType;
  final String caption;
  final DateTime createdAt;
  final String? mediaPath;
  final String? thumbnailPath;
  final String? communityId;
  final String? communityName;
  final bool allowComments;
  final bool allowSharing;
  final bool isAgeRestricted;
  final List<String> taggedUsers;
  final String? mediaUrl;
  final String? uploadedMediaId;
  final String? thumbnailUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'mediaType': mediaType.name,
        'caption': caption,
        'createdAt': createdAt.toIso8601String(),
        'mediaPath': mediaPath,
        'thumbnailPath': thumbnailPath,
        'communityId': communityId,
        'communityName': communityName,
        'allowComments': allowComments,
        'allowSharing': allowSharing,
        'isAgeRestricted': isAgeRestricted,
        'taggedUsers': taggedUsers,
        'mediaUrl': mediaUrl,
        'uploadedMediaId': uploadedMediaId,
        'thumbnailUrl': thumbnailUrl,
      };

  factory PostDraft.fromJson(Map<String, dynamic> json) {
    return PostDraft(
      id: (json['id'] ?? '').toString(),
      mediaType: MediaType.values.firstWhere(
        (MediaType e) => e.name == json['mediaType'],
        orElse: () => MediaType.video,
      ),
      caption: (json['caption'] as String?) ?? '',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      mediaPath: json['mediaPath'] as String?,
      thumbnailPath: json['thumbnailPath'] as String?,
      communityId: json['communityId'] as String?,
      communityName: json['communityName'] as String?,
      allowComments: (json['allowComments'] as bool?) ?? true,
      allowSharing: (json['allowSharing'] as bool?) ?? true,
      isAgeRestricted: (json['isAgeRestricted'] as bool?) ?? false,
      taggedUsers: (json['taggedUsers'] as List<dynamic>?)
              ?.map((dynamic e) => e.toString())
              .toList() ??
          const <String>[],
      mediaUrl: (json['mediaUrl'] ?? json['downloadUrl']) as String?,
      uploadedMediaId: (json['uploadedMediaId'] ?? json['mediaId']) as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }
}

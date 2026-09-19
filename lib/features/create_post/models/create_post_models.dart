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

enum MediaUploadStatus {
  idle,
  requestingUrl,
  uploading,
  completing,
  transcoding,
  ready,
  failed,
}

class MediaUploadResult {
  const MediaUploadResult({
    required this.id,
    this.uploadUrl,
    this.status = 'pending',
    this.downloadUrl,
    this.thumbnailUrl,
    this.key,
  });

  final String id;
  final String? uploadUrl;
  final String status;
  final String? downloadUrl;
  final String? thumbnailUrl;
  final String? key;

  String? get url => downloadUrl;

  bool get isReady => status.toLowerCase() == 'ready';

  factory MediaUploadResult.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map =
        (json['data'] is Map<String, dynamic>) ? json['data'] as Map<String, dynamic> : json;

    final String extractedId = _extractId(map);

    return MediaUploadResult(
      id: extractedId,
      uploadUrl: (map['uploadUrl'] ?? map['upload_url'] ?? map['signedUrl']) as String?,
      status: (map['status'] ?? 'pending').toString(),
      downloadUrl: (map['url'] ?? map['downloadUrl'] ?? map['download_url']) as String?,
      thumbnailUrl: (map['thumbnailUrl'] ?? map['thumbnail_url']) as String?,
      key: (map['key'] ?? map['s3Key'] ?? map['s3_key'] ?? map['objectKey']) as String?,
    );
  }

  static String _extractId(Map<String, dynamic> map) {
    // 1. Direct standard ID keys (case-insensitive)
    for (final MapEntry<String, dynamic> entry in map.entries) {
      final String k = entry.key.toLowerCase().replaceAll('_', '').replaceAll('-', '');
      if (k == 'id' ||
          k == 'mediaid' ||
          k == 'fileid' ||
          k == 'assetid' ||
          k == 'uploadid' ||
          k == 'uuid' ||
          k == 'videoid' ||
          k == 'imageid') {
        if (entry.value != null && entry.value.toString().trim().isNotEmpty) {
          return entry.value.toString().trim();
        }
      }
    }

    // 2. Nested objects like { media: { id: ... } } or { item: { id: ... } }
    for (final String key in <String>['media', 'item', 'data', 'asset', 'file', 'result', 'payload', 'upload']) {
      if (map[key] is Map<String, dynamic>) {
        final String nested = _extractId(map[key] as Map<String, dynamic>);
        if (nested.isNotEmpty) {
          return nested;
        }
      }
    }

    // 3. S3 object key like "key": "uploads/video-123.mp4" or "video-123"
    final dynamic keyVal = map['key'] ?? map['s3Key'] ?? map['s3_key'] ?? map['objectKey'];
    if (keyVal != null && keyVal.toString().trim().isNotEmpty) {
      String keyStr = keyVal.toString().trim();
      if (keyStr.contains('/')) {
        keyStr = keyStr.split('/').last;
      }
      return keyStr;
    }

    // 4. Fallback: extract from uploadUrl if present
    final dynamic uploadUrl =
        map['uploadUrl'] ?? map['url'] ?? map['upload_url'] ?? map['signedUrl'];
    if (uploadUrl is String && uploadUrl.isNotEmpty) {
      try {
        final Uri uri = Uri.parse(uploadUrl);
        if (uri.pathSegments.isNotEmpty) {
          final String lastSegment = uri.pathSegments.last;
          if (lastSegment.isNotEmpty) {
            return lastSegment;
          }
        }
      } catch (_) {}
    }

    return '';
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'uploadUrl': uploadUrl,
        'status': status,
        'downloadUrl': downloadUrl,
        'thumbnailUrl': thumbnailUrl,
        'key': key,
      };
}

class PostResponseModel {
  const PostResponseModel({
    required this.id,
    this.caption = '',
    this.type = 'TEXT',
    this.authorId,
    this.authorName,
    this.authorDisplayName,
    this.authorAvatar,
    this.createdAt,
    this.mediaRefs = const <String>[],
    this.tags = const <String>[],
    this.community,
    this.communityId,
    this.visibility,
    this.allowComments = true,
    this.allowDownloads = false,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.duration,
  });

  final String id;
  final String caption;
  final String type;
  final String? authorId;
  final String? authorName;
  final String? authorDisplayName;
  final String? authorAvatar;
  final String? createdAt;
  final List<String> mediaRefs;
  final List<String> tags;
  final String? community;
  final String? communityId;
  final String? visibility;
  final bool allowComments;
  final bool allowDownloads;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;
  final bool isSaved;
  final String? duration;

  String get body => caption;

  factory PostResponseModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map =
        (json['data'] is Map<String, dynamic>) ? json['data'] as Map<String, dynamic> : json;

    final List<dynamic>? rawMediaRefs =
        (map['mediaRefs'] ?? map['mediarefs'] ?? map['media']) as List<dynamic>?;
    final List<dynamic>? rawTags = map['tags'] as List<dynamic>?;

    final dynamic rawLikes = map['likeCount'] ?? map['likesCount'] ?? map['likes'] ?? (map['_count'] is Map ? map['_count']['likes'] : null);
    final dynamic rawComments = map['commentCount'] ?? map['commentsCount'] ?? map['comments'] ?? (map['_count'] is Map ? map['_count']['comments'] : null);

    final dynamic rawDuration = map['duration'] ??
        (map['metadata'] is Map ? map['metadata']['duration'] : null) ??
        map['videoDuration'] ??
        map['length'];
    String? durationStr;
    if (rawDuration != null) {
      if (rawDuration is num) {
        final int secs = rawDuration.toInt();
        final int m = secs ~/ 60;
        final int s = secs % 60;
        durationStr = '$m:${s.toString().padLeft(2, '0')}';
      } else {
        durationStr = rawDuration.toString();
      }
    }

    final String? resolvedAuthorId = (map['authorId'] ??
            map['author_id'] ??
            map['ownerId'] ??
            map['owner_id'] ??
            map['creatorId'] ??
            map['creator_id'] ??
            map['userId'] ??
            map['user_id'] ??
            map['participantId'] ??
            map['createdBy'] ??
            map['postedBy'] ??
            map['uploaderId'] ??
            (map['author'] is Map
                ? (map['author']['id'] ??
                    map['author']['_id'] ??
                    map['author']['userId'] ??
                    map['author']['authorId'])
                : (map['author'] is String ? map['author'] : null)) ??
            (map['user'] is Map
                ? (map['user']['id'] ??
                    map['user']['_id'] ??
                    map['user']['userId'])
                : (map['user'] is String ? map['user'] : null)) ??
            (map['creator'] is Map
                ? (map['creator']['id'] ??
                    map['creator']['_id'] ??
                    map['creator']['userId'])
                : null))
        ?.toString();

    String? finalAuthorId = (resolvedAuthorId != null && resolvedAuthorId.trim().isNotEmpty)
        ? resolvedAuthorId.trim()
        : null;

    if (finalAuthorId == null) {
      final String fullStr = map.toString();
      final Match? match = RegExp(
        r'/(?:original|images|videos|users|avatars)/([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})',
      ).firstMatch(fullStr);
      if (match != null) {
        finalAuthorId = match.group(1);
      }
    }

    if (finalAuthorId == null) {
      final String postId = (map['id'] ?? map['_id'] ?? '').toString();
      final Iterable<Match> matches = RegExp(
        r'([0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12})',
      ).allMatches(map.toString());
      for (final Match m in matches) {
        final String? matchedId = m.group(1);
        if (matchedId != null &&
            matchedId != postId &&
            (rawMediaRefs == null ||
                !rawMediaRefs.any((dynamic r) => r.toString().contains(matchedId)))) {
          finalAuthorId = matchedId;
          break;
        }
      }
    }

    final String? resolvedAuthorName = (map['author'] is Map
            ? (map['author']['username'] ??
                map['author']['userName'] ??
                map['author']['handle'] ??
                map['author']['displayName'] ??
                map['author']['name'])
            : null) ??
        (map['user'] is Map
            ? (map['user']['username'] ??
                map['user']['userName'] ??
                map['user']['handle'] ??
                map['user']['displayName'] ??
                map['user']['name'])
            : null) ??
        map['authorName']?.toString() ??
        map['author_name']?.toString() ??
        map['userName']?.toString() ??
        map['username']?.toString();

    final String? resolvedAuthorDisplayName = (map['author'] is Map
            ? (map['author']['displayName'] ??
                map['author']['name'] ??
                map['author']['fullName'])
            : null) ??
        (map['user'] is Map
            ? (map['user']['displayName'] ??
                map['user']['name'] ??
                map['user']['fullName'])
            : null) ??
        map['displayName']?.toString() ??
        map['authorDisplayName']?.toString();

    final String? resolvedAuthorAvatar = (map['author'] is Map
            ? (map['author']['avatarUrl'] ??
                map['author']['avatar'] ??
                map['author']['profilePic'] ??
                map['author']['profilePicture'])
            : null) ??
        (map['user'] is Map
            ? (map['user']['avatarUrl'] ??
                map['user']['avatar'] ??
                map['user']['profilePic'] ??
                map['user']['profilePicture'])
            : null) ??
        map['authorAvatar']?.toString() ??
        map['author_avatar']?.toString() ??
        map['avatarUrl']?.toString() ??
        map['avatar']?.toString();

    return PostResponseModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      caption: (map['body'] ?? map['caption'] ?? '').toString(),
      type: (map['type'] ?? 'TEXT').toString(),
      authorId: finalAuthorId,
      authorName: resolvedAuthorName,
      authorDisplayName: resolvedAuthorDisplayName,
      authorAvatar: resolvedAuthorAvatar,
      createdAt: map['createdAt']?.toString(),
      mediaRefs: rawMediaRefs?.map((e) => e.toString()).toList() ?? <String>[],
      tags: rawTags?.map((e) => e.toString()).toList() ?? <String>[],
      community: (map['community'] ?? map['communityId'])?.toString(),
      communityId: map['communityId']?.toString(),
      visibility: map['visibility']?.toString(),
      allowComments: map['allowComments'] as bool? ?? true,
      allowDownloads: map['allowDownloads'] as bool? ?? false,
      likesCount: rawLikes is num ? rawLikes.toInt() : int.tryParse(rawLikes?.toString() ?? '0') ?? 0,
      commentsCount: rawComments is num ? rawComments.toInt() : int.tryParse(rawComments?.toString() ?? '0') ?? 0,
      isLiked: (map['isLiked'] ?? map['liked'] ?? false) == true,
      isSaved: (map['isSaved'] ?? map['saved'] ?? false) == true,
      duration: durationStr,
    );
  }
}


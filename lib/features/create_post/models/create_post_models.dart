import 'dart:typed_data';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/config/app_config.dart';
import '../../../core/cache/cache_manager.dart';

class AuthorInfo {
  const AuthorInfo({
    required this.id,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.hideMyLikes,
    this.isPrivate = false,
    this.allowCommentsFrom = 'everyone',
  });

  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool? hideMyLikes;
  final bool isPrivate;
  final String allowCommentsFrom;
}

class AuthorProfileCache {
  AuthorProfileCache._();
  static final Map<String, AuthorInfo> _cache = <String, AuthorInfo>{};

  static AuthorInfo? get(String userId) {
    final String clean = userId.trim();
    if (clean.isEmpty) return null;
    return _cache[clean];
  }

  static AuthorInfo? getByName(String username) {
    final String clean = username.replaceAll('@', '').trim().toLowerCase();
    if (clean.isEmpty) return null;
    for (final AuthorInfo info in _cache.values) {
      if (info.username.replaceAll('@', '').trim().toLowerCase() == clean) {
        return info;
      }
    }
    return null;
  }

  static void set(String userId, AuthorInfo info) {
    final String clean = userId.trim();
    if (clean.isEmpty) return;
    _cache[clean] = info;
  }

  static bool contains(String userId) => _cache.containsKey(userId.trim());
}

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
    this.mediaUrl,
    this.thumbnailUrl,
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
  final String? mediaUrl;
  final String? thumbnailUrl;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'assetPath': assetPath,
    'videoAsset': videoAsset,
    'isVideo': isVideo,
    'duration': duration,
    'durationSeconds': durationSeconds,
    'filePath': filePath,
    'mediaUrl': mediaUrl,
    'thumbnailUrl': thumbnailUrl,
  };

  factory GalleryMediaItem.fromJson(Map<String, dynamic> json) => GalleryMediaItem(
    id: json['id'] as String? ?? '',
    assetPath: json['assetPath'] as String? ?? '',
    videoAsset: json['videoAsset'] as String?,
    isVideo: json['isVideo'] as bool? ?? false,
    duration: json['duration'] as String? ?? '',
    durationSeconds: json['durationSeconds'] as int? ?? 0,
    filePath: json['filePath'] as String?,
    mediaUrl: json['mediaUrl'] as String?,
    thumbnailUrl: json['thumbnailUrl'] as String?,
  );
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
        (json['data'] is Map<String, dynamic>)
            ? json['data'] as Map<String, dynamic>
            : (json['media'] is Map<String, dynamic>)
                ? json['media'] as Map<String, dynamic>
                : json;

    final String extractedId = _extractId(map);

    final dynamic rawUrl = map['url'] ??
        map['downloadUrl'] ??
        map['download_url'] ??
        map['cdnUrl'] ??
        map['cdn_url'] ??
        map['mediaUrl'] ??
        map['media_url'] ??
        map['fileUrl'] ??
        map['file_url'] ??
        map['publicUrl'] ??
        map['public_url'] ??
        map['location'] ??
        map['signedUrl'] ??
        map['uploadUrl'] ??
        map['path'];

    final dynamic rawThumb = map['thumbnailUrl'] ??
        map['thumbnail_url'] ??
        map['thumbUrl'] ??
        map['thumbnail'] ??
        map['posterUrl'] ??
        map['previewUrl'];

    return MediaUploadResult(
      id: extractedId,
      uploadUrl: (map['uploadUrl'] ?? map['upload_url'] ?? map['signedUrl'])?.toString(),
      status: (map['status'] ?? 'pending').toString(),
      downloadUrl: rawUrl?.toString(),
      thumbnailUrl: rawThumb?.toString(),
      key: (map['key'] ?? map['s3Key'] ?? map['s3_key'] ?? map['objectKey'])?.toString(),
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
    this.allowDownloads = true,
    this.isAuthorPrivate = false,
    this.allowCommentsFrom = 'everyone',
    this.hasLikeCount = true,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.viewsCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.hideLikes = false,
    this.duration,
    this.postImageUrl,
    this.thumbnailUrl,
    this.status,
    this.deletedAt,
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
  final bool isAuthorPrivate;
  final String allowCommentsFrom;
  final bool hasLikeCount;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final bool isLiked;
  final bool isSaved;
  final bool hideLikes;
  final String? duration;
  final String? postImageUrl;
  final String? thumbnailUrl;
  final String? status;
  final String? deletedAt;

  String get body => caption;
  bool get isDeleted =>
      deletedAt != null ||
      status?.toLowerCase() == 'deleted' ||
      status?.toLowerCase() == 'removed';

  PostResponseModel copyWith({
    String? id,
    String? caption,
    String? type,
    String? authorId,
    String? authorName,
    String? authorDisplayName,
    String? authorAvatar,
    String? createdAt,
    List<String>? mediaRefs,
    List<String>? tags,
    String? community,
    String? communityId,
    String? visibility,
    bool? allowComments,
    bool? allowDownloads,
    bool? isAuthorPrivate,
    String? allowCommentsFrom,
    bool? hasLikeCount,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
    bool? isLiked,
    bool? isSaved,
    bool? hideLikes,
    String? duration,
    String? postImageUrl,
    String? thumbnailUrl,
    String? status,
    String? deletedAt,
  }) {
    return PostResponseModel(
      id: id ?? this.id,
      caption: caption ?? this.caption,
      type: type ?? this.type,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      authorDisplayName: authorDisplayName ?? this.authorDisplayName,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      createdAt: createdAt ?? this.createdAt,
      mediaRefs: mediaRefs ?? this.mediaRefs,
      tags: tags ?? this.tags,
      community: community ?? this.community,
      communityId: communityId ?? this.communityId,
      visibility: visibility ?? this.visibility,
      allowComments: allowComments ?? this.allowComments,
      allowDownloads: allowDownloads ?? this.allowDownloads,
      isAuthorPrivate: isAuthorPrivate ?? this.isAuthorPrivate,
      allowCommentsFrom: allowCommentsFrom ?? this.allowCommentsFrom,
      hasLikeCount: hasLikeCount ?? this.hasLikeCount,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      viewsCount: viewsCount ?? this.viewsCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      hideLikes: hideLikes ?? this.hideLikes,
      duration: duration ?? this.duration,
      postImageUrl: postImageUrl ?? this.postImageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      status: status ?? this.status,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  factory PostResponseModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> map =
        (json['data'] is Map<String, dynamic>) ? json['data'] as Map<String, dynamic> : json;

    final List<String> extractedMediaRefs = <String>[];
    String? explicitImageUrl;

    void addMediaRef(dynamic val) {
      if (val == null) return;
      if (val is List) {
        for (final dynamic item in val) {
          addMediaRef(item);
        }
      } else if (val is String) {
        final String s = val.trim();
        if (s.isNotEmpty && !extractedMediaRefs.contains(s)) {
          if (s.startsWith('http://') || s.startsWith('https://')) {
            extractedMediaRefs.insert(0, s);
            explicitImageUrl ??= s;
          } else {
            extractedMediaRefs.add(s);
          }
        }
      } else if (val is Map) {
        final dynamic nestedUrl = val['url'] ??
            val['downloadUrl'] ??
            val['download_url'] ??
            val['cdnUrl'] ??
            val['mediaUrl'] ??
            val['fileUrl'] ??
            val['thumbnailUrl'] ??
            val['path'] ??
            val['id'] ??
            val['_id'];
        if (nestedUrl != null) {
          addMediaRef(nestedUrl);
        }
      }
    }

    addMediaRef(map['mediaRefs']);
    addMediaRef(map['mediarefs']);
    addMediaRef(map['mediaUrls']);
    addMediaRef(map['media_urls']);
    addMediaRef(map['images']);
    addMediaRef(map['imageUrls']);
    addMediaRef(map['image_urls']);
    addMediaRef(map['photos']);
    addMediaRef(map['photoUrls']);
    addMediaRef(map['attachments']);
    addMediaRef(map['imageUrl']);
    addMediaRef(map['image_url']);
    addMediaRef(map['photoUrl']);
    addMediaRef(map['photo_url']);
    addMediaRef(map['mediaUrl']);
    addMediaRef(map['media_url']);
    addMediaRef(map['image']);
    addMediaRef(map['photo']);
    addMediaRef(map['picture']);
    addMediaRef(map['pictures']);
    addMediaRef(map['media']);
    addMediaRef(map['files']);
    addMediaRef(map['file']);
    addMediaRef(map['postImage']);
    addMediaRef(map['postImageUrl']);

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
            !extractedMediaRefs.any((dynamic r) => r.toString().contains(matchedId))) {
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
        (map['creator'] is Map
            ? (map['creator']['username'] ??
                map['creator']['userName'] ??
                map['creator']['handle'] ??
                map['creator']['displayName'] ??
                map['creator']['name'])
            : null) ??
        map['authorName']?.toString() ??
        map['author_name']?.toString() ??
        map['userName']?.toString() ??
        map['username']?.toString() ??
        map['user_name']?.toString() ??
        map['handle']?.toString();

    final String? resolvedAuthorDisplayName = (map['author'] is Map
            ? (map['author']['displayName'] ??
                map['author']['display_name'] ??
                map['author']['name'] ??
                map['author']['fullName'] ??
                map['author']['full_name'])
            : null) ??
        (map['user'] is Map
            ? (map['user']['displayName'] ??
                map['user']['display_name'] ??
                map['user']['name'] ??
                map['user']['fullName'] ??
                map['user']['full_name'])
            : null) ??
        (map['creator'] is Map
            ? (map['creator']['displayName'] ??
                map['creator']['display_name'] ??
                map['creator']['name'] ??
                map['creator']['fullName'] ??
                map['creator']['full_name'])
            : null) ??
        map['displayName']?.toString() ??
        map['display_name']?.toString() ??
        map['authorDisplayName']?.toString() ??
        map['author_display_name']?.toString() ??
        map['fullName']?.toString() ??
        map['full_name']?.toString() ??
        map['name']?.toString();

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

    String? finalAuthorName = resolvedAuthorName;
    String? finalAuthorDisplayName = resolvedAuthorDisplayName;
    String? finalAuthorAvatar = resolvedAuthorAvatar;
    AuthorInfo? cachedAuthor;

    if (finalAuthorId != null && finalAuthorId.isNotEmpty) {
      cachedAuthor = AuthorProfileCache.get(finalAuthorId);
      if (cachedAuthor != null) {
        finalAuthorName ??= cachedAuthor.username;
        finalAuthorDisplayName ??= cachedAuthor.displayName;
        finalAuthorAvatar ??= cachedAuthor.avatarUrl;
      } else {
        try {
          final dynamic persistent =
              CacheManager.instance.get('profile_details_$finalAuthorId');
          if (persistent is Map) {
            final Map<String, dynamic> c =
                Map<String, dynamic>.from(persistent);
            final dynamic userObj =
                c['data'] ?? c['user'] ?? c['profile'] ?? c;
            if (userObj is Map) {
              final String? u = (userObj['username'] ??
                      userObj['userName'] ??
                      userObj['handle'])
                  ?.toString();
              if (u != null && u.trim().isNotEmpty) {
                final String? d = (userObj['displayName'] ??
                        userObj['display_name'] ??
                        userObj['name'] ??
                        userObj['fullName'])
                    ?.toString();
                final String? a = (userObj['avatarUrl'] ??
                        userObj['avatar'] ??
                        userObj['profilePic'])
                    ?.toString();
                final bool? hideLikes =
                    (userObj['hideMyLikes'] ?? userObj['hideLikes']) as bool?;
                final bool isPriv = (userObj['isPrivate'] ?? userObj['is_private']) == true;
                final String acf = (userObj['allowCommentsFrom'] ?? userObj['allow_comments_from'] ?? 'everyone').toString().trim().toLowerCase();
                final AuthorInfo info = AuthorInfo(
                  id: finalAuthorId,
                  username: u.trim(),
                  displayName: (d != null && d.trim().isNotEmpty)
                      ? d.trim()
                      : u.trim(),
                  avatarUrl: a,
                  hideMyLikes: hideLikes,
                  isPrivate: isPriv,
                  allowCommentsFrom: acf,
                );
                AuthorProfileCache.set(finalAuthorId, info);
                cachedAuthor = info;
                finalAuthorName ??= info.username;
                finalAuthorDisplayName ??= info.displayName;
                finalAuthorAvatar ??= info.avatarUrl;
              }
            }
          }
        } catch (_) {}
      }
    }

    final String parsedRawType = (map['type'] ??
            map['postType'] ??
            map['post_type'] ??
            map['mediaType'] ??
            map['media_type'] ??
            map['contentType'] ??
            map['content_type'] ??
            (map['media'] is Map ? map['media']['type'] : null) ??
            (map['media'] is List &&
                    (map['media'] as List).isNotEmpty &&
                    map['media'][0] is Map
                ? map['media'][0]['type']
                : null) ??
            '')
        .toString()
        .toUpperCase()
        .trim();

    final bool isVideoType = parsedRawType == 'VIDEO' ||
        parsedRawType == 'REEL' ||
        (durationStr != null && durationStr.isNotEmpty) ||
        extractedMediaRefs.any((String r) {
          final String l = r.toLowerCase();
          return l.endsWith('.mp4') ||
              l.endsWith('.mov') ||
              l.endsWith('.webm') ||
              l.endsWith('.mkv') ||
              l.contains('/videos/') ||
              l.contains('/video/');
        });

    final String finalType = isVideoType
        ? 'VIDEO'
        : (parsedRawType.isNotEmpty
            ? parsedRawType
            : (extractedMediaRefs.isNotEmpty ? 'PHOTO' : 'TEXT'));

    final String? rootAllowCommentsFrom =
        map['allowCommentsFrom']?.toString() ??
        map['allow_comments_from']?.toString();
    final String? authorAllowCommentsFrom = (map['author'] is Map
            ? (map['author']['allowCommentsFrom'] ?? map['author']['allow_comments_from'])
            : null)?.toString() ??
        (map['user'] is Map
            ? (map['user']['allowCommentsFrom'] ?? map['user']['allow_comments_from'])
            : null)?.toString();

    final String resolvedAllowCommentsFrom = (rootAllowCommentsFrom ??
            authorAllowCommentsFrom ??
            cachedAuthor?.allowCommentsFrom ??
            'everyone')
        .trim()
        .toLowerCase();

    final bool resolvedIsAuthorPrivate = (map['author'] is Map
            ? (map['author']['isPrivate'] ?? map['author']['is_private'])
            : null) == true ||
        (map['user'] is Map
            ? (map['user']['isPrivate'] ?? map['user']['is_private'])
            : null) == true ||
        map['isPrivate'] == true ||
        map['is_private'] == true ||
        map['isAuthorPrivate'] == true ||
        cachedAuthor?.isPrivate == true;

    if (finalAuthorId != null && finalAuthorId.isNotEmpty) {
      if (cachedAuthor == null && (finalAuthorName != null || finalAuthorDisplayName != null)) {
        AuthorProfileCache.set(
          finalAuthorId,
          AuthorInfo(
            id: finalAuthorId,
            username: finalAuthorName ?? '',
            displayName: finalAuthorDisplayName ?? finalAuthorName ?? '',
            avatarUrl: finalAuthorAvatar,
            hideMyLikes: (map['hideLikes'] ?? map['hideMyLikes']) as bool?,
            isPrivate: resolvedIsAuthorPrivate,
            allowCommentsFrom: resolvedAllowCommentsFrom,
          ),
        );
      }
    }

    return PostResponseModel(
      id: (map['id'] ?? map['_id'] ?? '').toString(),
      caption: (map['body'] ??
              map['caption'] ??
              map['content'] ??
              map['text'] ??
              map['title'] ??
              map['description'] ??
              '')
          .toString(),
      type: finalType,
      authorId: finalAuthorId,
      authorName: finalAuthorName,
      authorDisplayName: finalAuthorDisplayName,
      authorAvatar: finalAuthorAvatar,
      createdAt: map['createdAt']?.toString(),
      mediaRefs: extractedMediaRefs,
      tags: rawTags?.map((e) => e.toString()).toList() ?? <String>[],
      community: (map['community'] ?? map['communityId'])?.toString(),
      communityId: map['communityId']?.toString(),
      visibility: map['visibility']?.toString(),
      allowComments: (map['allowComments'] ?? map['allowComment']) as bool? ?? true,
      allowDownloads: (map['allowDownloads'] ?? map['allowSharing'] ?? map['allowDownload']) as bool? ?? true,
      isAuthorPrivate: resolvedIsAuthorPrivate,
      allowCommentsFrom: resolvedAllowCommentsFrom,
      hasLikeCount: rawLikes != null,
      likesCount: () {
        if (rawLikes is num) return rawLikes.toInt();
        if (rawLikes is List) return rawLikes.length;
        if (rawLikes != null) return int.tryParse(rawLikes.toString()) ?? 0;
        return 0;
      }(),
      commentsCount: () {
        if (rawComments is num) return rawComments.toInt();
        if (rawComments is List) return rawComments.length;
        if (rawComments != null) return int.tryParse(rawComments.toString()) ?? 0;
        return 0;
      }(),
      viewsCount: () {
        final dynamic rawViews = map['viewCount'] ??
            map['viewsCount'] ??
            map['view_count'] ??
            map['views_count'] ??
            map['views'] ??
            map['playCount'] ??
            map['playsCount'] ??
            map['play_count'] ??
            map['plays_count'] ??
            map['plays'] ??
            map['impressions'] ??
            map['totalViews'] ??
            map['totalPlays'] ??
            (map['metadata'] is Map
                ? (map['metadata']['views'] ??
                    map['metadata']['plays'] ??
                    map['metadata']['viewCount'] ??
                    map['metadata']['playCount'])
                : null) ??
            (map['_count'] is Map
                ? (map['_count']['views'] ??
                    map['_count']['plays'] ??
                    map['_count']['viewCount'] ??
                    map['_count']['playCount'])
                : null);
        return rawViews is num
            ? rawViews.toInt()
            : int.tryParse(rawViews?.toString() ?? '0') ?? 0;
      }(),
      isLiked: () {
        final dynamic raw = map['isLiked'] ??
            map['is_liked'] ??
            map['liked'] ??
            map['hasLiked'] ??
            map['has_liked'] ??
            map['userLiked'] ??
            map['user_liked'] ??
            map['likedByMe'] ??
            map['liked_by_me'] ??
            map['isLikedByMe'] ??
            map['is_liked_by_me'] ??
            (map['viewer'] is Map
                ? (map['viewer']['isLiked'] ?? map['viewer']['liked'])
                : null) ??
            (map['metadata'] is Map
                ? (map['metadata']['isLiked'] ?? map['metadata']['is_liked'])
                : null);
        return raw == true || raw == 1 || raw == 'true';
      }(),
      isSaved: () {
        final dynamic raw = map['isSaved'] ??
            map['is_saved'] ??
            map['saved'] ??
            map['hasSaved'] ??
            map['has_saved'] ??
            map['userSaved'] ??
            map['user_saved'] ??
            map['savedByMe'] ??
            map['saved_by_me'] ??
            map['isSavedByMe'] ??
            map['is_saved_by_me'] ??
            (map['viewer'] is Map
                ? (map['viewer']['isSaved'] ?? map['viewer']['saved'])
                : null) ??
            (map['metadata'] is Map
                ? (map['metadata']['isSaved'] ?? map['metadata']['is_saved'])
                : null);
        return raw == true || raw == 1 || raw == 'true';
      }(),
      hideLikes: (map['hideLikes'] ??
              map['hideMyLikes'] ??
              (map['author'] is Map
                  ? (map['author']['hideMyLikes'] ?? map['author']['hideLikes'])
                  : null) ??
              (map['user'] is Map
                  ? (map['user']['hideMyLikes'] ?? map['user']['hideLikes'])
                  : null) ??
              cachedAuthor?.hideMyLikes ??
              false) ==
          true,
      duration: durationStr,
      postImageUrl: () {
        final dynamic rawThumb = map['thumbnailUrl'] ??
            map['thumbnail_url'] ??
            map['thumbUrl'] ??
            map['thumbnail'] ??
            map['posterUrl'] ??
            map['previewUrl'] ??
            (map['media'] is Map ? (map['media']['thumbnailUrl'] ?? map['media']['thumbUrl']) : null) ??
            (map['media'] is List && (map['media'] as List).isNotEmpty && (map['media'] as List).first is Map
                ? ((map['media'] as List).first['thumbnailUrl'] ?? (map['media'] as List).first['thumbUrl'])
                : null);
        String? resolvedThumb = rawThumb?.toString().trim();

        if ((resolvedThumb == null || resolvedThumb.isEmpty) && isVideoType && extractedMediaRefs.isNotEmpty) {
          final String firstRef = extractedMediaRefs.first.trim();
          if (!firstRef.startsWith('http://') && !firstRef.startsWith('https://')) {
            final String clean = firstRef
                .replaceAll(RegExp(r'^/+'), '')
                .replaceAll(RegExp(r'^media/'), '');
            resolvedThumb = '${AppConfig.cdnUrl}/videos/processed/$clean/thumb.0000000.jpg';
          } else if (firstRef.contains('/videos/processed/')) {
            resolvedThumb = firstRef.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg');
          }
        }

        if (isVideoType) {
          if (resolvedThumb != null && resolvedThumb.isNotEmpty) {
            return resolvedThumb;
          }
          if (explicitImageUrl != null &&
              !explicitImageUrl!.endsWith('.mp4') &&
              !explicitImageUrl!.endsWith('.m3u8')) {
            return explicitImageUrl;
          }
          return null;
        }
        return explicitImageUrl ??
            (extractedMediaRefs.isNotEmpty
                ? ((extractedMediaRefs.first.startsWith('http://') ||
                        extractedMediaRefs.first.startsWith('https://') ||
                        extractedMediaRefs.first.startsWith('assets/'))
                    ? extractedMediaRefs.first
                    : (finalAuthorId != null && finalAuthorId.isNotEmpty
                        ? '${AppConfig.cdnUrl}/images/original/$finalAuthorId/${extractedMediaRefs.first.replaceAll(RegExp(r"^/+"), "").replaceAll(RegExp(r"^media/"), "")}.jpg'
                        : '${AppConfig.cdnUrl}/images/original/${extractedMediaRefs.first.replaceAll(RegExp(r"^/+"), "").replaceAll(RegExp(r"^media/"), "")}.jpg'))
                : null);
      }(),
      thumbnailUrl: () {
        final dynamic rawThumb = map['thumbnailUrl'] ??
            map['thumbnail_url'] ??
            map['thumbUrl'] ??
            map['thumbnail'] ??
            map['posterUrl'] ??
            map['previewUrl'] ??
            (map['media'] is Map ? (map['media']['thumbnailUrl'] ?? map['media']['thumbUrl']) : null) ??
            (map['media'] is List && (map['media'] as List).isNotEmpty && (map['media'] as List).first is Map
                ? ((map['media'] as List).first['thumbnailUrl'] ?? (map['media'] as List).first['thumbUrl'])
                : null);
        String? resolvedThumb = rawThumb?.toString().trim();

        if ((resolvedThumb == null || resolvedThumb.isEmpty) && isVideoType && extractedMediaRefs.isNotEmpty) {
          final String firstRef = extractedMediaRefs.first.trim();
          if (!firstRef.startsWith('http://') && !firstRef.startsWith('https://')) {
            final String clean = firstRef
                .replaceAll(RegExp(r'^/+'), '')
                .replaceAll(RegExp(r'^media/'), '');
            resolvedThumb = '${AppConfig.cdnUrl}/videos/processed/$clean/thumb.0000000.jpg';
          } else if (firstRef.contains('/videos/processed/')) {
            resolvedThumb = firstRef.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg');
          }
        }
        return resolvedThumb;
      }(),
      status: map['status']?.toString(),
      deletedAt: map['deletedAt']?.toString() ?? map['deleted_at']?.toString(),
    );
  }
}


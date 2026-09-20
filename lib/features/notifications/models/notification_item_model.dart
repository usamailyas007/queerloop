import '../../../core/theme/app_images.dart';

/// Represents an in-app notification item received from `GET /notifications`.
class NotificationItemModel {
  const NotificationItemModel({
    required this.id,
    required this.type,
    this.title,
    this.body,
    this.actorId,
    this.actorUsername,
    this.actorName,
    this.actorAvatar,
    this.postThumbnail,
    this.postId,
    this.commentId,
    this.followRequestId,
    this.followStatus,
    this.isRead = false,
    this.createdAt,
    this.extraData,
  });

  final String id;
  final String type; // 'LIKE', 'COMMENT', 'FOLLOW', 'FOLLOW_REQUEST', 'MENTION', 'SAFETY', etc.
  final String? title;
  final String? body;
  final String? actorId;
  final String? actorUsername;
  final String? actorName;
  final String? actorAvatar;
  final String? postThumbnail;
  final String? postId;
  final String? commentId;
  final String? followRequestId;
  final String? followStatus;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic>? extraData;

  bool get isLike =>
      type.toUpperCase().contains('LIKE') ||
      (body?.toLowerCase().contains('liked') ?? false);

  bool get isComment =>
      type.toUpperCase().contains('COMMENT') ||
      (body?.toLowerCase().contains('commented') ?? false);

  bool get isFollow =>
      type.toUpperCase().contains('FOLLOW') ||
      (body?.toLowerCase().contains('follow') ?? false);

  bool get isFollowRequest =>
      type.toUpperCase().contains('FOLLOW_REQUEST') ||
      (body?.toLowerCase().contains('requested to follow') ?? false);

  bool get isSafety =>
      type.toUpperCase().contains('SAFETY') ||
      type.toUpperCase().contains('REPORT') ||
      type.toUpperCase().contains('MODERAT') ||
      (body?.toLowerCase().contains('report') ?? false);

  /// Friendly short timestamp (e.g. "2m", "1h", "3d")
  String get timeAgo {
    if (createdAt == null) return 'now';
    final Duration diff = DateTime.now().difference(createdAt!);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    return '${(diff.inDays / 30).floor()}mo';
  }

  /// Display text for actor username
  String get displayUsername {
    if (actorUsername != null && actorUsername!.trim().isNotEmpty) {
      final String u = actorUsername!.trim();
      return u.startsWith('@') ? u : '@$u';
    }
    return '@user';
  }

  /// Clean display name
  String get displayName {
    if (actorName != null && actorName!.trim().isNotEmpty) {
      return actorName!.trim();
    }
    return displayUsername.replaceAll('@', '');
  }

  /// Safe avatar string (network url or asset)
  String get safeAvatar {
    if (actorAvatar != null && actorAvatar!.trim().isNotEmpty) {
      return actorAvatar!.trim();
    }
    return AppImages.user1;
  }

  factory NotificationItemModel.fromJson(Map<String, dynamic> json) {
    // 1. Resolve ID
    final String resolvedId = (json['id'] ??
            json['_id'] ??
            json['notificationId'] ??
            'notif_${DateTime.now().millisecondsSinceEpoch}')
        .toString();

    // 2. Resolve Type
    final String resolvedType = (json['type'] ??
            json['notificationType'] ??
            json['action'] ??
            'GENERAL')
        .toString()
        .toUpperCase();

    // 3. Resolve Title & Body
    final String? resolvedTitle = (json['title'] ?? json['header'])?.toString();
    final String? resolvedBody = (json['body'] ??
            json['message'] ??
            json['content'] ??
            json['text'])
        ?.toString();

    // 4. Resolve Actor
    String? resolvedActorId;
    String? resolvedActorUsername;
    String? resolvedActorName;
    String? resolvedActorAvatar;

    final dynamic actorRaw = json['actor'] ??
        json['sender'] ??
        json['user'] ??
        json['fromUser'] ??
        json['author'];

    if (actorRaw is Map<String, dynamic>) {
      resolvedActorId = (actorRaw['id'] ??
              actorRaw['_id'] ??
              actorRaw['userId'])
          ?.toString();
      resolvedActorUsername = (actorRaw['username'] ??
              actorRaw['handle'] ??
              actorRaw['name'])
          ?.toString();
      resolvedActorName = (actorRaw['displayName'] ??
              actorRaw['name'] ??
              actorRaw['fullName'])
          ?.toString();
      resolvedActorAvatar = (actorRaw['avatarUrl'] ??
              actorRaw['avatar'] ??
              actorRaw['profilePicture'])
          ?.toString();
    } else {
      resolvedActorId = (json['actorId'] ?? json['senderId'])?.toString();
      resolvedActorUsername = (json['actorUsername'] ??
              json['senderUsername'] ??
              json['username'])
          ?.toString();
      resolvedActorName =
          (json['actorName'] ?? json['senderName'] ?? json['name'])?.toString();
      resolvedActorAvatar = (json['actorAvatar'] ??
              json['senderAvatar'] ??
              json['avatarUrl'])
          ?.toString();
    }

    // 5. Resolve Related Post / Comment
    final dynamic dataMap = json['data'] ?? json['metadata'] ?? json['payload'];
    String? resolvedPostId;
    String? resolvedCommentId;
    String? resolvedPostThumbnail;

    if (dataMap is Map<String, dynamic>) {
      resolvedPostId = (dataMap['postId'] ?? dataMap['post_id'])?.toString();
      resolvedCommentId =
          (dataMap['commentId'] ?? dataMap['comment_id'])?.toString();
      resolvedPostThumbnail = (dataMap['postThumbnail'] ??
              dataMap['postImage'] ??
              dataMap['imageUrl'])
          ?.toString();
    }

    resolvedPostId ??= (json['postId'] ?? json['targetId'])?.toString();
    resolvedCommentId ??= json['commentId']?.toString();
    resolvedPostThumbnail ??= (json['postThumbnail'] ??
            json['postImage'] ??
            json['imageUrl'] ??
            json['mediaUrl'])
        ?.toString();

    // 5b. Resolve Follow Request ID
    String? resolvedFollowRequestId;
    if (dataMap is Map<String, dynamic>) {
      final dynamic nestedReq = dataMap['followRequest'] ?? dataMap['request'];
      if (nestedReq is Map<String, dynamic>) {
        resolvedFollowRequestId = (nestedReq['id'] ??
                nestedReq['_id'] ??
                nestedReq['requestId'])
            ?.toString();
      }
      resolvedFollowRequestId ??= (dataMap['requestId'] ??
              dataMap['request_id'] ??
              dataMap['followRequestId'] ??
              dataMap['follow_request_id'] ??
              dataMap['id'])
          ?.toString();
    }
    final dynamic rootReq = json['followRequest'] ?? json['request'];
    if (rootReq is Map<String, dynamic>) {
      resolvedFollowRequestId ??= (rootReq['id'] ??
              rootReq['_id'] ??
              rootReq['requestId'])
          ?.toString();
    }
    resolvedFollowRequestId ??= (json['requestId'] ??
            json['request_id'] ??
            json['followRequestId'] ??
            json['follow_request_id'])
        ?.toString();

    if (resolvedType.contains('FOLLOW_REQUEST') && resolvedFollowRequestId == null) {
      if (json['targetId'] != null) {
        resolvedFollowRequestId = json['targetId'].toString();
      } else if (dataMap is Map<String, dynamic> && dataMap['targetId'] != null) {
        resolvedFollowRequestId = dataMap['targetId'].toString();
      }
    }

    // 6. Resolve Read Status
    final bool resolvedIsRead = json['isRead'] == true ||
        json['read'] == true ||
        json['status'] == 'READ' ||
        json['readAt'] != null;

    // 7. Resolve CreatedAt
    DateTime? resolvedCreatedAt;
    final dynamic rawDate =
        json['createdAt'] ?? json['created_at'] ?? json['timestamp'];
    if (rawDate != null) {
      if (rawDate is DateTime) {
        resolvedCreatedAt = rawDate;
      } else {
        resolvedCreatedAt = DateTime.tryParse(rawDate.toString());
      }
    }

    // 8. Resolve Follow Action Status
    String? resolvedFollowStatus;
    final String rawStatus = (json['status'] ??
            json['followStatus'] ??
            json['requestStatus'] ??
            json['state'] ??
            (dataMap is Map<String, dynamic>
                ? (dataMap['status'] ?? dataMap['requestStatus'] ?? dataMap['followStatus'])
                : null) ??
            (rootReq is Map<String, dynamic> ? rootReq['status'] : null))
        ?.toString()
        .toLowerCase() ??
        '';

    if (rawStatus == 'accepted' || rawStatus == 'approved') {
      resolvedFollowStatus = 'accepted';
    } else if (rawStatus == 'declined' || rawStatus == 'rejected') {
      resolvedFollowStatus = 'declined';
    }

    return NotificationItemModel(
      id: resolvedId,
      type: resolvedType,
      title: resolvedTitle,
      body: resolvedBody,
      actorId: resolvedActorId,
      actorUsername: resolvedActorUsername,
      actorName: resolvedActorName,
      actorAvatar: resolvedActorAvatar,
      postThumbnail: resolvedPostThumbnail,
      postId: resolvedPostId,
      commentId: resolvedCommentId,
      followRequestId: resolvedFollowRequestId,
      followStatus: resolvedFollowStatus,
      isRead: resolvedIsRead,
      createdAt: resolvedCreatedAt,
      extraData: dataMap is Map<String, dynamic> ? dataMap : null,
    );
  }

  NotificationItemModel copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    String? actorId,
    String? actorUsername,
    String? actorName,
    String? actorAvatar,
    String? postThumbnail,
    String? postId,
    String? commentId,
    String? followRequestId,
    String? followStatus,
    bool? isRead,
    DateTime? createdAt,
    Map<String, dynamic>? extraData,
  }) {
    return NotificationItemModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      actorId: actorId ?? this.actorId,
      actorUsername: actorUsername ?? this.actorUsername,
      actorName: actorName ?? this.actorName,
      actorAvatar: actorAvatar ?? this.actorAvatar,
      postThumbnail: postThumbnail ?? this.postThumbnail,
      postId: postId ?? this.postId,
      commentId: commentId ?? this.commentId,
      followRequestId: followRequestId ?? this.followRequestId,
      followStatus: followStatus ?? this.followStatus,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      extraData: extraData ?? this.extraData,
    );
  }
}

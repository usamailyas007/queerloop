import '../../../core/config/app_config.dart';
import '../../../core/theme/app_images.dart';
import '../../create_post/models/create_post_models.dart';
import '../services/shared_post_cache.dart';

DateTime? parseUtcToLocal(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw.toLocal();
  if (raw is num) {
    final int val = raw.toInt();
    if (val > 1000000000000) {
      return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
    } else if (val > 1000000000) {
      return DateTime.fromMillisecondsSinceEpoch(val * 1000).toLocal();
    }
  }
  final String str = raw.toString().trim();
  if (str.isEmpty || str == 'null') return null;

  try {
    DateTime? dt = DateTime.tryParse(str);
    if (dt == null) return null;
    if (!dt.isUtc && !str.endsWith('Z') && !RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(str)) {
      dt = DateTime.utc(
        dt.year,
        dt.month,
        dt.day,
        dt.hour,
        dt.minute,
        dt.second,
        dt.millisecond,
        dt.microsecond,
      );
    }
    return dt.toLocal();
  } catch (_) {
    return null;
  }
}

enum MessageType {
  text,
  gradientText,
  cyanOutlinedText,
  image,
  postShare,
}

class MessageReactionModel {
  const MessageReactionModel({
    required this.emoji,
    this.userId,
    this.username,
  });

  final String emoji;
  final String? userId;
  final String? username;

  factory MessageReactionModel.fromJson(dynamic json) {
    if (json is String) {
      return MessageReactionModel(emoji: json);
    }
    if (json is Map<String, dynamic>) {
      return MessageReactionModel(
        emoji: (json['emoji'] ?? '').toString(),
        userId: json['userId']?.toString() ??
            json['user']?['id']?.toString() ??
            json['user']?['_id']?.toString(),
        username: json['username']?.toString() ??
            json['user']?['username']?.toString(),
      );
    }
    return MessageReactionModel(emoji: json.toString());
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'emoji': emoji,
        if (userId != null) 'userId': userId,
        if (username != null) 'username': username,
      };
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.senderUsername,
    required this.isMe,
    required this.timestamp,
    this.conversationId,
    this.senderId,
    this.text,
    this.imageAsset,
    this.imageFilePath,
    this.mediaUrl,
    this.postThumbnailAsset,
    this.postAuthor,
    this.postAuthorId,
    this.postAuthorAvatarUrl,
    this.postCaption,
    this.postType,
    this.postLikes,
    this.postComments,
    this.sharedPostId,
    this.postViews,
    this.reactionEmoji,
    this.reactionCount,
    this.reactions = const <MessageReactionModel>[],
    this.isRead = false,
    this.isUnsent = false,
    this.unsentAt,
    this.createdAt,
    this.type = MessageType.text,
  });

  final String id;
  final String? conversationId;
  final String? senderId;
  final String senderUsername;
  final bool isMe;
  final String timestamp;
  final String? text;
  final String? imageAsset;
  final String? imageFilePath;
  final String? mediaUrl;
  final String? postThumbnailAsset;
  final String? postAuthor;
  final String? postAuthorId;
  final String? postAuthorAvatarUrl;
  final String? postCaption;
  final String? postType;
  final int? postLikes;
  final int? postComments;
  final String? sharedPostId;
  final String? postViews;
  final String? reactionEmoji;
  final int? reactionCount;
  final List<MessageReactionModel> reactions;
  final bool isRead;
  final bool isUnsent;
  final DateTime? unsentAt;
  final DateTime? createdAt;
  final MessageType type;

  factory ChatMessageModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final String msgId =
        (json['id'] ?? json['_id'] ?? json['messageId'] ?? '').toString();
    final String convId = (json['conversationId'] ?? '').toString();

    // Sender resolution
    final dynamic senderRaw = json['sender'];
    final String sId = (json['senderId'] ??
            (senderRaw is Map ? (senderRaw['id'] ?? senderRaw['_id']) : null) ??
            '')
        .toString();
    final String sUsername = (json['senderUsername'] ??
            (senderRaw is Map ? senderRaw['username'] : null) ??
            (sId == currentUserId ? 'me' : 'User'))
        .toString();

    final bool me = (currentUserId != null &&
            currentUserId.isNotEmpty &&
            sId.isNotEmpty)
        ? (sId == currentUserId)
        : (json['isMe'] == true || sUsername.toLowerCase() == 'me');

    final String? unsentRaw = json['unsentAt']?.toString() ??
        json['unsent_at']?.toString() ??
        json['deletedAt']?.toString() ??
        json['deleted_at']?.toString();
    final bool isUnsent = json['isUnsent'] == true ||
        json['isDeleted'] == true ||
        (unsentRaw != null && unsentRaw.isNotEmpty && unsentRaw != 'null');
    final DateTime? unsentTime =
        isUnsent && unsentRaw != null ? DateTime.tryParse(unsentRaw) : null;

    final String rawU = (sUsername.isNotEmpty && sUsername != 'User')
        ? sUsername
        : (senderRaw is Map
            ? (senderRaw['username'] ??
                senderRaw['name'] ??
                senderRaw['displayName'] ??
                'User')
            : 'User').toString();
    final String cleanUsername =
        rawU.startsWith('@') ? rawU.substring(1) : rawU;

    final String? body =
        (json['body'] ?? json['text'] ?? json['content'])?.toString();

    final String? rawMediaCandidate = isUnsent
        ? null
        : (json['mediaUrl'] ??
                json['imageUrl'] ??
                json['attachmentUrl'] ??
                json['mediaRef'] ??
                json['media'] ??
                json['attachment'])
            ?.toString();

    final bool isBodyImageUrl = !isUnsent &&
        body != null &&
        (body.trim().startsWith('http://') || body.trim().startsWith('https://')) &&
        (body.contains('/images/') ||
            body.contains('/media/') ||
            body.endsWith('.jpg') ||
            body.endsWith('.jpeg') ||
            body.endsWith('.png') ||
            body.endsWith('.webp') ||
            body.endsWith('.gif') ||
            body.contains('cloudfront.net'));

    final String? rawMedia = (rawMediaCandidate != null &&
            rawMediaCandidate.trim().isNotEmpty &&
            rawMediaCandidate.trim().toLowerCase() != 'null')
        ? rawMediaCandidate
        : (isBodyImageUrl ? body : null);

    final String? parsedText = isUnsent
        ? (me ? 'You unsent this message' : '$cleanUsername has unsent this message')
        : (isBodyImageUrl && (rawMediaCandidate == null || rawMediaCandidate.trim().isEmpty || rawMediaCandidate.trim().toLowerCase() == 'null') ? '' : body);

    final String? media = (rawMedia == null ||
            rawMedia.trim().isEmpty ||
            rawMedia.trim().toLowerCase() == 'null')
        ? null
        : (rawMedia.trim().startsWith('http') ||
                rawMedia.trim().startsWith('assets/')
            ? rawMedia.trim()
            : '${AppConfig.baseUrl.replaceAll(RegExp(r"/+$"), "")}/media/${rawMedia.trim().replaceAll(RegExp(r"^/media/"), "").replaceAll(RegExp(r"^/+"), "")}');

    // Parse reactions (supports List of reaction objects or Map format: {"😂": ["user_id"]})
    final List<MessageReactionModel> parsedReactions = <MessageReactionModel>[];
    final dynamic rawReactions = json['reactions'];
    if (rawReactions is List) {
      for (final dynamic r in rawReactions) {
        parsedReactions.add(MessageReactionModel.fromJson(r));
      }
    } else if (rawReactions is Map) {
      rawReactions.forEach((dynamic key, dynamic val) {
        final String emojiKey = key.toString().trim();
        if (emojiKey.isNotEmpty) {
          if (val is List) {
            for (final dynamic u in val) {
              parsedReactions.add(MessageReactionModel(
                emoji: emojiKey,
                userId: u?.toString(),
              ));
            }
          } else if (val is num) {
            for (int i = 0; i < val.toInt(); i++) {
              parsedReactions.add(MessageReactionModel(emoji: emojiKey));
            }
          } else if (val != null) {
            parsedReactions.add(MessageReactionModel(
              emoji: emojiKey,
              userId: val.toString(),
            ));
          }
        }
      });
    }

    String? singleEmoji = json['reactionEmoji']?.toString();
    if (singleEmoji != null && singleEmoji.trim().isEmpty) {
      singleEmoji = null;
    }
    int? count = json['reactionCount'] is num
        ? (json['reactionCount'] as num).toInt()
        : null;

    if (parsedReactions.isNotEmpty) {
      // Find my reaction or default to first
      final MessageReactionModel myReaction = parsedReactions.firstWhere(
        (MessageReactionModel r) =>
            currentUserId != null && r.userId == currentUserId,
        orElse: () => parsedReactions.first,
      );
      singleEmoji ??= myReaction.emoji;
      count ??= parsedReactions.length;
    }

    // Parse timestamp
    final DateTime? created =
        parseUtcToLocal(json['createdAt'] ?? json['created_at']);
    String timeFormatted = json['timestamp']?.toString() ?? '';
    if (timeFormatted.isNotEmpty && timeFormatted != 'null') {
      final DateTime? parsedTs = parseUtcToLocal(timeFormatted);
      if (parsedTs != null) {
        timeFormatted =
            '${parsedTs.hour.toString().padLeft(2, '0')}:${parsedTs.minute.toString().padLeft(2, '0')}';
      }
    } else if (created != null) {
      timeFormatted =
          '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
    }
    if (timeFormatted.isEmpty || timeFormatted == 'null') {
      timeFormatted = 'Just now';
    }

    // Shared post / content parsing
    final String? sharedPostId = (json['sharedPostId'] ??
            json['contentId'] ??
            (json['sharedContent'] is Map ? json['sharedContent']['id'] : null))
        ?.toString();

    final dynamic sharedContent = json['sharedContent'];

    final bool isSharedPost = (sharedPostId != null && sharedPostId.isNotEmpty) ||
        sharedContent != null ||
        json['type'] == 'postShare' ||
        json['postAuthor'] != null;

    String? postThumbnail =
        (json['postThumbnailAsset'] ?? json['thumbnailUrl'] ?? json['mediaUrl'])?.toString();
    String? postAuthorName = json['postAuthor']?.toString();
    String? postAuthorId = json['postAuthorId']?.toString();
    String? postAuthorAvatar = json['postAuthorAvatar']?.toString();
    String? postCaption = json['postCaption']?.toString();
    String? postType = json['postType']?.toString();
    String? postViews = json['postViews']?.toString();
    int? postLikes;
    int? postComments;

    if (sharedContent is Map) {
      final String rawType = (sharedContent['type'] ??
              sharedContent['postType'] ??
              sharedContent['contentType'] ??
              'post')
          .toString()
          .toLowerCase();
      postType = (rawType == 'video' || rawType == 'reel') ? 'reel' : 'post';
      postCaption ??= (sharedContent['body'] ??
              sharedContent['caption'] ??
              sharedContent['text'] ??
              sharedContent['content'])
          ?.toString();

      final dynamic rawMedia = sharedContent['mediaRefs'] ??
          sharedContent['media'] ??
          sharedContent['images'] ??
          sharedContent['imageUrls'] ??
          sharedContent['attachments'] ??
          sharedContent['thumbnailUrl'] ??
          sharedContent['imageUrl'] ??
          sharedContent['mediaUrl'] ??
          sharedContent['url'] ??
          sharedContent['downloadUrl'] ??
          sharedContent['videoUrl'];

      if (rawMedia is List && rawMedia.isNotEmpty) {
        final dynamic first = rawMedia.first;
        if (first is String && first.trim().isNotEmpty) {
          postThumbnail ??= first.trim();
        } else if (first is Map) {
          final dynamic u = first['thumbnailUrl'] ??
              first['url'] ??
              first['downloadUrl'] ??
              first['mediaUrl'] ??
              first['imageUrl'] ??
              first['path'];
          if (u != null && u.toString().trim().isNotEmpty) {
            postThumbnail ??= u.toString().trim();
          }
        }
      } else if (rawMedia is String && rawMedia.trim().isNotEmpty) {
        postThumbnail ??= rawMedia.trim();
      } else if (rawMedia is Map) {
        final dynamic u = rawMedia['thumbnailUrl'] ??
            rawMedia['url'] ??
            rawMedia['downloadUrl'] ??
            rawMedia['mediaUrl'] ??
            rawMedia['imageUrl'];
        if (u != null && u.toString().trim().isNotEmpty) {
          postThumbnail ??= u.toString().trim();
        }
      }

      final dynamic likesRaw = sharedContent['likeCount'] ??
          sharedContent['likesCount'] ??
          sharedContent['likes'] ??
          (sharedContent['_count'] is Map ? sharedContent['_count']['likes'] : null);
      if (likesRaw is num) postLikes = likesRaw.toInt();

      final dynamic commentsRaw = sharedContent['commentCount'] ??
          sharedContent['commentsCount'] ??
          sharedContent['comments'] ??
          (sharedContent['_count'] is Map ? sharedContent['_count']['comments'] : null);
      if (commentsRaw is num) postComments = commentsRaw.toInt();

      final dynamic author = sharedContent['author'] ?? sharedContent['user'];
      if (author is Map) {
        final String aUser = (author['username'] ?? '').toString().trim();
        final String aName = (author['displayName'] ?? author['name'] ?? '').toString().trim();
        if (aUser.isNotEmpty) {
          postAuthorName = aUser.startsWith('@') ? aUser : '@$aUser';
        } else if (aName.isNotEmpty) {
          postAuthorName = aName;
        }
        postAuthorAvatar ??=
            (author['avatarUrl'] ?? author['avatar'] ?? author['profilePicture'])?.toString();
        postAuthorId ??= (author['id'] ?? author['_id'] ?? author['userId'] ?? author['authorId'])?.toString();
      } else if (sharedContent['authorName'] != null) {
        final String an = sharedContent['authorName'].toString().trim();
        postAuthorName = an.startsWith('@') ? an : '@$an';
      }

      postAuthorId ??= (sharedContent['authorId'] ??
              sharedContent['author_id'] ??
              sharedContent['userId'] ??
              sharedContent['user_id'] ??
              sharedContent['creatorId'])
          ?.toString();

      if (postAuthorAvatar == null && sharedContent['authorAvatar'] != null) {
        postAuthorAvatar = sharedContent['authorAvatar'].toString().trim();
      }

      final dynamic rawViews = sharedContent['viewCount'] ??
          sharedContent['viewsCount'] ??
          sharedContent['views'] ??
          sharedContent['playCount'] ??
          sharedContent['playsCount'] ??
          sharedContent['plays'] ??
          (sharedContent['_count'] is Map
              ? (sharedContent['_count']['views'] ??
                  sharedContent['_count']['plays'])
              : null);
      if (rawViews != null) {
        final int v = (rawViews is num)
            ? rawViews.toInt()
            : int.tryParse(rawViews.toString()) ?? 0;
        if (v > 0) {
          if (v >= 1000000) {
            postViews = '${(v / 1000000).toStringAsFixed(1)}M';
          } else if (v >= 1000) {
            postViews = '${(v / 1000).toStringAsFixed(1)}K';
          } else {
            postViews = '$v';
          }
        }
      }

      if (postViews == null || postViews == '0') {
        final String? cleanId = (sharedPostId != null && sharedPostId.isNotEmpty)
            ? sharedPostId
            : sharedContent['id']?.toString() ?? sharedContent['_id']?.toString();
        if (cleanId != null && cleanId.isNotEmpty) {
          final SharedPostData? cached = SharedPostCache.get(cleanId);
          if (cached != null && cached.views > 0) {
            final int v = cached.views;
            if (v >= 1000000) {
              postViews = '${(v / 1000000).toStringAsFixed(1)}M';
            } else if (v >= 1000) {
              postViews = '${(v / 1000).toStringAsFixed(1)}K';
            } else {
              postViews = '$v';
            }
          }
        }
      }

      if (postViews == null) {
        if (postType == 'reel') {
          postViews = '0';
        } else if (postLikes != null && postLikes > 0) {
          postViews = '$postLikes ${postLikes == 1 ? 'like' : 'likes'}';
        }
      }
    }

    // Message type
    MessageType mType = MessageType.text;
    final String? rawMsgType = json['type']?.toString().toLowerCase();
    if (isSharedPost) {
      mType = MessageType.postShare;
    } else if ((media != null && media.isNotEmpty) ||
        rawMsgType == 'image' ||
        rawMsgType == 'photo') {
      mType = MessageType.image;
    } else if (me) {
      mType = MessageType.gradientText;
    }

    final dynamic readByRaw =
        json['readBy'] ?? json['read_by'] ?? json['seenBy'] ?? json['seen_by'];

    final bool readByMe = readByRaw is List &&
        currentUserId != null &&
        readByRaw.any((dynamic item) =>
            item.toString() == currentUserId ||
            (item is Map &&
                ((item['id'] ?? item['_id'] ?? item['userId'] ?? item['user_id'] ?? item['user'])?.toString() == currentUserId ||
                 (item['user'] is Map && (item['user']['id'] ?? item['user']['_id'])?.toString() == currentUserId))));

    final bool readByOther = readByRaw is List &&
        readByRaw.any((dynamic item) {
          final String? id = item is Map
              ? (item['id'] ??
                      item['_id'] ??
                      item['userId'] ??
                      item['user_id'] ??
                      item['user'] ??
                      (item['user'] is Map ? (item['user']['id'] ?? item['user']['_id']) : null))
                  ?.toString()
              : item.toString();
          return id != null && id.isNotEmpty && id != currentUserId;
        });

    final bool hasExplicitReadIndicator = json['readAt'] != null ||
        json['read_at'] != null ||
        json['seenAt'] != null ||
        json['seen_at'] != null ||
        json['status'] == 'read' ||
        json['status'] == 'seen';

    final bool serverConfirmedRead = json['read'] == true ||
        json['read'] == 'true' ||
        json['read'] == 1 ||
        json['isRead'] == true ||
        json['isRead'] == 'true' ||
        json['isRead'] == 1 ||
        json['is_read'] == true ||
        json['is_read'] == 'true' ||
        json['is_read'] == 1;

    final bool isMsgRead = me
        // For messages sent by ME (outgoing): read when recipient read it (confirmed by server, readByOther, or explicit indicator)
        ? (readByOther || hasExplicitReadIndicator || serverConfirmedRead)
        // For messages sent to ME (incoming): read when I have read it or backend confirms read
        : (readByMe || hasExplicitReadIndicator || serverConfirmedRead);

    return ChatMessageModel(
      id: msgId,
      conversationId: convId.isNotEmpty ? convId : null,
      senderId: sId.isNotEmpty ? sId : null,
      senderUsername: sUsername,
      isMe: me,
      timestamp: timeFormatted,
      text: parsedText,
      mediaUrl: media,
      postThumbnailAsset: postThumbnail,
      postAuthor: postAuthorName,
      postAuthorId: postAuthorId,
      postAuthorAvatarUrl: postAuthorAvatar,
      postCaption: postCaption,
      postType: postType,
      postLikes: postLikes,
      postComments: postComments,
      sharedPostId: sharedPostId,
      postViews: postViews,
      reactionEmoji: singleEmoji,
      reactionCount: count,
      reactions: parsedReactions,
      isRead: isMsgRead,
      isUnsent: isUnsent,
      unsentAt: unsentTime,
      createdAt: created,
      type: mType,
    );
  }

  ChatMessageModel copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderUsername,
    bool? isMe,
    String? timestamp,
    String? text,
    String? imageAsset,
    String? imageFilePath,
    String? mediaUrl,
    String? postThumbnailAsset,
    String? postAuthor,
    String? postAuthorId,
    String? postAuthorAvatarUrl,
    String? postCaption,
    String? postType,
    int? postLikes,
    int? postComments,
    String? sharedPostId,
    String? postViews,
    String? reactionEmoji,
    int? reactionCount,
    List<MessageReactionModel>? reactions,
    bool clearReaction = false,
    bool? isRead,
    bool? isUnsent,
    DateTime? unsentAt,
    DateTime? createdAt,
    MessageType? type,
  }) {
    return ChatMessageModel(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderUsername: senderUsername ?? this.senderUsername,
      isMe: isMe ?? this.isMe,
      timestamp: timestamp ?? this.timestamp,
      text: text ?? this.text,
      imageAsset: imageAsset ?? this.imageAsset,
      imageFilePath: imageFilePath ?? this.imageFilePath,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      postThumbnailAsset: postThumbnailAsset ?? this.postThumbnailAsset,
      postAuthor: postAuthor ?? this.postAuthor,
      postAuthorId: postAuthorId ?? this.postAuthorId,
      postAuthorAvatarUrl: postAuthorAvatarUrl ?? this.postAuthorAvatarUrl,
      postCaption: postCaption ?? this.postCaption,
      postType: postType ?? this.postType,
      postLikes: postLikes ?? this.postLikes,
      postComments: postComments ?? this.postComments,
      sharedPostId: sharedPostId ?? this.sharedPostId,
      postViews: postViews ?? this.postViews,
      reactionEmoji: clearReaction ? null : (reactionEmoji ?? this.reactionEmoji),
      reactionCount: clearReaction ? null : (reactionCount ?? this.reactionCount),
      reactions: clearReaction ? const <MessageReactionModel>[] : (reactions ?? this.reactions),
      isRead: isRead ?? this.isRead,
      isUnsent: isUnsent ?? this.isUnsent,
      unsentAt: unsentAt ?? this.unsentAt,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }
}

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.username,
    required this.avatarAsset,
    required this.lastMessage,
    required this.timeAgo,
    this.participantId,
    this.displayName,
    this.avatarUrl,
    this.unreadCount = 0,
    this.isTyping = false,
    this.isOnline = false,
    this.lastActive,
    this.isMuted = false,
    this.mutedUntil,
    this.hasStoryRing = false,
    this.lastMessageSenderId,
    this.messages = const <ChatMessageModel>[],
    this.lastMessageAt,
  });

  final String id;
  final String? participantId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String avatarAsset;
  final String lastMessage;
  final String timeAgo;
  final int unreadCount;
  final bool isTyping;
  final bool isOnline;
  final dynamic lastActive;
  final bool isMuted;
  final String? mutedUntil;
  final bool hasStoryRing;
  final String? lastMessageSenderId;
  final List<ChatMessageModel> messages;
  final DateTime? lastMessageAt;

  String get formattedLocalTime {
    final DateTime? dt = lastMessageAt ??
        (messages.isNotEmpty && messages.last.createdAt != null
            ? messages.last.createdAt
            : null);

    if (dt != null) {
      final DateTime local = dt.toLocal();
      final DateTime now = DateTime.now();
      final bool isToday = local.year == now.year &&
          local.month == now.month &&
          local.day == now.day;
      if (isToday) {
        final String hour = local.hour.toString().padLeft(2, '0');
        final String minute = local.minute.toString().padLeft(2, '0');
        return '$hour:$minute';
      }
      final DateTime yesterday = now.subtract(const Duration(days: 1));
      final bool isYesterday = local.year == yesterday.year &&
          local.month == yesterday.month &&
          local.day == yesterday.day;
      if (isYesterday) {
        return 'Yesterday';
      }
      final Duration diff = now.difference(local);
      if (diff.inDays < 7) {
        return '${diff.inDays}d';
      }
      return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}';
    }

    if (timeAgo.isNotEmpty && timeAgo != 'null') {
      final DateTime? parsed = parseUtcToLocal(timeAgo);
      if (parsed != null) {
        final DateTime now = DateTime.now();
        final bool isToday = parsed.year == now.year &&
            parsed.month == now.month &&
            parsed.day == now.day;
        if (isToday) {
          final String hour = parsed.hour.toString().padLeft(2, '0');
          final String minute = parsed.minute.toString().padLeft(2, '0');
          return '$hour:$minute';
        }
        final DateTime yesterday = now.subtract(const Duration(days: 1));
        if (parsed.year == yesterday.year &&
            parsed.month == yesterday.month &&
            parsed.day == yesterday.day) {
          return 'Yesterday';
        }
        return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}';
      }
      return timeAgo;
    }
    return '';
  }

  factory ConversationModel.fromJson(
    Map<String, dynamic> rawJson, {
    String? currentUserId,
  }) {
    final Map<String, dynamic> json =
        (rawJson['conversation'] is Map<String, dynamic>)
            ? rawJson['conversation'] as Map<String, dynamic>
            : ((rawJson['data'] is Map<String, dynamic>)
                ? rawJson['data'] as Map<String, dynamic>
                : rawJson);

    final String convId =
        (json['id'] ?? json['_id'] ?? json['conversationId'] ?? '').toString();

    // Extract the other participant
    String? pId;
    String pUsername = 'User';
    String? pDisplayName;
    String? pAvatarUrl;

    if (json['otherParticipant'] is Map<String, dynamic>) {
      final Map<String, dynamic> other =
          json['otherParticipant'] as Map<String, dynamic>;
      pId = (other['userId'] ?? other['id'] ?? other['_id'])?.toString();
      pUsername = (other['username'] ?? other['name'] ?? other['handle'] ?? 'User').toString();
      pDisplayName = (other['displayName'] ?? other['name'])?.toString();
      pAvatarUrl = (other['avatarUrl'] ?? other['avatar'] ?? other['profilePicture'])?.toString();
    } else if (json['participant'] is Map<String, dynamic>) {
      final Map<String, dynamic> part =
          json['participant'] as Map<String, dynamic>;
      pId = (part['id'] ?? part['_id'] ?? part['userId'] ?? part['user_id'])?.toString();
      pUsername = (part['username'] ?? part['name'] ?? 'User').toString();
      pDisplayName = part['displayName']?.toString();
      pAvatarUrl = (part['avatarUrl'] ?? part['avatar'])?.toString();
    } else if (json['participantA'] is Map<String, dynamic> || json['participantB'] is Map<String, dynamic>) {
      final Map<String, dynamic>? partA = json['participantA'] as Map<String, dynamic>?;
      final Map<String, dynamic>? partB = json['participantB'] as Map<String, dynamic>?;
      final String? idA = (partA?['id'] ?? partA?['_id'] ?? partA?['userId'])?.toString();
      final String? idB = (partB?['id'] ?? partB?['_id'] ?? partB?['userId'])?.toString();
      final Map<String, dynamic>? target = (currentUserId != null && idA == currentUserId)
          ? partB
          : ((currentUserId != null && idB == currentUserId) ? partA : (partB ?? partA));
      if (target != null) {
        pId = (target['id'] ?? target['_id'] ?? target['userId'])?.toString();
        pUsername = (target['username'] ?? target['name'] ?? target['handle'] ?? 'User').toString();
        pDisplayName = (target['displayName'] ?? target['name'])?.toString();
        pAvatarUrl = (target['avatarUrl'] ?? target['avatar'] ?? target['profilePicture'])?.toString();
      }
    } else if (json['otherUser'] is Map<String, dynamic> ||
        json['user'] is Map<String, dynamic> ||
        json['recipient'] is Map<String, dynamic>) {
      final Map<String, dynamic> uObj = (json['otherUser'] ?? json['user'] ?? json['recipient']) as Map<String, dynamic>;
      pId = (uObj['id'] ?? uObj['_id'] ?? uObj['userId'] ?? uObj['user_id'])?.toString();
      pUsername = (uObj['username'] ?? uObj['name'] ?? uObj['handle'] ?? 'User').toString();
      pDisplayName = (uObj['displayName'] ?? uObj['name'])?.toString();
      pAvatarUrl = (uObj['avatarUrl'] ?? uObj['avatar'] ?? uObj['profilePicture'])?.toString();
    } else if (json['participants'] is List) {
      final List<dynamic> parts = json['participants'] as List<dynamic>;
      // Find the other user
      for (final dynamic item in parts) {
        if (item is Map<String, dynamic>) {
          final String itemUserId = (item['id'] ??
                  item['_id'] ??
                  item['userId'] ??
                  item['user_id'] ??
                  (item['user'] is Map ? (item['user']['id'] ?? item['user']['_id']) : null))
              ?.toString() ??
              '';
          if (currentUserId == null || itemUserId != currentUserId) {
            pId = itemUserId;
            pUsername = (item['username'] ??
                    item['name'] ??
                    (item['user'] is Map ? item['user']['username'] : null) ??
                    'User')
                .toString();
            pDisplayName = item['displayName']?.toString();
            pAvatarUrl = (item['avatarUrl'] ?? item['avatar'])?.toString();
            break;
          }
        }
      }
    } else {
      pId = (json['participantId'] ??
              json['recipientId'] ??
              json['userId'] ??
              json['targetUserId'])
          ?.toString();
      pUsername = (json['username'] ?? 'User').toString();
      pDisplayName = json['displayName']?.toString();
      pAvatarUrl = (json['avatarUrl'] ?? json['avatar'])?.toString();
    }

    if (pId == null || pId.trim().isEmpty) {
      final String? pA = json['participantAId']?.toString();
      final String? pB = json['participantBId']?.toString();
      if (pA != null && pA.isNotEmpty && pA != currentUserId) {
        pId = pA;
      } else if (pB != null && pB.isNotEmpty && pB != currentUserId) {
        pId = pB;
      }
    }

    if (pId != null && pId.trim().isEmpty) {
      pId = null;
    } else if (pId != null) {
      pId = pId.trim();
    }

    // Hydrate from AuthorProfileCache if available
    if (pId != null && pId.isNotEmpty) {
      final AuthorInfo? cached = AuthorProfileCache.get(pId);
      if (cached != null) {
        if (pUsername == 'User' || pUsername.isEmpty) {
          pUsername = cached.username;
        }
        pDisplayName ??= cached.displayName;
        pAvatarUrl ??= cached.avatarUrl;
      }
    }

    // Last message extraction
    String lastMsgText = 'No messages yet';
    String? lastSender;
    DateTime? lastMsgTime;

    final dynamic lastMsgRaw = json['lastMessage'] ??
        json['last_message'] ??
        json['latestMessage'] ??
        json['latest_message'] ??
        json['recentMessage'] ??
        json['recent_message'] ??
        json['message'];

    if (lastMsgRaw is Map<String, dynamic>) {
      final String? unsentRaw = (lastMsgRaw['unsentAt'] ?? lastMsgRaw['unsent_at'])?.toString();
      final bool isLastUnsent = lastMsgRaw['isUnsent'] == true ||
          (unsentRaw != null && unsentRaw.isNotEmpty && unsentRaw != 'null');

      final String rawBody = (lastMsgRaw['body'] ??
              lastMsgRaw['text'] ??
              lastMsgRaw['content'] ??
              lastMsgRaw['message'] ??
              '')
          .toString();
      lastSender = (lastMsgRaw['senderId'] ??
              lastMsgRaw['sender_id'] ??
              lastMsgRaw['sender']?['id'] ??
              lastMsgRaw['sender']?['_id'])
          ?.toString();
      final bool isMe = (currentUserId != null && lastSender == currentUserId);
      lastMsgTime = parseUtcToLocal(
          lastMsgRaw['createdAt'] ?? lastMsgRaw['created_at']);

      if (isLastUnsent) {
        lastMsgText = isMe
            ? 'You unsent a message'
            : '${pUsername.replaceAll('@', '')} unsent a message';
      } else if (rawBody.trim().isNotEmpty) {
        lastMsgText = rawBody.trim();
      } else if (lastMsgRaw['sharedPostId'] != null ||
          lastMsgRaw['sharedContent'] != null) {
        lastMsgText = 'Shared a post';
      } else if (lastMsgRaw['mediaUrl'] != null ||
          lastMsgRaw['imageUrl'] != null ||
          lastMsgRaw['attachmentUrl'] != null ||
          lastMsgRaw['image'] != null) {
        lastMsgText = '📷 Photo';
      }
    } else if (lastMsgRaw is String && lastMsgRaw.trim().isNotEmpty) {
      lastMsgText = lastMsgRaw.trim();
    }

    // Fallback: check embedded messages array if lastMessage was not directly provided
    if ((lastMsgText == 'No messages yet' || lastMsgText.isEmpty) &&
        json['messages'] is List &&
        (json['messages'] as List).isNotEmpty) {
      final dynamic lastItem = (json['messages'] as List).last;
      if (lastItem is Map<String, dynamic>) {
        final String? unsentRaw = (lastItem['unsentAt'] ?? lastItem['unsent_at'])?.toString();
        final bool isLastUnsent = lastItem['isUnsent'] == true ||
            (unsentRaw != null && unsentRaw.isNotEmpty && unsentRaw != 'null');

        final String rawBody = (lastItem['body'] ??
                lastItem['text'] ??
                lastItem['content'] ??
                lastItem['message'] ??
                '')
            .toString();
        lastSender = (lastItem['senderId'] ??
                lastItem['sender_id'] ??
                lastItem['sender']?['id'] ??
                lastItem['sender']?['_id'])
            ?.toString();
        final bool isMe = (currentUserId != null && lastSender == currentUserId);
        lastMsgTime = parseUtcToLocal(
            lastItem['createdAt'] ?? lastItem['created_at']);

        if (isLastUnsent) {
          lastMsgText = isMe
              ? 'You unsent a message'
              : '${pUsername.replaceAll('@', '')} unsent a message';
        } else if (rawBody.trim().isNotEmpty) {
          lastMsgText = rawBody.trim();
        } else if (lastItem['sharedPostId'] != null ||
            lastItem['sharedContent'] != null) {
          lastMsgText = 'Shared a post';
        } else if (lastItem['mediaUrl'] != null ||
            lastItem['imageUrl'] != null ||
            lastItem['attachmentUrl'] != null) {
          lastMsgText = '📷 Photo';
        }
      }
    }

    // Format last message with 'You: ' prefix if sent by current user
    if (lastMsgText != 'No messages yet' &&
        lastSender != null &&
        currentUserId != null &&
        lastSender == currentUserId &&
        !lastMsgText.startsWith('You: ') &&
        !lastMsgText.startsWith('You unsent')) {
      lastMsgText = 'You: $lastMsgText';
    }

    // Fallback time to updatedAt
    lastMsgTime ??= parseUtcToLocal(
        json['updatedAt'] ?? json['updated_at']);

    String timeStr = (json['timeAgo'] ?? json['time_ago'])?.toString() ?? '';
    if (timeStr.isNotEmpty && timeStr != 'null') {
      final DateTime? parsed = parseUtcToLocal(timeStr);
      if (parsed != null) {
        lastMsgTime ??= parsed;
        final DateTime now = DateTime.now();
        if (parsed.year == now.year &&
            parsed.month == now.month &&
            parsed.day == now.day) {
          timeStr =
              '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
        } else {
          final DateTime yesterday = now.subtract(const Duration(days: 1));
          if (parsed.year == yesterday.year &&
              parsed.month == yesterday.month &&
              parsed.day == yesterday.day) {
            timeStr = 'Yesterday';
          } else {
            final Duration diff = now.difference(parsed);
            if (diff.inDays < 7) {
              timeStr = '${diff.inDays}d';
            } else {
              timeStr = '${(diff.inDays / 7).floor()}w';
            }
          }
        }
      }
    } else if (lastMsgTime != null) {
      final DateTime localTime = lastMsgTime;
      final DateTime now = DateTime.now();
      if (localTime.year == now.year &&
          localTime.month == now.month &&
          localTime.day == now.day) {
        timeStr =
            '${localTime.hour.toString().padLeft(2, '0')}:${localTime.minute.toString().padLeft(2, '0')}';
      } else {
        final DateTime yesterday = now.subtract(const Duration(days: 1));
        if (localTime.year == yesterday.year &&
            localTime.month == yesterday.month &&
            localTime.day == yesterday.day) {
          timeStr = 'Yesterday';
        } else {
          final Duration diff = now.difference(localTime);
          if (diff.inDays < 7) {
            timeStr = '${diff.inDays}d';
          } else {
            timeStr = '${(diff.inDays / 7).floor()}w';
          }
        }
      }
    }

    final bool muted = json['muted'] == true ||
        json['isMuted'] == true ||
        json['mutedUntil'] != null;

    final dynamic rawUnread = json['unreadCount'] ??
        json['unread_count'] ??
        json['unreadMessagesCount'] ??
        json['unread_messages_count'] ??
        json['unread'];

    int unread = 0;
    if (rawUnread != null && rawUnread is num) {
      unread = rawUnread.toInt();
    } else if (rawUnread == null && json['messages'] is List) {
      // Only fallback to counting if backend did not provide any unreadCount field at all
      final List<dynamic> msgList = json['messages'] as List<dynamic>;
      unread = msgList.where((dynamic m) {
        if (m is Map<String, dynamic>) {
          final String mSender = (m['senderId'] ??
                  m['sender_id'] ??
                  (m['sender'] is Map ? (m['sender']['id'] ?? m['sender']['_id']) : null))
              ?.toString() ??
              '';
          final bool isMe = currentUserId != null && mSender == currentUserId;
          final dynamic readByRaw = m['readBy'] ?? m['read_by'] ?? m['seenBy'] ?? m['seen_by'];
          final bool readByMe = readByRaw is List &&
              currentUserId != null &&
              readByRaw.any((dynamic item) =>
                  item.toString() == currentUserId ||
                  (item is Map &&
                      ((item['id'] ?? item['_id'] ?? item['userId'] ?? item['user_id'] ?? item['user'])?.toString() == currentUserId ||
                       (item['user'] is Map && (item['user']['id'] ?? item['user']['_id'])?.toString() == currentUserId))));
          final bool isRead = m['read'] == true ||
              m['isRead'] == true ||
              m['is_read'] == true ||
              m['readAt'] != null ||
              m['read_at'] != null ||
              m['seenAt'] != null ||
              m['seen_at'] != null ||
              m['status'] == 'read' ||
              m['status'] == 'seen' ||
              readByMe;
          return !isMe && !isRead;
        }
        return false;
      }).length;
    }

    final dynamic otherRaw = json['otherParticipant'] ?? json['participant'];
    final Map<String, dynamic>? otherMap =
        otherRaw is Map<String, dynamic> ? otherRaw : null;

    final bool online = json['isOnline'] == true ||
        json['online'] == true ||
        (otherMap != null &&
            (otherMap['isOnline'] == true ||
                otherMap['online'] == true));

    final dynamic lastActiveVal = json['lastActive'] ??
        json['last_active'] ??
        json['lastSeen'] ??
        json['last_seen'] ??
        (otherMap != null
            ? (otherMap['lastActive'] ??
                otherMap['last_active'] ??
                otherMap['lastSeen'] ??
                otherMap['last_seen'])
            : null);

    return ConversationModel(
      id: convId,
      participantId: pId,
      username: pUsername,
      displayName: pDisplayName,
      avatarUrl: pAvatarUrl,
      avatarAsset: (pAvatarUrl != null && pAvatarUrl.isNotEmpty)
          ? pAvatarUrl
          : AppImages.user1,
      lastMessage: lastMsgText,
      timeAgo: timeStr,
      unreadCount: unread,
      isOnline: online,
      lastActive: lastActiveVal,
      isMuted: muted,
      mutedUntil: json['mutedUntil']?.toString(),
      hasStoryRing: json['hasStoryRing'] == true,
      lastMessageSenderId: lastSender,
      lastMessageAt: lastMsgTime,
    );
  }

  ConversationModel copyWith({
    String? id,
    String? participantId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? avatarAsset,
    String? lastMessage,
    String? timeAgo,
    int? unreadCount,
    bool? isTyping,
    bool? isOnline,
    dynamic lastActive,
    bool? isMuted,
    String? mutedUntil,
    bool? hasStoryRing,
    String? lastMessageSenderId,
    List<ChatMessageModel>? messages,
    DateTime? lastMessageAt,
  }) {
    return ConversationModel(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      lastMessage: lastMessage ?? this.lastMessage,
      timeAgo: timeAgo ?? this.timeAgo,
      unreadCount: unreadCount ?? this.unreadCount,
      isTyping: isTyping ?? this.isTyping,
      isOnline: isOnline ?? this.isOnline,
      lastActive: lastActive ?? this.lastActive,
      isMuted: isMuted ?? this.isMuted,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      hasStoryRing: hasStoryRing ?? this.hasStoryRing,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      messages: messages ?? this.messages,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'participantId': participantId,
        'username': username,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
        'avatarAsset': avatarAsset,
        'lastMessage': lastMessage,
        'timeAgo': timeAgo,
        'unreadCount': unreadCount,
        'isTyping': isTyping,
        'isOnline': isOnline,
        'lastActive': lastActive?.toString(),
        'isMuted': isMuted,
        'mutedUntil': mutedUntil,
        'hasStoryRing': hasStoryRing,
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageAt': lastMessageAt?.toIso8601String(),
      };
}

class MessageRequestModel {
  const MessageRequestModel({
    required this.id,
    required this.username,
    required this.avatarAsset,
    required this.previewMessage,
    this.participantId,
    this.displayName,
    this.avatarUrl,
    this.createdAt,
    this.isOutgoing = false,
  });

  final String id;
  final String? participantId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String avatarAsset;
  final String previewMessage;
  final DateTime? createdAt;
  final bool isOutgoing;

  factory MessageRequestModel.fromJson(
    Map<String, dynamic> json, {
    String? currentUserId,
  }) {
    final String reqId =
        (json['id'] ?? json['_id'] ?? json['conversationId'] ?? '').toString();

    String? pId;
    String pUsername = 'User';
    String? pDisplayName;
    String? pAvatarUrl;

    if (json['otherParticipant'] is Map<String, dynamic>) {
      final Map<String, dynamic> other =
          json['otherParticipant'] as Map<String, dynamic>;
      pId = (other['userId'] ?? other['id'] ?? other['_id'])?.toString();
      pUsername = (other['username'] ?? other['name'] ?? other['handle'] ?? 'User').toString();
      pDisplayName = (other['displayName'] ?? other['name'])?.toString();
      pAvatarUrl = (other['avatarUrl'] ?? other['avatar'] ?? other['profilePicture'])?.toString();
    } else if (json['participant'] is Map<String, dynamic>) {
      final Map<String, dynamic> part =
          json['participant'] as Map<String, dynamic>;
      pId = (part['id'] ?? part['_id'] ?? part['userId'] ?? part['user_id'])?.toString();
      pUsername = (part['username'] ?? part['name'] ?? part['handle'] ?? 'User').toString();
      pDisplayName = (part['displayName'] ?? part['name'])?.toString();
      pAvatarUrl = (part['avatarUrl'] ?? part['avatar'] ?? part['profilePicture'])?.toString();
    } else if (json['sender'] is Map<String, dynamic>) {
      final Map<String, dynamic> sender =
          json['sender'] as Map<String, dynamic>;
      pId = (sender['id'] ?? sender['_id'] ?? sender['userId'] ?? sender['user_id'])?.toString();
      pUsername = (sender['username'] ?? sender['name'] ?? sender['handle'] ?? 'User').toString();
      pDisplayName = (sender['displayName'] ?? sender['name'])?.toString();
      pAvatarUrl = (sender['avatarUrl'] ?? sender['avatar'] ?? sender['profilePicture'])?.toString();
    } else if (json['user'] is Map<String, dynamic>) {
      final Map<String, dynamic> user =
          json['user'] as Map<String, dynamic>;
      pId = (user['id'] ?? user['_id'] ?? user['userId'] ?? user['user_id'])?.toString();
      pUsername = (user['username'] ?? user['name'] ?? user['handle'] ?? 'User').toString();
      pDisplayName = (user['displayName'] ?? user['name'])?.toString();
      pAvatarUrl = (user['avatarUrl'] ?? user['avatar'] ?? user['profilePicture'])?.toString();
    } else if (json['participants'] is List) {
      final List<dynamic> parts = json['participants'] as List<dynamic>;
      for (final dynamic item in parts) {
        if (item is Map<String, dynamic>) {
          final String itemUserId = (item['id'] ??
                  item['_id'] ??
                  item['userId'] ??
                  item['user_id'] ??
                  (item['user'] is Map ? (item['user']['id'] ?? item['user']['_id']) : null))
              ?.toString() ??
              '';
          if (currentUserId == null || itemUserId != currentUserId) {
            pId = itemUserId;
            pUsername = (item['username'] ??
                    item['name'] ??
                    (item['user'] is Map ? item['user']['username'] : null) ??
                    'User')
                .toString();
            pDisplayName = (item['displayName'] ?? item['name'])?.toString();
            pAvatarUrl = (item['avatarUrl'] ?? item['avatar'] ?? item['profilePicture'])?.toString();
            break;
          }
        }
      }
    } else {
      pId = (json['participantId'] ??
              json['senderId'] ??
              json['userId'] ??
              json['targetUserId'])
          ?.toString();
      pUsername = (json['username'] ?? 'User').toString();
      pDisplayName = json['displayName']?.toString();
      pAvatarUrl = (json['avatarUrl'] ?? json['avatar'])?.toString();
    }

    if (pId == null || pId.trim().isEmpty) {
      final String? initId = json['initiatorId']?.toString();
      final String? pA = json['participantAId']?.toString();
      final String? pB = json['participantBId']?.toString();
      if (initId != null && initId.isNotEmpty && initId != currentUserId) {
        pId = initId;
      } else if (pA != null && pA.isNotEmpty && pA != currentUserId) {
        pId = pA;
      } else if (pB != null && pB.isNotEmpty && pB != currentUserId) {
        pId = pB;
      }
    }

    if (pId != null && pId.trim().isEmpty) {
      pId = null;
    } else if (pId != null) {
      pId = pId.trim();
    }

    String preview = 'Sent you a message request';
    final dynamic lastMsgRaw = json['lastMessage'] ?? json['message'];
    String? lastSenderId;
    if (lastMsgRaw is Map<String, dynamic>) {
      lastSenderId = (lastMsgRaw['senderId'] ??
              lastMsgRaw['sender_id'] ??
              lastMsgRaw['userId'] ??
              (lastMsgRaw['sender'] is Map
                  ? (lastMsgRaw['sender']['id'] ??
                      lastMsgRaw['sender']['_id'])
                  : null))
          ?.toString();
      preview = (lastMsgRaw['body'] ??
              lastMsgRaw['text'] ??
              lastMsgRaw['content'] ??
              preview)
          .toString();
    } else if (lastMsgRaw is String && lastMsgRaw.isNotEmpty) {
      preview = lastMsgRaw;
    } else if (json['previewMessage'] != null) {
      preview = json['previewMessage'].toString();
    }

    final String? initiatorId = (json['initiatorId'] ??
            json['initiator_id'] ??
            json['senderId'] ??
            json['sender_id'])
        ?.toString();

    final bool isOutgoing = (currentUserId != null &&
            currentUserId.trim().isNotEmpty) &&
        ((lastSenderId != null &&
                lastSenderId.trim().toLowerCase() ==
                    currentUserId.trim().toLowerCase()) ||
            (initiatorId != null &&
                initiatorId.trim().toLowerCase() ==
                    currentUserId.trim().toLowerCase()) ||
            json['isOutgoing'] == true ||
            json['isSender'] == true);

    return MessageRequestModel(
      id: reqId,
      participantId: pId,
      username: pUsername,
      displayName: pDisplayName,
      avatarUrl: pAvatarUrl,
      avatarAsset: (pAvatarUrl != null && pAvatarUrl.isNotEmpty)
          ? pAvatarUrl
          : AppImages.user1,
      previewMessage: preview,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      isOutgoing: isOutgoing,
    );
  }
}

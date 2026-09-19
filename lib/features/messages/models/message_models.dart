import '../../../core/theme/app_images.dart';

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
    this.postViews,
    this.reactionEmoji,
    this.reactionCount,
    this.reactions = const <MessageReactionModel>[],
    this.isRead = false,
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
  final String? postViews;
  final String? reactionEmoji;
  final int? reactionCount;
  final List<MessageReactionModel> reactions;
  final bool isRead;
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

    final String? body =
        (json['body'] ?? json['text'] ?? json['content'])?.toString();
    final String? media =
        (json['mediaUrl'] ?? json['imageUrl'] ?? json['attachmentUrl'])
            ?.toString();

    // Parse reactions
    final List<MessageReactionModel> parsedReactions = <MessageReactionModel>[];
    if (json['reactions'] is List) {
      for (final dynamic r in json['reactions'] as List) {
        parsedReactions.add(MessageReactionModel.fromJson(r));
      }
    }

    String? singleEmoji = json['reactionEmoji']?.toString();
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
        DateTime.tryParse(json['createdAt']?.toString() ?? '');
    String timeFormatted = json['timestamp']?.toString() ?? '';
    if (timeFormatted.isEmpty && created != null) {
      timeFormatted =
          '${created.hour.toString().padLeft(2, '0')}:${created.minute.toString().padLeft(2, '0')}';
    }
    if (timeFormatted.isEmpty) {
      timeFormatted = 'Just now';
    }

    // Message type
    MessageType mType = MessageType.text;
    if (media != null && media.isNotEmpty) {
      mType = MessageType.image;
    } else if (json['type'] == 'postShare' || json['postAuthor'] != null) {
      mType = MessageType.postShare;
    } else if (me) {
      mType = MessageType.gradientText;
    }

    return ChatMessageModel(
      id: msgId,
      conversationId: convId.isNotEmpty ? convId : null,
      senderId: sId.isNotEmpty ? sId : null,
      senderUsername: sUsername,
      isMe: me,
      timestamp: timeFormatted,
      text: body,
      mediaUrl: media,
      reactionEmoji: singleEmoji,
      reactionCount: count,
      reactions: parsedReactions,
      isRead: json['read'] == true ||
          json['isRead'] == true ||
          json['readAt'] != null,
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
    String? postViews,
    String? reactionEmoji,
    int? reactionCount,
    List<MessageReactionModel>? reactions,
    bool? isRead,
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
      postViews: postViews ?? this.postViews,
      reactionEmoji: reactionEmoji ?? this.reactionEmoji,
      reactionCount: reactionCount ?? this.reactionCount,
      reactions: reactions ?? this.reactions,
      isRead: isRead ?? this.isRead,
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
    this.isMuted = false,
    this.mutedUntil,
    this.hasStoryRing = false,
    this.lastMessageSenderId,
    this.messages = const <ChatMessageModel>[],
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
  final bool isMuted;
  final String? mutedUntil;
  final bool hasStoryRing;
  final String? lastMessageSenderId;
  final List<ChatMessageModel> messages;

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

    if (json['participant'] is Map<String, dynamic>) {
      final Map<String, dynamic> part =
          json['participant'] as Map<String, dynamic>;
      pId = (part['id'] ?? part['_id'] ?? part['userId'] ?? part['user_id'])?.toString();
      pUsername = (part['username'] ?? part['name'] ?? 'User').toString();
      pDisplayName = part['displayName']?.toString();
      pAvatarUrl = (part['avatarUrl'] ?? part['avatar'])?.toString();
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

    if (pId != null && pId.trim().isEmpty) {
      pId = null;
    } else if (pId != null) {
      pId = pId.trim();
    }

    // Last message extraction
    String lastMsgText = 'No messages yet';
    String? lastSender;
    DateTime? lastMsgTime;

    final dynamic lastMsgRaw = json['lastMessage'];
    if (lastMsgRaw is Map<String, dynamic>) {
      lastMsgText = (lastMsgRaw['body'] ??
              lastMsgRaw['text'] ??
              lastMsgRaw['content'] ??
              'No messages yet')
          .toString();
      lastSender = (lastMsgRaw['senderId'] ?? lastMsgRaw['sender']?['id'])
          ?.toString();
      lastMsgTime =
          DateTime.tryParse(lastMsgRaw['createdAt']?.toString() ?? '');
    } else if (lastMsgRaw is String && lastMsgRaw.isNotEmpty) {
      lastMsgText = lastMsgRaw;
    }

    // Fallback time to updatedAt
    lastMsgTime ??= DateTime.tryParse(json['updatedAt']?.toString() ?? '');

    String timeStr = json['timeAgo']?.toString() ?? '';
    if (timeStr.isEmpty && lastMsgTime != null) {
      final Duration diff = DateTime.now().difference(lastMsgTime);
      if (diff.inMinutes < 1) {
        timeStr = 'Just now';
      } else if (diff.inMinutes < 60) {
        timeStr = '${diff.inMinutes}m';
      } else if (diff.inHours < 24) {
        timeStr = '${diff.inHours}h';
      } else if (diff.inDays < 7) {
        timeStr = '${diff.inDays}d';
      } else {
        timeStr = '${(diff.inDays / 7).floor()}w';
      }
    }

    final bool muted = json['muted'] == true ||
        json['isMuted'] == true ||
        json['mutedUntil'] != null;

    final int unread = json['unreadCount'] is num
        ? (json['unreadCount'] as num).toInt()
        : 0;

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
      isMuted: muted,
      mutedUntil: json['mutedUntil']?.toString(),
      hasStoryRing: json['hasStoryRing'] == true,
      lastMessageSenderId: lastSender,
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
    bool? isMuted,
    String? mutedUntil,
    bool? hasStoryRing,
    String? lastMessageSenderId,
    List<ChatMessageModel>? messages,
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
      isMuted: isMuted ?? this.isMuted,
      mutedUntil: mutedUntil ?? this.mutedUntil,
      hasStoryRing: hasStoryRing ?? this.hasStoryRing,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      messages: messages ?? this.messages,
    );
  }
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
  });

  final String id;
  final String? participantId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String avatarAsset;
  final String previewMessage;
  final DateTime? createdAt;

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

    if (json['participant'] is Map<String, dynamic>) {
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

    if (pId != null && pId.trim().isEmpty) {
      pId = null;
    } else if (pId != null) {
      pId = pId.trim();
    }

    String preview = 'Sent you a message request';
    final dynamic lastMsgRaw = json['lastMessage'] ?? json['message'];
    if (lastMsgRaw is Map<String, dynamic>) {
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
    );
  }
}

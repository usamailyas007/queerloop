enum MessageType {
  text,
  gradientText,
  cyanOutlinedText,
  image,
  postShare,
}

class ChatMessageModel {
  const ChatMessageModel({
    required this.id,
    required this.senderUsername,
    required this.isMe,
    required this.timestamp,
    this.text,
    this.imageAsset,
    this.imageFilePath,
    this.postThumbnailAsset,
    this.postAuthor,
    this.postViews,
    this.reactionEmoji,
    this.reactionCount,
    this.type = MessageType.text,
  });

  final String id;
  final String senderUsername;
  final bool isMe;
  final String timestamp;
  final String? text;
  final String? imageAsset;
  final String? imageFilePath;
  final String? postThumbnailAsset;
  final String? postAuthor;
  final String? postViews;
  final String? reactionEmoji;
  final int? reactionCount;
  final MessageType type;
}

class ConversationModel {
  const ConversationModel({
    required this.id,
    required this.username,
    required this.avatarAsset,
    required this.lastMessage,
    required this.timeAgo,
    this.unreadCount = 0,
    this.isTyping = false,
    this.isMuted = false,
    this.hasStoryRing = false,
    this.messages = const <ChatMessageModel>[],
  });

  final String id;
  final String username;
  final String avatarAsset;
  final String lastMessage;
  final String timeAgo;
  final int unreadCount;
  final bool isTyping;
  final bool isMuted;
  final bool hasStoryRing;
  final List<ChatMessageModel> messages;
}

class MessageRequestModel {
  const MessageRequestModel({
    required this.id,
    required this.username,
    required this.avatarAsset,
    required this.previewMessage,
  });

  final String id;
  final String username;
  final String avatarAsset;
  final String previewMessage;
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_images.dart';
import '../models/message_models.dart';

class MessagesProvider extends ChangeNotifier {
  // ── Search State ─────────────────────────────────────────────────────
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Mute / Block / Typing Settings Map ────────────────────────────────
  final Map<String, bool> _mutedUsers = <String, bool>{'kit.lumen': true};
  final Map<String, bool> _restrictedUsers = <String, bool>{};
  final Map<String, bool> _blockedUsers = <String, bool>{};
  final Map<String, bool> _typingIndicatorEnabled = <String, bool>{'jules.does': true};

  bool isMuted(String username) => _mutedUsers[username] ?? false;
  bool isRestricted(String username) => _restrictedUsers[username] ?? false;
  bool isBlocked(String username) => _blockedUsers[username] ?? false;
  bool isTypingIndicatorEnabled(String username) =>
      _typingIndicatorEnabled[username] ?? true;

  void toggleMute(String username) {
    _mutedUsers[username] = !isMuted(username);
    notifyListeners();
  }

  void toggleRestrict(String username) {
    _restrictedUsers[username] = !isRestricted(username);
    notifyListeners();
  }

  void toggleBlock(String username) {
    _blockedUsers[username] = !isBlocked(username);
    notifyListeners();
  }

  void toggleTypingIndicator(String username, bool enabled) {
    _typingIndicatorEnabled[username] = enabled;
    notifyListeners();
  }

  // ── Message Requests ─────────────────────────────────────────────────
  final List<MessageRequestModel> _messageRequests = <MessageRequestModel>[
    const MessageRequestModel(
      id: 'req1',
      username: 'finn.rides',
      avatarAsset: AppImages.user4,
      previewMessage: 'loved your post about the Tuesday call, mind if I...',
    ),
    const MessageRequestModel(
      id: 'req2',
      username: 'parker.osei',
      avatarAsset: AppImages.user2,
      previewMessage: "hey! saw we're both in the Bisexual community...",
    ),
    const MessageRequestModel(
      id: 'req3',
      username: 'dg_returns',
      avatarAsset: AppImages.user1,
      previewMessage: 'hey beautiful, add me on...',
    ),
  ];

  List<MessageRequestModel> get messageRequests =>
      List<MessageRequestModel>.unmodifiable(_messageRequests);

  void removeRequest(String id) {
    _messageRequests.removeWhere((MessageRequestModel req) => req.id == id);
    notifyListeners();
  }

  // ── Conversations ────────────────────────────────────────────────────
  final List<ConversationModel> _conversations = <ConversationModel>[
    const ConversationModel(
      id: 'c1',
      username: 'jules.does',
      avatarAsset: AppImages.user2,
      lastMessage: 'typing...',
      timeAgo: '2m',
      unreadCount: 2,
      isTyping: true,
      hasStoryRing: true,
      messages: <ChatMessageModel>[
        ChatMessageModel(
          id: 'm1',
          senderUsername: 'jules.does',
          isMe: false,
          timestamp: '9:12',
          text: "did you see rowan's six month video",
          type: MessageType.text,
        ),
        ChatMessageModel(
          id: 'm2',
          senderUsername: 'me',
          isMe: true,
          timestamp: '9:14',
          text: 'watched it twice already',
          type: MessageType.gradientText,
        ),
        ChatMessageModel(
          id: 'm3',
          senderUsername: 'jules.does',
          isMe: false,
          timestamp: '9:14',
          imageAsset: AppImages.searchResult1,
          reactionEmoji: '❤️',
          reactionCount: 2,
          type: MessageType.image,
        ),
        ChatMessageModel(
          id: 'm4',
          senderUsername: 'jules.does',
          isMe: false,
          timestamp: '9:15',
          text: 'brunch sunday? bringing the bad camera',
          type: MessageType.cyanOutlinedText,
        ),
      ],
    ),
    const ConversationModel(
      id: 'c2',
      username: 'rowankeeps',
      avatarAsset: AppImages.user1,
      lastMessage: 'Sent you a video',
      timeAgo: '1h',
      messages: <ChatMessageModel>[
        ChatMessageModel(
          id: 'rm1',
          senderUsername: 'me',
          isMe: true,
          timestamp: 'Sent 9:41',
          postThumbnailAsset: AppImages.forYouImg,
          postAuthor: "@ashinorbit's post",
          postViews: '12.4K',
          type: MessageType.postShare,
        ),
        ChatMessageModel(
          id: 'rm2',
          senderUsername: 'rowankeeps',
          isMe: false,
          timestamp: '9:42',
          text:
              'omg this is exactly the binder fit thing I was asking about 😭',
          type: MessageType.text,
        ),
      ],
    ),
    const ConversationModel(
      id: 'c3',
      username: 'moss.and.oat',
      avatarAsset: AppImages.user3,
      lastMessage: 'okay but the bookshelf is load bearing now',
      timeAgo: 'Yesterday',
    ),
    const ConversationModel(
      id: 'c4',
      username: 'theo.vance',
      avatarAsset: AppImages.user4,
      lastMessage: 'You: see you at 7 🙌',
      timeAgo: 'Tue',
    ),
    const ConversationModel(
      id: 'c5',
      username: 'kit.lumen',
      avatarAsset: AppImages.user1,
      lastMessage: 'Muted conversation',
      timeAgo: 'Mon',
      isMuted: true,
    ),
  ];

  List<ConversationModel> get conversations {
    if (_searchQuery.trim().isEmpty) return _conversations;
    return _conversations
        .where((ConversationModel c) =>
            c.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            c.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ── Delete Conversation State ─────────────────────────────────────────
  ConversationModel? _lastDeletedConv;
  int? _lastDeletedIndex;

  ConversationModel? get lastDeletedConv => _lastDeletedConv;

  void deleteConversation(String id) {
    final int idx =
        _conversations.indexWhere((ConversationModel c) => c.id == id);
    if (idx != -1) {
      _lastDeletedConv = _conversations[idx];
      _lastDeletedIndex = idx;
      _conversations.removeAt(idx);
      notifyListeners();
    }
  }

  void undoDeleteConversation() {
    if (_lastDeletedConv != null) {
      final int insertIdx = (_lastDeletedIndex != null &&
              _lastDeletedIndex! <= _conversations.length)
          ? _lastDeletedIndex!
          : _conversations.length;
      _conversations.insert(insertIdx, _lastDeletedConv!);
      _lastDeletedConv = null;
      _lastDeletedIndex = null;
      notifyListeners();
    }
  }

  void dismissDeletedBanner() {
    _lastDeletedConv = null;
    _lastDeletedIndex = null;
    notifyListeners();
  }

  // ── Reaction & Delete Message Methods ─────────────────────────────────
  void addReaction(String conversationId, String messageId, String emoji) {
    final int convIdx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    if (convIdx != -1) {
      final ConversationModel target = _conversations[convIdx];
      final List<ChatMessageModel> updatedMsgs =
          target.messages.map((ChatMessageModel msg) {
        if (msg.id == messageId) {
          return ChatMessageModel(
            id: msg.id,
            senderUsername: msg.senderUsername,
            isMe: msg.isMe,
            timestamp: msg.timestamp,
            text: msg.text,
            imageAsset: msg.imageAsset,
            postThumbnailAsset: msg.postThumbnailAsset,
            postAuthor: msg.postAuthor,
            postViews: msg.postViews,
            reactionEmoji: emoji,
            reactionCount:
                (msg.reactionEmoji == emoji) ? ((msg.reactionCount ?? 1) + 1) : 1,
            type: msg.type,
          );
        }
        return msg;
      }).toList();

      _conversations[convIdx] = ConversationModel(
        id: target.id,
        username: target.username,
        avatarAsset: target.avatarAsset,
        lastMessage: target.lastMessage,
        timeAgo: target.timeAgo,
        unreadCount: target.unreadCount,
        isTyping: target.isTyping,
        hasStoryRing: target.hasStoryRing,
        isMuted: target.isMuted,
        messages: updatedMsgs,
      );
      notifyListeners();
    }
  }

  void deleteMessage(String conversationId, String messageId) {
    final int convIdx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    if (convIdx != -1) {
      final ConversationModel target = _conversations[convIdx];
      final List<ChatMessageModel> updatedMsgs = target.messages
          .where((ChatMessageModel msg) => msg.id != messageId)
          .toList();

      final String newLastMsg = updatedMsgs.isNotEmpty
          ? (updatedMsgs.last.text ?? 'Media message')
          : 'No messages yet';

      _conversations[convIdx] = ConversationModel(
        id: target.id,
        username: target.username,
        avatarAsset: target.avatarAsset,
        lastMessage: newLastMsg,
        timeAgo: target.timeAgo,
        unreadCount: target.unreadCount,
        isTyping: target.isTyping,
        hasStoryRing: target.hasStoryRing,
        isMuted: target.isMuted,
        messages: updatedMsgs,
      );
      notifyListeners();
    }
  }

  // ── Send Message in Conversation ──────────────────────────────────────
  void sendMessage(String conversationId, String text) {
    final int idx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    if (idx != -1) {
      final ConversationModel target = _conversations[idx];
      final List<ChatMessageModel> updatedMsgs =
          List<ChatMessageModel>.from(target.messages)
            ..add(
              ChatMessageModel(
                id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                senderUsername: 'me',
                isMe: true,
                timestamp: 'Just now',
                text: text,
                type: MessageType.gradientText,
              ),
            );

      _conversations[idx] = ConversationModel(
        id: target.id,
        username: target.username,
        avatarAsset: target.avatarAsset,
        lastMessage: 'You: $text',
        timeAgo: 'Just now',
        unreadCount: 0,
        isTyping: false,
        hasStoryRing: target.hasStoryRing,
        messages: updatedMsgs,
      );
      notifyListeners();
    }
  }

  // ── Send Image Message in Conversation ────────────────────────────────
  void sendImageMessage(
    String conversationId, {
    String? imageFilePath,
    String? imageAsset,
  }) {
    final int idx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    if (idx != -1) {
      final ConversationModel target = _conversations[idx];
      final List<ChatMessageModel> updatedMsgs =
          List<ChatMessageModel>.from(target.messages)
            ..add(
              ChatMessageModel(
                id: 'm_${DateTime.now().millisecondsSinceEpoch}',
                senderUsername: 'me',
                isMe: true,
                timestamp: 'Just now',
                imageFilePath: imageFilePath,
                imageAsset: imageAsset,
                type: MessageType.image,
              ),
            );

      _conversations[idx] = ConversationModel(
        id: target.id,
        username: target.username,
        avatarAsset: target.avatarAsset,
        lastMessage: 'You: Sent an image',
        timeAgo: 'Just now',
        unreadCount: 0,
        isTyping: false,
        hasStoryRing: target.hasStoryRing,
        messages: updatedMsgs,
      );
      notifyListeners();
    }
  }
}

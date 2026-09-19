import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/api/api_exception.dart';
import '../models/message_models.dart';
import '../services/conversations_service.dart';

class MessagesProvider extends ChangeNotifier {
  MessagesProvider({
    ConversationsService? service,
    String? currentUserId,
  })  : _service = service,
        _currentUserId = currentUserId;

  ConversationsService? _service;
  String? _currentUserId;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_isDisposed) return;
    final WidgetsBinding binding = WidgetsBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.persistentCallbacks ||
        binding.schedulerPhase == SchedulerPhase.midFrameMicrotasks) {
      binding.addPostFrameCallback((_) {
        if (!_isDisposed) {
          super.notifyListeners();
        }
      });
    } else {
      super.notifyListeners();
    }
  }

  void updateAuth({String? userId, ConversationsService? service}) {
    bool shouldReload = false;
    if (userId != null && userId != _currentUserId) {
      _currentUserId = userId;
      shouldReload = true;
    }
    if (service != null && service != _service) {
      _service = service;
      shouldReload = true;
    }
    if (shouldReload) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        loadConversations();
        loadMessageRequests();
      });
    }
  }

  // ── Search State ───────────────────────────────────────────────────────────
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ── Mute / Block / Typing Settings ─────────────────────────────────────────
  final Map<String, bool> _mutedUsers = <String, bool>{};
  final Map<String, bool> _restrictedUsers = <String, bool>{};
  final Map<String, bool> _blockedUsers = <String, bool>{};
  final Map<String, bool> _typingIndicatorEnabled = <String, bool>{};

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

  // ── Loading Flags ──────────────────────────────────────────────────────────
  bool _isLoadingConversations = false;
  bool get isLoadingConversations => _isLoadingConversations;

  bool _isLoadingRequests = false;
  bool get isLoadingRequests => _isLoadingRequests;

  final Map<String, bool> _loadingMessagesMap = <String, bool>{};
  bool isLoadingMessages(String conversationId) =>
      _loadingMessagesMap[conversationId] ?? false;

  bool _isSendingMessage = false;
  bool get isSendingMessage => _isSendingMessage;

  // ── Message Requests ───────────────────────────────────────────────────────
  final List<MessageRequestModel> _messageRequests = <MessageRequestModel>[];
  List<MessageRequestModel> get messageRequests =>
      List<MessageRequestModel>.unmodifiable(_messageRequests);

  Future<void> loadMessageRequests({bool force = false}) async {
    if (_service == null) return;
    _isLoadingRequests = true;
    notifyListeners();

    try {
      final List<MessageRequestModel> items =
          await _service!.getMessageRequests(currentUserId: _currentUserId);
      _messageRequests.clear();
      _messageRequests.addAll(items);
    } catch (e) {
      debugPrint('Error loading message requests: $e');
    } finally {
      _isLoadingRequests = false;
      notifyListeners();
    }
  }

  Future<bool> acceptRequest(String conversationId) async {
    // Optimistic removal from requests
    _messageRequests.removeWhere((MessageRequestModel req) => req.id == conversationId);
    notifyListeners();

    if (_service != null) {
      final bool ok = await _service!.acceptRequest(conversationId);
      // Refresh inbox to display the newly accepted conversation
      await loadConversations();
      return ok;
    }
    return true;
  }

  Future<bool> rejectRequest(String conversationId) async {
    // Optimistic removal from requests
    _messageRequests.removeWhere((MessageRequestModel req) => req.id == conversationId);
    notifyListeners();

    if (_service != null) {
      return await _service!.rejectRequest(conversationId);
    }
    return true;
  }

  void removeRequest(String id) {
    rejectRequest(id);
  }

  // ── Conversations ──────────────────────────────────────────────────────────
  final List<ConversationModel> _conversations = <ConversationModel>[];
  final Map<String, List<ChatMessageModel>> _messagesByConvId =
      <String, List<ChatMessageModel>>{};

  List<ConversationModel> get conversations {
    if (_searchQuery.trim().isEmpty) return _conversations;
    return _conversations
        .where((ConversationModel c) =>
            c.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (c.displayName != null &&
                c.displayName!
                    .toLowerCase()
                    .contains(_searchQuery.toLowerCase())) ||
            c.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<ChatMessageModel> getMessagesFor(String conversationId) {
    return _messagesByConvId[conversationId] ?? const <ChatMessageModel>[];
  }

  Future<void> loadConversations({bool force = false}) async {
    if (_service == null) return;
    _isLoadingConversations = true;
    notifyListeners();

    try {
      final List<ConversationModel> items =
          await _service!.getConversations(currentUserId: _currentUserId);
      _conversations.clear();
      _conversations.addAll(items);
      // Sync muted map
      for (final ConversationModel c in items) {
        if (c.isMuted) {
          _mutedUsers[c.username] = true;
          _mutedUsers[c.id] = true;
        }
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<ConversationModel?> startConversation(String participantId) async {
    final String cleanId = participantId.trim();
    if (cleanId.isEmpty) {
      debugPrint('⚠️ [MessagesProvider] Cannot start conversation: participantId is empty.');
      return null;
    }
    if (_service == null) return null;

    // 1. Check existing in-memory conversations first
    final int existingIdx = _conversations.indexWhere((ConversationModel c) =>
        c.participantId == cleanId || c.id == cleanId);
    if (existingIdx != -1) {
      return _conversations[existingIdx];
    }

    // 2. If conversations list is empty, fetch from backend to see if one already exists
    if (_conversations.isEmpty) {
      try {
        await loadConversations();
        final int found = _conversations.indexWhere((ConversationModel c) =>
            c.participantId == cleanId || c.id == cleanId);
        if (found != -1) {
          return _conversations[found];
        }
      } catch (_) {}
    }

    try {
      final ConversationModel? conv = await _service!.startConversation(
        participantId: cleanId,
        currentUserId: _currentUserId,
      );

      if (conv != null) {
        final ConversationModel readyConv =
            (conv.participantId == null || conv.participantId!.trim().isEmpty)
                ? conv.copyWith(participantId: cleanId)
                : conv;

        final int existingIndex = _conversations
            .indexWhere((ConversationModel c) => c.id == readyConv.id);
        if (existingIndex != -1) {
          _conversations[existingIndex] = readyConv;
        } else {
          _conversations.insert(0, readyConv);
        }
        notifyListeners();
        return readyConv;
      }
    } on ApiException catch (e) {
      debugPrint('Error starting conversation: $e');
      // If startConversation failed with 409 (already exists on backend),
      // reload conversations and search again
      if (e.statusCode == 409) {
        try {
          await loadConversations();
          final int foundIdx = _conversations.indexWhere((ConversationModel c) =>
              c.participantId == cleanId || c.id == cleanId);
          if (foundIdx != -1) {
            return _conversations[foundIdx];
          }
        } catch (_) {}
      }
      rethrow;
    } catch (e) {
      debugPrint('Error starting conversation: $e');
      rethrow;
    }
    return null;
  }

  void updateConversation(ConversationModel updated) {
    final int idx = _conversations.indexWhere((ConversationModel c) =>
        c.id == updated.id ||
        (updated.participantId != null &&
            updated.participantId!.isNotEmpty &&
            c.participantId == updated.participantId));
    if (idx != -1) {
      _conversations[idx] = updated;
    } else {
      _conversations.insert(0, updated);
    }
    notifyListeners();
  }

  // ── Messages In Conversation ───────────────────────────────────────────────
  Future<void> loadMessages(String conversationId, {bool force = false}) async {
    if (_service == null) return;
    _loadingMessagesMap[conversationId] = true;
    notifyListeners();

    try {
      final List<ChatMessageModel> msgs = await _service!.getMessages(
        conversationId: conversationId,
        currentUserId: _currentUserId,
      );
      _messagesByConvId[conversationId] = msgs;

      // Also attach to conversation model if present
      final int idx =
          _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
      if (idx != -1) {
        _conversations[idx] = _conversations[idx].copyWith(messages: msgs);
      }
    } catch (e) {
      debugPrint('Error loading messages for $conversationId: $e');
    } finally {
      _loadingMessagesMap[conversationId] = false;
      notifyListeners();
    }
  }

  // ── Send Message ───────────────────────────────────────────────────────────
  Future<void> sendMessage(String conversationId, String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final String tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final ChatMessageModel optimisticMsg = ChatMessageModel(
      id: tempId,
      conversationId: conversationId,
      senderId: _currentUserId,
      senderUsername: 'me',
      isMe: true,
      timestamp: 'Just now',
      text: trimmed,
      type: MessageType.gradientText,
      createdAt: DateTime.now(),
    );

    // 1. Optimistic update to messages
    final List<ChatMessageModel> currentMsgs =
        List<ChatMessageModel>.from(_messagesByConvId[conversationId] ?? <ChatMessageModel>[])
          ..add(optimisticMsg);
    _messagesByConvId[conversationId] = currentMsgs;

    // 2. Optimistic update to conversation tile
    final int idx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(
        lastMessage: 'You: $trimmed',
        timeAgo: 'Just now',
        unreadCount: 0,
        messages: currentMsgs,
      );
    }
    notifyListeners();

    // 3. API Sync
    if (_service != null) {
      _isSendingMessage = true;
      try {
        String targetConvId = conversationId;
        final ConversationModel? conv =
            idx != -1 ? _conversations[idx] : null;

        // If conversation is not yet established on backend (e.g. dummy ID from UserProfile)
        if (conv == null ||
            conv.participantId == conversationId ||
            !conversationId.contains('-')) {
          final String? pId = conv?.participantId ??
              (conversationId.contains('-') ? conversationId : null);
          if (pId != null && pId.trim().isNotEmpty) {
            try {
              final ConversationModel? created =
                  await _service!.startConversation(
                participantId: pId.trim(),
                currentUserId: _currentUserId,
              );
              if (created != null) {
                targetConvId = created.id;
                final int existing = _conversations
                    .indexWhere((ConversationModel c) => c.id == created.id);
                if (existing != -1) {
                  _conversations[existing] = created;
                } else {
                  _conversations.insert(0, created);
                }
                if (targetConvId != conversationId) {
                  _messagesByConvId[targetConvId] =
                      _messagesByConvId[conversationId] ?? <ChatMessageModel>[];
                }
                notifyListeners();
              }
            } catch (e) {
              debugPrint('⚠️ [MessagesProvider] Error creating conv before send: $e');
              try {
                await loadConversations();
                final int foundIdx = _conversations.indexWhere(
                    (ConversationModel c) =>
                        c.participantId == pId || c.id == pId);
                if (foundIdx != -1) {
                  targetConvId = _conversations[foundIdx].id;
                  if (targetConvId != conversationId) {
                    _messagesByConvId[targetConvId] =
                        _messagesByConvId[conversationId] ?? <ChatMessageModel>[];
                  }
                  notifyListeners();
                }
              } catch (_) {}
            }
          }
        }

        final ChatMessageModel? serverMsg = await _service!.sendMessage(
          conversationId: targetConvId,
          body: trimmed,
          currentUserId: _currentUserId,
        );

        if (serverMsg != null) {
          final List<ChatMessageModel> targetMsgs =
              _messagesByConvId[targetConvId] ?? currentMsgs;
          final int msgIdx =
              targetMsgs.indexWhere((ChatMessageModel m) => m.id == tempId);
          if (msgIdx != -1) {
            targetMsgs[msgIdx] = serverMsg;
            _messagesByConvId[targetConvId] =
                List<ChatMessageModel>.from(targetMsgs);
            notifyListeners();
          }
        }
      } catch (e) {
        debugPrint('Error sending message: $e');
      } finally {
        _isSendingMessage = false;
        notifyListeners();
      }
    }
  }

  // ── Mark Message Read ──────────────────────────────────────────────────────
  Future<void> markMessageRead(String conversationId, String messageId) async {
    final List<ChatMessageModel>? msgs = _messagesByConvId[conversationId];
    if (msgs != null) {
      final int idx = msgs.indexWhere((ChatMessageModel m) => m.id == messageId);
      if (idx != -1 && !msgs[idx].isRead) {
        msgs[idx] = msgs[idx].copyWith(isRead: true);
        notifyListeners();
      }
    }

    if (_service != null) {
      await _service!.markMessageRead(
        conversationId: conversationId,
        messageId: messageId,
      );
    }
  }

  // ── Mark All Messages Read In Conversation ─────────────────────────────────
  Future<void> markAllMessagesAsRead(String conversationId) async {
    final List<ChatMessageModel>? msgs = _messagesByConvId[conversationId];
    if (msgs == null || msgs.isEmpty) return;

    final List<String> unreadIds = msgs
        .where((ChatMessageModel m) => !m.isMe && !m.isRead)
        .map((ChatMessageModel m) => m.id)
        .toList();

    if (unreadIds.isEmpty) return;

    for (final String msgId in unreadIds) {
      final int idx = msgs.indexWhere((ChatMessageModel m) => m.id == msgId);
      if (idx != -1) {
        msgs[idx] = msgs[idx].copyWith(isRead: true);
      }
    }

    final int convIdx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    if (convIdx != -1) {
      _conversations[convIdx] =
          _conversations[convIdx].copyWith(unreadCount: 0);
    }

    notifyListeners();

    if (_service != null) {
      for (final String msgId in unreadIds) {
        _service!.markMessageRead(
          conversationId: conversationId,
          messageId: msgId,
        );
      }
    }
  }

  // ── Unsend / Delete Message ────────────────────────────────────────────────
  Future<void> unsendMessage(String conversationId, String messageId) async {
    // 1. Optimistic removal
    final List<ChatMessageModel>? msgs = _messagesByConvId[conversationId];
    if (msgs != null) {
      msgs.removeWhere((ChatMessageModel m) => m.id == messageId);
      _messagesByConvId[conversationId] = List<ChatMessageModel>.from(msgs);

      // Update last message in conversation
      final int convIdx =
          _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
      if (convIdx != -1) {
        final String newLastMsg = msgs.isNotEmpty
            ? (msgs.last.text ?? 'Media message')
            : 'No messages yet';
        _conversations[convIdx] = _conversations[convIdx].copyWith(
          lastMessage: newLastMsg,
          messages: msgs,
        );
      }
      notifyListeners();
    }

    // 2. API Sync
    if (_service != null) {
      await _service!.unsendMessage(
        conversationId: conversationId,
        messageId: messageId,
      );
    }
  }

  void deleteMessage(String conversationId, String messageId) {
    unsendMessage(conversationId, messageId);
  }

  // ── Reactions ──────────────────────────────────────────────────────────────
  Future<void> toggleReaction(
    String conversationId,
    String messageId,
    String emoji,
  ) async {
    final List<ChatMessageModel>? msgs = _messagesByConvId[conversationId];
    if (msgs == null) return;

    final int idx = msgs.indexWhere((ChatMessageModel m) => m.id == messageId);
    if (idx == -1) return;

    final ChatMessageModel target = msgs[idx];
    final bool alreadyReactedWithEmoji = target.reactionEmoji == emoji;

    // 1. Optimistic update
    final ChatMessageModel updated;
    if (alreadyReactedWithEmoji) {
      updated = target.copyWith(
        reactionEmoji: null,
        reactionCount: (target.reactionCount ?? 1) > 1
            ? (target.reactionCount! - 1)
            : null,
      );
    } else {
      updated = target.copyWith(
        reactionEmoji: emoji,
        reactionCount: (target.reactionCount ?? 0) + 1,
      );
    }
    msgs[idx] = updated;
    _messagesByConvId[conversationId] = List<ChatMessageModel>.from(msgs);
    notifyListeners();

    // 2. API Sync
    if (_service != null) {
      if (alreadyReactedWithEmoji) {
        await _service!.removeReaction(
          conversationId: conversationId,
          messageId: messageId,
          emoji: emoji,
        );
      } else {
        await _service!.addReaction(
          conversationId: conversationId,
          messageId: messageId,
          emoji: emoji,
        );
      }
    }
  }

  void addReaction(String conversationId, String messageId, String emoji) {
    toggleReaction(conversationId, messageId, emoji);
  }

  // ── Mute / Unmute Conversation ─────────────────────────────────────────────
  Future<void> muteConversation(
    String conversationId, {
    String duration = '1_week',
  }) async {
    // 1. Optimistic update
    final int idx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(isMuted: true);
      _mutedUsers[_conversations[idx].username] = true;
      _mutedUsers[conversationId] = true;
      notifyListeners();
    }

    // 2. API Sync
    if (_service != null) {
      await _service!.muteConversation(
        conversationId: conversationId,
        duration: duration,
      );
    }
  }

  Future<void> unmuteConversation(String conversationId) async {
    // 1. Optimistic update
    final int idx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(isMuted: false);
      _mutedUsers.remove(_conversations[idx].username);
      _mutedUsers.remove(conversationId);
      notifyListeners();
    }

    // 2. API Sync
    if (_service != null) {
      await _service!.unmuteConversation(conversationId);
    }
  }

  // ── Delete Conversation For Self ───────────────────────────────────────────
  ConversationModel? _lastDeletedConv;
  int? _lastDeletedIndex;
  ConversationModel? get lastDeletedConv => _lastDeletedConv;

  Future<void> deleteConversation(String conversationId) async {
    final int idx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    if (idx != -1) {
      _lastDeletedConv = _conversations[idx];
      _lastDeletedIndex = idx;
      _conversations.removeAt(idx);
      _messagesByConvId.remove(conversationId);
      notifyListeners();

      if (_service != null) {
        await _service!.deleteConversation(conversationId);
      }
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

  // ── Send Image Message ─────────────────────────────────────────────────────
  void sendImageMessage(
    String conversationId, {
    String? imageFilePath,
    String? imageAsset,
  }) {
    final List<ChatMessageModel> currentMsgs = List<ChatMessageModel>.from(
        _messagesByConvId[conversationId] ?? <ChatMessageModel>[])
      ..add(
        ChatMessageModel(
          id: 'm_${DateTime.now().millisecondsSinceEpoch}',
          conversationId: conversationId,
          senderId: _currentUserId,
          senderUsername: 'me',
          isMe: true,
          timestamp: 'Just now',
          imageFilePath: imageFilePath,
          imageAsset: imageAsset,
          type: MessageType.image,
          createdAt: DateTime.now(),
        ),
      );

    _messagesByConvId[conversationId] = currentMsgs;

    final int idx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    if (idx != -1) {
      _conversations[idx] = _conversations[idx].copyWith(
        lastMessage: 'You: Sent an image',
        timeAgo: 'Just now',
        unreadCount: 0,
        messages: currentMsgs,
      );
    }
    notifyListeners();
  }
}

import 'dart:async' show StreamSubscription, Timer;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_exception.dart';
import '../../create_post/models/create_post_models.dart';
import '../../create_post/services/media_upload_service.dart';
import '../../create_post/services/post_content_service.dart';
import '../models/message_models.dart';
import '../services/chat_socket_service.dart';
import '../services/conversations_service.dart';

class MessagesProvider extends ChangeNotifier {
  MessagesProvider({
    ConversationsService? service,
    ChatSocketService? socketService,
    String? currentUserId,
    String? token,
  })  : _service = service,
        _socketService = socketService,
        _currentUserId = currentUserId {
    _loadPersistedReadStates();
    _attachSocketListeners();
    loadBlockedUsers();
    if (token != null && token.isNotEmpty) {
      _token = token;
      _socketService?.connect(token: token, currentUserId: currentUserId);
      if (currentUserId != null && currentUserId.isNotEmpty) {
        _socketService?.joinUserRoom(currentUserId);
      }
    }
  }

  ConversationsService? _service;
  ChatSocketService? _socketService;
  String? _currentUserId;
  String? get currentUserId => _currentUserId;
  String? _token;
  String? get token => _token;
  bool _isDisposed = false;
  Timer? _pollTimer;
  String? _activeChatConvId;

  // Socket event subscriptions
  StreamSubscription<bool>? _subConnection;
  StreamSubscription<SocketNewMessageEvent>? _subNewMessage;
  StreamSubscription<SocketMessageReadEvent>? _subMessageRead;
  StreamSubscription<SocketReactionEvent>? _subReaction;
  StreamSubscription<SocketUserPresenceEvent>? _subPresence;
  StreamSubscription<SocketTypingEvent>? _subTyping;

  // Presence & Typing State
  final Map<String, String> _userPresenceMap = <String, String>{};
  final Map<String, dynamic> _userLastActiveMap = <String, dynamic>{};
  final Map<String, bool> _typingByConvId = <String, bool>{};
  final Map<String, Timer> _typingResetTimers = <String, Timer>{};

  bool isUserOnline(String? userId, [ConversationModel? conv]) {
    if (userId != null && userId.isNotEmpty) {
      if (userId == _currentUserId) return false;
      final String? status = _userPresenceMap[userId];
      if (status != null) {
        final String s = status.toLowerCase().trim();
        if (s == 'online' || s == 'active') return true;
        if (s == 'offline') return false;
      }
      final String clean = userId.startsWith('@') ? userId.substring(1) : userId;
      final String? statusClean = _userPresenceMap[clean] ?? _userPresenceMap['@$clean'];
      if (statusClean != null) {
        final String s = statusClean.toLowerCase().trim();
        if (s == 'online' || s == 'active') return true;
        if (s == 'offline') return false;
      }

      final dynamic la = _userLastActiveMap[userId] ??
          _userLastActiveMap[clean] ??
          _userLastActiveMap['@$clean'];
      if (la != null) {
        if (la is String &&
            (la.toLowerCase() == 'active now' ||
                la.toLowerCase() == 'online' ||
                la.toLowerCase() == 'active')) {
          return true;
        }
        final DateTime? dt =
            la is DateTime ? la : (la is String ? DateTime.tryParse(la) : null);
        if (dt != null && DateTime.now().difference(dt).inMinutes.abs() <= 3) {
          return true;
        }
      }
    }
    if (conv != null) {
      if (conv.participantId != null && conv.participantId == _currentUserId) {
        return false;
      }
      if (conv.participantId != null && _userPresenceMap.containsKey(conv.participantId!)) {
        final String s = _userPresenceMap[conv.participantId!]!.toLowerCase().trim();
        if (s == 'online' || s == 'active') return true;
        if (s == 'offline') return false;
      }
      if (_userPresenceMap.containsKey(conv.id)) {
        final String s = _userPresenceMap[conv.id]!.toLowerCase().trim();
        if (s == 'online' || s == 'active') return true;
        if (s == 'offline') return false;
      }
      final String cleanU = conv.username.startsWith('@') ? conv.username.substring(1) : conv.username;
      if (_userPresenceMap.containsKey(cleanU)) {
        final String s = _userPresenceMap[cleanU]!.toLowerCase().trim();
        if (s == 'online' || s == 'active') return true;
        if (s == 'offline') return false;
      }
      if (conv.isOnline) return true;

      final dynamic la = conv.lastActive;
      if (la != null) {
        if (la is String &&
            (la.toLowerCase() == 'active now' ||
                la.toLowerCase() == 'online' ||
                la.toLowerCase() == 'active')) {
          return true;
        }
        final DateTime? dt =
            la is DateTime ? la : (la is String ? DateTime.tryParse(la) : null);
        if (dt != null && DateTime.now().difference(dt).inMinutes.abs() <= 3) {
          return true;
        }
      }
    }
    return false;
  }

  String? getUserPresence(String? userId) =>
      userId != null ? _userPresenceMap[userId] : null;

  String? getUserLastActiveText(String? userId, [ConversationModel? conv]) {
    if (isUserOnline(userId, conv)) {
      return 'Active now';
    }
    dynamic lastActive;
    if (userId != null && userId.isNotEmpty) {
      lastActive = _userLastActiveMap[userId];
    }
    if (lastActive == null && conv != null) {
      lastActive = conv.lastActive;
    }
    if (lastActive == null) return null;

    DateTime? dt;
    if (lastActive is DateTime) {
      dt = lastActive;
    } else if (lastActive is String) {
      dt = DateTime.tryParse(lastActive);
    } else if (lastActive is num) {
      dt = DateTime.fromMillisecondsSinceEpoch(lastActive.toInt());
    }

    if (dt != null) {
      final Duration diff = DateTime.now().difference(dt);
      final int diffMins = diff.inMinutes;
      if (diffMins.abs() < 1) {
        return 'Active just now';
      } else if (diffMins > 0 && diffMins < 60) {
        return 'Active ${diffMins}m ago';
      } else if (diff.inHours > 0 && diff.inHours < 24) {
        return 'Active ${diff.inHours}h ago';
      } else if (diff.inDays == 1) {
        return 'Active yesterday';
      } else if (diff.inDays > 1 && diff.inDays < 7) {
        return 'Active ${diff.inDays}d ago';
      } else if (diff.inDays >= 7) {
        return 'Active ${(diff.inDays / 7).floor()}w ago';
      }
    }

    final String str = lastActive.toString().trim();
    if (str.isEmpty ||
        str.toLowerCase() == 'active' ||
        str.toLowerCase() == 'online' ||
        str.toLowerCase() == 'offline') {
      return null;
    }
    return str.toLowerCase().startsWith('active') ? str : 'Active $str';
  }

  bool isConversationTyping(String? convId) {
    if (convId == null || convId.isEmpty) return false;
    if (_typingByConvId[convId] == true) return true;
    final String clean = convId.startsWith('@') ? convId.substring(1) : convId;
    if (_typingByConvId[clean] == true) return true;
    if (_typingByConvId['@$clean'] == true) return true;
    for (final ConversationModel c in _conversations) {
      if (c.id == convId ||
          c.participantId == convId ||
          c.username == convId ||
          c.username == clean ||
          c.username == '@$clean') {
        if (c.isTyping) return true;
        if (c.participantId != null &&
            _typingByConvId[c.participantId!] == true) {
          return true;
        }
        if (_typingByConvId[c.id] == true) return true;
        if (_typingByConvId[c.username] == true) return true;
      }
    }
    return false;
  }

  final Set<String> _locallyReadMessageIds = <String>{};
  final Set<String> _readSentMessageIds = <String>{};
  final Map<String, String> _readSentMessageTime = <String, String>{};
  final Map<String, String> _localReactionMap = <String, String>{};
  final Map<String, DateTime> _lastReadTimeByConv = <String, DateTime>{};

  bool isMessageSentRead(String messageId) =>
      _readSentMessageIds.contains(messageId);

  String? getReadTime(String messageId) => _readSentMessageTime[messageId];

  /// Returns the latest stored timestamp string for [messageId] across all
  /// conversation message maps. Used so ChatBubble can reactively show the
  /// updated "Read HH:mm" time without needing the user to navigate away.
  String? getMessageTimestamp(String messageId) {
    if (_readSentMessageTime.containsKey(messageId)) {
      return _readSentMessageTime[messageId];
    }
    for (final List<ChatMessageModel> msgs in _messagesByConvId.values) {
      for (final ChatMessageModel m in msgs) {
        if (m.id == messageId) {
          if (_readSentMessageTime.containsKey(m.id)) {
            return _readSentMessageTime[m.id];
          }
          return m.timestamp;
        }
      }
    }
    return null;
  }

  Future<void> _loadPersistedReadStates() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String userSuffix = _currentUserId ?? 'guest';
      final List<String>? savedIds =
          prefs.getStringList('locally_read_msg_ids_$userSuffix');
      if (savedIds != null && savedIds.isNotEmpty) {
        _locallyReadMessageIds.addAll(savedIds);
      }
      final String? rawMap = prefs.getString('last_read_conv_$userSuffix');
      if (rawMap != null && rawMap.isNotEmpty) {
        final dynamic decoded = jsonDecode(rawMap);
        if (decoded is Map<String, dynamic>) {
          for (final MapEntry<String, dynamic> entry in decoded.entries) {
            final DateTime? dt = DateTime.tryParse(entry.value.toString());
            if (dt != null) {
              _lastReadTimeByConv[entry.key] = dt;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ [MessagesProvider] Error loading persisted read states: $e');
    }
  }

  Future<void> _persistReadStates() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String userSuffix = _currentUserId ?? 'guest';
      await prefs.setStringList(
        'locally_read_msg_ids_$userSuffix',
        _locallyReadMessageIds.take(1500).toList(),
      );
      final Map<String, String> mapToSave = <String, String>{};
      for (final MapEntry<String, DateTime> entry in _lastReadTimeByConv.entries) {
        mapToSave[entry.key] = entry.value.toIso8601String();
      }
      await prefs.setString(
        'last_read_conv_$userSuffix',
        jsonEncode(mapToSave),
      );
    } catch (e) {
      debugPrint('⚠️ [MessagesProvider] Error saving read states: $e');
    }
  }

  List<ChatMessageModel> _applyReadStatesToMessages(
    String conversationId,
    List<ChatMessageModel> rawMessages,
  ) {
    if (rawMessages.isEmpty) return rawMessages;
    final DateTime? lastReadTime = _lastReadTimeByConv[conversationId];
    return rawMessages.map((ChatMessageModel m) {
      ChatMessageModel processed = m;

      // 1. Preserve optimistic or local reaction so it never vanishes on poll/refresh
      final String? cachedEmoji = _localReactionMap[m.id];
      if (cachedEmoji != null &&
          (processed.reactionEmoji == null || processed.reactionEmoji!.isEmpty)) {
        processed = processed.copyWith(
          reactionEmoji: cachedEmoji,
          reactionCount: (processed.reactionCount ?? 0) > 0
              ? processed.reactionCount
              : 1,
        );
      }

      if (processed.isRead) return processed;

      // 2. Local read states for INCOMING messages (!m.isMe)
      if (!processed.isMe) {
        if (_locallyReadMessageIds.contains(processed.id)) {
          return processed.copyWith(isRead: true);
        }
        if (lastReadTime != null &&
            processed.createdAt != null &&
            !processed.createdAt!.isAfter(lastReadTime)) {
          return processed.copyWith(isRead: true);
        }
      } else {
        // 3. Sent messages read by recipient
        if (_readSentMessageIds.contains(processed.id)) {
          return processed.copyWith(isRead: true);
        }
      }
      return processed;
    }).toList();
  }

  int _calculateUnreadForConversation(
    String conversationId,
    List<ChatMessageModel> messages, {
    int defaultUnread = 0,
    DateTime? lastMessageAt,
  }) {
    if (_activeChatConvId == conversationId) return 0;

    if (messages.isNotEmpty) {
      return messages.where((ChatMessageModel m) => !m.isMe && !m.isRead).length;
    }

    if (_lastReadTimeByConv.containsKey(conversationId)) {
      final DateTime lastRead = _lastReadTimeByConv[conversationId]!;
      if (lastMessageAt != null && !lastMessageAt.isAfter(lastRead)) {
        return 0;
      }
    }

    return defaultUnread;
  }

  String? get activeChatConvId => _activeChatConvId;

  void setActiveChat(String? conversationId) {
    _activeChatConvId = conversationId;
    if (conversationId != null && conversationId.isNotEmpty) {
      joinConversation(conversationId);
      _socketService?.sendPresence(isOnline: true, conversationId: conversationId);
      final int idx = _conversations.indexWhere((ConversationModel c) =>
          c.id == conversationId || c.participantId == conversationId);
      if (idx != -1) {
        final String? pId = _conversations[idx].participantId;
        if (pId != null && pId.isNotEmpty && pId != conversationId) {
          joinConversation(pId);
          _socketService?.sendPresence(isOnline: true, conversationId: pId);
        }
      }
    } else {
      _socketService?.sendPresence(isOnline: true);
    }
  }

  void joinConversation(String conversationId) {
    _socketService?.joinConversation(conversationId);
  }

  void sendTyping(String conversationId, bool isTyping) {
    if (conversationId.isEmpty) return;
    final int idx = _conversations.indexWhere((ConversationModel c) =>
        c.id == conversationId || c.participantId == conversationId);
    if (idx != -1) {
      final ConversationModel c = _conversations[idx];
      // If user disabled typing indicator for this chat, don't broadcast typing start
      if (isTyping &&
          (!isTypingIndicatorEnabled(c.username) ||
              !isTypingIndicatorEnabled(c.id) ||
              (c.participantId != null &&
                  !isTypingIndicatorEnabled(c.participantId!)))) {
        return;
      }
    }

    _socketService?.sendTyping(
      conversationId: conversationId,
      isTyping: isTyping,
      userId: _currentUserId,
    );
    if (idx != -1) {
      final String? pId = _conversations[idx].participantId;
      if (pId != null && pId.isNotEmpty && pId != conversationId) {
        _socketService?.sendTyping(
          conversationId: pId,
          isTyping: isTyping,
          userId: _currentUserId,
        );
      }
    }
  }

  void _attachSocketListeners() {
    _cancelSocketSubscriptions();
    if (_socketService == null) return;

    _subConnection =
        _socketService!.onConnectionChanged.listen((bool isConnected) {
      if (!isConnected &&
          _currentUserId != null &&
          _currentUserId!.isNotEmpty) {
        final String? fresh = _service?.client.authToken;
        if (fresh != null &&
            fresh.isNotEmpty &&
            fresh != _token &&
            fresh != _socketService?.token) {
          debugPrint(
              '🔄 [MessagesProvider] Found newer token from ApiClient. Reconnecting socket...');
          _token = fresh;
          _socketService?.connect(
            token: fresh,
            currentUserId: _currentUserId,
          );
        }
      }
    });

    _subNewMessage =
        _socketService!.onNewMessage.listen(_handleSocketNewMessage);
    _subMessageRead =
        _socketService!.onMessageRead.listen(_handleSocketMessageRead);
    _subReaction =
        _socketService!.onReactionAdded.listen(_handleSocketReaction);
    _subPresence =
        _socketService!.onUserPresence.listen(_handleSocketPresence);
    _subTyping = _socketService!.onTyping.listen(_handleSocketTyping);
  }

  void _cancelSocketSubscriptions() {
    _subConnection?.cancel();
    _subConnection = null;
    _subNewMessage?.cancel();
    _subNewMessage = null;
    _subMessageRead?.cancel();
    _subMessageRead = null;
    _subReaction?.cancel();
    _subReaction = null;
    _subPresence?.cancel();
    _subPresence = null;
    _subTyping?.cancel();
    _subTyping = null;
  }

  void _handleSocketNewMessage(SocketNewMessageEvent event) {
    if (event.conversationId.isEmpty || event.messageId.isEmpty) return;

    final String convId = event.conversationId;
    _typingByConvId[convId] = false;
    if (event.senderId.isNotEmpty) {
      _typingByConvId[event.senderId] = false;
      final String cleanU = event.senderId.startsWith('@')
          ? event.senderId.substring(1)
          : event.senderId;
      _typingByConvId[cleanU] = false;
      _typingByConvId['@$cleanU'] = false;
    }
    final int typingConvIdx = _conversations.indexWhere((ConversationModel c) =>
        c.id == convId ||
        c.participantId == convId ||
        c.participantId == event.senderId);
    if (typingConvIdx != -1) {
      _conversations[typingConvIdx] =
          _conversations[typingConvIdx].copyWith(isTyping: false);
    }

    final List<ChatMessageModel> msgs = List<ChatMessageModel>.from(
        _messagesByConvId[convId] ?? <ChatMessageModel>[]);

    // 1. Deduplicate if this message ID was already added
    final bool alreadyExists =
        msgs.any((ChatMessageModel m) => m.id == event.messageId);
    if (alreadyExists) return;

    final bool isFromMe = (event.senderId.isNotEmpty &&
        event.senderId == _currentUserId);

    // 2. Reconcile with optimistic message if sent by me
    if (isFromMe) {
      final int tempIdx = msgs.indexWhere((ChatMessageModel m) =>
          m.id.startsWith('temp_') &&
          (m.text == event.body || event.body.isEmpty));
      if (tempIdx != -1) {
        msgs[tempIdx] = msgs[tempIdx].copyWith(id: event.messageId);
        _messagesByConvId[convId] = msgs;
        notifyListeners();
        return;
      }
    }

    // 3. Construct new chat message
    final bool isRead = isFromMe || _activeChatConvId == convId;
    final ChatMessageModel newMsg;
    if (event.raw.isNotEmpty) {
      newMsg = ChatMessageModel.fromJson(
        event.raw,
        currentUserId: _currentUserId,
      ).copyWith(
        id: event.messageId,
        conversationId: convId,
        isRead: isRead,
        isMe: isFromMe,
      );
    } else {
      newMsg = ChatMessageModel(
        id: event.messageId,
        conversationId: convId,
        senderId: event.senderId,
        senderUsername: isFromMe ? 'me' : 'User',
        isMe: isFromMe,
        timestamp: 'Just now',
        text: event.body,
        isRead: isRead,
        createdAt: DateTime.now(),
        type: MessageType.text,
      );
    }

    msgs.add(newMsg);
    _messagesByConvId[convId] = msgs;

    if (newMsg.sharedPostId != null &&
        newMsg.sharedPostId!.isNotEmpty &&
        (newMsg.postThumbnailAsset == null || !newMsg.postThumbnailAsset!.startsWith('http'))) {
      resolveSharedPost(newMsg.sharedPostId!);
    }

    // 4. If user is currently in this conversation, mark read immediately
    if (!isFromMe && _activeChatConvId == convId) {
      _locallyReadMessageIds.add(event.messageId);
      _lastReadTimeByConv[convId] = DateTime.now();
      _persistReadStates();
      _socketService?.markMessageRead(
        conversationId: convId,
        messageId: event.messageId,
      );
    }

    // 5. Update conversation tile in inbox
    final int convIdx = _conversations.indexWhere(
        (ConversationModel c) => c.id == convId || c.participantId == convId);
    final String prefix = isFromMe ? 'You: ' : '';
    final String snippet = newMsg.type == MessageType.postShare
        ? (newMsg.text != null && newMsg.text!.isNotEmpty
            ? newMsg.text!
            : 'Shared a post')
        : (event.body.isNotEmpty ? event.body : 'Sent a message');
    if (convIdx != -1) {
      final ConversationModel current = _conversations[convIdx];
      final int unread = (!isFromMe && _activeChatConvId != convId)
          ? (current.unreadCount + 1)
          : 0;
      _conversations[convIdx] = current.copyWith(
        lastMessage: '$prefix$snippet',
        lastMessageAt: DateTime.now(),
        timeAgo: 'Just now',
        unreadCount: unread,
        messages: msgs,
        isTyping: false,
      );
      final ConversationModel moved = _conversations.removeAt(convIdx);
      _conversations.insert(0, moved);
    }

    _sortConversations();
    notifyListeners();
  }

  void _handleSocketMessageRead(SocketMessageReadEvent event) {
    if (event.conversationId.isEmpty && event.messageId.isEmpty) return;

    final Set<String> matchingKeys = <String>{};
    if (event.conversationId.isNotEmpty) {
      matchingKeys.add(event.conversationId);
    }
    if (_activeChatConvId != null && _activeChatConvId!.isNotEmpty) {
      matchingKeys.add(_activeChatConvId!);
    }
    for (final ConversationModel c in _conversations) {
      if (c.id == event.conversationId ||
          c.participantId == event.conversationId ||
          (event.messageId.isNotEmpty &&
              c.messages.any((ChatMessageModel m) => m.id == event.messageId))) {
        matchingKeys.add(c.id);
        if (c.participantId != null && c.participantId!.isNotEmpty) {
          matchingKeys.add(c.participantId!);
        }
      }
    }

    if (event.messageId.isNotEmpty) {
      for (final MapEntry<String, List<ChatMessageModel>> entry in _messagesByConvId.entries) {
        if (entry.value.any((ChatMessageModel m) => m.id == event.messageId)) {
          matchingKeys.add(entry.key);
        }
      }
    }

    if (matchingKeys.isEmpty && _activeChatConvId != null) {
      matchingKeys.add(_activeChatConvId!);
    }

    bool anyChanged = false;
    for (final String key in matchingKeys) {
      final List<ChatMessageModel>? msgs = _messagesByConvId[key];
      if (msgs != null && msgs.isNotEmpty) {
        final int targetIdx = event.messageId.isNotEmpty
            ? msgs.indexWhere((ChatMessageModel m) => m.id == event.messageId)
            : -1;

        for (int i = 0; i < msgs.length; i++) {
          final ChatMessageModel m = msgs[i];
          if (m.isMe) {
            bool shouldMark = false;
            if (event.messageId.isEmpty) {
              shouldMark = true;
            } else if (m.id == event.messageId) {
              shouldMark = true;
            } else if (targetIdx != -1 && i <= targetIdx) {
              shouldMark = true;
            } else if (m.id.startsWith('temp_') || m.id.startsWith('m_')) {
              shouldMark = true;
            }

            if (shouldMark) {
              _readSentMessageIds.add(m.id);
              if (event.messageId.isNotEmpty) {
                _readSentMessageIds.add(event.messageId);
              }
              final DateTime now = DateTime.now();
              final String readTime =
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
              _readSentMessageTime[m.id] = readTime;
              if (event.messageId.isNotEmpty) {
                _readSentMessageTime[event.messageId] = readTime;
              }
              msgs[i] = m.copyWith(isRead: true, timestamp: readTime);
              anyChanged = true;
            }
          }
        }
        if (anyChanged) {
          _messagesByConvId[key] = List<ChatMessageModel>.from(msgs);
        }
      }
    }

    if (anyChanged) {
      for (int i = 0; i < _conversations.length; i++) {
        final String convId = _conversations[i].id;
        final String? partId = _conversations[i].participantId;
        if (matchingKeys.contains(convId) || (partId != null && matchingKeys.contains(partId))) {
          final List<ChatMessageModel>? updatedMsgs = _messagesByConvId[convId];
          if (updatedMsgs != null) {
            _conversations[i] = _conversations[i].copyWith(messages: updatedMsgs);
          }
        }
      }
      notifyListeners();
    }
  }

  void _handleSocketReaction(SocketReactionEvent event) {
    if (event.messageId.isEmpty) return;

    final Set<String> matchingKeys = <String>{};
    if (event.conversationId.isNotEmpty) {
      matchingKeys.add(event.conversationId);
    }
    if (_activeChatConvId != null && _activeChatConvId!.isNotEmpty) {
      matchingKeys.add(_activeChatConvId!);
    }
    for (final MapEntry<String, List<ChatMessageModel>> entry in _messagesByConvId.entries) {
      if (entry.value.any((ChatMessageModel m) => m.id == event.messageId)) {
        matchingKeys.add(entry.key);
      }
    }
    for (final ConversationModel c in _conversations) {
      if (c.id == event.conversationId ||
          c.participantId == event.conversationId ||
          c.messages.any((ChatMessageModel m) => m.id == event.messageId)) {
        matchingKeys.add(c.id);
        if (c.participantId != null && c.participantId!.isNotEmpty) {
          matchingKeys.add(c.participantId!);
        }
      }
    }

    if (matchingKeys.isEmpty && _activeChatConvId != null) {
      matchingKeys.add(_activeChatConvId!);
    }

    bool anyChanged = false;
    for (final String key in matchingKeys) {
      final List<ChatMessageModel>? msgs = _messagesByConvId[key];
      if (msgs != null && msgs.isNotEmpty) {
        int idx = msgs.indexWhere((ChatMessageModel m) => m.id == event.messageId);
        if (idx == -1 && msgs.isNotEmpty) {
          idx = msgs.lastIndexWhere((ChatMessageModel m) =>
              m.id.startsWith('temp_') || m.id.startsWith('m_'));
        }
        if (idx != -1) {
          final List<MessageReactionModel> reactionsList =
              <MessageReactionModel>[];
          String? resolvedEmoji;

          if (event.reactions != null) {
            if (event.reactions is List) {
              for (final dynamic r in event.reactions as List) {
                if (r is String && r.trim().isNotEmpty) {
                  reactionsList.add(MessageReactionModel(emoji: r.trim()));
                  resolvedEmoji ??= r.trim();
                } else if (r is Map) {
                  final MessageReactionModel m = MessageReactionModel.fromJson(r);
                  reactionsList.add(m);
                  resolvedEmoji ??= m.emoji;
                }
              }
            } else if (event.reactions is String &&
                (event.reactions as String).trim().isNotEmpty) {
              resolvedEmoji = (event.reactions as String).trim();
              reactionsList.add(
                  MessageReactionModel(emoji: resolvedEmoji, userId: event.userId));
            } else if (event.reactions is Map) {
              final Map<dynamic, dynamic> map = event.reactions as Map<dynamic, dynamic>;
              // Check for standard emoji/reaction key first
              final String? e =
                  map['emoji']?.toString() ?? map['reaction']?.toString();
              if (e != null && e.isNotEmpty) {
                resolvedEmoji = e;
                reactionsList.add(MessageReactionModel.fromJson(map));
              } else {
                // Backend sends { "😂": ["userId1", ...] } — key IS the emoji
                for (final dynamic emojiKey in map.keys) {
                  final String ek = emojiKey.toString().trim();
                  if (ek.isEmpty) continue;
                  resolvedEmoji ??= ek;
                  final dynamic userList = map[emojiKey];
                  if (userList is List) {
                    for (final dynamic uid in userList) {
                      reactionsList.add(MessageReactionModel(
                        emoji: ek,
                        userId: uid?.toString(),
                      ));
                    }
                  } else {
                    reactionsList.add(MessageReactionModel(emoji: ek));
                  }
                }
              }
            }
          }

          if (event.emoji != null && event.emoji!.isNotEmpty) {
            resolvedEmoji ??= event.emoji;
            if (!reactionsList
                .any((MessageReactionModel r) => r.emoji == event.emoji)) {
              reactionsList.add(MessageReactionModel(
                  emoji: event.emoji!, userId: event.userId));
            }
          }

          final bool isCleared = event.isRemoved;

          if (isCleared) {
            _localReactionMap.remove(event.messageId);
            msgs[idx] = msgs[idx].copyWith(clearReaction: true);
            _messagesByConvId[key] = List<ChatMessageModel>.from(msgs);
            anyChanged = true;
          } else {
            final String? effectiveEmoji = resolvedEmoji ??
                (reactionsList.isNotEmpty ? reactionsList.first.emoji : null) ??
                _localReactionMap[event.messageId] ??
                msgs[idx].reactionEmoji;

            if (effectiveEmoji != null && effectiveEmoji.isNotEmpty) {
              _localReactionMap[event.messageId] = effectiveEmoji;
              msgs[idx] = msgs[idx].copyWith(
                reactions:
                    reactionsList.isNotEmpty ? reactionsList : msgs[idx].reactions,
                reactionEmoji: effectiveEmoji,
                reactionCount: reactionsList.isNotEmpty
                    ? reactionsList.length
                    : (msgs[idx].reactionCount ?? 1),
              );
              _messagesByConvId[key] = List<ChatMessageModel>.from(msgs);
              anyChanged = true;
            }
          }
        }
      }
    }

    if (anyChanged) {
      for (int i = 0; i < _conversations.length; i++) {
        if (matchingKeys.contains(_conversations[i].id) ||
            matchingKeys.contains(_conversations[i].participantId)) {
          final List<ChatMessageModel>? updatedMsgs =
              _messagesByConvId[_conversations[i].id];
          if (updatedMsgs != null) {
            _conversations[i] =
                _conversations[i].copyWith(messages: updatedMsgs);
          }
        }
      }
      notifyListeners();
    }
  }

  void _handleSocketPresence(SocketUserPresenceEvent event) {
    if (event.userId.isEmpty) return;
    if (event.userId == _currentUserId) return;

    final String presenceVal = event.isOnline ? 'online' : 'offline';
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    _userPresenceMap[event.userId] = presenceVal;
    if (event.isOnline) {
      _userLastActiveMap[event.userId] = nowIso;
    } else if (event.lastActive != null) {
      _userLastActiveMap[event.userId] = event.lastActive;
    } else {
      _userLastActiveMap[event.userId] = nowIso;
    }

    final String cleanUserId = event.userId.startsWith('@')
        ? event.userId.substring(1)
        : event.userId;
    _userPresenceMap[cleanUserId] = presenceVal;
    _userPresenceMap['@$cleanUserId'] = presenceVal;
    if (event.isOnline) {
      _userLastActiveMap[cleanUserId] = nowIso;
      _userLastActiveMap['@$cleanUserId'] = nowIso;
    } else {
      final dynamic la = _userLastActiveMap[event.userId];
      _userLastActiveMap[cleanUserId] = la;
      _userLastActiveMap['@$cleanUserId'] = la;
    }

    for (int i = 0; i < _conversations.length; i++) {
      final ConversationModel c = _conversations[i];
      final String cleanU =
          c.username.startsWith('@') ? c.username.substring(1) : c.username;
      final bool matches = c.participantId == event.userId ||
          c.participantId == cleanUserId ||
          c.id == event.userId ||
          c.id == cleanUserId ||
          cleanU.toLowerCase() == cleanUserId.toLowerCase() ||
          c.username.toLowerCase() == event.userId.toLowerCase();
      if (matches) {
        _conversations[i] = c.copyWith(
          isOnline: event.isOnline,
          lastActive: event.isOnline
              ? 'Active now'
              : (_userLastActiveMap[event.userId] ?? c.lastActive),
        );
        if (c.participantId != null && c.participantId!.isNotEmpty) {
          _userPresenceMap[c.participantId!] = presenceVal;
          _userPresenceMap[cleanUserId] = presenceVal;
        }
        _userPresenceMap[c.id] = presenceVal;
      }
    }
    notifyListeners();
  }

  void _handleSocketTyping(SocketTypingEvent event) {
    if (event.conversationId.isEmpty && event.userId.isEmpty) return;
    if (event.userId.isNotEmpty && event.userId == _currentUserId) return;

    final String convKey = event.conversationId;
    if (convKey.isNotEmpty) {
      _typingByConvId[convKey] = event.isTyping;
    }
    if (event.userId.isNotEmpty) {
      _typingByConvId[event.userId] = event.isTyping;
      final String cleanU = event.userId.startsWith('@')
          ? event.userId.substring(1)
          : event.userId;
      _typingByConvId[cleanU] = event.isTyping;
      _typingByConvId['@$cleanU'] = event.isTyping;
    }

    final int idx = _conversations.indexWhere((ConversationModel c) =>
        (convKey.isNotEmpty &&
            (c.id == convKey || c.participantId == convKey)) ||
        (event.userId.isNotEmpty &&
            (c.participantId == event.userId ||
                c.id == event.userId ||
                c.username == event.userId ||
                c.username == '@${event.userId}')));

    if (idx != -1) {
      final ConversationModel target = _conversations[idx];
      _conversations[idx] = target.copyWith(isTyping: event.isTyping);
      _typingByConvId[target.id] = event.isTyping;
      if (target.participantId != null && target.participantId!.isNotEmpty) {
        _typingByConvId[target.participantId!] = event.isTyping;
      }
      if (target.username.isNotEmpty) {
        _typingByConvId[target.username] = event.isTyping;
      }
      notifyListeners();
    } else {
      notifyListeners();
    }

    if (event.isTyping) {
      final String timerKey = convKey.isNotEmpty ? convKey : event.userId;
      _typingResetTimers[timerKey]?.cancel();
      _typingResetTimers[timerKey] =
          Timer(const Duration(milliseconds: 3500), () {
        if (convKey.isNotEmpty) {
          _typingByConvId[convKey] = false;
        }
        if (event.userId.isNotEmpty) {
          _typingByConvId[event.userId] = false;
        }
        final int targetIdx = _conversations.indexWhere((ConversationModel c) =>
            (convKey.isNotEmpty &&
                (c.id == convKey || c.participantId == convKey)) ||
            (event.userId.isNotEmpty &&
                (c.participantId == event.userId || c.id == event.userId)));
        if (targetIdx != -1) {
          final ConversationModel target = _conversations[targetIdx];
          _conversations[targetIdx] = target.copyWith(isTyping: false);
          _typingByConvId[target.id] = false;
          if (target.participantId != null &&
              target.participantId!.isNotEmpty) {
            _typingByConvId[target.participantId!] = false;
          }
        }
        notifyListeners();
      });
    }
  }

  void startPolling() {
    // Disabled: Real-time messaging, presence, reactions, and typing are all handled via Socket.IO.
    // Periodic HTTP polling is completely turned off to eliminate redundant background API calls.
    stopPolling();
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    stopPolling();
    _cancelSocketSubscriptions();
    for (final Timer t in _typingResetTimers.values) {
      t.cancel();
    }
    _typingResetTimers.clear();
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

  void updateAuth({
    String? userId,
    ConversationsService? service,
    ChatSocketService? socketService,
    String? token,
  }) {
    bool shouldReload = false;
    if (userId != null && userId != _currentUserId) {
      _currentUserId = userId;
      shouldReload = true;
      _loadPersistedReadStates();
      _socketService?.joinUserRoom(userId);
    }
    if (service != null && service != _service) {
      _service = service;
      shouldReload = true;
    }
    if (socketService != null && socketService != _socketService) {
      _socketService = socketService;
      _attachSocketListeners();
    }
    final String? effectiveToken = (token != null && token.isNotEmpty)
        ? token
        : _service?.client.authToken;
    if (effectiveToken != null && effectiveToken.isNotEmpty) {
      if (effectiveToken != _token || !(_socketService?.isConnected ?? false)) {
        _token = effectiveToken;
        _socketService?.connect(
            token: effectiveToken, currentUserId: _currentUserId);
      }
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        _socketService?.joinUserRoom(_currentUserId!);
      }
    }
    if (userId == null || userId.isEmpty) {
      _currentUserId = null;
      _conversations.clear();
      _messagesByConvId.clear();
      _messageRequests.clear();
      _socketService?.disconnect();
      stopPolling();
      notifyListeners();
    } else {
      startPolling();
      if (shouldReload || _conversations.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          loadConversations();
          loadMessageRequests();
          loadBlockedUsers();
        });
      }
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
  final Set<String> _blockedUserIds = <String>{};
  final Set<String> _blockedUsernames = <String>{};
  final Map<String, bool> _typingIndicatorEnabled = <String, bool>{};
  bool _isLoadingBlocked = false;
  bool get isLoadingBlocked => _isLoadingBlocked;

  bool isMuted(String key) {
    if (_mutedUsers[key] == true) return true;
    final String clean = key.startsWith('@') ? key.substring(1) : key;
    if (_mutedUsers[clean] == true || _mutedUsers['@$clean'] == true) return true;
    return false;
  }
  bool isRestricted(String username) => _restrictedUsers[username] ?? false;

  bool isBlocked(String? key) {
    if (key == null || key.trim().isEmpty) return false;
    final String raw = key.trim();
    if (_blockedUsers[raw] == true) return true;
    final String clean = raw.replaceAll('@', '').toLowerCase();
    if (_blockedUsers[clean] == true || _blockedUsers['@$clean'] == true) return true;
    if (_blockedUserIds.contains(clean)) return true;
    if (_blockedUsernames.contains(clean)) return true;
    return false;
  }

  Set<String> get blockedUserIds => Set<String>.unmodifiable(_blockedUserIds);
  Set<String> get blockedUsernames => Set<String>.unmodifiable(_blockedUsernames);

  /// Fetch blocked users from backend: GET /users/me/blocked
  Future<void> loadBlockedUsers({bool force = false}) async {
    if (_service == null) return;
    _isLoadingBlocked = true;
    try {
      final List<Map<String, dynamic>> items = await _service!.getBlockedUsers();
      _blockedUsers.clear();
      _blockedUserIds.clear();
      _blockedUsernames.clear();

      for (final Map<String, dynamic> raw in items) {
        final Map<String, dynamic> userMap =
            (raw['blockedUser'] is Map<String, dynamic>)
                ? raw['blockedUser'] as Map<String, dynamic>
                : (raw['user'] is Map<String, dynamic>)
                    ? raw['user'] as Map<String, dynamic>
                    : raw;

        final String uId = (userMap['userId'] ??
                userMap['id'] ??
                userMap['_id'] ??
                raw['blockedUserId'] ??
                raw['userId'] ??
                raw['id'] ??
                '')
            .toString()
            .trim()
            .toLowerCase();

        final String uname = (userMap['username'] ??
                userMap['handle'] ??
                raw['username'] ??
                '')
            .toString()
            .replaceAll('@', '')
            .trim()
            .toLowerCase();

        if (uId.isNotEmpty) {
          _blockedUserIds.add(uId);
          _blockedUsers[uId] = true;
        }
        if (uname.isNotEmpty) {
          _blockedUsernames.add(uname);
          _blockedUsers[uname] = true;
          _blockedUsers['@$uname'] = true;
        }
      }
      debugPrint('✅ [MessagesProvider] Loaded ${_blockedUserIds.length} blocked user(s)');
    } catch (e) {
      debugPrint('⚠️ [MessagesProvider] Failed to load blocked users: $e');
    } finally {
      _isLoadingBlocked = false;
      notifyListeners();
    }
  }

  Future<bool> blockUser(String userId, {String? username}) async {
    if (userId.trim().isEmpty) return false;
    final String cleanId = userId.trim().toLowerCase();
    final String cleanUname = (username ?? '').replaceAll('@', '').trim().toLowerCase();

    _blockedUserIds.add(cleanId);
    _blockedUsers[cleanId] = true;
    _blockedUsers[userId] = true;
    if (cleanUname.isNotEmpty) {
      _blockedUsernames.add(cleanUname);
      _blockedUsers[cleanUname] = true;
      _blockedUsers['@$cleanUname'] = true;
    }
    notifyListeners();

    if (_service != null) {
      final bool ok = await _service!.blockUser(userId);
      if (!ok) {
        _blockedUserIds.remove(cleanId);
        _blockedUsers.remove(cleanId);
        _blockedUsers.remove(userId);
        if (cleanUname.isNotEmpty) {
          _blockedUsernames.remove(cleanUname);
          _blockedUsers.remove(cleanUname);
          _blockedUsers.remove('@$cleanUname');
        }
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  Future<bool> unblockUser(String userId, {String? username}) async {
    if (userId.trim().isEmpty) return false;
    final String cleanId = userId.trim().toLowerCase();
    final String cleanUname = (username ?? '').replaceAll('@', '').trim().toLowerCase();

    _blockedUserIds.remove(cleanId);
    _blockedUsers.remove(cleanId);
    _blockedUsers.remove(userId);
    if (cleanUname.isNotEmpty) {
      _blockedUsernames.remove(cleanUname);
      _blockedUsers.remove(cleanUname);
      _blockedUsers.remove('@$cleanUname');
    }
    notifyListeners();

    if (_service != null) {
      final bool ok = await _service!.unblockUser(userId);
      if (!ok) {
        _blockedUserIds.add(cleanId);
        _blockedUsers[cleanId] = true;
        _blockedUsers[userId] = true;
        if (cleanUname.isNotEmpty) {
          _blockedUsernames.add(cleanUname);
          _blockedUsers[cleanUname] = true;
        }
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  Future<void> toggleBlock(String username, {String? userId}) async {
    final bool current = isBlocked(username) || (userId != null && isBlocked(userId));
    final String targetId = (userId != null && userId.isNotEmpty) ? userId : username;
    if (current) {
      await unblockUser(targetId, username: username);
    } else {
      await blockUser(targetId, username: username);
    }
  }

  void toggleMute(String username) {
    final bool current = isMuted(username);
    final String clean = username.startsWith('@') ? username.substring(1) : username;
    if (current) {
      _mutedUsers.remove(username);
      _mutedUsers.remove(clean);
      _mutedUsers.remove('@$clean');
    } else {
      _mutedUsers[username] = true;
      _mutedUsers[clean] = true;
      _mutedUsers['@$clean'] = true;
    }
    notifyListeners();
  }

  void toggleRestrict(String username) {
    _restrictedUsers[username] = !isRestricted(username);
    notifyListeners();
  }

  // ── Shared Post & Media Resolution ──────────────────────────────────────
  final Map<String, PostResponseModel> _resolvedPosts = <String, PostResponseModel>{};
  final Set<String> _resolvingPostIds = <String>{};

  PostResponseModel? getCachedPost(String postId) => _resolvedPosts[postId.trim()];

  Future<PostResponseModel?> resolveSharedPost(String postId) async {
    final String cleanPostId = postId.trim();
    if (cleanPostId.isEmpty) return null;
    if (_resolvedPosts.containsKey(cleanPostId)) {
      return _resolvedPosts[cleanPostId];
    }
    if (_resolvingPostIds.contains(cleanPostId)) return null;
    _resolvingPostIds.add(cleanPostId);

    try {
      if (_service == null) return null;
      final PostContentService postService = PostContentService(_service!.client);
      final MediaUploadService mediaService = MediaUploadService(_service!.client);

      final PostResponseModel post = await postService.getPost(cleanPostId);
      _resolvedPosts[cleanPostId] = post;

      String? mediaUrl;
      String? thumbUrl;
      if (post.mediaRefs.isNotEmpty) {
        final String firstRef = post.mediaRefs.first.trim();
        if (firstRef.startsWith('http://') || firstRef.startsWith('https://')) {
          mediaUrl = firstRef;
          thumbUrl = firstRef;
        } else {
          try {
            final MediaUploadResult status = await mediaService.getMediaStatus(firstRef);
            mediaUrl = status.url ?? status.downloadUrl;
            thumbUrl = status.thumbnailUrl ?? mediaUrl;
          } catch (_) {
            mediaUrl = firstRef;
            thumbUrl = firstRef;
          }
        }
      }

      final String effectiveThumb = thumbUrl ?? mediaUrl ?? '';
      final String rawType = post.type.trim().toUpperCase();
      final String pType = (rawType == 'VIDEO' || rawType == 'REEL') ? 'reel' : 'post';
      final String resolvedAuthor = (post.authorName != null && post.authorName!.isNotEmpty)
          ? (post.authorName!.startsWith('@') ? post.authorName! : '@${post.authorName!}')
          : '@creator';

      bool anyUpdated = false;
      for (final MapEntry<String, List<ChatMessageModel>> entry in _messagesByConvId.entries) {
        final List<ChatMessageModel> list = entry.value;
        for (int i = 0; i < list.length; i++) {
          if (list[i].sharedPostId == cleanPostId) {
            list[i] = list[i].copyWith(
              postThumbnailAsset: effectiveThumb.isNotEmpty ? effectiveThumb : list[i].postThumbnailAsset,
              postCaption: post.caption.isNotEmpty ? post.caption : list[i].postCaption,
              postAuthor: resolvedAuthor,
              postAuthorAvatarUrl: post.authorAvatar ?? list[i].postAuthorAvatarUrl,
              postType: pType,
              postLikes: post.likesCount > 0 ? post.likesCount : list[i].postLikes,
              postComments: post.commentsCount > 0 ? post.commentsCount : list[i].postComments,
            );
            anyUpdated = true;
          }
        }
        if (anyUpdated) {
          _messagesByConvId[entry.key] = List<ChatMessageModel>.from(list);
        }
      }

      if (anyUpdated) {
        notifyListeners();
      }
      return post;
    } catch (e) {
      debugPrint('⚠️ [MessagesProvider] Error resolving shared post $cleanPostId: $e');
      return null;
    } finally {
      _resolvingPostIds.remove(cleanPostId);
    }
  }

  bool isTypingIndicatorEnabled(String? key) {
    if (key == null || key.isEmpty) return true;
    if (_typingIndicatorEnabled.containsKey(key)) {
      return _typingIndicatorEnabled[key]!;
    }
    final String clean = key.startsWith('@') ? key.substring(1) : key;
    if (_typingIndicatorEnabled.containsKey(clean)) {
      return _typingIndicatorEnabled[clean]!;
    }
    if (_typingIndicatorEnabled.containsKey('@$clean')) {
      return _typingIndicatorEnabled['@$clean']!;
    }
    return true;
  }

  void toggleTypingIndicator(String key, bool enabled) {
    _typingIndicatorEnabled[key] = enabled;
    final String clean = key.startsWith('@') ? key.substring(1) : key;
    _typingIndicatorEnabled[clean] = enabled;
    _typingIndicatorEnabled['@$clean'] = enabled;
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
    final List<ConversationModel> list = _searchQuery.trim().isEmpty
        ? _conversations
        : _conversations
            .where((ConversationModel c) =>
                c.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                (c.displayName != null &&
                    c.displayName!
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase())) ||
                c.lastMessage.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();

    final List<ConversationModel> sorted = List<ConversationModel>.from(list);
    sorted.sort((ConversationModel a, ConversationModel b) {
      final DateTime timeA = _getEffectiveConversationTime(a);
      final DateTime timeB = _getEffectiveConversationTime(b);
      final int cmp = timeB.compareTo(timeA);
      if (cmp != 0) return cmp;
      if (a.unreadCount != b.unreadCount) {
        return b.unreadCount.compareTo(a.unreadCount);
      }
      return 0;
    });
    return sorted;
  }

  DateTime _getEffectiveConversationTime(ConversationModel c) {
    // 1. Direct lastMessageAt timestamp
    if (c.lastMessageAt != null) {
      return c.lastMessageAt!;
    }
    // 2. Cached in-memory messages
    final List<ChatMessageModel>? msgs = _messagesByConvId[c.id];
    if (msgs != null && msgs.isNotEmpty) {
      final ChatMessageModel lastMsg = msgs.last;
      if (lastMsg.createdAt != null) {
        return lastMsg.createdAt!;
      }
    }
    // 3. Embedded messages in model
    if (c.messages.isNotEmpty && c.messages.last.createdAt != null) {
      return c.messages.last.createdAt!;
    }
    // 4. Parse timeAgo string
    final String t = c.timeAgo.trim().toLowerCase();
    if (t.isNotEmpty) {
      if (t == 'just now' || t == 'now') {
        return DateTime.now();
      }
      final RegExp minRegex = RegExp(r'^(\d+)\s*m');
      final RegExp hrRegex = RegExp(r'^(\d+)\s*h');
      final RegExp dayRegex = RegExp(r'^(\d+)\s*d');
      final RegExp wkRegex = RegExp(r'^(\d+)\s*w');
      final RegExp moRegex = RegExp(r'^(\d+)\s*mo');

      final Match? mMin = minRegex.firstMatch(t);
      if (mMin != null) {
        final int val = int.tryParse(mMin.group(1) ?? '') ?? 0;
        return DateTime.now().subtract(Duration(minutes: val));
      }
      final Match? mHr = hrRegex.firstMatch(t);
      if (mHr != null) {
        final int val = int.tryParse(mHr.group(1) ?? '') ?? 0;
        return DateTime.now().subtract(Duration(hours: val));
      }
      final Match? mDay = dayRegex.firstMatch(t);
      if (mDay != null) {
        final int val = int.tryParse(mDay.group(1) ?? '') ?? 0;
        return DateTime.now().subtract(Duration(days: val));
      }
      final Match? mWk = wkRegex.firstMatch(t);
      if (mWk != null) {
        final int val = int.tryParse(mWk.group(1) ?? '') ?? 0;
        return DateTime.now().subtract(Duration(days: val * 7));
      }
      final Match? mMo = moRegex.firstMatch(t);
      if (mMo != null) {
        final int val = int.tryParse(mMo.group(1) ?? '') ?? 0;
        return DateTime.now().subtract(Duration(days: val * 30));
      }

      final RegExp clockRegex =
          RegExp(r'^(\d{1,2}):(\d{2})(?:\s*(AM|PM))?$', caseSensitive: false);
      final Match? mClock = clockRegex.firstMatch(t);
      if (mClock != null) {
        int hour = int.tryParse(mClock.group(1) ?? '') ?? 0;
        final int minute = int.tryParse(mClock.group(2) ?? '') ?? 0;
        final String? ampm = mClock.group(3)?.toUpperCase();
        if (ampm == 'PM' && hour < 12) hour += 12;
        if (ampm == 'AM' && hour == 12) hour = 0;
        final DateTime now = DateTime.now();
        return DateTime(now.year, now.month, now.day, hour, minute);
      }
    }

    if (c.lastMessage == 'No messages yet') {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    return DateTime.fromMillisecondsSinceEpoch(1);
  }

  void _sortConversations() {
    _conversations.sort((ConversationModel a, ConversationModel b) {
      final DateTime timeA = _getEffectiveConversationTime(a);
      final DateTime timeB = _getEffectiveConversationTime(b);
      final int cmp = timeB.compareTo(timeA);
      if (cmp != 0) return cmp;
      if (a.unreadCount != b.unreadCount) {
        return b.unreadCount.compareTo(a.unreadCount);
      }
      return 0;
    });
  }

  /// Total count of conversations that have unread received messages
  int get unreadConversationsCount =>
      _conversations.where((ConversationModel c) => c.unreadCount > 0).length;

  /// Total count of all unread messages across all conversations
  int get totalUnreadMessagesCount =>
      _conversations.fold<int>(0, (int sum, ConversationModel c) => sum + c.unreadCount);

  List<ChatMessageModel> getMessagesFor(String conversationId) {
    return _messagesByConvId[conversationId] ?? const <ChatMessageModel>[];
  }

  Future<void> loadConversations({bool force = false}) async {
    if (_service == null) return;
    loadBlockedUsers();
    if (_conversations.isEmpty) {
      _isLoadingConversations = true;
      notifyListeners();
    }

    try {
      final List<ConversationModel> items =
          await _service!.getConversations(currentUserId: _currentUserId);
      _conversations.clear();
      _conversations.addAll(items);
      // Sync muted map, socket rooms, and presence
      for (final ConversationModel c in items) {
        if (c.isMuted) {
          _mutedUsers[c.username] = true;
          _mutedUsers[c.id] = true;
        }
        if (c.id.isNotEmpty) {
          _socketService?.joinConversation(c.id);
        }
        if (c.participantId != null && c.participantId!.isNotEmpty) {
          if (c.lastActive != null) {
            _userLastActiveMap[c.participantId!] = c.lastActive;
          }
        }
      }

      // Check if we have cached messages in memory to hydrate lastMessage & unreadCount
      for (int i = 0; i < _conversations.length; i++) {
        final ConversationModel c = _conversations[i];
        if (_messagesByConvId.containsKey(c.id) &&
            _messagesByConvId[c.id]!.isNotEmpty) {
          final List<ChatMessageModel> msgs =
              _applyReadStatesToMessages(c.id, _messagesByConvId[c.id]!);
          _messagesByConvId[c.id] = msgs;
          final ChatMessageModel last = msgs.last;
          final String lastBody = (last.text != null && last.text!.isNotEmpty)
              ? last.text!
              : (last.mediaUrl != null ? '📷 Photo' : 'Sent a message');
          final String prefix = last.isMe ? 'You: ' : '';
          final int unread = _calculateUnreadForConversation(
            c.id,
            msgs,
            defaultUnread: c.unreadCount,
            lastMessageAt: last.createdAt ?? c.lastMessageAt,
          );

          _conversations[i] = c.copyWith(
            lastMessage: '$prefix$lastBody',
            timeAgo: last.timestamp.isNotEmpty ? last.timestamp : c.timeAgo,
            lastMessageAt: last.createdAt ?? c.lastMessageAt,
            unreadCount: unread,
            messages: msgs,
          );
        } else {
          final int unread = _calculateUnreadForConversation(
            c.id,
            const <ChatMessageModel>[],
            defaultUnread: c.unreadCount,
            lastMessageAt: c.lastMessageAt,
          );
          if (unread != c.unreadCount) {
            _conversations[i] = c.copyWith(unreadCount: unread);
          }
        }
      }

      _sortConversations();
      if (_isLoadingConversations) {
        _isLoadingConversations = false;
        notifyListeners();
      }

      // Fetch actual messages from backend for ALL conversations so new messages and unread counts always show
      final List<Future<void>> syncTasks = <Future<void>>[];
      for (final ConversationModel c in List<ConversationModel>.from(_conversations)) {
        if (c.id.isNotEmpty && !c.id.startsWith('temp_')) {
          syncTasks.add(() async {
            try {
              final List<ChatMessageModel> fetched = await _service!.getMessages(
                conversationId: c.id,
                currentUserId: _currentUserId,
              );
              if (fetched.isNotEmpty) {
                final List<ChatMessageModel> msgs =
                    _applyReadStatesToMessages(c.id, fetched);
                _messagesByConvId[c.id] = msgs;
                final ChatMessageModel last = msgs.last;
                final String lastBody = (last.text != null && last.text!.isNotEmpty)
                    ? last.text!
                    : (last.mediaUrl != null ? '📷 Photo' : 'Sent a message');
                final String prefix = last.isMe ? 'You: ' : '';
                final int unread = _calculateUnreadForConversation(
                  c.id,
                  msgs,
                  lastMessageAt: last.createdAt ?? c.lastMessageAt,
                );

                final int targetIdx = _conversations
                    .indexWhere((ConversationModel item) => item.id == c.id);
                if (targetIdx != -1) {
                  _conversations[targetIdx] = _conversations[targetIdx].copyWith(
                    lastMessage: '$prefix$lastBody',
                    timeAgo: last.timestamp.isNotEmpty
                        ? last.timestamp
                        : _conversations[targetIdx].timeAgo,
                    lastMessageSenderId: last.senderId,
                    lastMessageAt: last.createdAt ?? _conversations[targetIdx].lastMessageAt,
                    unreadCount: unread,
                    messages: msgs,
                  );
                  _sortConversations();
                  notifyListeners();
                }
              }
            } catch (_) {}
          }());
        }
      }
      if (syncTasks.isNotEmpty) {
        Future.wait(syncTasks).then((_) {
          _sortConversations();
          notifyListeners();
        });
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      _sortConversations();
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  Future<void> refreshConversationsSilently() async {
    if (_service == null || _currentUserId == null || _currentUserId!.isEmpty) {
      return;
    }
    try {
      final List<ConversationModel> items =
          await _service!.getConversations(currentUserId: _currentUserId);

      bool hasChanges = false;
      if (items.length != _conversations.length) {
        hasChanges = true;
      }

      for (final ConversationModel c in items) {
        final int idx = _conversations.indexWhere((item) => item.id == c.id);
        if (idx != -1) {
          final ConversationModel current = _conversations[idx];
          final DateTime? newestAt = (c.lastMessageAt != null &&
                  (current.lastMessageAt == null ||
                      c.lastMessageAt!.isAfter(current.lastMessageAt!)))
              ? c.lastMessageAt
              : current.lastMessageAt;
          final String updatedLastMsg = (c.lastMessage != 'No messages yet' &&
                  c.lastMessage != current.lastMessage)
              ? c.lastMessage
              : current.lastMessage;

          _conversations[idx] = c.copyWith(
            messages: _messagesByConvId[c.id] ?? current.messages,
            lastMessage: updatedLastMsg,
            lastMessageAt: newestAt,
            unreadCount: current.unreadCount,
          );
        } else {
          _conversations.add(c);
          hasChanges = true;
        }
      }

      final List<Future<void>> syncTasks = <Future<void>>[];
      for (final ConversationModel c in List<ConversationModel>.from(_conversations)) {
        if (c.id.isNotEmpty && !c.id.startsWith('temp_')) {
          syncTasks.add(() async {
            try {
              final List<ChatMessageModel> fetched = await _service!.getMessages(
                conversationId: c.id,
                currentUserId: _currentUserId,
              );
              if (fetched.isNotEmpty) {
                final List<ChatMessageModel> msgs =
                    _applyReadStatesToMessages(c.id, fetched);
                final int prevCount = _messagesByConvId[c.id]?.length ?? 0;
                _messagesByConvId[c.id] = msgs;
                final ChatMessageModel last = msgs.last;
                final String lastBody = (last.text != null && last.text!.isNotEmpty)
                    ? last.text!
                    : (last.mediaUrl != null ? '📷 Photo' : 'Sent a message');
                final String prefix = last.isMe ? 'You: ' : '';
                final String fullLastMsg = '$prefix$lastBody';
                final int unread = _calculateUnreadForConversation(
                  c.id,
                  msgs,
                  lastMessageAt: last.createdAt,
                );

                final int targetIdx = _conversations
                    .indexWhere((ConversationModel item) => item.id == c.id);
                if (targetIdx != -1) {
                  final ConversationModel target = _conversations[targetIdx];
                  if (target.lastMessage != fullLastMsg ||
                      target.unreadCount != unread ||
                      prevCount != msgs.length ||
                      target.timeAgo != (last.timestamp.isNotEmpty ? last.timestamp : target.timeAgo)) {
                    hasChanges = true;
                  }

                  _conversations[targetIdx] = target.copyWith(
                    lastMessage: fullLastMsg,
                    timeAgo: last.timestamp.isNotEmpty
                        ? last.timestamp
                        : target.timeAgo,
                    lastMessageSenderId: last.senderId,
                    lastMessageAt: last.createdAt ?? target.lastMessageAt,
                    unreadCount: unread,
                    messages: msgs,
                  );
                }
              }
            } catch (_) {}
          }());
        }
      }

      if (syncTasks.isNotEmpty) {
        await Future.wait(syncTasks);
      }

      if (hasChanges) {
        _sortConversations();
        notifyListeners();
      }
    } catch (_) {}
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
    _sortConversations();
    notifyListeners();
  }

  // ── Messages In Conversation ───────────────────────────────────────────────
  Future<void> loadMessages(
    String conversationId, {
    bool force = false,
    bool silent = false,
  }) async {
    if (_service == null) return;
    if (!silent) {
      _loadingMessagesMap[conversationId] = true;
      notifyListeners();
    }

    try {
      final List<ChatMessageModel> fetched = await _service!.getMessages(
        conversationId: conversationId,
        currentUserId: _currentUserId,
      );
      final List<ChatMessageModel>? prevMsgs = _messagesByConvId[conversationId];
      final int prevCount = prevMsgs?.length ?? 0;
      final List<ChatMessageModel> msgs =
          _applyReadStatesToMessages(conversationId, fetched);
      _messagesByConvId[conversationId] = msgs;

      for (final ChatMessageModel m in fetched) {
        if (m.sharedPostId != null &&
            m.sharedPostId!.isNotEmpty &&
            (m.postThumbnailAsset == null || !m.postThumbnailAsset!.startsWith('http'))) {
          resolveSharedPost(m.sharedPostId!);
        }
      }

      // If active chat is currently this conversation, mark unread messages as read
      if (_activeChatConvId == conversationId) {
        _lastReadTimeByConv[conversationId] = DateTime.now();
        if (_service != null && !conversationId.startsWith('temp_')) {
          _service!.markConversationRead(conversationId).catchError((_) => false);
          _socketService?.markConversationRead(conversationId: conversationId);
          for (final ChatMessageModel raw in fetched) {
            if (!raw.isMe && !raw.isRead && !raw.id.startsWith('temp_') && !raw.id.startsWith('m_')) {
              _service!.markMessageRead(
                conversationId: conversationId,
                messageId: raw.id,
              ).catchError((_) => false);
              _socketService?.markMessageRead(
                conversationId: conversationId,
                messageId: raw.id,
              );
            }
          }
        }
        for (int i = 0; i < msgs.length; i++) {
          final ChatMessageModel m = msgs[i];
          if (!m.isMe) {
            _locallyReadMessageIds.add(m.id);
            if (!m.isRead) {
              msgs[i] = m.copyWith(isRead: true);
            }
          }
        }
        _persistReadStates();
      }

      // Also attach to conversation model and update last message & unread count
      final int idx = _conversations.indexWhere((ConversationModel c) =>
          c.id == conversationId || c.participantId == conversationId);
      if (idx != -1) {
        if (msgs.isNotEmpty) {
          final ChatMessageModel last = msgs.last;
          final String lastBody = (last.text != null && last.text!.isNotEmpty)
              ? last.text!
              : (last.mediaUrl != null ? '📷 Photo' : 'Sent a message');
          final String prefix = last.isMe ? 'You: ' : '';
          final int unread = _calculateUnreadForConversation(
            conversationId,
            msgs,
            lastMessageAt: last.createdAt ?? _conversations[idx].lastMessageAt,
          );

          _conversations[idx] = _conversations[idx].copyWith(
            lastMessage: '$prefix$lastBody',
            timeAgo: last.timestamp.isNotEmpty
                ? last.timestamp
                : _conversations[idx].timeAgo,
            lastMessageSenderId: last.senderId,
            lastMessageAt: last.createdAt ?? _conversations[idx].lastMessageAt,
            unreadCount: unread,
            messages: msgs,
          );
          _sortConversations();
        } else {
          _conversations[idx] = _conversations[idx].copyWith(messages: msgs);
        }
      }

      if (silent) {
        bool hasChanged = msgs.length != prevCount;
        if (!hasChanged && prevMsgs != null) {
          final int checkLimit = msgs.length < prevMsgs.length ? msgs.length : prevMsgs.length;
          for (int i = 0; i < checkLimit; i++) {
            if (msgs[i].id != prevMsgs[i].id || msgs[i].isRead != prevMsgs[i].isRead) {
              hasChanged = true;
              break;
            }
          }
        }
        if (hasChanged) {
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error loading messages for $conversationId: $e');
    } finally {
      if (!silent) {
        _loadingMessagesMap[conversationId] = false;
        notifyListeners();
      }
    }
  }

  // ── Send Message ───────────────────────────────────────────────────────────
  Future<void> sendMessage(String conversationId, String text) async {
    final String trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final int convIdx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    final ConversationModel? targetConv =
        convIdx != -1 ? _conversations[convIdx] : null;
    final String? pId = targetConv?.participantId;
    final String uname = targetConv?.username ?? '';

    if (isBlocked(conversationId) || isBlocked(pId) || isBlocked(uname)) {
      debugPrint('⚠️ [MessagesProvider] Cannot send message: recipient is blocked.');
      return;
    }

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
      final ConversationModel updated = _conversations[idx].copyWith(
        lastMessage: 'You: $trimmed',
        timeAgo: 'Just now',
        lastMessageAt: DateTime.now(),
        unreadCount: 0,
        messages: currentMsgs,
      );
      _conversations.removeAt(idx);
      _conversations.insert(0, updated);
    } else {
      final int pIdx = _conversations.indexWhere((ConversationModel c) =>
          c.participantId == conversationId);
      if (pIdx != -1) {
        final ConversationModel updated = _conversations[pIdx].copyWith(
          lastMessage: 'You: $trimmed',
          timeAgo: 'Just now',
          lastMessageAt: DateTime.now(),
          unreadCount: 0,
          messages: currentMsgs,
        );
        _conversations.removeAt(pIdx);
        _conversations.insert(0, updated);
      }
    }
    _sortConversations();
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
            conversationId.isEmpty ||
            conversationId.startsWith('temp_')) {
          final String? pId = conv?.participantId;
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

        // Emit through socket gateway (pure socket per backend spec)
        _socketService?.sendMessage(
          conversationId: targetConvId,
          text: trimmed,
          body: trimmed,
        );
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
      if (idx != -1 && !msgs[idx].isRead && !msgs[idx].isMe) {
        msgs[idx] = msgs[idx].copyWith(isRead: true);
        notifyListeners();
      }
    }

    _socketService?.markMessageRead(
      conversationId: conversationId,
      messageId: messageId,
    );
  }

  // ── Mark All Messages Read In Conversation ─────────────────────────────────
  Future<void> markAllMessagesAsRead(String conversationId) async {
    _lastReadTimeByConv[conversationId] = DateTime.now();

    // 1. Immediately reset unread count on conversation tile
    final int convIdx = _conversations.indexWhere(
        (ConversationModel c) => c.id == conversationId || c.participantId == conversationId);
    if (convIdx != -1) {
      _conversations[convIdx] =
          _conversations[convIdx].copyWith(unreadCount: 0);
    }

    // 2. Mark all loaded incoming messages as read and save IDs
    final List<ChatMessageModel>? msgs = _messagesByConvId[conversationId];
    final List<String> unreadIds = <String>[];
    if (msgs != null && msgs.isNotEmpty) {
      for (int i = 0; i < msgs.length; i++) {
        if (!msgs[i].isMe) {
          unreadIds.add(msgs[i].id);
          _locallyReadMessageIds.add(msgs[i].id);
          msgs[i] = msgs[i].copyWith(isRead: true);
        }
      }
      _messagesByConvId[conversationId] = List<ChatMessageModel>.from(msgs);
      if (convIdx != -1) {
        _conversations[convIdx] =
            _conversations[convIdx].copyWith(messages: msgs, unreadCount: 0);
      }
    }

    _persistReadStates();
    notifyListeners();

    // 3. Emit message_read and conversation:read on socket
    _socketService?.markConversationRead(conversationId: conversationId);
    for (final String msgId in unreadIds) {
      _socketService?.markMessageRead(
        conversationId: conversationId,
        messageId: msgId,
      );
    }
    if (_service != null && !conversationId.startsWith('temp_')) {
      _service!.markConversationRead(conversationId).catchError((_) => false);
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

    // 2. Socket emit
    _socketService?.unsendMessage(
      conversationId: conversationId,
      messageId: messageId,
    );
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
    // 1. Locate all conversation keys where this message is present
    final Set<String> targetKeys = <String>{};
    if (conversationId.isNotEmpty) {
      targetKeys.add(conversationId);
    }
    for (final MapEntry<String, List<ChatMessageModel>> entry in _messagesByConvId.entries) {
      if (entry.value.any((ChatMessageModel m) => m.id == messageId)) {
        targetKeys.add(entry.key);
      }
    }
    for (final ConversationModel c in _conversations) {
      if (c.id == conversationId ||
          c.participantId == conversationId ||
          c.messages.any((ChatMessageModel m) => m.id == messageId)) {
        targetKeys.add(c.id);
        if (c.participantId != null && c.participantId!.isNotEmpty) {
          targetKeys.add(c.participantId!);
        }
      }
    }

    // Find target message
    ChatMessageModel? targetMessage;
    for (final String key in targetKeys) {
      final List<ChatMessageModel>? msgs = _messagesByConvId[key];
      if (msgs != null) {
        final int idx = msgs.indexWhere((ChatMessageModel m) => m.id == messageId);
        if (idx != -1) {
          targetMessage = msgs[idx];
          break;
        }
      }
    }

    if (targetMessage == null) {
      for (final ConversationModel c in _conversations) {
        final int idx = c.messages.indexWhere((ChatMessageModel m) => m.id == messageId);
        if (idx != -1) {
          targetMessage = c.messages[idx];
          _messagesByConvId[c.id] = List<ChatMessageModel>.from(c.messages);
          targetKeys.add(c.id);
          break;
        }
      }
    }

    if (targetMessage == null) {
      debugPrint('⚠️ [MessagesProvider] toggleReaction: message $messageId not found.');
      return;
    }

    // Check if current user already has a reaction on this message
    final String? myCurrentEmoji = _currentUserId != null
        ? targetMessage.reactions
            .cast<MessageReactionModel?>()
            .firstWhere(
              (MessageReactionModel? r) => r?.userId == _currentUserId,
              orElse: () => null,
            )
            ?.emoji
        : null;

    // alreadyReacted with the SAME emoji => remove. Different emoji => update.
    final bool alreadyReactedWithEmoji =
        myCurrentEmoji == emoji || targetMessage.reactionEmoji == emoji;
    final bool isUpdatingReaction =
        myCurrentEmoji != null && myCurrentEmoji != emoji;

    // Build updated reactions list (one entry per userId)
    List<MessageReactionModel> updatedReactions =
        List<MessageReactionModel>.from(targetMessage.reactions);
    // Remove existing entry for this user
    updatedReactions.removeWhere(
        (MessageReactionModel r) => r.userId == _currentUserId);

    final ChatMessageModel updated;
    if (alreadyReactedWithEmoji && !isUpdatingReaction) {
      // Remove reaction entirely
      updated = targetMessage.copyWith(
        clearReaction: updatedReactions.isEmpty,
        reactions: updatedReactions,
        reactionEmoji: updatedReactions.isEmpty
            ? null
            : updatedReactions.first.emoji,
        reactionCount: updatedReactions.isEmpty ? null : updatedReactions.length,
      );
      _localReactionMap.remove(messageId);
    } else {
      // Add or update reaction
      updatedReactions.add(MessageReactionModel(emoji: emoji, userId: _currentUserId));
      updated = targetMessage.copyWith(
        reactions: updatedReactions,
        reactionEmoji: emoji,
        reactionCount: updatedReactions.length,
      );
      _localReactionMap[messageId] = emoji;
    }

    // Apply to all candidate keys in memory
    for (final String key in targetKeys) {
      final List<ChatMessageModel>? msgs = _messagesByConvId[key];
      if (msgs != null) {
        final int idx = msgs.indexWhere((ChatMessageModel m) => m.id == messageId);
        if (idx != -1) {
          msgs[idx] = updated;
          _messagesByConvId[key] = List<ChatMessageModel>.from(msgs);
        }
      }
    }

    // Update in _conversations
    for (int i = 0; i < _conversations.length; i++) {
      if (targetKeys.contains(_conversations[i].id) ||
          targetKeys.contains(_conversations[i].participantId) ||
          _conversations[i].messages.any((ChatMessageModel m) => m.id == messageId)) {
        final List<ChatMessageModel> convMsgs =
            List<ChatMessageModel>.from(_conversations[i].messages);
        final int mIdx = convMsgs.indexWhere((ChatMessageModel m) => m.id == messageId);
        if (mIdx != -1) {
          convMsgs[mIdx] = updated;
        }
        _conversations[i] = _conversations[i].copyWith(
          messages: _messagesByConvId[_conversations[i].id] ?? convMsgs,
        );
      }
    }

    notifyListeners();

    // 2. Resolve best backend conversationId
    String backendConvId = conversationId;
    final int foundIdx = _conversations.indexWhere((ConversationModel c) =>
        c.id == conversationId ||
        c.participantId == conversationId ||
        c.messages.any((ChatMessageModel m) => m.id == messageId));
    if (foundIdx != -1) {
      final String candId = _conversations[foundIdx].id;
      if (candId.isNotEmpty && !candId.startsWith('temp_')) {
        backendConvId = candId;
      }
    }

    // 3. Socket emit and REST API sync
    if (backendConvId.isNotEmpty) {
      if (alreadyReactedWithEmoji && !isUpdatingReaction) {
        // Remove reaction
        _socketService?.removeReaction(
          conversationId: backendConvId,
          messageId: messageId,
          emoji: emoji,
          userId: _currentUserId,
        );
        if (_service != null && !backendConvId.startsWith('temp_') && !messageId.startsWith('temp_')) {
          _service!.removeReaction(
            conversationId: backendConvId,
            messageId: messageId,
            emoji: emoji,
          ).catchError((_) => false);
        }
      } else {
        // Add or update (backend accepts add_reaction; previous is replaced server-side per user)
        if (isUpdatingReaction) {
          // Optionally remove old emoji first
          _socketService?.removeReaction(
            conversationId: backendConvId,
            messageId: messageId,
            emoji: myCurrentEmoji,
            userId: _currentUserId,
          );
        }
        _socketService?.addReaction(
          conversationId: backendConvId,
          messageId: messageId,
          emoji: emoji,
          userId: _currentUserId,
        );
        if (_service != null && !backendConvId.startsWith('temp_') && !messageId.startsWith('temp_')) {
          _service!.addReaction(
            conversationId: backendConvId,
            messageId: messageId,
            emoji: emoji,
          ).catchError((_) => false);
        }
      }
    }
  }

  void addReaction(String conversationId, String messageId, String emoji) {
    toggleReaction(conversationId, messageId, emoji);
  }

  // ── Share Post / Reel ──────────────────────────────────────────────────────
  /// Shares a post/reel via REST API (`POST /conversations/share`) for
  /// persistence, then also emits a socket event for real-time delivery.
  ///
  /// - [sharedPostId]     : ID of the post or reel to share.
  /// - [conversationIds]  : Existing conversation IDs to share into.
  /// - [recipientUserIds] : User IDs to share to (creates conversation if needed).
  /// - [message]          : Optional text alongside the share.
  /// - [contentType]      : `"post"` / `"reel_share"` / `"post_share"` etc.
  Future<bool> sharePost({
    required String sharedPostId,
    List<String>? conversationIds,
    List<String>? recipientUserIds,
    String? message,
    String? contentType,
  }) async {
    if (sharedPostId.trim().isEmpty) {
      debugPrint('⚠️ [MessagesProvider] sharePost: sharedPostId is empty.');
      return false;
    }

    // ── 1. Resolve recipient user IDs → conversation IDs ────────────────────
    final Set<String> targetConvIds = <String>{};
    if (conversationIds != null) {
      targetConvIds.addAll(conversationIds.where((String id) => id.isNotEmpty));
    }

    final List<String> unresolvedUserIds = <String>[];
    if (recipientUserIds != null) {
      for (final String uId in recipientUserIds) {
        if (uId.isEmpty) continue;
        final int cIdx = _conversations.indexWhere(
            (ConversationModel c) => c.participantId == uId || c.id == uId);
        if (cIdx != -1 &&
            _conversations[cIdx].id.isNotEmpty &&
            !_conversations[cIdx].id.startsWith('temp_')) {
          targetConvIds.add(_conversations[cIdx].id);
        } else {
          unresolvedUserIds.add(uId);
        }
      }
    }

    // Filter out blocked users from sharing
    targetConvIds.removeWhere((String cId) {
      final int cIdx = _conversations.indexWhere((ConversationModel c) => c.id == cId);
      if (cIdx != -1) {
        return isBlocked(_conversations[cIdx].participantId) ||
            isBlocked(_conversations[cIdx].username) ||
            isBlocked(cId);
      }
      return isBlocked(cId);
    });
    unresolvedUserIds.removeWhere((String uId) => isBlocked(uId));

    if (targetConvIds.isEmpty && unresolvedUserIds.isEmpty) {
      debugPrint('⚠️ [MessagesProvider] sharePost: all recipients are blocked.');
      return false;
    }

    // ── 2. API call — preferred path ─────────────────────────────────────────
    bool apiOk = false;
    if (_service != null) {
      try {
        debugPrint(
            '🚀 [MessagesProvider] sharePost (API): postId=$sharedPostId, convs=$targetConvIds, users=$unresolvedUserIds');
        apiOk = await _service!.sharePost(
          sharedPostId: sharedPostId,
          conversationIds: targetConvIds.isNotEmpty ? targetConvIds.toList() : null,
          recipientUserIds: unresolvedUserIds.isNotEmpty ? unresolvedUserIds : null,
          message: message,
          contentType: contentType,
        );
        if (apiOk) {
          debugPrint('✅ [MessagesProvider] sharePost API succeeded.');
        }
      } catch (e) {
        debugPrint('⚠️ [MessagesProvider] sharePost API failed, falling back to socket: $e');
      }
    }

    // ── 3. Socket emit — real-time delivery to already-resolved conv IDs ─────
    for (final String cId in targetConvIds) {
      _socketService?.sendMessage(
        conversationId: cId,
        sharedPostId: sharedPostId,
        text: message,
        body: message,
      );
    }

    // ── 4. Optimistic UI update ───────────────────────────────────────────────
    for (final String cId in targetConvIds) {
      final int idx =
          _conversations.indexWhere((ConversationModel c) => c.id == cId);
      if (idx != -1) {
        _conversations[idx] = _conversations[idx].copyWith(
          lastMessage: 'You: Shared a post',
          lastMessageAt: DateTime.now(),
          timeAgo: 'Just now',
        );
      }
    }
    notifyListeners();

    // ── 5. Refresh conversations after a short delay so inbox is up to date ──
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadConversations();
    });

    return apiOk;
  }

  // ── Mute / Unmute Conversation ─────────────────────────────────────────────
  Future<void> muteConversation(
    String conversationId, {
    String duration = '1_week',
  }) async {
    // 1. Optimistic update
    final int idx = _conversations.indexWhere((ConversationModel c) =>
        c.id == conversationId || c.participantId == conversationId);
    String targetId = conversationId;
    if (idx != -1) {
      final ConversationModel c = _conversations[idx];
      targetId = c.id;
      _conversations[idx] = c.copyWith(isMuted: true);
      final String u = c.username;
      final String cleanU = u.startsWith('@') ? u.substring(1) : u;
      _mutedUsers[u] = true;
      _mutedUsers[cleanU] = true;
      _mutedUsers['@$cleanU'] = true;
      _mutedUsers[c.id] = true;
      if (c.participantId != null && c.participantId!.isNotEmpty) {
        _mutedUsers[c.participantId!] = true;
      }
    }
    _mutedUsers[conversationId] = true;
    notifyListeners();

    // 2. Socket emit
    _socketService?.muteConversation(
      conversationId: targetId,
      duration: duration,
    );
  }

  Future<void> unmuteConversation(String conversationId) async {
    // 1. Optimistic update
    final int idx = _conversations.indexWhere((ConversationModel c) =>
        c.id == conversationId || c.participantId == conversationId);
    String targetId = conversationId;
    if (idx != -1) {
      final ConversationModel c = _conversations[idx];
      targetId = c.id;
      _conversations[idx] = c.copyWith(isMuted: false);
      final String u = c.username;
      final String cleanU = u.startsWith('@') ? u.substring(1) : u;
      _mutedUsers.remove(u);
      _mutedUsers.remove(cleanU);
      _mutedUsers.remove('@$cleanU');
      _mutedUsers.remove(c.id);
      if (c.participantId != null && c.participantId!.isNotEmpty) {
        _mutedUsers.remove(c.participantId!);
      }
    }
    _mutedUsers.remove(conversationId);
    final String cleanConv =
        conversationId.startsWith('@') ? conversationId.substring(1) : conversationId;
    _mutedUsers.remove(cleanConv);
    _mutedUsers.remove('@$cleanConv');
    notifyListeners();

    // 2. Socket emit
    _socketService?.unmuteConversation(targetId);
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
    final int convIdx =
        _conversations.indexWhere((ConversationModel c) => c.id == conversationId);
    final ConversationModel? targetConv =
        convIdx != -1 ? _conversations[convIdx] : null;
    final String? pId = targetConv?.participantId;
    final String uname = targetConv?.username ?? '';

    if (isBlocked(conversationId) || isBlocked(pId) || isBlocked(uname)) {
      debugPrint('⚠️ [MessagesProvider] Cannot send image: recipient is blocked.');
      return;
    }

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
      final ConversationModel updated = _conversations[idx].copyWith(
        lastMessage: 'You: Sent an image',
        timeAgo: 'Just now',
        lastMessageAt: DateTime.now(),
        unreadCount: 0,
        messages: currentMsgs,
      );
      _conversations.removeAt(idx);
      _conversations.insert(0, updated);
    } else {
      final int pIdx = _conversations.indexWhere((ConversationModel c) =>
          c.participantId == conversationId);
      if (pIdx != -1) {
        final ConversationModel updated = _conversations[pIdx].copyWith(
          lastMessage: 'You: Sent an image',
          timeAgo: 'Just now',
          lastMessageAt: DateTime.now(),
          unreadCount: 0,
          messages: currentMsgs,
        );
        _conversations.removeAt(pIdx);
        _conversations.insert(0, updated);
      }
    }
    _sortConversations();
    notifyListeners();

    // Socket emit
    _socketService?.sendMessage(
      conversationId: conversationId,
      mediaRef: imageFilePath ?? imageAsset,
      text: '',
      body: '',
    );
  }
}

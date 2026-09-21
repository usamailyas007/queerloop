import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

import '../../../core/config/app_config.dart';

// ── Helpers ──────────────────────────────────────────────────────────────────

String cleanConversationId(dynamic raw) {
  if (raw == null) return '';
  final String s = raw.toString().trim();
  if (s.startsWith('conversation:')) {
    return s.substring(13).trim();
  }
  return s;
}

String cleanUserId(dynamic raw) {
  if (raw == null) return '';
  final String s = raw.toString().trim();
  if (s.startsWith('user:')) {
    return s.substring(5).trim();
  }
  return s;
}

// ── Event Data Models ────────────────────────────────────────────────────────

class SocketNewMessageEvent {
  const SocketNewMessageEvent({
    required this.conversationId,
    required this.messageId,
    required this.senderId,
    required this.body,
    this.raw = const <String, dynamic>{},
  });

  final String conversationId;
  final String messageId;
  final String senderId;
  final String body;
  final Map<String, dynamic> raw;

  factory SocketNewMessageEvent.fromJson(dynamic data) {
    if (data is! Map) {
      return const SocketNewMessageEvent(
        conversationId: '',
        messageId: '',
        senderId: '',
        body: '',
      );
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final dynamic payload = map['data'] is Map ? map['data'] : map;
    return SocketNewMessageEvent(
      conversationId: cleanConversationId(
        payload['conversationId'] ?? payload['conversation_id'],
      ),
      messageId: (payload['messageId'] ??
              payload['message_id'] ??
              payload['id'] ??
              payload['_id'] ??
              '')
          .toString(),
      senderId: cleanUserId(
        payload['senderId'] ??
            payload['sender_id'] ??
            payload['sender']?['id'] ??
            payload['sender']?['_id'],
      ),
      body: (payload['body'] ??
              payload['text'] ??
              payload['content'] ??
              '')
          .toString(),
      raw: Map<String, dynamic>.from(payload is Map ? payload : map),
    );
  }
}

class SocketMessageReadEvent {
  const SocketMessageReadEvent({
    required this.conversationId,
    required this.messageId,
    this.readerId,
  });

  final String conversationId;
  final String messageId;
  final String? readerId;

  factory SocketMessageReadEvent.fromJson(dynamic data) {
    if (data is! Map) {
      return const SocketMessageReadEvent(
        conversationId: '',
        messageId: '',
      );
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final dynamic payload = map['data'] is Map ? map['data'] : map;
    return SocketMessageReadEvent(
      conversationId: cleanConversationId(
        payload['conversationId'] ??
            payload['conversation_id'] ??
            payload['convId'] ??
            payload['room'] ??
            payload['roomId'],
      ),
      messageId: (payload['messageId'] ??
              payload['message_id'] ??
              payload['id'] ??
              '')
          .toString(),
      readerId: cleanUserId(
        payload['readerId'] ??
            payload['reader_id'] ??
            payload['userId'] ??
            payload['user_id'],
      ),
    );
  }
}

class SocketReactionEvent {
  const SocketReactionEvent({
    required this.conversationId,
    required this.messageId,
    this.reactions,
    this.emoji,
    this.userId,
    this.isRemoved = false,
  });

  final String conversationId;
  final String messageId;
  final dynamic reactions;
  final String? emoji;
  final String? userId;
  final bool isRemoved;

  factory SocketReactionEvent.fromJson(dynamic data, {bool isRemoved = false}) {
    if (data is! Map) {
      return SocketReactionEvent(
        conversationId: '',
        messageId: '',
        isRemoved: isRemoved,
      );
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final dynamic payload = map['data'] is Map ? map['data'] : map;
    return SocketReactionEvent(
      conversationId: cleanConversationId(
        payload['conversationId'] ??
            payload['conversation_id'] ??
            payload['convId'] ??
            payload['room'] ??
            payload['roomId'],
      ),
      messageId: (payload['messageId'] ??
              payload['message_id'] ??
              payload['id'] ??
              '')
          .toString(),
      reactions: payload['reactions'],
      emoji: payload['emoji']?.toString(),
      userId: cleanUserId(payload['userId'] ?? payload['user_id']),
      isRemoved: isRemoved,
    );
  }
}

class SocketUserPresenceEvent {
  const SocketUserPresenceEvent({
    required this.userId,
    required this.status,
    this.lastActive,
  });

  final String userId;
  final String status;
  final dynamic lastActive;

  bool get isOnline =>
      status.toLowerCase().trim() == 'online' ||
      status.toLowerCase().trim() == 'active';

  factory SocketUserPresenceEvent.fromJson(dynamic data, {String? defaultStatus}) {
    if (data is String) {
      return SocketUserPresenceEvent(
        userId: cleanUserId(data),
        status: defaultStatus ?? 'online',
      );
    }
    if (data is! Map) {
      return SocketUserPresenceEvent(
        userId: '',
        status: defaultStatus ?? 'offline',
      );
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final dynamic payload = map['data'] is Map ? map['data'] : map;

    final String uId = cleanUserId(
      payload['userId'] ??
          payload['user_id'] ??
          payload['id'] ??
          payload['_id'] ??
          '',
    );

    String parsedStatus = defaultStatus ?? 'offline';
    if (payload['isOnline'] == true || payload['online'] == true) {
      parsedStatus = 'online';
    } else if (payload['isOnline'] == false || payload['online'] == false) {
      parsedStatus = 'offline';
    } else if (payload['status'] != null) {
      final String s = payload['status'].toString().toLowerCase().trim();
      if (s == 'online' || s == 'active') {
        parsedStatus = 'online';
      } else {
        parsedStatus = 'offline';
      }
    }

    final dynamic lastActive = payload['lastActive'] ??
        payload['last_active'] ??
        payload['lastSeen'] ??
        payload['last_seen'] ??
        payload['updatedAt'] ??
        payload['updated_at'];

    return SocketUserPresenceEvent(
      userId: uId,
      status: parsedStatus,
      lastActive: lastActive,
    );
  }
}

class SocketTypingEvent {
  const SocketTypingEvent({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });

  final String conversationId;
  final String userId;
  final bool isTyping;

  factory SocketTypingEvent.fromAny(dynamic data, {bool? defaultTyping}) {
    if (data is String) {
      return SocketTypingEvent(
        conversationId: cleanConversationId(data),
        userId: '',
        isTyping: defaultTyping ?? true,
      );
    }
    if (data is! Map) {
      return SocketTypingEvent(
        conversationId: '',
        userId: '',
        isTyping: defaultTyping ?? false,
      );
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final dynamic payload = map['data'] is Map ? map['data'] : map;
    final dynamic typingRaw = payload['isTyping'] ??
        payload['typing'] ??
        payload['is_typing'] ??
        payload['status'];

    bool typing = defaultTyping ?? true;
    if (typingRaw is bool) {
      typing = typingRaw;
    } else if (typingRaw != null) {
      final String s = typingRaw.toString().toLowerCase();
      typing = s == 'true' || s == '1' || s == 'typing' || s == 'start';
    }

    return SocketTypingEvent(
      conversationId: cleanConversationId(
        payload['conversationId'] ??
            payload['conversation_id'] ??
            payload['convId'] ??
            payload['room'] ??
            payload['roomId'] ??
            '',
      ),
      userId: cleanUserId(
        payload['userId'] ??
            payload['user_id'] ??
            payload['senderId'] ??
            payload['sender_id'] ??
            '',
      ),
      isTyping: typing,
    );
  }

  factory SocketTypingEvent.fromConversationTyping(dynamic data) {
    return SocketTypingEvent.fromAny(data);
  }

  factory SocketTypingEvent.fromTypingIndicator(dynamic data) {
    return SocketTypingEvent.fromAny(data);
  }
}

// ── Chat Socket Service ──────────────────────────────────────────────────────

class ChatSocketService {
  ChatSocketService();

  socket_io.Socket? _socket;
  String? _token;
  String? _currentUserId;
  String? _customUrl;
  bool _isConnected = false;

  String? get token => _token;
  String? get currentUserId => _currentUserId;

  final Set<String> _joinedRooms = <String>{};

  // Broadcast stream controllers
  final StreamController<bool> _connectionStateController =
      StreamController<bool>.broadcast();
  final StreamController<SocketNewMessageEvent> _newMessageController =
      StreamController<SocketNewMessageEvent>.broadcast();
  final StreamController<SocketMessageReadEvent> _messageReadController =
      StreamController<SocketMessageReadEvent>.broadcast();
  final StreamController<SocketReactionEvent> _reactionController =
      StreamController<SocketReactionEvent>.broadcast();
  final StreamController<SocketUserPresenceEvent> _userPresenceController =
      StreamController<SocketUserPresenceEvent>.broadcast();
  final StreamController<SocketTypingEvent> _typingController =
      StreamController<SocketTypingEvent>.broadcast();

  // Public Streams
  Stream<bool> get onConnectionChanged => _connectionStateController.stream;
  Stream<SocketNewMessageEvent> get onNewMessage =>
      _newMessageController.stream;
  Stream<SocketMessageReadEvent> get onMessageRead =>
      _messageReadController.stream;
  Stream<SocketReactionEvent> get onReactionAdded =>
      _reactionController.stream;
  Stream<SocketUserPresenceEvent> get onUserPresence =>
      _userPresenceController.stream;
  Stream<SocketTypingEvent> get onTyping => _typingController.stream;

  bool get isConnected => (_socket != null && _socket!.connected) || _isConnected;

  /// Connect to the Socket.IO gateway with authentication.
  void connect({
    required String token,
    String? currentUserId,
    String? serverUrl,
  }) {
    if (token.isEmpty) {
      debugPrint('⚠️ [ChatSocketService] Cannot connect: auth token is empty.');
      return;
    }

    _token = token;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      _currentUserId = currentUserId;
    }
    if (serverUrl != null && serverUrl.isNotEmpty) {
      _customUrl = serverUrl;
    }

    final String url = _customUrl ?? AppConfig.socketUrl;
    if (url.isEmpty) {
      debugPrint('⚠️ [ChatSocketService] Socket URL is empty.');
      return;
    }

    // If socket already connected with same token and url, return
    if (_socket != null && _socket!.connected) {
      debugPrint('ℹ️ [ChatSocketService] Socket already connected. ID: ${_socket?.id}');
      return;
    }

    disconnect();

    debugPrint('🔌 [ChatSocketService] Connecting to $url with token (length: ${token.length})...');

    try {
      final String rawToken = token.startsWith('Bearer ')
          ? token.substring(7).trim()
          : token.trim();
      final String bearerToken = 'Bearer $rawToken';

      final socket_io.OptionBuilder builder = socket_io.OptionBuilder()
          .setTransports(<String>['websocket', 'polling'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .enableForceNew()
          .setAuth(<String, dynamic>{
            'token': rawToken,
            'accessToken': rawToken,
            'authorization': bearerToken,
            'Authorization': bearerToken,
          })
          .setQuery(<String, dynamic>{
            'token': rawToken,
          })
          .setExtraHeaders(<String, String>{
            'Authorization': bearerToken,
            'authorization': bearerToken,
          });

      _socket = socket_io.io(url, builder.build());

      _registerSocketEvents();
      _socket!.connect();
    } catch (e, stack) {
      debugPrint('❌ [ChatSocketService] Error creating socket connection: $e\n$stack');
    }
  }

  void _logEmit(String event, dynamic payload) {
    debugPrint('''
╔════════════════════════════════════════════════════════════════
║ 📤 [SOCKET EMIT]
║ Event:   $event
║ Payload: $payload
╚════════════════════════════════════════════════════════════════''');
  }

  void _logInbound(String event, dynamic data) {
    debugPrint('''
╔════════════════════════════════════════════════════════════════
║ 📥 [SOCKET RESPONSE / INBOUND EVENT]
║ Event:    $event
║ Response: $data
╚════════════════════════════════════════════════════════════════''');
  }

  void _registerSocketEvents() {
    if (_socket == null) return;

    // ── Global Event Catch-All (Logs any incoming response/event) ───────────────
    try {
      _socket!.onAny((dynamic event, dynamic data) {
        final String ev = event.toString();
        const Set<String> handledEvents = <String>{
          'message:new',
          'message_read',
          'message:read',
          'reaction_add',
          'reaction:add',
          'reaction_remove',
          'reaction:remove',
          'user_presence',
          'user:presence',
          'presence',
          'presence:update',
          'user_online',
          'user:online',
          'user_offline',
          'user:offline',
          'conversation:typing',
          'typing_indicator',
          'typing:indicator',
          'typing',
          'user_typing',
          'user:typing',
          'typing:start',
          'typing:stop',
        };
        if (!handledEvents.contains(ev)) {
          _logInbound(ev, data);
        }
      });
    } catch (_) {}

    // ── Lifecycle Events ───────────────────────────────────────────────────────
    _socket!.onConnect((_) {
      debugPrint('✅ [ChatSocketService] Socket connected successfully. ID: ${_socket?.id}');
      _isConnected = true;
      _connectionStateController.add(true);

      // Join user room: user:<userId>
      if (_currentUserId != null && _currentUserId!.isNotEmpty) {
        joinUserRoom(_currentUserId!);
      }

      // Re-join previously joined rooms upon reconnection
      for (final String room in _joinedRooms) {
        _logEmit('rejoin room', room);
        _socket!.emit('join', room);
        if (room.startsWith('conversation:')) {
          final String bareId = cleanConversationId(room);
          _socket!.emit('conversation:join', room);
          _socket!.emit('conversation:join', bareId);
        } else if (room.startsWith('user:')) {
          final String bareUid = cleanUserId(room);
          _socket!.emit('user:join', room);
          _socket!.emit('user:join', bareUid);
        }
      }

      // Announce online presence to socket gateway
      try {
        final String? cleanUid =
            _currentUserId != null ? cleanUserId(_currentUserId!) : null;
        final Map<String, dynamic> activePayload = <String, dynamic>{
          if (cleanUid != null && cleanUid.isNotEmpty) 'userId': cleanUid,
          'status': 'active',
        };
        final Map<String, dynamic> onlinePayload = <String, dynamic>{
          if (cleanUid != null && cleanUid.isNotEmpty) 'userId': cleanUid,
          'status': 'online',
        };
        _logEmit('user_presence', activePayload);
        _socket!.emit('user_presence', activePayload);
        _socket!.emit('user_presence', onlinePayload);
        _socket!.emit('presence:online', activePayload);
        _socket!.emit('presence', activePayload);
      } catch (_) {}
    });

    _socket!.onDisconnect((dynamic reason) {
      debugPrint('⚠️ [ChatSocketService] Socket disconnected: $reason');
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onConnectError((dynamic err) {
      debugPrint('❌ [ChatSocketService] Connection error: $err');
      _isConnected = false;
      _connectionStateController.add(false);
    });

    _socket!.onError((dynamic err) {
      debugPrint('❌ [ChatSocketService] Socket error: $err');
    });

    // ── Backend Inbound Events ────────────────────────────────────────────────

    // 1. message:new -> { conversationId, messageId, senderId, body }
    _socket!.on('message:new', (dynamic data) {
      _logInbound('message:new', data);
      try {
        final SocketNewMessageEvent event = SocketNewMessageEvent.fromJson(data);
        if (event.conversationId.isNotEmpty) {
          _newMessageController.add(event);
        }
      } catch (e) {
        debugPrint('⚠️ [ChatSocketService] Error parsing "message:new": $e');
      }
    });

    // 2. message_read / message:read -> { conversationId, messageId, readerId }
    void handleMessageRead(dynamic data, String eventName) {
      _logInbound(eventName, data);
      try {
        final SocketMessageReadEvent event = SocketMessageReadEvent.fromJson(data);
        if (event.conversationId.isNotEmpty) {
          _messageReadController.add(event);
        }
      } catch (e) {
        debugPrint('⚠️ [ChatSocketService] Error parsing "$eventName": $e');
      }
    }
    _socket!.on('message_read', (dynamic d) => handleMessageRead(d, 'message_read'));
    _socket!.on('message:read', (dynamic d) => handleMessageRead(d, 'message:read'));

    // 3. reaction_add / reaction:add -> { conversationId, messageId, reactions }
    void handleReactionAdd(dynamic data, String eventName) {
      _logInbound(eventName, data);
      try {
        final SocketReactionEvent event = SocketReactionEvent.fromJson(data);
        if (event.conversationId.isNotEmpty) {
          _reactionController.add(event);
        }
      } catch (e) {
        debugPrint('⚠️ [ChatSocketService] Error parsing "$eventName": $e');
      }
    }
    _socket!.on('reaction_add', (dynamic d) => handleReactionAdd(d, 'reaction_add'));
    _socket!.on('reaction:add', (dynamic d) => handleReactionAdd(d, 'reaction:add'));

    // 3b. reaction_remove / reaction:remove -> { conversationId, messageId, emoji }
    void handleReactionRemove(dynamic data, String eventName) {
      _logInbound(eventName, data);
      try {
        final SocketReactionEvent event = SocketReactionEvent.fromJson(data, isRemoved: true);
        if (event.conversationId.isNotEmpty) {
          _reactionController.add(event);
        }
      } catch (e) {
        debugPrint('⚠️ [ChatSocketService] Error parsing "$eventName": $e');
      }
    }
    _socket!.on('reaction_remove', (dynamic d) => handleReactionRemove(d, 'reaction_remove'));
    _socket!.on('reaction:remove', (dynamic d) => handleReactionRemove(d, 'reaction:remove'));

    // 4. user_presence -> { userId, status, lastActive }
    void handlePresence(dynamic data, String eventName, {String? defaultStatus}) {
      _logInbound(eventName, data);
      try {
        final SocketUserPresenceEvent event =
            SocketUserPresenceEvent.fromJson(data, defaultStatus: defaultStatus);
        if (event.userId.isNotEmpty) {
          _userPresenceController.add(event);
        }
      } catch (e) {
        debugPrint('⚠️ [ChatSocketService] Error parsing "$eventName": $e');
      }
    }

    _socket!.on('user_presence', (dynamic d) => handlePresence(d, 'user_presence'));
    _socket!.on('user:presence', (dynamic d) => handlePresence(d, 'user:presence'));
    _socket!.on('presence', (dynamic d) => handlePresence(d, 'presence'));
    _socket!.on('presence:update', (dynamic d) => handlePresence(d, 'presence:update'));
    _socket!.on('user_online', (dynamic d) => handlePresence(d, 'user_online', defaultStatus: 'online'));
    _socket!.on('user:online', (dynamic d) => handlePresence(d, 'user:online', defaultStatus: 'online'));
    _socket!.on('user_offline', (dynamic d) => handlePresence(d, 'user_offline', defaultStatus: 'offline'));
    _socket!.on('user:offline', (dynamic d) => handlePresence(d, 'user:offline', defaultStatus: 'offline'));

    // 5. Typing events
    void handleTyping(dynamic data, String eventName, {bool? defaultTyping}) {
      _logInbound(eventName, data);
      try {
        final SocketTypingEvent event =
            SocketTypingEvent.fromAny(data, defaultTyping: defaultTyping);
        if (event.conversationId.isNotEmpty || event.userId.isNotEmpty) {
          _typingController.add(event);
        }
      } catch (e) {
        debugPrint('⚠️ [ChatSocketService] Error parsing "$eventName": $e');
      }
    }

    _socket!.on('conversation:typing', (dynamic d) => handleTyping(d, 'conversation:typing'));
    _socket!.on('typing_indicator', (dynamic d) => handleTyping(d, 'typing_indicator'));
    _socket!.on('typing:indicator', (dynamic d) => handleTyping(d, 'typing:indicator'));
    _socket!.on('typing', (dynamic d) => handleTyping(d, 'typing'));
    _socket!.on('user_typing', (dynamic d) => handleTyping(d, 'user_typing'));
    _socket!.on('user:typing', (dynamic d) => handleTyping(d, 'user:typing'));
    _socket!.on('typing:start', (dynamic d) => handleTyping(d, 'typing:start', defaultTyping: true));
    _socket!.on('typing:stop', (dynamic d) => handleTyping(d, 'typing:stop', defaultTyping: false));
  }

  void _ensureConnected() {
    if (_socket == null) {
      if (_token != null && _token!.isNotEmpty) {
        debugPrint('⚠️ [ChatSocketService] Socket was not initialized, connecting now...');
        connect(token: _token!, currentUserId: _currentUserId);
      }
    } else if (!_socket!.connected) {
      debugPrint('ℹ️ [ChatSocketService] Socket disconnected, initiating reconnection...');
      try {
        _socket!.connect();
      } catch (_) {}
    }
  }

  // ── Frontend Outbound Events (Emit) ────────────────────────────────────────

  /// Join user's personal room: `user:<userId>`
  void joinUserRoom(String userId) {
    final String cleanId = cleanUserId(userId);
    if (cleanId.isEmpty) return;
    final String userRoom = 'user:$cleanId';
    _joinedRooms.add(userRoom);
    _joinedRooms.add(cleanId);

    _ensureConnected();
    _logEmit('join', userRoom);
    _socket?.emit('join', userRoom);
    _socket?.emit('join', cleanId);
    _socket?.emit('join', <String, dynamic>{'room': userRoom, 'userId': cleanId});
    _socket?.emit('user:join', userRoom);
    _socket?.emit('user:join', cleanId);
    _socket?.emit('user:join', <String, dynamic>{'userId': cleanId, 'room': userRoom});
  }

  /// 1. conversation:join
  /// payload: conversationId
  /// purpose: join the room for that conversation (`conversation:<id>`)
  void joinConversation(String conversationId) {
    final String cleanId = cleanConversationId(conversationId);
    if (cleanId.isEmpty) return;
    final String convRoom = 'conversation:$cleanId';
    _joinedRooms.add(convRoom);
    _joinedRooms.add(cleanId);

    _ensureConnected();
    _logEmit('conversation:join', convRoom);
    _socket?.emit('conversation:join', convRoom);
    _socket?.emit('conversation:join', cleanId);
    _socket?.emit('conversation:join', <String, dynamic>{'conversationId': cleanId, 'room': convRoom});
    _socket?.emit('join', convRoom);
    _socket?.emit('join', cleanId);
    _socket?.emit('join', <String, dynamic>{'room': convRoom, 'conversationId': cleanId});
  }

  /// 2. conversation:typing & typing_indicator
  /// payload: { conversationId, userId } / { conversationId, userId, isTyping }
  /// purpose: send typing state to the room
  void sendTyping({
    required String conversationId,
    required bool isTyping,
    String? userId,
  }) {
    final String cleanConv = cleanConversationId(conversationId);
    if (cleanConv.isEmpty) return;
    final String cleanUid = cleanUserId(userId ?? _currentUserId);
    final String convRoom = 'conversation:$cleanConv';

    _ensureConnected();

    final Map<String, dynamic> fullPayload = <String, dynamic>{
      'conversationId': cleanConv,
      'isTyping': isTyping,
      if (cleanUid.isNotEmpty) 'userId': cleanUid,
    };

    final Map<String, dynamic> convTypingPayload = <String, dynamic>{
      'conversationId': cleanConv,
      if (cleanUid.isNotEmpty) 'userId': cleanUid,
    };

    _logEmit('typing_indicator', fullPayload);
    _socket?.emit('typing_indicator', fullPayload);
    _socket?.emit('typing:indicator', fullPayload);

    if (isTyping) {
      _logEmit('conversation:typing', convTypingPayload);
      _socket?.emit('conversation:typing', convTypingPayload);
      _socket?.emit('conversation:typing', <String, dynamic>{
        'conversationId': convRoom,
        if (cleanUid.isNotEmpty) 'userId': cleanUid,
      });
      _socket?.emit('conversation:typing', cleanConv);
      _socket?.emit('conversation:typing', convRoom);
    }
    _socket?.emit('conversation:typing', fullPayload);
    _socket?.emit('typing', fullPayload);
  }

  /// 3. send_message
  /// payload: { conversationId, text?, body?, mediaRef?, sharedPostId? }
  /// purpose: send a message through the backend gateway
  void sendMessage({
    required String conversationId,
    String? text,
    String? body,
    String? mediaRef,
    String? sharedPostId,
  }) {
    final String cleanId = cleanConversationId(conversationId);
    if (cleanId.isEmpty) return;

    _ensureConnected();

    final String messageBody = (body ?? text ?? '').trim();
    final Map<String, dynamic> payload = <String, dynamic>{
      'conversationId': cleanId,
      if (text != null && text.isNotEmpty) 'text': text.trim(),
      if (body != null && body.isNotEmpty) 'body': body.trim(),
      if (text == null && body == null && messageBody.isNotEmpty) 'body': messageBody,
      if (mediaRef != null && mediaRef.isNotEmpty) 'mediaRef': mediaRef,
      if (sharedPostId != null && sharedPostId.isNotEmpty)
        'sharedPostId': sharedPostId,
    };

    _logEmit('send_message', payload);
    _socket?.emit('send_message', payload);
  }

  /// 4. message_read
  /// payload: { conversationId, messageId }
  void markMessageRead({
    required String conversationId,
    required String messageId,
  }) {
    final String cleanConv = cleanConversationId(conversationId);
    final String cleanMsg = messageId.trim();
    if (cleanConv.isEmpty || cleanMsg.isEmpty) return;

    _ensureConnected();

    final Map<String, dynamic> payload = <String, dynamic>{
      'conversationId': cleanConv,
      'messageId': cleanMsg,
    };
    _logEmit('message_read', payload);
    _socket?.emit('message_read', payload);
  }

  /// 5. reaction_add
  /// payload: { conversationId, messageId, emoji }
  void addReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
    String? userId,
  }) {
    final String cleanConv = cleanConversationId(conversationId);
    final String cleanMsg = messageId.trim();
    final String cleanEmoji = emoji.trim();
    if (cleanConv.isEmpty || cleanMsg.isEmpty || cleanEmoji.isEmpty) {
      return;
    }

    _ensureConnected();

    final Map<String, dynamic> payload = <String, dynamic>{
      'conversationId': cleanConv,
      'messageId': cleanMsg,
      'emoji': cleanEmoji,
    };
    _logEmit('reaction_add', payload);
    _socket?.emit('reaction_add', payload);
  }

  /// 6. reaction_remove
  /// payload: { conversationId, messageId, emoji }
  void removeReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
    String? userId,
  }) {
    final String cleanConv = cleanConversationId(conversationId);
    final String cleanMsg = messageId.trim();
    final String cleanEmoji = emoji.trim();
    if (cleanConv.isEmpty || cleanMsg.isEmpty || cleanEmoji.isEmpty) {
      return;
    }

    _ensureConnected();

    final Map<String, dynamic> payload = <String, dynamic>{
      'conversationId': cleanConv,
      'messageId': cleanMsg,
      'emoji': cleanEmoji,
    };
    _logEmit('reaction_remove', payload);
    _socket?.emit('reaction_remove', payload);
  }

  /// 7. unsend_message
  /// payload: { conversationId, messageId }
  void unsendMessage({
    required String conversationId,
    required String messageId,
  }) {
    final String cleanConv = cleanConversationId(conversationId);
    final String cleanMsg = messageId.trim();
    if (cleanConv.isEmpty || cleanMsg.isEmpty) return;

    _ensureConnected();

    final Map<String, dynamic> payload = <String, dynamic>{
      'conversationId': cleanConv,
      'messageId': cleanMsg,
    };
    _logEmit('unsend_message', payload);
    _socket?.emit('unsend_message', payload);
  }

  /// 8. mute_conversation
  /// payload: { conversationId, duration? }
  void muteConversation({
    required String conversationId,
    String? duration,
  }) {
    final String cleanConv = cleanConversationId(conversationId);
    if (cleanConv.isEmpty) return;

    _ensureConnected();

    final Map<String, dynamic> payload = <String, dynamic>{
      'conversationId': cleanConv,
      if (duration != null && duration.isNotEmpty) 'duration': duration,
    };
    _logEmit('mute_conversation', payload);
    _socket?.emit('mute_conversation', payload);
  }

  /// 9. unmute_conversation
  /// payload: { conversationId }
  void unmuteConversation(String conversationId) {
    final String cleanConv = cleanConversationId(conversationId);
    if (cleanConv.isEmpty) return;

    _ensureConnected();

    final Map<String, dynamic> payload = <String, dynamic>{
      'conversationId': cleanConv,
    };
    _logEmit('unmute_conversation', payload);
    _socket?.emit('unmute_conversation', payload);
  }

  /// Disconnect socket and clear state.
  void disconnect() {
    if (_socket != null) {
      try {
        _socket!.disconnect();
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }
    _isConnected = false;
    _connectionStateController.add(false);
  }

  /// Dispose service and close all streams.
  void dispose() {
    disconnect();
    _connectionStateController.close();
    _newMessageController.close();
    _messageReadController.close();
    _reactionController.close();
    _userPresenceController.close();
    _typingController.close();
  }
}

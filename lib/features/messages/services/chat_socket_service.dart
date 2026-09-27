import 'dart:async';
import 'dart:convert';
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

class SocketMessageDeletedEvent {
  const SocketMessageDeletedEvent({
    required this.conversationId,
    required this.messageId,
  });

  final String conversationId;
  final String messageId;

  factory SocketMessageDeletedEvent.fromJson(dynamic data) {
    if (data is String) {
      try {
        final dynamic decoded = jsonDecode(data);
        if (decoded is Map) {
          return SocketMessageDeletedEvent.fromJson(decoded);
        }
      } catch (_) {
        return SocketMessageDeletedEvent(conversationId: '', messageId: data.trim());
      }
    }
    if (data is! Map) {
      return const SocketMessageDeletedEvent(conversationId: '', messageId: '');
    }
    final Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final dynamic payload = map['data'] is Map ? map['data'] : map;
    final dynamic rawMsg = payload['message'];
    final String msgId = (payload['messageId'] ??
            payload['message_id'] ??
            (rawMsg is Map ? (rawMsg['id'] ?? rawMsg['messageId']) : null) ??
            payload['id'] ??
            payload['_id'] ??
            '')
        .toString()
        .trim();

    return SocketMessageDeletedEvent(
      conversationId: cleanConversationId(
        payload['conversationId'] ??
            payload['conversation_id'] ??
            (rawMsg is Map ? rawMsg['conversationId'] : null) ??
            payload['convId'] ??
            payload['room'] ??
            payload['roomId'],
      ),
      messageId: msgId,
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
    this.username,
    this.lastActive,
  });

  final String userId;
  final String status;
  final String? username;
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

    final dynamic rawUser = payload['user'];
    String uId = cleanUserId(
      payload['userId'] ??
          payload['user_id'] ??
          payload['senderId'] ??
          payload['sender_id'] ??
          payload['participantId'] ??
          (rawUser is Map ? (rawUser['id'] ?? rawUser['_id'] ?? rawUser['userId']) : null) ??
          payload['id'] ??
          payload['_id'] ??
          '',
    );

    final String rawUname = (payload['username'] ??
            payload['handle'] ??
            (rawUser is Map ? (rawUser['username'] ?? rawUser['handle']) : null) ??
            '')
        .toString()
        .trim();
    final String cleanUname = cleanUserId(rawUname);

    if (uId.isEmpty && cleanUname.isNotEmpty) {
      uId = cleanUname;
    }

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
      username: cleanUname.isNotEmpty ? cleanUname : null,
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
        payload['status'] ??
        payload['state'] ??
        payload['action'];

    bool typing = defaultTyping ?? true;
    if (typingRaw is bool) {
      typing = typingRaw;
    } else if (typingRaw != null) {
      final String s = typingRaw.toString().toLowerCase();
      typing = s == 'true' || s == '1' || s == 'typing' || s == 'start';
    }

    final dynamic sender = payload['sender'] is Map ? payload['sender'] : null;
    final dynamic user = payload['user'] is Map ? payload['user'] : null;

    final String extractedConvId = cleanConversationId(
      payload['conversationId'] ??
          payload['conversation_id'] ??
          payload['convId'] ??
          payload['room'] ??
          payload['roomId'] ??
          payload['id'] ??
          '',
    );

    final String extractedUserId = cleanUserId(
      payload['userId'] ??
          payload['user_id'] ??
          payload['senderId'] ??
          payload['sender_id'] ??
          (sender != null ? (sender['userId'] ?? sender['id']) : null) ??
          (user != null ? (user['userId'] ?? user['id']) : null) ??
          payload['username'] ??
          '',
    );

    return SocketTypingEvent(
      conversationId: extractedConvId,
      userId: extractedUserId,
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
  final StreamController<void> _presenceQueryController =
      StreamController<void>.broadcast();
  final StreamController<SocketMessageDeletedEvent> _messageDeletedController =
      StreamController<SocketMessageDeletedEvent>.broadcast();

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
  Stream<void> get onPresenceQuery => _presenceQueryController.stream;
  Stream<SocketMessageDeletedEvent> get onMessageDeleted =>
      _messageDeletedController.stream;

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

    String url = _customUrl ?? AppConfig.socketUrl;
    if (url.isEmpty) {
      url = 'http://3.208.100.236:3018';
    } else if (url.contains(':3001')) {
      url = url.replaceAll(':3001', ':3018');
    }

    // If socket already connected with same token and url, return
    if (_socket != null && _socket!.connected) {
      debugPrint('ℹ️ [ChatSocketService] Socket already connected. ID: ${_socket?.id}');
      return;
    }

    disconnect();

    debugPrint('🔌 [ChatSocketService] Connecting to $url via websocket transport with token (length: ${token.length})...');

    try {
      final String rawToken = token.startsWith('Bearer ')
          ? token.substring(7).trim()
          : token.trim();
      final String bearerToken = 'Bearer $rawToken';

      final socket_io.OptionBuilder builder = socket_io.OptionBuilder()
          .setTransports(<String>['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(20)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000)
          .enableForceNew()
          .setAuth(<String, dynamic>{
            'token': rawToken,
            'accessToken': rawToken,
          })
          .setQuery(<String, dynamic>{
            'token': rawToken,
            'accessToken': rawToken,
          })
          .setExtraHeaders(<String, String>{
            'Authorization': bearerToken,
            'authorization': bearerToken,
            'token': rawToken,
            'accessToken': rawToken,
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
          'unsend_message',
          'message:unsend',
          'message_unsend',
          'delete_message',
          'message:delete',
          'message_deleted',
          'message:deleted',
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

      // Announce online presence to socket gateway with current timestamp
      try {
        final String? cleanUid =
            _currentUserId != null ? cleanUserId(_currentUserId!) : null;
        final String nowIso = DateTime.now().toUtc().toIso8601String();
        final int nowEpoch = DateTime.now().millisecondsSinceEpoch;
        final Map<String, dynamic> activePayload = <String, dynamic>{
          if (cleanUid != null && cleanUid.isNotEmpty) 'userId': cleanUid,
          'status': 'active',
          'isOnline': true,
          'online': true,
          'lastActive': nowIso,
          'timestamp': nowEpoch,
        };
        final Map<String, dynamic> onlinePayload = <String, dynamic>{
          if (cleanUid != null && cleanUid.isNotEmpty) 'userId': cleanUid,
          'status': 'online',
          'isOnline': true,
          'online': true,
          'lastActive': nowIso,
          'timestamp': nowEpoch,
        };
        _logEmit('user_presence', activePayload);
        _socket!.emit('user_presence', activePayload);
        _socket!.emit('user_presence', onlinePayload);
        _socket!.emit('presence:online', activePayload);
        _socket!.emit('presence', activePayload);
        _socket!.emit('user:presence', activePayload);
        _socket!.emit('user_online', activePayload);
        _socket!.emit('user:online', activePayload);
        _socket!.emit('presence:query', activePayload);
        _socket!.emit('user_presence:query', activePayload);
        _socket!.emit('get_presence', activePayload);
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

    // 3c. unsend_message / delete_message -> { conversationId, messageId }
    void handleMessageDeleted(dynamic data, String eventName) {
      _logInbound(eventName, data);
      try {
        final SocketMessageDeletedEvent event = SocketMessageDeletedEvent.fromJson(data);
        if (event.messageId.isNotEmpty) {
          _messageDeletedController.add(event);
        }
      } catch (e) {
        debugPrint('⚠️ [ChatSocketService] Error parsing "$eventName": $e');
      }
    }
    _socket!.on('unsend_message', (dynamic d) => handleMessageDeleted(d, 'unsend_message'));
    _socket!.on('message:unsend', (dynamic d) => handleMessageDeleted(d, 'message:unsend'));
    _socket!.on('message_unsend', (dynamic d) => handleMessageDeleted(d, 'message_unsend'));
    _socket!.on('message_unsent', (dynamic d) => handleMessageDeleted(d, 'message_unsent'));
    _socket!.on('message:unsent', (dynamic d) => handleMessageDeleted(d, 'message:unsent'));
    _socket!.on('unsend', (dynamic d) => handleMessageDeleted(d, 'unsend'));
    _socket!.on('delete_message', (dynamic d) => handleMessageDeleted(d, 'delete_message'));
    _socket!.on('message:delete', (dynamic d) => handleMessageDeleted(d, 'message:delete'));
    _socket!.on('message_delete', (dynamic d) => handleMessageDeleted(d, 'message_delete'));
    _socket!.on('message_deleted', (dynamic d) => handleMessageDeleted(d, 'message_deleted'));
    _socket!.on('message:deleted', (dynamic d) => handleMessageDeleted(d, 'message:deleted'));
    _socket!.on('reaction:remove', (dynamic d) => handleReactionRemove(d, 'reaction:remove'));

    // 4. user_presence -> { userId, status, lastActive }
    void handlePresence(dynamic data, String eventName, {String? defaultStatus}) {
      _logInbound(eventName, data);
      try {
        if (data is List) {
          for (final dynamic item in data) {
            final SocketUserPresenceEvent event =
                SocketUserPresenceEvent.fromJson(item, defaultStatus: defaultStatus);
            if (event.userId.isNotEmpty) {
              _userPresenceController.add(event);
            }
          }
          return;
        }
        if (data is Map && data['users'] is List) {
          for (final dynamic item in data['users'] as List) {
            final SocketUserPresenceEvent event =
                SocketUserPresenceEvent.fromJson(item, defaultStatus: defaultStatus);
            if (event.userId.isNotEmpty) {
              _userPresenceController.add(event);
            }
          }
          return;
        }
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
    _socket!.on('conversation:presence', (dynamic d) => handlePresence(d, 'conversation:presence'));
    _socket!.on('conversation_presence', (dynamic d) => handlePresence(d, 'conversation_presence'));

    // Presence queries from other peers asking who is online
    void handlePresenceQuery(dynamic data, String eventName) {
      _logInbound(eventName, data);
      _presenceQueryController.add(null);
    }
    _socket!.on('presence:query', (dynamic d) => handlePresenceQuery(d, 'presence:query'));
    _socket!.on('user_presence:query', (dynamic d) => handlePresenceQuery(d, 'user_presence:query'));
    _socket!.on('get_presence', (dynamic d) => handlePresenceQuery(d, 'get_presence'));

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
    _socket!.on('message:typing', (dynamic d) => handleTyping(d, 'message:typing'));
    _socket!.on('chat:typing', (dynamic d) => handleTyping(d, 'chat:typing'));
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
    final String roomName = 'conversation:$cleanId';
    _joinedRooms.add(roomName);
    _joinedRooms.add(cleanId);

    _ensureConnected();
    _logEmit('join', roomName);
    _socket?.emit('join', roomName);
    _socket?.emit('join', cleanId);
    _socket?.emit('conversation:join', roomName);
    _socket?.emit('conversation:join', cleanId);
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
    _socket?.emit('typing', fullPayload);
    _socket?.emit('conversation:typing', fullPayload);
    _socket?.emit('user_typing', fullPayload);
    _socket?.emit('user:typing', fullPayload);

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

  /// Broadcast online/offline presence explicitly with current timestamp
  void sendPresence({
    required bool isOnline,
    String? targetUserId,
    String? conversationId,
  }) {
    if (_socket == null || !_socket!.connected) return;
    final String? cleanUid =
        _currentUserId != null ? cleanUserId(_currentUserId!) : null;
    final String? cleanTarget =
        targetUserId != null && targetUserId.isNotEmpty ? cleanUserId(targetUserId) : null;
    final String? cleanConv =
        conversationId != null && conversationId.isNotEmpty ? cleanConversationId(conversationId) : null;
    final String nowIso = DateTime.now().toUtc().toIso8601String();
    final int nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final Map<String, dynamic> payload = <String, dynamic>{
      if (cleanUid != null && cleanUid.isNotEmpty) 'userId': cleanUid,
      'status': isOnline ? 'active' : 'offline',
      'isOnline': isOnline,
      'online': isOnline,
      'lastActive': nowIso,
      'timestamp': nowEpoch,
      if (cleanTarget != null && cleanTarget.isNotEmpty) ...<String, dynamic>{
        'targetUserId': cleanTarget,
        'recipientId': cleanTarget,
        'participantId': cleanTarget,
      },
      if (cleanConv != null && cleanConv.isNotEmpty) 'conversationId': cleanConv,
    };
    _logEmit('user_presence', payload);
    _socket?.emit('user_presence', payload);
    _socket?.emit('presence', payload);
    _socket?.emit('user:presence', payload);
    if (isOnline) {
      _socket?.emit('presence:online', payload);
      _socket?.emit('user_online', payload);
      _socket?.emit('user:online', payload);
      if (cleanConv != null && cleanConv.isNotEmpty) {
        _socket?.emit('conversation:presence', payload);
        _socket?.emit('conversation_presence', payload);
      }
    } else {
      _socket?.emit('presence:offline', payload);
      _socket?.emit('user_offline', payload);
      _socket?.emit('user:offline', payload);
      if (cleanConv != null && cleanConv.isNotEmpty) {
        _socket?.emit('conversation:offline', payload);
      }
    }
  }

  /// Ask all connected peers to announce their current online status.
  /// Called after joining conversation rooms so already-online users reply back
  /// with their presence even if they logged in before us.
  void requestPresenceFromAll() {
    if (_socket == null || !_socket!.connected) return;
    final String? cleanUid =
        _currentUserId != null ? cleanUserId(_currentUserId!) : null;
    final int nowEpoch = DateTime.now().millisecondsSinceEpoch;
    final Map<String, dynamic> queryPayload = <String, dynamic>{
      if (cleanUid != null && cleanUid.isNotEmpty) 'userId': cleanUid,
      'timestamp': nowEpoch,
    };
    _logEmit('presence:query', queryPayload);
    _socket?.emit('presence:query', queryPayload);
    _socket?.emit('user_presence:query', queryPayload);
    _socket?.emit('get_presence', queryPayload);
    _socket?.emit('presence:ping', queryPayload);
    _socket?.emit('who_is_online', queryPayload);
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
    _socket?.emit('message:read', payload);
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
    _socket?.emit('message:unsend', payload);
    _socket?.emit('delete_message', payload);
    _socket?.emit('message:delete', payload);
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
        // Best-effort: announce offline before closing connection
        if (_socket!.connected) {
          final String? cleanUid =
              _currentUserId != null ? cleanUserId(_currentUserId!) : null;
          final String nowIso = DateTime.now().toUtc().toIso8601String();
          final Map<String, dynamic> offlinePayload = <String, dynamic>{
            if (cleanUid != null && cleanUid.isNotEmpty) 'userId': cleanUid,
            'status': 'offline',
            'isOnline': false,
            'online': false,
            'lastActive': nowIso,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
          _socket!.emit('user_presence', offlinePayload);
          _socket!.emit('user:presence', offlinePayload);
          _socket!.emit('user_offline', offlinePayload);
          _socket!.emit('user:offline', offlinePayload);
        }
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
    _presenceQueryController.close();
    _messageDeletedController.close();
  }
}

import 'dart:async' show Timer;
import 'dart:convert' show jsonDecode, jsonEncode;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_exception.dart';
import '../models/message_models.dart';
import '../services/conversations_service.dart';

class MessagesProvider extends ChangeNotifier {
  MessagesProvider({
    ConversationsService? service,
    String? currentUserId,
  })  : _service = service,
        _currentUserId = currentUserId {
    _loadPersistedReadStates();
    if (_currentUserId != null && _currentUserId!.isNotEmpty) {
      startPolling();
    }
  }

  ConversationsService? _service;
  String? _currentUserId;
  bool _isDisposed = false;
  Timer? _pollTimer;
  String? _activeChatConvId;

  final Set<String> _locallyReadMessageIds = <String>{};
  final Map<String, DateTime> _lastReadTimeByConv = <String, DateTime>{};

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
      if (m.isRead) return m;
      // CRITICAL: Local read states only apply to INCOMING messages (!m.isMe).
      // A message sent by me (m.isMe) can ONLY be marked as read when the recipient reads it on the server!
      if (!m.isMe) {
        if (_locallyReadMessageIds.contains(m.id)) {
          return m.copyWith(isRead: true);
        }
        if (lastReadTime != null &&
            m.createdAt != null &&
            !m.createdAt!.isAfter(lastReadTime)) {
          return m.copyWith(isRead: true);
        }
      }
      return m;
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
  }

  void startPolling() {
    if (_pollTimer != null && _pollTimer!.isActive) return;
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (_isDisposed) return;
      if (_currentUserId == null || _currentUserId!.isEmpty) return;

      // 1. If user is currently in a chat, poll newest messages for this chat
      if (_activeChatConvId != null && _activeChatConvId!.isNotEmpty) {
        try {
          await loadMessages(_activeChatConvId!, silent: true);
        } catch (_) {}
      }

      // 2. Poll and sync all conversations and their latest messages
      try {
        await refreshConversationsSilently();
      } catch (_) {}
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void dispose() {
    _isDisposed = true;
    stopPolling();
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
      _loadPersistedReadStates();
    }
    if (service != null && service != _service) {
      _service = service;
      shouldReload = true;
    }
    if (userId == null || userId.isEmpty) {
      _currentUserId = null;
      _conversations.clear();
      _messagesByConvId.clear();
      _messageRequests.clear();
      stopPolling();
      notifyListeners();
    } else {
      startPolling();
      if (shouldReload || _conversations.isEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          loadConversations();
          loadMessageRequests();
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
  final Map<String, bool> _typingIndicatorEnabled = <String, bool>{};

  bool isMuted(String key) {
    if (_mutedUsers[key] == true) return true;
    final String clean = key.startsWith('@') ? key.substring(1) : key;
    if (_mutedUsers[clean] == true || _mutedUsers['@$clean'] == true) return true;
    return false;
  }
  bool isRestricted(String username) => _restrictedUsers[username] ?? false;
  bool isBlocked(String username) => _blockedUsers[username] ?? false;
  bool isTypingIndicatorEnabled(String username) =>
      _typingIndicatorEnabled[username] ?? true;

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
    if (_conversations.isEmpty) {
      _isLoadingConversations = true;
      notifyListeners();
    }

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

      // If active chat is currently this conversation, mark unread messages as read
      if (_activeChatConvId == conversationId) {
        _lastReadTimeByConv[conversationId] = DateTime.now();
        if (_service != null && !conversationId.startsWith('temp_')) {
          _service!.markConversationRead(conversationId);
          for (final ChatMessageModel raw in fetched) {
            if (!raw.isMe && !raw.isRead && !raw.id.startsWith('temp_') && !raw.id.startsWith('m_')) {
              _service!.markMessageRead(
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
            final int cIdx = _conversations.indexWhere((c) => c.id == targetConvId);
            if (cIdx != -1) {
              _conversations[cIdx] = _conversations[cIdx].copyWith(
                lastMessageAt: serverMsg.createdAt ?? DateTime.now(),
              );
              _sortConversations();
            }
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
      if (idx != -1 && !msgs[idx].isRead && !msgs[idx].isMe) {
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

    // 3. Sync read status with backend
    if (_service != null &&
        conversationId.isNotEmpty &&
        !conversationId.startsWith('temp_')) {
      _service!.markConversationRead(conversationId);
      await Future.wait(
        unreadIds
            .where((String id) => !id.startsWith('temp_') && !id.startsWith('m_'))
            .map((String msgId) => _service!.markMessageRead(
                  conversationId: conversationId,
                  messageId: msgId,
                )),
      );

      // If messages weren't loaded in memory yet, fetch and mark unread items
      if (msgs == null || msgs.isEmpty) {
        try {
          final List<ChatMessageModel> fetched = await _service!.getMessages(
            conversationId: conversationId,
            currentUserId: _currentUserId,
          );
          if (fetched.isNotEmpty) {
            final List<ChatMessageModel> updatedList = <ChatMessageModel>[];
            final List<Future<bool>> markTasks = <Future<bool>>[];
            for (final ChatMessageModel m in fetched) {
              if (!m.isMe) {
                _locallyReadMessageIds.add(m.id);
                if (!m.isRead && !m.id.startsWith('temp_') && !m.id.startsWith('m_')) {
                  markTasks.add(_service!.markMessageRead(
                    conversationId: conversationId,
                    messageId: m.id,
                  ));
                }
                updatedList.add(m.copyWith(isRead: true));
              } else {
                updatedList.add(m);
              }
            }
            if (markTasks.isNotEmpty) {
              await Future.wait(markTasks);
            }
            _messagesByConvId[conversationId] = updatedList;
            _persistReadStates();
            if (convIdx != -1) {
              _conversations[convIdx] =
                  _conversations[convIdx].copyWith(messages: updatedList, unreadCount: 0);
              notifyListeners();
            }
          }
        } catch (_) {}
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

    // 2. API Sync
    if (_service != null && targetId.isNotEmpty && !targetId.startsWith('temp_')) {
      await _service!.muteConversation(
        conversationId: targetId,
        duration: duration,
      );
    }
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

    // 2. API Sync
    if (_service != null && targetId.isNotEmpty && !targetId.startsWith('temp_')) {
      await _service!.unmuteConversation(targetId);
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
  }
}

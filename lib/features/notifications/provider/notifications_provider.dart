import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../profile/models/user_relationship_models.dart';
import '../../profile/services/user_relationship_service.dart';
import '../models/notification_item_model.dart';
import '../services/notifications_service.dart';

class NotificationsProvider extends ChangeNotifier {
  NotificationsProvider({
    required NotificationsService service,
    UserRelationshipService? relationshipService,
    String? currentUserId,
  })  : _service = service,
        _relationshipService = relationshipService,
        _currentUserId = currentUserId {
    _loadPersistedFollowStatuses();
  }

  final NotificationsService _service;
  UserRelationshipService? _relationshipService;
  String? _currentUserId;

  List<NotificationItemModel> _notifications = <NotificationItemModel>[];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int _selectedFilterIndex = 0;
  String? _registeredToken;

  static const String _prefDeviceTokenKey = 'ql_device_push_token';
  static const String _prefFollowStatusesKey = 'ql_follow_action_statuses';

  // Getters
  List<NotificationItemModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get selectedFilterIndex => _selectedFilterIndex;
  String? get registeredToken => _registeredToken;

  static const List<String> filters = <String>[
    'All',
    'Likes',
    'Comments',
    'Follows',
    'Safety',
  ];

  List<NotificationItemModel> get filteredNotifications {
    switch (_selectedFilterIndex) {
      case 1: // Likes
        return _notifications.where((NotificationItemModel n) => n.isLike).toList();
      case 2: // Comments
        return _notifications.where((NotificationItemModel n) => n.isComment).toList();
      case 3: // Follows
        return _notifications
            .where((NotificationItemModel n) => n.isFollow || n.isFollowRequest)
            .toList();
      case 4: // Safety
        return _notifications.where((NotificationItemModel n) => n.isSafety).toList();
      case 0: // All
      default:
        return _notifications;
    }
  }

  void setFilterIndex(int index) {
    if (_selectedFilterIndex == index) return;
    _selectedFilterIndex = index;
    notifyListeners();
  }

  /// Sync user authentication changes (e.g. from ProxyProvider)
  void syncAuth({
    String? userId,
    UserRelationshipService? relationshipService,
  }) {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      if (userId != null && userId.isNotEmpty) {
        initDeviceToken();
        loadNotifications(refresh: true);
      } else {
        _notifications.clear();
        _unreadCount = 0;
        _registeredToken = null;
        notifyListeners();
      }
    }
    if (relationshipService != null) {
      _relationshipService = relationshipService;
    }
  }

  // ── Fetch Notifications & Unread Count ─────────────────────────────────────
  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading && !refresh) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final Future<List<NotificationItemModel>> notifsFuture =
          _service.getNotifications();
      final Future<int> countFuture = _service.getUnreadCount();

      final List<dynamic> results = await Future.wait<dynamic>(<Future<dynamic>>[
        notifsFuture,
        countFuture,
      ]);

      final List<NotificationItemModel> remoteNotifs =
          results[0] as List<NotificationItemModel>;
      final int remoteCount = results[1] as int;

      _notifications = _deduplicateNotifications(remoteNotifs);
      final int actualUnread =
          _notifications.where((NotificationItemModel n) => !n.isRead).length;
      _unreadCount = (remoteCount > 0 && remoteCount <= _notifications.length)
          ? remoteCount
          : actualUnread;
    } catch (e) {
      debugPrint('⚠️ [NotificationsProvider] loadNotifications error: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<NotificationItemModel> _deduplicateNotifications(
    List<NotificationItemModel> rawList,
  ) {
    if (rawList.isEmpty) return <NotificationItemModel>[];

    final Set<String> seenIds = <String>{};
    final Set<String> seenFollowActors = <String>{};
    final List<NotificationItemModel> result = <NotificationItemModel>[];

    String getActorKey(NotificationItemModel item) {
      if (item.actorId != null && item.actorId!.trim().isNotEmpty) {
        return item.actorId!.trim().toLowerCase();
      }
      return item.displayUsername.replaceAll('@', '').trim().toLowerCase();
    }

    for (final NotificationItemModel item in rawList) {
      // 1. Strict unique ID check
      if (!seenIds.add(item.id)) {
        continue;
      }

      final String actorKey = getActorKey(item);

      // 2. Follow / Follow-Request deduplication per actor
      if (item.isFollow || item.isFollowRequest) {
        if (actorKey.isNotEmpty) {
          if (!seenFollowActors.add(actorKey)) {
            continue;
          }
        }
      }

      // 3. Proximity / Semantic deduplication for interactions & likes
      final bool isDuplicate = result.any((NotificationItemModel existing) {
        final String existingActor = getActorKey(existing);
        if (existingActor.isEmpty || actorKey.isEmpty) return false;
        if (existingActor != actorKey) return false;

        final bool sameType =
            existing.type.toUpperCase() == item.type.toUpperCase();
        final bool sameBody = (existing.body != null &&
            item.body != null &&
            existing.body!.trim().toLowerCase() ==
                item.body!.trim().toLowerCase());

        if (sameType || sameBody) {
          final bool samePost = existing.postId == item.postId;
          final bool sameComment = existing.commentId == item.commentId;

          if (samePost && sameComment) {
            if (existing.createdAt != null && item.createdAt != null) {
              final Duration diff =
                  existing.createdAt!.difference(item.createdAt!).abs();
              if (diff.inMinutes <= 15) return true;
            } else if (existing.timeAgo == item.timeAgo) {
              return true;
            }
          }
        }
        return false;
      });

      if (isDuplicate) {
        continue;
      }

      result.add(item);
    }

    return result;
  }

  // ── Mark Single Notification as Read ───────────────────────────────────────
  Future<void> markAsRead(String id) async {
    final int index = _notifications.indexWhere((NotificationItemModel n) => n.id == id);
    if (index == -1) return;

    if (_notifications[index].isRead) return; // Already read

    // Optimistic local update
    _notifications[index] = _notifications[index].copyWith(isRead: true);
    if (_unreadCount > 0) {
      _unreadCount--;
    }
    notifyListeners();

    // Call API in background
    await _service.markAsRead(id);
  }

  // ── Mark All Notifications as Read ─────────────────────────────────────────
  Future<void> markAllAsRead() async {
    if (_notifications.isEmpty && _unreadCount == 0) return;

    // Optimistic local update
    _notifications = _notifications
        .map((NotificationItemModel n) => n.copyWith(isRead: true))
        .toList();
    _unreadCount = 0;
    notifyListeners();

    // Call API in background
    await _service.markAllAsRead();
  }

  // ── Follow Request Actions ─────────────────────────────────────────────────
  final Map<String, String> _followActionStatuses = <String, String>{};

  Future<void> _loadPersistedFollowStatuses() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String>? entries = prefs.getStringList(_prefFollowStatusesKey);
      if (entries != null) {
        for (final String e in entries) {
          final int sep = e.indexOf(':');
          if (sep != -1) {
            final String k = e.substring(0, sep);
            final String v = e.substring(sep + 1);
            _followActionStatuses[k] = v;
          }
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> _savePersistedFollowStatuses() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<String> entries = _followActionStatuses.entries
          .map((MapEntry<String, String> e) => '${e.key}:${e.value}')
          .toList();
      await prefs.setStringList(_prefFollowStatusesKey, entries);
    } catch (_) {}
  }

  String getFollowStatus(
    String notifId, {
    String? actorId,
    String? username,
    String? fallbackStatus,
  }) {
    if (_followActionStatuses.containsKey(notifId)) {
      return _followActionStatuses[notifId]!;
    }
    if (actorId != null && actorId.isNotEmpty) {
      if (_followActionStatuses.containsKey('actor_$actorId')) {
        return _followActionStatuses['actor_$actorId']!;
      }
      if (_followActionStatuses.containsKey('user_${actorId.toLowerCase()}')) {
        return _followActionStatuses['user_${actorId.toLowerCase()}']!;
      }
    }
    if (username != null && username.isNotEmpty) {
      final String clean = username.replaceAll('@', '').trim().toLowerCase();
      if (_followActionStatuses.containsKey('user_$clean')) {
        return _followActionStatuses['user_$clean']!;
      }
    }
    if (fallbackStatus != null && fallbackStatus.isNotEmpty) {
      return fallbackStatus;
    }

    // If there is another notification in the list confirming this user is already following
    final String cleanUser =
        (username ?? '').replaceAll('@', '').trim().toLowerCase();
    final String cleanActor = (actorId ?? '').trim().toLowerCase();
    final bool hasFollowNotification = _notifications.any((NotificationItemModel n) {
      if (!n.isFollow || n.isFollowRequest) return false;
      final String nActor = (n.actorId ?? '').trim().toLowerCase();
      final String nUser = n.displayUsername.replaceAll('@', '').trim().toLowerCase();
      return (cleanActor.isNotEmpty && nActor == cleanActor) ||
          (cleanUser.isNotEmpty && nUser == cleanUser);
    });

    if (hasFollowNotification) {
      return 'accepted';
    }

    return '';
  }

  Future<bool> acceptFollowRequest({
    required String notificationId,
    required String userId,
    required String username,
    String? followRequestId,
  }) async {
    _followActionStatuses[notificationId] = 'accepted';
    if (userId.isNotEmpty) {
      _followActionStatuses['actor_$userId'] = 'accepted';
      _followActionStatuses['user_${userId.toLowerCase()}'] = 'accepted';
    }
    if (username.isNotEmpty) {
      final String clean = username.replaceAll('@', '').trim().toLowerCase();
      _followActionStatuses['user_$clean'] = 'accepted';
    }
    _savePersistedFollowStatuses();
    notifyListeners();

    markAsRead(notificationId);

    if (_relationshipService != null) {
      try {
        String? targetRequestId = followRequestId?.trim();

        // If followRequestId is not available from notification payload,
        // lookup pending follow requests to find the exact request ID.
        if (targetRequestId == null || targetRequestId.isEmpty) {
          debugPrint('🔍 [NotificationsProvider] Looking up pending follow requests for $userId / $username...');
          try {
            final List<FollowRequestItem> requests =
                await _relationshipService!.getFollowRequests();
            final String cleanUser =
                username.replaceAll('@', '').trim().toLowerCase();
            final String cleanUserId = userId.trim().toLowerCase();

            for (final FollowRequestItem req in requests) {
              final bool idMatches = cleanUserId.isNotEmpty &&
                  (req.userId.trim().toLowerCase() == cleanUserId ||
                      req.id.trim().toLowerCase() == cleanUserId);
              final bool nameMatches = cleanUser.isNotEmpty &&
                  (req.username.trim().toLowerCase() == cleanUser ||
                      req.displayName.trim().toLowerCase() == cleanUser);

              if (idMatches || nameMatches) {
                targetRequestId = req.id;
                debugPrint('✅ [NotificationsProvider] Found pending request match: ${req.id} (user: ${req.username})');
                break;
              }
            }
          } catch (e) {
            debugPrint('⚠️ [NotificationsProvider] Error querying follow requests: $e');
          }
        }

        final String primaryId = (targetRequestId != null && targetRequestId.isNotEmpty)
            ? targetRequestId
            : userId;

        debugPrint('🚀 [NotificationsProvider] Accepting follow request using ID: $primaryId');
        try {
          final bool ok = await _relationshipService!.acceptFollowRequest(primaryId);
          if (ok) return true;
        } catch (e) {
          debugPrint('⚠️ [NotificationsProvider] Primary accept ($primaryId) failed: $e');
          if (primaryId != userId && userId.trim().isNotEmpty) {
            debugPrint('🔄 [NotificationsProvider] Retrying accept with userId: $userId');
            final bool ok = await _relationshipService!.acceptFollowRequest(userId);
            return ok;
          }
          rethrow;
        }
      } catch (e) {
        debugPrint('⚠️ [NotificationsProvider] acceptFollowRequest error: $e');
        _followActionStatuses.remove(notificationId);
        _savePersistedFollowStatuses();
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  Future<bool> declineFollowRequest({
    required String notificationId,
    required String userId,
    required String username,
    String? followRequestId,
  }) async {
    _followActionStatuses[notificationId] = 'declined';
    if (userId.isNotEmpty) {
      _followActionStatuses['actor_$userId'] = 'declined';
      _followActionStatuses['user_${userId.toLowerCase()}'] = 'declined';
    }
    if (username.isNotEmpty) {
      final String clean = username.replaceAll('@', '').trim().toLowerCase();
      _followActionStatuses['user_$clean'] = 'declined';
    }
    _savePersistedFollowStatuses();
    notifyListeners();

    markAsRead(notificationId);

    if (_relationshipService != null) {
      try {
        String? targetRequestId = followRequestId?.trim();

        if (targetRequestId == null || targetRequestId.isEmpty) {
          debugPrint('🔍 [NotificationsProvider] Looking up pending follow requests for $userId / $username...');
          try {
            final List<FollowRequestItem> requests =
                await _relationshipService!.getFollowRequests();
            final String cleanUser =
                username.replaceAll('@', '').trim().toLowerCase();
            final String cleanUserId = userId.trim().toLowerCase();

            for (final FollowRequestItem req in requests) {
              final bool idMatches = cleanUserId.isNotEmpty &&
                  (req.userId.trim().toLowerCase() == cleanUserId ||
                      req.id.trim().toLowerCase() == cleanUserId);
              final bool nameMatches = cleanUser.isNotEmpty &&
                  (req.username.trim().toLowerCase() == cleanUser ||
                      req.displayName.trim().toLowerCase() == cleanUser);

              if (idMatches || nameMatches) {
                targetRequestId = req.id;
                debugPrint('✅ [NotificationsProvider] Found pending request match: ${req.id} (user: ${req.username})');
                break;
              }
            }
          } catch (e) {
            debugPrint('⚠️ [NotificationsProvider] Error querying follow requests: $e');
          }
        }

        final String primaryId = (targetRequestId != null && targetRequestId.isNotEmpty)
            ? targetRequestId
            : userId;

        debugPrint('🚀 [NotificationsProvider] Rejecting follow request using ID: $primaryId');
        try {
          final bool ok = await _relationshipService!.rejectFollowRequest(primaryId);
          if (ok) return true;
        } catch (e) {
          debugPrint('⚠️ [NotificationsProvider] Primary reject ($primaryId) failed: $e');
          if (primaryId != userId && userId.trim().isNotEmpty) {
            debugPrint('🔄 [NotificationsProvider] Retrying reject with userId: $userId');
            final bool ok = await _relationshipService!.rejectFollowRequest(userId);
            return ok;
          }
          rethrow;
        }
      } catch (e) {
        debugPrint('⚠️ [NotificationsProvider] declineFollowRequest error: $e');
        _followActionStatuses.remove(notificationId);
        _savePersistedFollowStatuses();
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  // ── Device Push Token Management ───────────────────────────────────────────
  Future<void> initDeviceToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString(_prefDeviceTokenKey);

      if (token == null || token.isEmpty) {
        final int timestamp = DateTime.now().millisecondsSinceEpoch;
        final String platformName = kIsWeb
            ? 'web'
            : (Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'unknown'));
        token = 'dev_${platformName}_${_currentUserId ?? 'user'}_$timestamp';
        await prefs.setString(_prefDeviceTokenKey, token);
      }

      _registeredToken = token;
      final String platform = kIsWeb
          ? 'web'
          : (Platform.isIOS ? 'ios' : 'android');

      debugPrint('📲 [NotificationsProvider] Registering push token: $token ($platform)');
      await _service.registerDeviceToken(token: token, platform: platform);
    } catch (e) {
      debugPrint('⚠️ [NotificationsProvider] initDeviceToken error: $e');
    }
  }

  Future<void> unregisterDeviceToken() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? token = _registeredToken ?? prefs.getString(_prefDeviceTokenKey);
      if (token != null && token.isNotEmpty) {
        debugPrint('📲 [NotificationsProvider] Unregistering push token: $token');
        await _service.unregisterDeviceToken(token);
        await prefs.remove(_prefDeviceTokenKey);
        _registeredToken = null;
      }
    } catch (e) {
      debugPrint('⚠️ [NotificationsProvider] unregisterDeviceToken error: $e');
    }
  }
}

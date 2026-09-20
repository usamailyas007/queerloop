import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import '../models/notification_item_model.dart';

/// Service for in-app and push notification endpoints:
/// - POST   /users/me/device-tokens (Register push token)
/// - DELETE /users/me/device-tokens/:token (Unregister push token)
/// - GET    /notifications (List notifications)
/// - GET    /notifications/unread-count (Unread count)
/// - PATCH  /notifications/:id/read (Mark single notification read)
/// - POST   /notifications/mark-all-read (Mark all notifications read)
class NotificationsService {
  const NotificationsService(this._client);

  final ApiClient _client;

  // ── 1. List Notifications ──────────────────────────────────────────────────
  /// GET /notifications
  Future<List<NotificationItemModel>> getNotifications({
    int limit = 50,
    int page = 1,
  }) async {
    try {
      debugPrint('🚀 [NotificationsService] GET ${ApiEndpoints.notifications}');
      final dynamic res = await _client.get(
        ApiEndpoints.notifications,
        useCache: false,
      );

      final List<dynamic> list = _extractList(
        res,
        keys: const <String>['notifications', 'data', 'items', 'results'],
      );

      return list
          .whereType<Map<String, dynamic>>()
          .map(NotificationItemModel.fromJson)
          .toList();
    } on ApiException catch (e) {
      debugPrint('❌ [NotificationsService] getNotifications error: $e');
      return <NotificationItemModel>[];
    } catch (e, stack) {
      debugPrint('❌ [NotificationsService] getNotifications unexpected: $e\n$stack');
      return <NotificationItemModel>[];
    }
  }

  // ── 2. Unread Count ────────────────────────────────────────────────────────
  /// GET /notifications/unread-count
  Future<int> getUnreadCount() async {
    try {
      debugPrint('🚀 [NotificationsService] GET ${ApiEndpoints.notificationsUnreadCount}');
      final dynamic res = await _client.get(
        ApiEndpoints.notificationsUnreadCount,
        useCache: false,
      );

      if (res is num) return res.toInt();
      if (res is Map<String, dynamic>) {
        final dynamic val = res['count'] ??
            res['unreadCount'] ??
            res['unread'] ??
            (res['data'] is num
                ? res['data']
                : (res['data'] is Map ? res['data']['count'] ?? res['data']['unreadCount'] : null));
        if (val is num) return val.toInt();
        if (val is String) return int.tryParse(val) ?? 0;
      }
      return 0;
    } on ApiException catch (e) {
      debugPrint('⚠️ [NotificationsService] getUnreadCount error: $e');
      return 0;
    } catch (e) {
      debugPrint('⚠️ [NotificationsService] getUnreadCount unexpected: $e');
      return 0;
    }
  }

  // ── 3. Mark Single Notification Read ───────────────────────────────────────
  /// PATCH /notifications/:id/read
  Future<bool> markAsRead(String notificationId) async {
    if (notificationId.isEmpty) return false;
    try {
      debugPrint('🚀 [NotificationsService] PATCH ${ApiEndpoints.notificationRead(notificationId)}');
      await _client.patch(ApiEndpoints.notificationRead(notificationId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [NotificationsService] markAsRead error: $e');
      return false;
    } catch (e) {
      debugPrint('❌ [NotificationsService] markAsRead unexpected: $e');
      return false;
    }
  }

  // ── 4. Mark All Notifications Read ─────────────────────────────────────────
  /// POST /notifications/mark-all-read
  Future<bool> markAllAsRead() async {
    try {
      debugPrint('🚀 [NotificationsService] POST ${ApiEndpoints.notificationsMarkAllRead}');
      await _client.post(ApiEndpoints.notificationsMarkAllRead);
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [NotificationsService] markAllAsRead error: $e');
      return false;
    } catch (e) {
      debugPrint('❌ [NotificationsService] markAllAsRead unexpected: $e');
      return false;
    }
  }

  // ── 5. Register Device Push Token ──────────────────────────────────────────
  /// POST /users/me/device-tokens
  /// body: { "token": "...", "platform": "android" }
  Future<bool> registerDeviceToken({
    required String token,
    String platform = 'android',
  }) async {
    final String cleanToken = token.trim();
    if (cleanToken.isEmpty) return false;

    try {
      debugPrint('🚀 [NotificationsService] POST ${ApiEndpoints.deviceTokens} (platform: $platform)');
      await _client.post(
        ApiEndpoints.deviceTokens,
        body: <String, dynamic>{
          'token': cleanToken,
          'platform': platform.toLowerCase(),
        },
      );
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [NotificationsService] registerDeviceToken error: $e');
      return false;
    } catch (e) {
      debugPrint('❌ [NotificationsService] registerDeviceToken unexpected: $e');
      return false;
    }
  }

  // ── 6. Unregister Device Push Token ────────────────────────────────────────
  /// DELETE /users/me/device-tokens/:token
  Future<bool> unregisterDeviceToken(String token) async {
    final String cleanToken = token.trim();
    if (cleanToken.isEmpty) return false;

    try {
      debugPrint('🚀 [NotificationsService] DELETE ${ApiEndpoints.deviceToken(cleanToken)}');
      await _client.delete(ApiEndpoints.deviceToken(cleanToken));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [NotificationsService] unregisterDeviceToken error: $e');
      return false;
    } catch (e) {
      debugPrint('❌ [NotificationsService] unregisterDeviceToken unexpected: $e');
      return false;
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  List<dynamic> _extractList(dynamic res, {required List<String> keys}) {
    if (res is List) return res;
    if (res is Map<String, dynamic>) {
      for (final String key in keys) {
        if (res[key] is List) return res[key] as List<dynamic>;
        if (res[key] is Map<String, dynamic>) {
          for (final String subKey in keys) {
            if ((res[key] as Map<String, dynamic>)[subKey] is List) {
              return (res[key] as Map<String, dynamic>)[subKey] as List<dynamic>;
            }
          }
        }
      }
    }
    return <dynamic>[];
  }
}

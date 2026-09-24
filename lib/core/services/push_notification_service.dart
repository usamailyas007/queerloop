import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';

import '../../firebase_options.dart';
import '../../features/home/provider/home_feed_provider.dart';
import '../../features/messages/models/message_models.dart';
import '../../features/messages/provider/messages_provider.dart';
import '../../features/messages/screens/chat_screen.dart';
import '../../features/profile/provider/profile_provider.dart';
import '../../features/profile/screens/followers_following_screen.dart';
import '../../features/profile/screens/user_profile_screen.dart';
import '../api/api_client.dart';
import '../../features/notifications/services/notifications_service.dart';
import 'navigation_service.dart';


/// Top-level background message handler required by FirebaseMessaging.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {}
  debugPrint('📩 [FCM] Background message received: ${message.messageId}, data: ${message.data}');
}

/// Centralized service to manage Firebase Cloud Messaging (FCM) push notifications
/// and foreground local notification popups.
abstract final class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'queerloop_notifications';
  static const String channelName = 'QueerLoop Notifications';
  static const String channelDescription =
      'Notifications for messages, reactions, mentions, and activity on QueerLoop.';

  static bool _initialized = false;
  static String? _cachedDeviceToken;
  static ApiClient? _activeApiClient;

  static String? get cachedDeviceToken => _cachedDeviceToken;

  /// Initialize FCM, setup notification channels, foreground listeners, and permissions.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final FirebaseMessaging messaging = FirebaseMessaging.instance;

      // 1. Request notification permissions (required for iOS & Android 13+)
      final NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('🔔 [PushNotificationService] Authorization status: ${settings.authorizationStatus}');

      // 2. Initialize FlutterLocalNotifications for heads-up alerts when app is open
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('🔔 [PushNotificationService] Foreground notification tapped: ${response.payload}');
          _handleNotificationPayload(response.payload);
        },
      );

      // 3. Create high-importance Android notification channel
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        channelId,
        channelName,
        description: channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidPlatform =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlatform != null) {
        await androidPlatform.createNotificationChannel(channel);
        await androidPlatform.requestNotificationsPermission();
      }

      // 4. Listen to foreground messages and show heads-up local notification
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('📩 [PushNotificationService] Foreground FCM message: ${message.messageId}, data: ${message.data}');
        _showForegroundNotification(message);
      });

      // 5. App opened from background notification tap
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('📲 [PushNotificationService] App opened from background notification: ${message.data}');
        _handleNotificationData(message.data);
      });

      // 6. Check if app was launched from terminated state via notification
      final RemoteMessage? initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📲 [PushNotificationService] App launched from terminated state: ${initialMessage.data}');
        _handleNotificationData(initialMessage.data);
      }

      // 7. Retrieve device token
      try {
        _cachedDeviceToken = await messaging.getToken();
        if (_cachedDeviceToken != null) {
          debugPrint('🔑 [PushNotificationService] FCM Device Token: $_cachedDeviceToken');
        }
      } catch (e) {
        debugPrint('⚠️ [PushNotificationService] Failed to retrieve FCM token: $e');
      }

      // 8. Listen for token refresh
      messaging.onTokenRefresh.listen((String newToken) {
        debugPrint('🔄 [PushNotificationService] FCM token refreshed: $newToken');
        _cachedDeviceToken = newToken;
        if (_activeApiClient != null) {
          syncDeviceToken(_activeApiClient!);
        }
      });

      _initialized = true;
      debugPrint('✅ [PushNotificationService] Push notification service initialized.');
    } catch (e, stack) {
      debugPrint('⚠️ [PushNotificationService] Initialization error: $e\n$stack');
    }
  }

  /// Displays a heads-up push notification banner while the user is actively inside the app.
  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    final Map<String, dynamic> data = message.data;
    final Map<String, dynamic> d =
        (data['data'] is Map<String, dynamic>) ? data['data'] as Map<String, dynamic> : data;

    // Suppress notifications if sender is restricted or blocked
    final BuildContext? ctx = navigatorKey.currentContext;
    if (ctx != null) {
      try {
        final MessagesProvider msgProv = ctx.read<MessagesProvider>();
        ProfileProvider? profileProv;
        try {
          profileProv = ctx.read<ProfileProvider>();
        } catch (_) {}

        final dynamic rawSender = d['sender'] ?? d['user'] ?? d['actor'] ?? d['author'];
        String? nestedSenderId;
        String? nestedSenderUname;
        if (rawSender is Map) {
          nestedSenderId = (rawSender['id'] ??
                  rawSender['_id'] ??
                  rawSender['userId'] ??
                  rawSender['user_id'])
              ?.toString();
          nestedSenderUname = (rawSender['username'] ??
                  rawSender['handle'] ??
                  rawSender['name'])
              ?.toString();
        }

        final String? senderId = (d['senderId'] ??
                d['sender_id'] ??
                d['actorId'] ??
                d['actor_id'] ??
                d['userId'] ??
                d['user_id'] ??
                d['authorId'] ??
                nestedSenderId)
            ?.toString();
        final String? senderUname = (d['senderUsername'] ??
                d['sender_username'] ??
                d['username'] ??
                d['actorUsername'] ??
                d['actor_username'] ??
                nestedSenderUname)
            ?.toString();
        final String? convId = (d['conversationId'] ??
                d['conversation_id'] ??
                d['convId'] ??
                d['targetId'])
            ?.toString();

        final bool isUserRestricted = msgProv.isRestricted(senderId) ||
            msgProv.isRestricted(senderUname) ||
            msgProv.isRestricted(convId) ||
            (profileProv != null &&
                (profileProv.isRestricted(senderId) ||
                    profileProv.isRestricted(senderUname) ||
                    profileProv.isRestricted(convId)));

        final bool isUserBlocked = msgProv.isBlocked(senderId) ||
            msgProv.isBlocked(senderUname) ||
            msgProv.isBlocked(convId) ||
            (profileProv != null &&
                (profileProv.isBlocked(senderId) ||
                    profileProv.isBlocked(senderUname) ||
                    profileProv.isBlocked(convId)));

        if (isUserRestricted || isUserBlocked) {
          debugPrint(
              '🔇 [PushNotificationService] Suppressing notification from restricted/blocked user: id=$senderId, uname=$senderUname, conv=$convId');
          return;
        }
      } catch (_) {}
    }

    final String title = notification?.title ??
        (data['title']?.toString() ?? 'QueerLoop');
    final String body = notification?.body ??
        (data['body']?.toString() ??
            data['message']?.toString() ??
            '');

    if (title.isEmpty && body.isEmpty) return;

    final int id = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _localNotifications.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: jsonEncode(data),
      );
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Error showing local notification: $e');
    }
  }

  /// Sends the device push token to the backend API.
  static Future<void> syncDeviceToken(ApiClient apiClient) async {
    _activeApiClient = apiClient;
    final String? token = apiClient.authToken;
    if (token == null || token.trim().isEmpty) return;

    if (_cachedDeviceToken == null) {
      try {
        _cachedDeviceToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {
        debugPrint('⚠️ [PushNotificationService] Could not fetch token for sync: $e');
        return;
      }
    }

    if (_cachedDeviceToken == null || _cachedDeviceToken!.isEmpty) return;

    final String platformName = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      _ => 'android',
    };

    try {
      final NotificationsService service = NotificationsService(apiClient);
      final bool success = await service.registerDeviceToken(
        token: _cachedDeviceToken!,
        platform: platformName,
      );
      if (success) {
        debugPrint('✅ [PushNotificationService] Successfully registered device token with backend.');
      } else {
        debugPrint('⚠️ [PushNotificationService] Backend returned failure registering device token.');
      }
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Exception registering device token: $e');
    }
  }

  /// Removes the device push token on backend when user logs out or session expires.
  static Future<void> unregisterDeviceToken(ApiClient apiClient, {String? authToken}) async {
    if (_cachedDeviceToken == null || _cachedDeviceToken!.isEmpty) {
      try {
        _cachedDeviceToken = await FirebaseMessaging.instance.getToken();
      } catch (_) {}
    }
    if (_cachedDeviceToken == null || _cachedDeviceToken!.isEmpty) return;

    try {
      final NotificationsService service = NotificationsService(apiClient);
      await service.unregisterDeviceToken(_cachedDeviceToken!, authToken: authToken);
      debugPrint('✅ [PushNotificationService] Unregistered device token: $_cachedDeviceToken');
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Error unregistering token: $e');
    }
  }

  static void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final dynamic decoded = jsonDecode(payload);
      if (decoded is Map<String, dynamic>) {
        _handleNotificationData(decoded);
      }
    } catch (e) {
      debugPrint('⚠️ [PushNotificationService] Error decoding payload: $e');
    }
  }

  static void _handleNotificationData(Map<String, dynamic> data) {
    debugPrint('👉 [PushNotificationService] Notification data received: $data');

    // Normalise: some backends nest payload under "data" key
    final Map<String, dynamic> d =
        (data['data'] is Map<String, dynamic>) ? data['data'] as Map<String, dynamic> : data;

    final String type = (d['type'] ??
            d['notificationType'] ??
            d['notification_type'] ??
            '')
        .toString()
        .toUpperCase();

    // ── 1. Chat / Message notification ──────────────────────────────────────
    if (type.contains('MESSAGE') ||
        type.contains('CHAT') ||
        d.containsKey('conversationId') ||
        d.containsKey('conversation_id') ||
        d.containsKey('convId') ||
        ((type == 'MESSAGE' || type == 'CHAT') &&
            (d.containsKey('targetId') || d.containsKey('target_id')))) {
      navigateToConversation(d);
      return;
    }

    // ── 2. Follow / Follow-request handling ──────────────────────────────────
    final String status = (d['status'] ??
            d['followStatus'] ??
            d['requestStatus'] ??
            '')
        .toString()
        .toLowerCase();

    final bool isFollowType = type.contains('FOLLOW');
    if (isFollowType) {
      final bool isAccepted = status == 'accepted' ||
          status == 'approved' ||
          status == 'following' ||
          type.contains('ACCEPT') ||
          type.contains('APPROVED') ||
          (type == 'FOLLOW' && !type.contains('REQUEST'));

      final String? actorId = (d['actorId'] ??
              d['actor_id'] ??
              d['senderId'] ??
              d['userId'] ??
              d['actor']?['id'] ??
              d['actor']?['_id'])
          ?.toString();
      final String? username = (d['actorUsername'] ??
              d['username'] ??
              d['senderUsername'] ??
              d['actor']?['username'])
          ?.toString();

      if (isAccepted && actorId != null && actorId.isNotEmpty) {
        navigateToUserProfile(actorId: actorId, username: username);
      } else {
        navigateToFollowRequests();
      }
      return;
    }
  }

  // ── Navigation helpers ────────────────────────────────────────────────────

  /// Navigate to [ChatScreen] for a specific conversation.
  /// Falls back to opening Messages tab if not enough data.
  static void navigateToConversation(Map<String, dynamic> d) {
    // Give the app a moment to finish mounting (terminated-state launch)
    Future<void>.delayed(const Duration(milliseconds: 500), () async {
      // Pull all the fields we may have
      final String convId = (d['conversationId'] ??
              d['conversation_id'] ??
              d['convId'] ??
              d['targetId'] ??
              d['target_id'] ??
              '')
          .toString()
          .trim();
      final String senderId = (d['senderId'] ??
              d['sender_id'] ??
              d['actorId'] ??
              d['userId'] ??
              '')
          .toString()
          .trim();
      final String username = (d['username'] ??
              d['actorUsername'] ??
              d['senderUsername'] ??
              '')
          .toString()
          .trim();
      final String displayName = (d['displayName'] ??
              d['senderName'] ??
              d['actorName'] ??
              username)
          .toString()
          .trim();
      final String avatarUrl = (d['avatarUrl'] ??
              d['avatar'] ??
              d['profilePicture'] ??
              '')
          .toString()
          .trim();

      if (convId.isEmpty && senderId.isEmpty) {
        // Not enough data — just switch to Messages tab
        switchToMessagesTabViaKey();
        return;
      }

      // Look up existing conversation in MessagesProvider
      ConversationModel? found;
      try {
        final BuildContext? ctx = navigatorKey.currentContext;
        if (ctx != null) {
          // ignore: use_build_context_synchronously
          final MessagesProvider mp = Provider.of<MessagesProvider>(ctx, listen: false);
          if (mp.conversations.isEmpty) {
            try {
              await mp.loadConversations();
            } catch (_) {}
          }
          if (convId.isNotEmpty) {
            final ConversationModel match = mp.conversations.firstWhere(
              (ConversationModel c) => c.id == convId || c.participantId == convId,
              orElse: () => _emptyConv(),
            );
            if (match.id.isNotEmpty) found = match;
          }
          if (found == null && senderId.isNotEmpty) {
            final ConversationModel match = mp.conversations.firstWhere(
              (ConversationModel c) =>
                  c.participantId == senderId ||
                  c.id == senderId ||
                  c.username.replaceAll('@', '') == username.replaceAll('@', ''),
              orElse: () => _emptyConv(),
            );
            if (match.id.isNotEmpty) found = match;
          }
        }
      } catch (_) {}

      final ConversationModel conv = found ??
          ConversationModel(
            id: convId.isNotEmpty ? convId : senderId,
            participantId: senderId.isNotEmpty ? senderId : null,
            username: username.isNotEmpty ? username : 'Chat',
            displayName: displayName.isNotEmpty ? displayName : null,
            avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
            avatarAsset: '',
            lastMessage: '',
            timeAgo: '',
          );

      // Switch to Messages tab, then push ChatScreen
      switchToMessagesTabViaKey();
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        final BuildContext? navCtx = navigatorKey.currentContext;
        if (navCtx == null) return;
        // ignore: use_build_context_synchronously
        Navigator.of(navCtx).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => ChatScreen(conversation: conv),
          ),
        );
      });
    });
  }

  /// Open [UserProfileScreen] for the user who accepted our follow / followed us.
  static void navigateToUserProfile({
    required String actorId,
    String? username,
    String? name,
    String? avatarAsset,
  }) {
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      final NavigatorState? nav = navigatorKey.currentState;
      if (nav == null) return;
      nav.push<void>(
        MaterialPageRoute<void>(
          builder: (_) => UserProfileScreen(
            userId: actorId,
            username: username ?? '',
            name: (name != null && name.isNotEmpty)
                ? name
                : (username ?? ''),
            avatarAsset: avatarAsset ?? '',
          ),
        ),
      );
    });
  }

  /// Open [FollowersFollowingScreen] on the Requests tab (index 2).
  static void navigateToFollowRequests() {
    Future<void>.delayed(const Duration(milliseconds: 500), () {
      // ignore: use_build_context_synchronously — context re-read inside delayed
      final BuildContext? ctx = navigatorKey.currentContext;
      if (ctx == null) return;
      // ignore: use_build_context_synchronously
      Navigator.of(ctx).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => const FollowersFollowingScreen(
            initialTabIndex: 2, // Requests tab (0=Followers, 1=Following, 2=Requests)
          ),
        ),
      );
    });
  }

  /// Switch bottom-nav to Messages tab (index 3) using the global navigator key.
  static void switchToMessagesTabViaKey() {
    // ignore: use_build_context_synchronously — context re-read inside helper
    final BuildContext? ctx = navigatorKey.currentContext;
    if (ctx == null) return;
    try {
      // ignore: use_build_context_synchronously
      Provider.of<HomeFeedProvider>(ctx, listen: false).setBottomNavIndex(3);
    } catch (_) {}
  }

  static ConversationModel _emptyConv() => const ConversationModel(
        id: '',
        username: '',
        avatarAsset: '',
        lastMessage: '',
        timeAgo: '',
      );
}

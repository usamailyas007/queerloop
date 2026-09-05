// Profile Provider — manages fetching and updating User Profile via GET/PATCH /users/:id.

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import '../../profile_setup/models/profile_models.dart';

class ProfileProvider extends ChangeNotifier {
  ProfileProvider({required ApiClient client}) : _client = client;

  final ApiClient _client;

  UserProfile? _profile;
  bool _isBusy = false;
  String? _error;

  UserProfile? get profile => _profile;
  bool get isBusy => _isBusy;
  String? get error => _error;

  String get displayName => _profile?.displayName ?? 'Ash Mercado';
  String get username => _profile?.username ?? 'ashinorbit';
  String get bio =>
      _profile?.bio ??
      'Film nerd, softball catcher, chronically making playlists.';
  String get avatarUrl =>
      _profile?.avatarUrl ?? 'https://picsum.photos/seed/ash/400';
  String get pronounsFormatted => _profile?.formattedPronouns ?? 'she / they';
  List<String> get pronouns =>
      _profile?.pronouns ?? const <String>['she/her', 'they/them'];

  String get postsCount =>
      _profile?.postsCount != null ? '${_profile!.postsCount}' : '128';
  String get followersCount =>
      _profile?.followersCount != null ? '${_profile!.followersCount}' : '4,290';
  String get followingCount =>
      _profile?.followingCount != null ? '${_profile!.followingCount}' : '311';

  List<String> get interests => _profile?.interests ?? const <String>[];
  bool get isPrivate => _profile?.isPrivate ?? false;
  bool get showInDiscover => _profile?.showInDiscover ?? true;
  String get allowMessagesFrom => _profile?.allowMessagesFrom ?? 'everyone';
  String get allowMessagesFromLabel =>
      formatPrivacyLabel(_profile?.allowMessagesFrom);
  bool get hideMyLikes => _profile?.hideMyLikes ?? false;
  String get profileVisibility => _profile?.profileVisibility ?? 'everyone';
  String get profileVisibilityLabel =>
      formatPrivacyLabel(_profile?.profileVisibility);
  bool get notifyOnLike => _profile?.notifyOnLike ?? true;
  bool get notifyOnComment => _profile?.notifyOnComment ?? true;
  bool get notifyOnFollow => _profile?.notifyOnFollow ?? true;
  bool get notifyOnMessage => _profile?.notifyOnMessage ?? true;

  String get allowCommentsFrom => _profile?.allowCommentsFrom ?? 'everyone';
  String get allowCommentsFromLabel =>
      formatPrivacyLabel(_profile?.allowCommentsFrom);
  bool get showActivityStatus => _profile?.showActivityStatus ?? true;
  bool get sendReadReceipts => _profile?.sendReadReceipts ?? true;
  bool get notifyOnFollowRequests => _profile?.notifyOnFollowRequests ?? true;
  bool get notifyOnCommunityPosts => _profile?.notifyOnCommunityPosts ?? true;
  bool get notifyOnAnnouncementsFeatures =>
      _profile?.notifyOnAnnouncementsFeatures ?? true;
  bool get notifyOnSafetyModerationUpdates =>
      _profile?.notifyOnSafetyModerationUpdates ?? true;

  static String formatPrivacyLabel(String? val) {
    if (val == null || val.isEmpty) return 'Everyone';
    final String lower = val.toLowerCase().trim();
    if (lower.contains('everyone')) return 'Everyone';
    if (lower.contains('nobody')) return 'Nobody';
    if (lower.contains('mutual')) return 'Mutual follows';
    if (lower.contains('follow')) return 'People you follow';
    return 'Everyone';
  }

  // ── GET /users/:id ─────────────────────────────────────────────────────────

  Future<void> fetchProfile(String userId) async {
    if (userId.isEmpty) return;

    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      if (AppConfig.useMockApi) {
        _profile = UserProfile(
          id: userId,
          displayName: 'Ash Mercado',
          username: 'ashinorbit',
          bio: 'Film nerd, softball catcher, chronically making playlists.',
          avatarUrl: 'https://picsum.photos/seed/ash/400',
          pronouns: const <String>['she/her', 'they/them'],
          pronounsPrivate: false,
        );
      } else {
        debugPrint('🚀 [ProfileProvider] Fetching profile for user: $userId (GET /users/$userId)');
        final dynamic data = await _client.get(ApiEndpoints.user(userId));
        debugPrint('📥 [ProfileProvider] Profile data received: $data');
        _profile = UserProfile.fromJson(data as Map<String, dynamic>);
      }
      _error = null;
    } on ApiException catch (e) {
      _error = e.message;
      debugPrint('⚠️ [ProfileProvider] Fetch profile API error: ${e.message}');
    } catch (e) {
      _error = 'Failed to load profile.';
      debugPrint('⚠️ [ProfileProvider] Fetch profile generic error: $e');
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  // ── PATCH /users/:id ───────────────────────────────────────────────────────

  Future<bool> updateProfile(
    String userId, {
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    String? avatarBase64,
    List<String>? pronouns,
    bool? pronounsPrivate,
    List<String>? interests,
    bool? isPrivate,
    bool? showInDiscover,
    String? allowMessagesFrom,
    bool? hideMyLikes,
    String? profileVisibility,
    String? allowCommentsFrom,
    bool? showActivityStatus,
    bool? sendReadReceipts,
    bool? notifyOnLike,
    bool? notifyOnComment,
    bool? notifyOnFollow,
    bool? notifyOnMessage,
    bool? notifyOnFollowRequests,
    bool? notifyOnCommunityPosts,
    bool? notifyOnAnnouncementsFeatures,
    bool? notifyOnSafetyModerationUpdates,
  }) async {
    if (userId.isEmpty) return false;

    _isBusy = true;
    _error = null;
    notifyListeners();

    final Map<String, dynamic> payload = <String, dynamic>{};
    if (displayName != null) payload['displayName'] = displayName.trim();
    if (username != null) payload['username'] = username.trim();
    if (bio != null) payload['bio'] = bio.trim();
    if (avatarBase64 != null && avatarBase64.isNotEmpty) {
      payload['avatarBase64'] = avatarBase64;
    } else if (avatarUrl != null && avatarUrl.isNotEmpty) {
      payload['avatarUrl'] = avatarUrl.trim();
    }
    if (pronouns != null) payload['pronouns'] = pronouns;
    if (pronounsPrivate != null) payload['pronounsPrivate'] = pronounsPrivate;
    if (interests != null) payload['interests'] = interests;
    if (isPrivate != null) payload['isPrivate'] = isPrivate;
    if (showInDiscover != null) payload['showInDiscover'] = showInDiscover;
    if (allowMessagesFrom != null) {
      payload['allowMessagesFrom'] = _normalizePrivacy(allowMessagesFrom);
    }
    if (allowCommentsFrom != null) {
      payload['allowCommentsFrom'] = _normalizePrivacy(allowCommentsFrom);
    }
    if (hideMyLikes != null) payload['hideMyLikes'] = hideMyLikes;
    if (profileVisibility != null) {
      payload['profileVisibility'] = _normalizePrivacy(profileVisibility);
    }
    if (showActivityStatus != null) {
      payload['showActivityStatus'] = showActivityStatus;
    }
    if (sendReadReceipts != null) {
      payload['sendReadReceipts'] = sendReadReceipts;
    }
    if (notifyOnLike != null) payload['notifyOnLike'] = notifyOnLike;
    if (notifyOnComment != null) payload['notifyOnComment'] = notifyOnComment;
    if (notifyOnFollow != null) payload['notifyOnFollow'] = notifyOnFollow;
    if (notifyOnMessage != null) payload['notifyOnMessage'] = notifyOnMessage;
    if (notifyOnFollowRequests != null) {
      payload['notifyOnFollowRequests'] = notifyOnFollowRequests;
    }
    if (notifyOnCommunityPosts != null) {
      payload['notifyOnCommunityPosts'] = notifyOnCommunityPosts;
    }
    if (notifyOnAnnouncementsFeatures != null) {
      payload['notifyOnAnnouncementsFeatures'] = notifyOnAnnouncementsFeatures;
    }
    if (notifyOnSafetyModerationUpdates != null) {
      payload['notifyOnSafetyModerationUpdates'] =
          notifyOnSafetyModerationUpdates;
    }

    if (payload.isEmpty) {
      _isBusy = false;
      notifyListeners();
      return true;
    }

    try {
      if (!AppConfig.useMockApi) {
        debugPrint(
            '🚀 [ProfileProvider] Updating profile for: $userId (PATCH /users/$userId)\n   Payload: $payload');
        final dynamic data = await _client.patch(
          ApiEndpoints.user(userId),
          body: payload,
        );
        debugPrint('📥 [ProfileProvider] Profile updated: $data');
        final UserProfile updated =
            UserProfile.fromJson(data as Map<String, dynamic>);
        _profile = (_profile ?? UserProfile(id: userId)).merge(updated);
      } else {
        _profile = (_profile ?? UserProfile(id: userId)).merge(
          UserProfile(
            id: userId,
            displayName: displayName,
            username: username,
            bio: bio,
            avatarUrl: avatarUrl,
            pronouns: pronouns,
            pronounsPrivate: pronounsPrivate,
            interests: interests,
            isPrivate: isPrivate,
            showInDiscover: showInDiscover,
            allowMessagesFrom: allowMessagesFrom,
            allowCommentsFrom: allowCommentsFrom,
            hideMyLikes: hideMyLikes,
            profileVisibility: profileVisibility,
            showActivityStatus: showActivityStatus,
            sendReadReceipts: sendReadReceipts,
            notifyOnLike: notifyOnLike,
            notifyOnComment: notifyOnComment,
            notifyOnFollow: notifyOnFollow,
            notifyOnMessage: notifyOnMessage,
            notifyOnFollowRequests: notifyOnFollowRequests,
            notifyOnCommunityPosts: notifyOnCommunityPosts,
            notifyOnAnnouncementsFeatures: notifyOnAnnouncementsFeatures,
            notifyOnSafetyModerationUpdates: notifyOnSafetyModerationUpdates,
          ),
        );
      }
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to update profile.';
      notifyListeners();
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  String _normalizePrivacy(String val) {
    val = val.toLowerCase().trim();
    if (val.contains('everyone')) return 'everyone';
    if (val.contains('nobody')) return 'nobody';
    if (val.contains('mutual')) return 'mutual';
    if (val.contains('follow')) return 'following';
    return val;
  }

  void clearError() {
    if (_error == null) return;
    _error = null;
    notifyListeners();
  }
}

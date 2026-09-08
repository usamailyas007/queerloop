// Profile Setup Service — all PATCH /users/:id and community-join calls.
// Each method maps 1-to-1 with one wizard step from the Postman collection.

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/config/app_config.dart';
import 'models/community_model.dart';
import 'models/profile_models.dart';

class ProfileSetupService {
  const ProfileSetupService(this._client);

  final ApiClient _client;

  // ── Username availability ─────────────────────────────────────────────────
  // GET /users/username-available?username=<value>
  // Returns: { available: bool }

  Future<bool> checkUsernameAvailable(String username) async {
    if (AppConfig.useMockApi) {
      // Mock: anything not 'taken' is available
      return username.toLowerCase() != 'taken';
    }

    debugPrint('🔍 [ProfileSetup] Checking username: $username');
    final dynamic data = await _client.get(
      ApiEndpoints.usernameAvailable,
      query: <String, dynamic>{'username': username},
    );
    final bool available =
        (data as Map<String, dynamic>)['available'] as bool? ?? false;
    debugPrint('📥 [ProfileSetup] Username "$username" available: $available');
    return available;
  }

  // ── Step 1 — Display name, username, bio ─────────────────────────────────
  // PATCH /users/:id  { displayName, username, bio }
  // Returns: updated UserProfile

  Future<UserProfile> saveBasicInfo({
    required String userId,
    required String displayName,
    required String username,
    required String bio,
  }) async {
    if (AppConfig.useMockApi) {
      return UserProfile(
        id: userId,
        displayName: displayName,
        username: username.toLowerCase(),
        bio: bio,
      );
    }

    debugPrint('🚀 [ProfileSetup] Saving Step 1 (Basic Info) for user: $userId');
    final dynamic data = await _client.patch(
      ApiEndpoints.user(userId),
      body: <String, dynamic>{
        'displayName': displayName,
        'username': username,
        'bio': bio,
      },
    );
    debugPrint('📥 [ProfileSetup] Step 1 Response: $data');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  // ── Step 2 — Avatar ───────────────────────────────────────────────────────
  // PATCH /users/:id  { avatarBase64 }
  // Returns: updated UserProfile

  Future<UserProfile> saveAvatar({
    required String userId,
    required String avatarBase64,
  }) async {
    if (AppConfig.useMockApi) {
      return UserProfile(
        id: userId,
        avatarUrl:
            'https://cdn.queerloop.example/mock/image/$userId/mock-avatar',
      );
    }

    debugPrint(
        '🚀 [ProfileSetup] Saving Step 2 (Avatar Base64) for user: $userId');
    final dynamic data = await _client.patch(
      ApiEndpoints.user(userId),
      body: <String, dynamic>{'avatarBase64': avatarBase64},
    );
    debugPrint('📥 [ProfileSetup] Step 2 Response: $data');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  // ── Step 3 — Pronouns ─────────────────────────────────────────────────────
  // PATCH /users/:id  { pronouns: [], pronounsPrivate: bool }

  Future<UserProfile> savePronouns({
    required String userId,
    required List<String> pronouns,
    required bool pronounsPrivate,
  }) async {
    if (AppConfig.useMockApi) {
      return UserProfile(
          id: userId, pronouns: pronouns, pronounsPrivate: pronounsPrivate);
    }

    debugPrint('🚀 [ProfileSetup] Saving Step 3 (Pronouns) for user: $userId');
    final dynamic data = await _client.patch(
      ApiEndpoints.user(userId),
      body: <String, dynamic>{
        'pronouns': pronouns,
        'pronounsPrivate': pronounsPrivate,
      },
    );
    debugPrint('📥 [ProfileSetup] Step 3 Response: $data');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  // ── Onboarding — Interests ───────────────────────────────────────────────
  // PATCH /users/:id  { interests: [] }

  Future<UserProfile> saveInterests({
    required String userId,
    required List<String> interests,
  }) async {
    if (AppConfig.useMockApi) {
      return UserProfile(id: userId, interests: interests);
    }
    debugPrint(
        '🚀 [ProfileSetup] Saving Interests for user: $userId: $interests');
    final dynamic data = await _client.patch(
      ApiEndpoints.user(userId),
      body: <String, dynamic>{'interests': interests},
    );
    debugPrint('📥 [ProfileSetup] Interests Response: $data');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  // ── Step 4 — Fetch communities ────────────────────────────────────────────
  // GET /communities
  // Returns: List<CommunityModel>

  Future<List<CommunityModel>> getCommunities() async {
    if (AppConfig.useMockApi) {
      return const <CommunityModel>[];
    }
    debugPrint('🚀 [ProfileSetup] Fetching communities (GET /communities)');
    final dynamic data = await _client.get(ApiEndpoints.communities);
    debugPrint('📥 [ProfileSetup] Communities received: $data');
    List<dynamic> rawList = <dynamic>[];
    if (data is List) {
      rawList = data;
    } else if (data is Map<String, dynamic>) {
      if (data['data'] is List) {
        rawList = data['data'] as List<dynamic>;
      } else if (data['communities'] is List) {
        rawList = data['communities'] as List<dynamic>;
      } else if (data['items'] is List) {
        rawList = data['items'] as List<dynamic>;
      }
    }
    return rawList
        .map((dynamic item) =>
            CommunityModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  // ── Step 4 — Join a community ─────────────────────────────────────────────
  // POST /communities/join (Fallback: POST /communities/:id/join)

  Future<void> joinCommunity(String communityId) async {
    if (AppConfig.useMockApi) {
      return;
    }
    debugPrint(
        '🚀 [ProfileSetup] Joining Community: $communityId (POST ${ApiEndpoints.joinCommunities})');
    try {
      await _client.post(
        ApiEndpoints.joinCommunities,
        body: <String, dynamic>{
          'communityIds': <String>[communityId],
        },
      );
    } catch (_) {
      await _client.post(ApiEndpoints.joinCommunity(communityId));
    }
  }

  // ── Step 4 — Join multiple communities (batch) ────────────────────────────
  // POST /communities/join
  // Body: { "communityIds": [ "id1", "id2", ... ] }

  Future<void> joinCommunities(Iterable<String> communityIds) async {
    if (AppConfig.useMockApi || communityIds.isEmpty) {
      return;
    }
    final List<String> idList = communityIds.toList();
    debugPrint(
        '🚀 [ProfileSetup] Joining ${idList.length} Communities (POST ${ApiEndpoints.joinCommunities})...');
    final dynamic response = await _client.post(
      ApiEndpoints.joinCommunities,
      body: <String, dynamic>{
        'communityIds': idList,
      },
    );
    debugPrint('📥 [ProfileSetup] Finished joining communities response: $response');
  }

  // ── Step 4 — Leave a community ────────────────────────────────────────────
  // DELETE /communities/:id/leave

  Future<void> leaveCommunity(String communityId) async {
    if (AppConfig.useMockApi || communityId.isEmpty) {
      return;
    }
    debugPrint(
        '🚀 [ProfileSetup] Leaving Community: $communityId (DELETE ${ApiEndpoints.leaveCommunity(communityId)})');
    try {
      await _client.delete(ApiEndpoints.leaveCommunity(communityId));
    } catch (e) {
      debugPrint('⚠️ [ProfileSetup] Failed to leave community $communityId: $e');
    }
  }

  // ── Step 4 — Leave multiple communities (batch) ───────────────────────────

  Future<void> leaveCommunities(Iterable<String> communityIds) async {
    if (AppConfig.useMockApi || communityIds.isEmpty) {
      return;
    }
    final List<String> idList = communityIds.toList();
    debugPrint(
        '🚀 [ProfileSetup] Leaving ${idList.length} Communities...');
    await Future.wait(
      idList.map((String id) => leaveCommunity(id)),
      eagerError: false,
    );
    debugPrint('📥 [ProfileSetup] Finished leaving communities');
  }

  // ── Step 5 — Privacy settings ─────────────────────────────────────────────
  // PATCH /users/:id  { isPrivate, showInDiscover, allowMessagesFrom,
  //                     hideMyLikes, profileVisibility }

  Future<UserProfile> savePrivacySettings({
    required String userId,
    required bool isPrivate,
    required bool showInDiscover,
    required String allowMessagesFrom,
    required bool hideMyLikes,
    required String profileVisibility,
  }) async {
    final String normalizedMessages = _normalizePrivacy(allowMessagesFrom);
    final String normalizedVisibility = _normalizePrivacy(profileVisibility);

    if (AppConfig.useMockApi) {
      return UserProfile(
        id: userId,
        isPrivate: isPrivate,
        showInDiscover: showInDiscover,
        allowMessagesFrom: normalizedMessages,
        hideMyLikes: hideMyLikes,
        profileVisibility: normalizedVisibility,
      );
    }

    debugPrint('🚀 [ProfileSetup] Saving Step 5 (Privacy) for user: $userId');
    final dynamic data = await _client.patch(
      ApiEndpoints.user(userId),
      body: <String, dynamic>{
        'isPrivate': isPrivate,
        'showInDiscover': showInDiscover,
        'allowMessagesFrom': normalizedMessages,
        'hideMyLikes': hideMyLikes,
        'profileVisibility': normalizedVisibility,
      },
    );
    debugPrint('📥 [ProfileSetup] Step 5 Response: $data');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  // ── Get profile ───────────────────────────────────────────────────────────
  // GET /users/:id

  Future<UserProfile> getProfile(String userId) async {
    if (AppConfig.useMockApi) {
      return UserProfile(id: userId);
    }
    final dynamic data = await _client.get(ApiEndpoints.user(userId));
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  String _normalizePrivacy(String val) {
    val = val.toLowerCase().trim();
    if (val.contains('everyone')) return 'everyone';
    if (val.contains('nobody')) return 'nobody';
    if (val.contains('mutual')) return 'mutual';
    if (val.contains('follow')) return 'following';
    return val;
  }
}



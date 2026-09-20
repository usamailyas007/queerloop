import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import '../../discover/models/discover_models.dart';
import '../../discover/services/discover_service.dart';
import '../models/user_relationship_models.dart';

class UserRelationshipService {
  UserRelationshipService(this._client);

  final ApiClient _client;

  // ── Helper: Safe List Extractor ───────────────────────────────────────────
  List<dynamic> _extractList(dynamic data, List<String> candidateKeys) {
    if (data is List) {
      return data;
    }
    if (data is Map<String, dynamic>) {
      for (final String key in candidateKeys) {
        if (data[key] is List) {
          return data[key] as List<dynamic>;
        }
      }
      if (data['data'] is List) {
        return data['data'] as List<dynamic>;
      }
      if (data['items'] is List) {
        return data['items'] as List<dynamic>;
      }
      if (data['results'] is List) {
        return data['results'] as List<dynamic>;
      }

      if (data['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> inner = data['data'] as Map<String, dynamic>;
        for (final String key in candidateKeys) {
          if (inner[key] is List) {
            return inner[key] as List<dynamic>;
          }
        }
        if (inner['items'] is List) {
          return inner['items'] as List<dynamic>;
        }
        if (inner['results'] is List) {
          return inner['results'] as List<dynamic>;
        }
      }
    }
    return <dynamic>[];
  }

  // ── Username to UserId Resolution ─────────────────────────────────────────
  Future<String?> resolveUserId(String rawUsername) async {
    final String clean = rawUsername.replaceAll('@', '').trim();
    if (clean.isEmpty) return null;
    try {
      final DiscoverService discover = DiscoverService(_client);
      final MultiTabSearchResults results = await discover.search(
        query: clean,
        tab: 'people',
      );
      if (results.people.isNotEmpty) {
        final DiscoverPerson match = results.people.firstWhere(
          (DiscoverPerson p) =>
              p.username.replaceAll('@', '').toLowerCase() ==
              clean.toLowerCase(),
          orElse: () => results.people.first,
        );
        if (match.id != null && match.id!.trim().isNotEmpty) {
          return match.id!.trim();
        }
      }
    } catch (e) {
      debugPrint('⚠️ [UserRelationshipService] Could not resolve username "$clean": $e');
    }
    return null;
  }

  // ── Follow / Unfollow ──────────────────────────────────────────────────────

  /// Follow User (A follows B, or request private account): POST /users/:id/follow
  Future<bool> followUser(String userId, {String? currentUserId}) async {
    if (userId.isEmpty) return false;
    if (currentUserId != null &&
        currentUserId.isNotEmpty &&
        userId.trim() == currentUserId.trim()) {
      debugPrint('⚠️ [UserRelationshipService] Prevented attempt to follow yourself.');
      return false;
    }
    try {
      debugPrint('🚀 [UserRelationshipService] Follow user: POST ${ApiEndpoints.userFollow(userId)}');
      await _client.post(ApiEndpoints.userFollow(userId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [UserRelationshipService] Follow API error: ${e.message}');
      if (e.message.toLowerCase().contains('cannot follow yourself')) {
        return false;
      }
      rethrow;
    } catch (e) {
      debugPrint('❌ [UserRelationshipService] Follow generic error: $e');
      rethrow;
    }
  }

  /// Unfollow User (A unfollows B, or cancel pending request): DELETE /users/:id/follow
  Future<bool> unfollowUser(String userId) async {
    if (userId.isEmpty) return false;
    try {
      debugPrint('🚀 [UserRelationshipService] Unfollow user: DELETE ${ApiEndpoints.userFollow(userId)}');
      await _client.delete(ApiEndpoints.userFollow(userId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [UserRelationshipService] Unfollow API error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [UserRelationshipService] Unfollow generic error: $e');
      rethrow;
    }
  }

  // ── Followers & Following Lists ───────────────────────────────────────────

  /// List user's followers (public): GET /users/:id/followers
  Future<List<UserRelationItem>> getFollowers(String userId) async {
    if (userId.isEmpty) return <UserRelationItem>[];
    try {
      debugPrint('🚀 [UserRelationshipService] Get followers: GET ${ApiEndpoints.userFollowers(userId)}');
      dynamic data;
      try {
        data = await _client.get(ApiEndpoints.userFollowers(userId));
      } catch (e) {
        if (userId == 'me') {
          data = await _client.get('/users/me/followers');
        } else {
          rethrow;
        }
      }
      final List<dynamic> list = _extractList(data, <String>[
        'followers',
        'followerUsers',
        'users',
        'accounts',
        'items',
        'data',
        'results',
      ]);
      return list
          .whereType<Map<String, dynamic>>()
          .map(UserRelationItem.fromJson)
          .toList();
    } catch (e) {
      debugPrint('⚠️ [UserRelationshipService] Get followers error: $e');
      return <UserRelationItem>[];
    }
  }

  /// List user's following (public): GET /users/:id/following
  Future<List<UserRelationItem>> getFollowing(String userId) async {
    if (userId.isEmpty) return <UserRelationItem>[];
    try {
      debugPrint('🚀 [UserRelationshipService] Get following: GET ${ApiEndpoints.userFollowing(userId)}');
      dynamic data;
      try {
        data = await _client.get(ApiEndpoints.userFollowing(userId));
      } catch (e) {
        if (userId == 'me') {
          data = await _client.get('/users/me/following');
        } else {
          rethrow;
        }
      }
      final List<dynamic> list = _extractList(data, <String>[
        'following',
        'followings',
        'followingUsers',
        'users',
        'accounts',
        'items',
        'data',
        'results',
      ]);
      return list
          .whereType<Map<String, dynamic>>()
          .map(UserRelationItem.fromJson)
          .toList();
    } catch (e) {
      debugPrint('⚠️ [UserRelationshipService] Get following error: $e');
      return <UserRelationItem>[];
    }
  }

  /// Remove User as a Follower (without blocking): DELETE /users/me/followers/:id
  Future<bool> removeFollower(String userId) async {
    if (userId.isEmpty) return false;
    try {
      debugPrint('🚀 [UserRelationshipService] Remove follower: DELETE ${ApiEndpoints.userRemoveFollower(userId)}');
      await _client.delete(ApiEndpoints.userRemoveFollower(userId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [UserRelationshipService] Remove follower API error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [UserRelationshipService] Remove follower error: $e');
      rethrow;
    }
  }

  // ── Block & Unblock ───────────────────────────────────────────────────────

  /// Block User (A blocks B): POST /users/:id/block
  Future<bool> blockUser(String userId) async {
    if (userId.isEmpty) return false;
    try {
      debugPrint('🚀 [UserRelationshipService] Block user: POST ${ApiEndpoints.userBlock(userId)}');
      await _client.post(ApiEndpoints.userBlock(userId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [UserRelationshipService] Block user API error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [UserRelationshipService] Block user error: $e');
      rethrow;
    }
  }

  /// Unblock User (A unblocks B): DELETE /users/:id/block
  Future<bool> unblockUser(String userId) async {
    if (userId.isEmpty) return false;
    try {
      debugPrint('🚀 [UserRelationshipService] Unblock user: DELETE ${ApiEndpoints.userBlock(userId)}');
      await _client.delete(ApiEndpoints.userBlock(userId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [UserRelationshipService] Unblock user API error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [UserRelationshipService] Unblock user error: $e');
      rethrow;
    }
  }

  /// List current user's blocked accounts: GET /users/me/blocked
  Future<List<BlockedAccountItem>> getBlockedAccounts() async {
    try {
      debugPrint('🚀 [UserRelationshipService] Get blocked: GET ${ApiEndpoints.userBlocked}');
      final dynamic data = await _client.get(ApiEndpoints.userBlocked);
      final List<dynamic> list = _extractList(data, <String>[
        'blocked',
        'blockedUsers',
        'users',
        'items',
        'accounts',
        'data',
      ]);
      return list
          .whereType<Map<String, dynamic>>()
          .map(BlockedAccountItem.fromJson)
          .toList();
    } catch (e) {
      debugPrint('⚠️ [UserRelationshipService] Get blocked accounts error: $e');
      return <BlockedAccountItem>[];
    }
  }

  // ── Mute & Unmute ─────────────────────────────────────────────────────────

  /// Mute User (A mutes B, posts scope, duration): POST /users/:id/mute
  Future<bool> muteUser(
    String userId, {
    String scope = 'posts',
    int durationHours = 8,
  }) async {
    if (userId.isEmpty) return false;
    try {
      debugPrint('🚀 [UserRelationshipService] Mute user: POST ${ApiEndpoints.userMute(userId)}');
      final Map<String, dynamic> body = <String, dynamic>{
        'scope': scope,
        'durationHours': durationHours,
        'duration': '${durationHours}_hours',
      };
      await _client.post(ApiEndpoints.userMute(userId), body: body);
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [UserRelationshipService] Mute user API error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [UserRelationshipService] Mute user error: $e');
      rethrow;
    }
  }

  /// Unmute User (A unmutes B): DELETE /users/:id/mute
  Future<bool> unmuteUser(String userId) async {
    if (userId.isEmpty) return false;
    try {
      debugPrint('🚀 [UserRelationshipService] Unmute user: DELETE ${ApiEndpoints.userMute(userId)}');
      await _client.delete(ApiEndpoints.userMute(userId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [UserRelationshipService] Unmute user API error: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ [UserRelationshipService] Unmute user error: $e');
      rethrow;
    }
  }

  /// List current user's muted accounts: GET /users/me/muted
  Future<List<MutedAccountItem>> getMutedAccounts() async {
    try {
      debugPrint('🚀 [UserRelationshipService] Get muted: GET ${ApiEndpoints.userMuted}');
      final dynamic data = await _client.get(ApiEndpoints.userMuted);
      final List<dynamic> list = _extractList(data, <String>[
        'muted',
        'mutedUsers',
        'users',
        'items',
        'accounts',
        'data',
      ]);
      return list
          .whereType<Map<String, dynamic>>()
          .map(MutedAccountItem.fromJson)
          .toList();
    } catch (e) {
      debugPrint('⚠️ [UserRelationshipService] Get muted accounts error: $e');
      return <MutedAccountItem>[];
    }
  }

  // ── Follow Requests (Private Accounts) ────────────────────────────────────

  /// List current user's follow requests: GET /users/me/follow-requests
  Future<List<FollowRequestItem>> getFollowRequests() async {
    try {
      debugPrint('🚀 [UserRelationshipService] Get follow requests: GET ${ApiEndpoints.userFollowRequests}');
      final dynamic data = await _client.get(ApiEndpoints.userFollowRequests);
      final List<dynamic> list = _extractList(data, <String>['requests', 'followRequests', 'items']);
      return list
          .whereType<Map<String, dynamic>>()
          .map(FollowRequestItem.fromJson)
          .toList();
    } catch (e) {
      debugPrint('⚠️ [UserRelationshipService] Get follow requests error: $e');
      return <FollowRequestItem>[];
    }
  }

  /// Accept follow request: POST /users/me/follow-requests/:id/accept
  Future<bool> acceptFollowRequest(String requestId) async {
    final String cleanId = requestId.trim();
    if (cleanId.isEmpty) return false;
    try {
      debugPrint('🚀 [UserRelationshipService] Accept follow request: POST ${ApiEndpoints.userFollowRequestAccept(cleanId)}');
      await _client.post(
        ApiEndpoints.userFollowRequestAccept(cleanId),
        body: const <String, dynamic>{},
      );
      return true;
    } on ApiException catch (e) {
      debugPrint('⚠️ [UserRelationshipService] Accept request primary failed ($e), trying alternatives...');
      // Alternative 1: POST /users/:id/follow/accept
      try {
        await _client.post(
          '/users/$cleanId/follow/accept',
          body: const <String, dynamic>{},
        );
        return true;
      } catch (_) {
        // Alternative 2: POST /users/:id/accept
        try {
          await _client.post(
            '/users/$cleanId/accept',
            body: const <String, dynamic>{},
          );
          return true;
        } catch (_) {
          // Alternative 3: POST /follow-requests/:id/accept
          try {
            await _client.post(
              '/follow-requests/$cleanId/accept',
              body: const <String, dynamic>{},
            );
            return true;
          } catch (_) {
            rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [UserRelationshipService] Accept request error: $e');
      rethrow;
    }
  }

  /// Reject follow request: POST /users/me/follow-requests/:id/reject
  Future<bool> rejectFollowRequest(String requestId) async {
    final String cleanId = requestId.trim();
    if (cleanId.isEmpty) return false;
    try {
      debugPrint('🚀 [UserRelationshipService] Reject follow request: POST ${ApiEndpoints.userFollowRequestReject(cleanId)}');
      await _client.post(
        ApiEndpoints.userFollowRequestReject(cleanId),
        body: const <String, dynamic>{},
      );
      return true;
    } on ApiException catch (e) {
      debugPrint('⚠️ [UserRelationshipService] Reject request primary failed ($e), trying alternatives...');
      try {
        await _client.post(
          '/users/$cleanId/follow/reject',
          body: const <String, dynamic>{},
        );
        return true;
      } catch (_) {
        try {
          await _client.post(
            '/users/$cleanId/reject',
            body: const <String, dynamic>{},
          );
          return true;
        } catch (_) {
          try {
            await _client.post(
              '/follow-requests/$cleanId/reject',
              body: const <String, dynamic>{},
            );
            return true;
          } catch (_) {
            rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('❌ [UserRelationshipService] Reject request error: $e');
      rethrow;
    }
  }
}

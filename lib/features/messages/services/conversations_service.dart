import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import '../models/message_models.dart';

class ConversationsService {
  const ConversationsService(this._client);

  final ApiClient _client;
  ApiClient get client => _client;

  // ── Helper: Extract List from raw or enveloped JSON ────────────────────────
  List<dynamic> _extractList(dynamic res, {List<String> keys = const <String>[]}) {
    if (res == null) return <dynamic>[];
    if (res is List) return res;
    if (res is Map<String, dynamic>) {
      for (final String key in keys) {
        if (res[key] is List) return res[key] as List<dynamic>;
      }
      if (res['data'] is List) return res['data'] as List<dynamic>;
      if (res['items'] is List) return res['items'] as List<dynamic>;
      if (res['results'] is List) return res['results'] as List<dynamic>;

      // Check nested data
      if (res['data'] is Map<String, dynamic>) {
        final Map<String, dynamic> data = res['data'] as Map<String, dynamic>;
        for (final String key in keys) {
          if (data[key] is List) return data[key] as List<dynamic>;
        }
        if (data['items'] is List) return data['items'] as List<dynamic>;
      }
    }
    return <dynamic>[];
  }

  // ── Helper: Extract Map from raw or enveloped JSON ─────────────────────────
  Map<String, dynamic>? _extractMap(dynamic res) {
    if (res == null) return null;
    if (res is Map<String, dynamic>) {
      if (res['data'] is Map<String, dynamic>) {
        return res['data'] as Map<String, dynamic>;
      }
      if (res['conversation'] is Map<String, dynamic>) {
        return res['conversation'] as Map<String, dynamic>;
      }
      return res;
    }
    return null;
  }

  // ── 1. Start Conversation (A → B) ──────────────────────────────────────────
  /// POST /conversations
  /// body: { "participantId": ":userBId" }
  Future<ConversationModel?> startConversation({
    required String participantId,
    String? currentUserId,
  }) async {
    final String cleanParticipantId = participantId.trim();
    if (cleanParticipantId.isEmpty) {
      debugPrint('⚠️ [ConversationsService] Cannot start conversation: participantId is empty.');
      return null;
    }

    try {
      debugPrint('🚀 [ConversationsService] Starting conversation with $cleanParticipantId');
      final dynamic res = await _client.post(
        ApiEndpoints.conversations,
        body: <String, dynamic>{
          'participantId': cleanParticipantId,
        },
      );

      final Map<String, dynamic>? map = _extractMap(res);
      if (map != null) {
        final ConversationModel conv =
            ConversationModel.fromJson(map, currentUserId: currentUserId);
        if (conv.participantId == null || conv.participantId!.trim().isEmpty) {
          return conv.copyWith(participantId: cleanParticipantId);
        }
        return conv;
      }
      return null;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] startConversation error: $e');
      rethrow;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] startConversation unexpected: $e\n$stack');
      return null;
    }
  }

  // ── 2. List Conversations (Primary Inbox) ──────────────────────────────────
  /// GET /conversations
  Future<List<ConversationModel>> getConversations({String? currentUserId}) async {
    try {
      debugPrint('🚀 [ConversationsService] Fetching conversations...');
      final dynamic res = await _client.get(
        ApiEndpoints.conversations,
        useCache: false,
      );

      final List<dynamic> list = _extractList(
        res,
        keys: const <String>['conversations', 'inbox', 'items'],
      );

      return list
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) =>
              ConversationModel.fromJson(item, currentUserId: currentUserId))
          .toList();
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] getConversations error: $e');
      return <ConversationModel>[];
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] getConversations unexpected: $e\n$stack');
      return <ConversationModel>[];
    }
  }

  // ── 3. List Message Requests ───────────────────────────────────────────────
  /// GET /conversations/requests
  Future<List<MessageRequestModel>> getMessageRequests({String? currentUserId}) async {
    try {
      debugPrint('🚀 [ConversationsService] Fetching message requests...');
      final dynamic res = await _client.get(
        ApiEndpoints.conversationRequests,
        useCache: false,
      );
      debugPrint('📥 [ConversationsService] Message requests response: $res');

      final List<dynamic> list = _extractList(
        res,
        keys: const <String>[
          'requests',
          'conversations',
          'messageRequests',
          'items',
          'data',
          'results',
        ],
      );

      return list
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) =>
              MessageRequestModel.fromJson(item, currentUserId: currentUserId))
          .toList();
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] getMessageRequests error: $e');
      return <MessageRequestModel>[];
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] getMessageRequests unexpected: $e\n$stack');
      return <MessageRequestModel>[];
    }
  }

  // ── 4. Accept Message Request ──────────────────────────────────────────────
  /// POST /conversations/:id/accept
  Future<bool> acceptRequest(String conversationId) async {
    try {
      debugPrint('🚀 [ConversationsService] Accepting request $conversationId');
      await _client.post(ApiEndpoints.conversationAccept(conversationId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] acceptRequest error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] acceptRequest unexpected: $e\n$stack');
      return false;
    }
  }

  // ── 5. Reject Message Request ──────────────────────────────────────────────
  /// POST /conversations/:id/reject
  Future<bool> rejectRequest(String conversationId) async {
    try {
      debugPrint('🚀 [ConversationsService] Rejecting request $conversationId');
      await _client.post(ApiEndpoints.conversationReject(conversationId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] rejectRequest error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] rejectRequest unexpected: $e\n$stack');
      return false;
    }
  }

  // ── 6. List Messages in Conversation ───────────────────────────────────────
  /// GET /conversations/:id/messages
  Future<List<ChatMessageModel>> getMessages({
    required String conversationId,
    String? currentUserId,
  }) async {
    try {
      debugPrint('🚀 [ConversationsService] Fetching messages for $conversationId');
      final dynamic res = await _client.get(
        ApiEndpoints.conversationMessages(conversationId),
        useCache: false,
      );

      final List<dynamic> list = _extractList(
        res,
        keys: const <String>['messages', 'items'],
      );

      return list
          .whereType<Map<String, dynamic>>()
          .map((Map<String, dynamic> item) =>
              ChatMessageModel.fromJson(item, currentUserId: currentUserId))
          .toList();
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] getMessages error: $e');
      return <ChatMessageModel>[];
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] getMessages unexpected: $e\n$stack');
      return <ChatMessageModel>[];
    }
  }

  // ── 7. Send Message ────────────────────────────────────────────────────────
  /// POST /conversations/:id/messages
  /// body: { "body": ":text", "sharedPostId"?: ":id" }
  Future<ChatMessageModel?> sendMessage({
    required String conversationId,
    required String body,
    String? sharedPostId,
    String? currentUserId,
  }) async {
    try {
      debugPrint('🚀 [ConversationsService] Sending message to $conversationId');
      final Map<String, dynamic> payload = <String, dynamic>{
        'body': body,
        if (sharedPostId != null && sharedPostId.isNotEmpty)
          'sharedPostId': sharedPostId,
      };
      final dynamic res = await _client.post(
        ApiEndpoints.conversationMessages(conversationId),
        body: payload,
      );

      final Map<String, dynamic>? map = _extractMap(res);
      if (map != null) {
        return ChatMessageModel.fromJson(map, currentUserId: currentUserId);
      }
      return null;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] sendMessage error: $e');
      rethrow;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] sendMessage unexpected: $e\n$stack');
      return null;
    }
  }

  // ── 7b. Fan-Out Share Post/Reel ─────────────────────────────────────────────
  /// POST /conversations/share
  /// Spec body: { "contentType": "post"|"reel", "contentId": ":id", "conversationIds"?: [...], "recipientUserIds"?: [...], "message"?: ":text" }
  /// Note: "sharedPostId" must NOT be sent to this endpoint; backend strictly enforces "contentId".
  Future<bool> sharePost({
    required String sharedPostId,
    List<String>? conversationIds,
    List<String>? recipientUserIds,
    String? message,
    String? contentType,
  }) async {
    try {
      debugPrint(
          '🚀 [ConversationsService] (API) Sharing post $sharedPostId to convs: $conversationIds, users: $recipientUserIds');
      final String normalizedContentType = _normalizeContentType(contentType);
      final Map<String, dynamic> payload = <String, dynamic>{
        'contentType': normalizedContentType,
        'contentId': sharedPostId,
        if (conversationIds != null && conversationIds.isNotEmpty)
          'conversationIds': conversationIds,
        if (recipientUserIds != null && recipientUserIds.isNotEmpty)
          'recipientUserIds': recipientUserIds,
        if (message != null && message.trim().isNotEmpty)
          'message': message.trim(),
      };
      await _client.post(
        ApiEndpoints.conversationShare,
        body: payload,
      );
      debugPrint(
          '✅ [ConversationsService] (API) Post $sharedPostId successfully shared via POST /conversations/share');
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] (API) /conversations/share error: $e. Retrying per-recipient via API...');
      // If fan-out endpoint fails, try sending to each conversation or recipient directly via API
      bool anySuccess = false;
      if (conversationIds != null && conversationIds.isNotEmpty) {
        for (final String cId in conversationIds) {
          try {
            await sendMessage(
              conversationId: cId,
              body: message ?? 'Shared a post',
              sharedPostId: sharedPostId,
            );
            anySuccess = true;
          } catch (_) {}
        }
      }
      if (recipientUserIds != null && recipientUserIds.isNotEmpty) {
        for (final String uId in recipientUserIds) {
          try {
            final ConversationModel? conv =
                await startConversation(participantId: uId);
            if (conv != null && conv.id.isNotEmpty) {
              await sendMessage(
                conversationId: conv.id,
                body: message ?? 'Shared a post',
                sharedPostId: sharedPostId,
              );
              anySuccess = true;
            }
          } catch (_) {}
        }
      }
      return anySuccess;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] (API) sharePost unexpected: $e\n$stack');
      return false;
    }
  }

  String _normalizeContentType(String? type) {
    if (type == null) return 'post';
    final String lower = type.toLowerCase().trim();
    if (lower.contains('reel')) return 'reel';
    return 'post';
  }

  // ── 8. Mark Message Read ───────────────────────────────────────────────────
  /// POST or PATCH /conversations/:id/messages/:messageId/read
  Future<bool> markMessageRead({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      debugPrint('🚀 [ConversationsService] POST ${ApiEndpoints.conversationMessageRead(conversationId, messageId)}');
      await _client.post(
        ApiEndpoints.conversationMessageRead(conversationId, messageId),
      );
      return true;
    } catch (_) {
      try {
        await _client.patch(
          ApiEndpoints.conversationMessageRead(conversationId, messageId),
        );
        return true;
      } catch (e) {
        debugPrint('❌ [ConversationsService] markMessageRead error: $e');
        return false;
      }
    }
  }

  /// Mark all messages in conversation as read
  Future<bool> markConversationRead(String conversationId) async {
    try {
      debugPrint('🚀 [ConversationsService] Marking entire conversation $conversationId read');
      await _client.post('/conversations/$conversationId/read');
      return true;
    } catch (_) {
      try {
        await _client.patch('/conversations/$conversationId/read');
        return true;
      } catch (_) {
        return false;
      }
    }
  }

  // ── 9. Unsend Message ──────────────────────────────────────────────────────
  /// DELETE /conversations/:id/messages/:messageId
  Future<bool> unsendMessage({
    required String conversationId,
    required String messageId,
  }) async {
    try {
      debugPrint('🚀 [ConversationsService] Unsending message $messageId in $conversationId');
      await _client.delete(
        ApiEndpoints.conversationMessage(conversationId, messageId),
      );
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] unsendMessage error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] unsendMessage unexpected: $e\n$stack');
      return false;
    }
  }

  // ── 10. Mute Conversation ──────────────────────────────────────────────────
  /// POST /conversations/:id/mute
  /// body: { "duration": "1_week" }
  Future<bool> muteConversation({
    required String conversationId,
    String duration = '1_week',
  }) async {
    try {
      debugPrint('🚀 [ConversationsService] Muting $conversationId for $duration');
      await _client.post(
        ApiEndpoints.conversationMute(conversationId),
        body: <String, dynamic>{
          'duration': duration,
        },
      );
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] muteConversation error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] muteConversation unexpected: $e\n$stack');
      return false;
    }
  }

  // ── 11. Unmute Conversation ────────────────────────────────────────────────
  /// DELETE /conversations/:id/mute (Fallback: POST /conversations/:id/unmute)
  Future<bool> unmuteConversation(String conversationId) async {
    try {
      debugPrint('🚀 [ConversationsService] Unmuting $conversationId via DELETE ${ApiEndpoints.conversationMute(conversationId)}');
      await _client.delete(ApiEndpoints.conversationMute(conversationId));
      return true;
    } catch (_) {
      try {
        debugPrint('🚀 [ConversationsService] Fallback unmuting via POST /conversations/$conversationId/unmute');
        await _client.post('/conversations/$conversationId/unmute');
        return true;
      } catch (_) {
        try {
          await _client.delete('/conversations/$conversationId/unmute');
          return true;
        } catch (e, stack) {
          debugPrint('❌ [ConversationsService] unmuteConversation unexpected: $e\n$stack');
          return false;
        }
      }
    }
  }

  // ── 12. React to Message ───────────────────────────────────────────────────
  /// POST /conversations/:id/messages/:messageId/reactions
  /// body: { "emoji": "👍" }
  Future<bool> addReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      debugPrint('🚀 [ConversationsService] Reacting $emoji to $messageId in $conversationId');
      await _client.post(
        ApiEndpoints.conversationMessageReactions(conversationId, messageId),
        body: <String, dynamic>{
          'emoji': emoji,
        },
      );
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] addReaction error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] addReaction unexpected: $e\n$stack');
      return false;
    }
  }

  // ── 13. Remove Reaction ────────────────────────────────────────────────────
  /// DELETE /conversations/:id/messages/:messageId/reactions?emoji=:emoji
  Future<bool> removeReaction({
    required String conversationId,
    required String messageId,
    required String emoji,
  }) async {
    try {
      debugPrint('🚀 [ConversationsService] Removing reaction $emoji from $messageId');
      await _client.delete(
        ApiEndpoints.conversationMessageReaction(conversationId, messageId, emoji),
      );
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] removeReaction error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] removeReaction unexpected: $e\n$stack');
      return false;
    }
  }

  // ── 14. Clear/Delete Conversation for Self ─────────────────────────────────
  /// DELETE /conversations/:id
  Future<bool> deleteConversation(String conversationId) async {
    try {
      debugPrint('🚀 [ConversationsService] Deleting conversation $conversationId');
      await _client.delete(ApiEndpoints.conversation(conversationId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] deleteConversation error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] deleteConversation unexpected: $e\n$stack');
      return false;
    }
  }

  // ── 15. Blocked Users ──────────────────────────────────────────────────────
  /// List current user's blocked accounts: GET /users/me/blocked
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    try {
      debugPrint('🚀 [ConversationsService] Get blocked users: GET ${ApiEndpoints.userBlocked}');
      final dynamic res = await _client.get(ApiEndpoints.userBlocked);
      final List<dynamic> list = _extractList(
        res,
        keys: const <String>['blocked', 'blockedUsers', 'users', 'items', 'accounts'],
      );
      return list.whereType<Map<String, dynamic>>().toList();
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] getBlockedUsers error: $e');
      return <Map<String, dynamic>>[];
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] getBlockedUsers unexpected: $e\n$stack');
      return <Map<String, dynamic>>[];
    }
  }

  /// Block user: POST /users/:id/block
  Future<bool> blockUser(String userId) async {
    if (userId.trim().isEmpty) return false;
    try {
      debugPrint('🚀 [ConversationsService] Block user: POST ${ApiEndpoints.userBlock(userId)}');
      await _client.post(ApiEndpoints.userBlock(userId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] blockUser error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] blockUser unexpected: $e\n$stack');
      return false;
    }
  }

  /// Unblock user: DELETE /users/:id/block
  Future<bool> unblockUser(String userId) async {
    if (userId.trim().isEmpty) return false;
    try {
      debugPrint('🚀 [ConversationsService] Unblock user: DELETE ${ApiEndpoints.userBlock(userId)}');
      await _client.delete(ApiEndpoints.userBlock(userId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] unblockUser error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] unblockUser unexpected: $e\n$stack');
      return false;
    }
  }

  // ── 16. Restricted Users ───────────────────────────────────────────────────
  /// List current user's restricted accounts: GET /users/me/restricted
  Future<List<Map<String, dynamic>>> getRestrictedUsers() async {
    try {
      debugPrint('🚀 [ConversationsService] Get restricted users: GET ${ApiEndpoints.userRestricted}');
      final dynamic res = await _client.get(ApiEndpoints.userRestricted);
      final List<dynamic> list = _extractList(
        res,
        keys: const <String>['restricted', 'restrictedUsers', 'users', 'items', 'accounts'],
      );
      return list.whereType<Map<String, dynamic>>().toList();
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] getRestrictedUsers error: $e');
      return <Map<String, dynamic>>[];
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] getRestrictedUsers unexpected: $e\n$stack');
      return <Map<String, dynamic>>[];
    }
  }

  /// Restrict user: POST /users/:id/restrict
  Future<bool> restrictUser(String userId) async {
    if (userId.trim().isEmpty) return false;
    try {
      debugPrint('🚀 [ConversationsService] Restrict user: POST ${ApiEndpoints.userRestrict(userId)}');
      await _client.post(ApiEndpoints.userRestrict(userId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] restrictUser error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] restrictUser unexpected: $e\n$stack');
      return false;
    }
  }

  /// Unrestrict user: DELETE /users/:id/restrict
  Future<bool> unrestrictUser(String userId) async {
    if (userId.trim().isEmpty) return false;
    try {
      debugPrint('🚀 [ConversationsService] Unrestrict user: DELETE ${ApiEndpoints.userRestrict(userId)}');
      await _client.delete(ApiEndpoints.userRestrict(userId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] unrestrictUser error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] unrestrictUser unexpected: $e\n$stack');
      return false;
    }
  }

  // ── 17. Muted Users ────────────────────────────────────────────────────────
  /// List current user's muted accounts: GET /users/me/muted
  Future<List<Map<String, dynamic>>> getMutedUsers() async {
    try {
      debugPrint('🚀 [ConversationsService] Get muted users: GET ${ApiEndpoints.userMuted}');
      final dynamic res = await _client.get(ApiEndpoints.userMuted);
      final List<dynamic> list = _extractList(
        res,
        keys: const <String>['muted', 'mutedUsers', 'users', 'items', 'accounts'],
      );
      return list.whereType<Map<String, dynamic>>().toList();
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] getMutedUsers error: $e');
      return <Map<String, dynamic>>[];
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] getMutedUsers unexpected: $e\n$stack');
      return <Map<String, dynamic>>[];
    }
  }

  /// Mute user: POST /users/:id/mute
  Future<bool> muteUser(String userId, {String scope = 'posts', int durationHours = 8}) async {
    if (userId.trim().isEmpty) return false;
    try {
      debugPrint('🚀 [ConversationsService] Mute user: POST ${ApiEndpoints.userMute(userId)}');
      final Map<String, dynamic> body = <String, dynamic>{
        'scope': scope,
        'durationHours': durationHours,
        'duration': '${durationHours}_hours',
      };
      await _client.post(ApiEndpoints.userMute(userId), body: body);
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] muteUser error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] muteUser unexpected: $e\n$stack');
      return false;
    }
  }

  /// Unmute user: DELETE /users/:id/mute
  Future<bool> unmuteUser(String userId) async {
    if (userId.trim().isEmpty) return false;
    try {
      debugPrint('🚀 [ConversationsService] Unmute user: DELETE ${ApiEndpoints.userMute(userId)}');
      await _client.delete(ApiEndpoints.userMute(userId));
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [ConversationsService] unmuteUser error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [ConversationsService] unmuteUser unexpected: $e\n$stack');
      return false;
    }
  }
}

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import '../models/message_models.dart';

class ConversationsService {
  const ConversationsService(this._client);

  final ApiClient _client;

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
  /// body: { "body": ":text" }
  Future<ChatMessageModel?> sendMessage({
    required String conversationId,
    required String body,
    String? currentUserId,
  }) async {
    try {
      debugPrint('🚀 [ConversationsService] Sending message to $conversationId');
      final dynamic res = await _client.post(
        ApiEndpoints.conversationMessages(conversationId),
        body: <String, dynamic>{
          'body': body,
        },
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
}

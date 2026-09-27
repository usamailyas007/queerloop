import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/config/api_endpoints.dart';
import '../models/cotd_models.dart';

/// Service for Conversation of the Day (CotD) endpoints.
class CotdService {
  const CotdService(this._client);

  final ApiClient _client;

  /// GET /engagement/cotd/current — fetch today's question.
  Future<CotdQuestion?> fetchCurrentQuestion() async {
    try {
      debugPrint('🚀 [CotdService] GET ${ApiEndpoints.cotdCurrent}');
      final dynamic data = await _client.get(
        ApiEndpoints.cotdCurrent,
        useCache: false,
      );
      if (data == null) return null;
      final Map<String, dynamic> json = data is Map<String, dynamic>
          ? data
          : <String, dynamic>{};
      // The API might wrap in a 'data' key
      final Map<String, dynamic> questionJson =
          (json['data'] as Map<String, dynamic>?) ?? json;
      if (questionJson['id'] == null) return null;
      return CotdQuestion.fromJson(questionJson);
    } on ApiException catch (e) {
      debugPrint('❌ [CotdService] fetchCurrentQuestion error: $e');
      return null;
    } catch (e, stack) {
      debugPrint('❌ [CotdService] fetchCurrentQuestion unexpected: $e\n$stack');
      return null;
    }
  }

  /// POST /engagement/cotd/:id/answers — submit an answer.
  Future<bool> submitAnswer({
    required String questionId,
    required String body,
  }) async {
    try {
      debugPrint(
          '🚀 [CotdService] POST ${ApiEndpoints.cotdAnswerSubmit(questionId)}');
      await _client.post(
        ApiEndpoints.cotdAnswerSubmit(questionId),
        body: <String, dynamic>{'body': body},
      );
      return true;
    } on ApiException catch (e) {
      debugPrint('❌ [CotdService] submitAnswer error: $e');
      return false;
    } catch (e, stack) {
      debugPrint('❌ [CotdService] submitAnswer unexpected: $e\n$stack');
      return false;
    }
  }

  /// GET /engagement/cotd/:id/answers — list answers.
  Future<List<CotdAnswer>> fetchAnswers(String questionId) async {
    try {
      debugPrint(
          '🚀 [CotdService] GET ${ApiEndpoints.cotdAnswers(questionId)}');
      final dynamic data = await _client.get(
        ApiEndpoints.cotdAnswers(questionId),
        useCache: false,
      );
      final List<dynamic> list;
      if (data is List<dynamic>) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        list = data['answers'] as List<dynamic>? ??
            data['data'] as List<dynamic>? ??
            <dynamic>[];
      } else {
        list = <dynamic>[];
      }
      return list
          .whereType<Map<String, dynamic>>()
          .map(CotdAnswer.fromJson)
          .toList();
    } on ApiException catch (e) {
      debugPrint('❌ [CotdService] fetchAnswers error: $e');
      return <CotdAnswer>[];
    } catch (e, stack) {
      debugPrint('❌ [CotdService] fetchAnswers unexpected: $e\n$stack');
      return <CotdAnswer>[];
    }
  }
}

// Conversation of the Day service — all /admin/cotd* and /engagement/cotd* calls.
// Mirrors the app-side feature services (see features/profile_setup/profile_setup_service.dart).

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import 'models/cotd_models.dart';

class CotdService {
  const CotdService(this._client);

  final ApiClient _client;

  /// POST /admin/cotd — publish a new question (ends the current live one).
  Future<CotdQuestion> publishQuestion(String question) async {
    debugPrint('🚀 [CotdService] POST ${ApiEndpoints.adminCotd}');
    final dynamic data = await _client.post(
      ApiEndpoints.adminCotd,
      body: <String, dynamic>{'question': question},
    );
    return CotdQuestion.fromJson(data as Map<String, dynamic>);
  }

  /// GET /admin/cotd/history — every question that has gone live.
  Future<List<CotdQuestion>> fetchHistory() async {
    debugPrint('🚀 [CotdService] GET ${ApiEndpoints.adminCotdHistory}');
    final dynamic data = await _client.get(
      ApiEndpoints.adminCotdHistory,
      useCache: false,
    );
    return (data as List<dynamic>)
        .map((dynamic e) => CotdQuestion.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// GET /engagement/cotd/:id/answers
  Future<List<CotdAnswer>> fetchAnswers(String questionId) async {
    debugPrint('🚀 [CotdService] GET ${ApiEndpoints.cotdAnswers(questionId)}');
    final dynamic data = await _client.get(
      ApiEndpoints.cotdAnswers(questionId),
      useCache: false,
    );
    return (data as List<dynamic>)
        .map((dynamic e) => CotdAnswer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// PATCH /admin/cotd/answers/:id/feature
  Future<CotdAnswer> featureAnswer(String answerId) async {
    debugPrint('🚀 [CotdService] PATCH ${ApiEndpoints.adminCotdAnswerFeature(answerId)}');
    final dynamic data =
        await _client.patch(ApiEndpoints.adminCotdAnswerFeature(answerId));
    return CotdAnswer.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /admin/cotd/answers/:id/hide
  Future<CotdAnswer> hideAnswer(String answerId) async {
    debugPrint('🚀 [CotdService] PATCH ${ApiEndpoints.adminCotdAnswerHide(answerId)}');
    final dynamic data =
        await _client.patch(ApiEndpoints.adminCotdAnswerHide(answerId));
    return CotdAnswer.fromJson(data as Map<String, dynamic>);
  }
}

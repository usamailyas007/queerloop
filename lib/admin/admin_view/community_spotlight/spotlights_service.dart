// Community Spotlight service — /admin/spotlights* and /engagement/spotlights.
// Mirrors the app-side feature services (see features/profile_setup/profile_setup_service.dart).

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import 'models/spotlight.dart';

class SpotlightsService {
  const SpotlightsService(this._client);

  final ApiClient _client;

  /// GET /engagement/spotlights — every spotlight, newest first (`live` flag set).
  Future<List<Spotlight>> fetchSpotlights({String? search}) async {
    final Map<String, dynamic>? query =
        (search != null && search.trim().isNotEmpty)
            ? <String, dynamic>{'search': search.trim()}
            : null;
    debugPrint('🚀 [SpotlightsService] GET ${ApiEndpoints.engagementSpotlights} $query');
    final dynamic data = await _client.get(
      ApiEndpoints.engagementSpotlights,
      query: query,
      useCache: false,
    );
    final List<dynamic> list;
    if (data is List<dynamic>) {
      list = data;
    } else if (data is Map<String, dynamic> && data['spotlights'] is List<dynamic>) {
      list = data['spotlights'] as List<dynamic>;
    } else if (data is Map<String, dynamic> && data['data'] is List<dynamic>) {
      list = data['data'] as List<dynamic>;
    } else {
      list = <dynamic>[];
    }
    return list
        .map((dynamic e) => Spotlight.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /admin/spotlights — publish a new spotlight (supersedes the live one).
  Future<Spotlight> createSpotlight({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    debugPrint('🚀 [SpotlightsService] POST ${ApiEndpoints.adminSpotlights}');
    final dynamic data = await _client.post(
      ApiEndpoints.adminSpotlights,
      body: _payload(title: title, body: body, imageUrl: imageUrl),
    );
    return Spotlight.fromJson(data as Map<String, dynamic>);
  }

  /// PATCH /admin/spotlights/:id — edit an existing spotlight.
  Future<Spotlight> updateSpotlight({
    required String id,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    debugPrint('🚀 [SpotlightsService] PATCH ${ApiEndpoints.adminSpotlight(id)}');
    final dynamic data = await _client.patch(
      ApiEndpoints.adminSpotlight(id),
      body: _payload(title: title, body: body, imageUrl: imageUrl),
    );
    return Spotlight.fromJson(data as Map<String, dynamic>);
  }

  /// POST /admin/spotlights/:id/rerun — re-publish a past spotlight as a new one.
  Future<Spotlight> rerunSpotlight(String id) async {
    debugPrint('🚀 [SpotlightsService] POST ${ApiEndpoints.adminSpotlightRerun(id)}');
    final dynamic data =
        await _client.post(ApiEndpoints.adminSpotlightRerun(id));
    return Spotlight.fromJson(data as Map<String, dynamic>);
  }

  Map<String, dynamic> _payload({
    required String title,
    required String body,
    String? imageUrl,
  }) {
    return <String, dynamic>{
      'title': title,
      'body': body,
      if (imageUrl != null && imageUrl.trim().isNotEmpty)
        'imageUrl': imageUrl.trim(),
    };
  }
}

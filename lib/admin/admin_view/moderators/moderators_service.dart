// Moderators service — GET / POST /admin/moderators.
// Mirrors the app-side feature services (see features/profile_setup/profile_setup_service.dart).

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import 'models/moderator.dart';

class ModeratorsService {
  const ModeratorsService(this._client);

  final ApiClient _client;

  /// GET /admin/moderators — full roster (admins included).
  Future<List<Moderator>> fetchModerators() async {
    debugPrint('🚀 [ModeratorsService] GET ${ApiEndpoints.adminModerators}');
    final dynamic data = await _client.get(
      ApiEndpoints.adminModerators,
      useCache: false,
    );
    return (data as List<dynamic>)
        .map((dynamic e) => Moderator.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /admin/moderators — create + invite a moderator account.
  Future<void> inviteModerator({
    required String email,
    required String password,
    required List<String> communityIds,
    String role = 'moderator',
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'email': email,
      'password': password,
      'role': role,
      'communityIds': communityIds,
    };

    debugPrint('🚀 [ModeratorsService] POST ${ApiEndpoints.adminModerators} ($email)');
    await _client.post(ApiEndpoints.adminModerators, body: body);
  }
}

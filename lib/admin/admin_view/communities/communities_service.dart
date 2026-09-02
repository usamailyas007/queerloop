// Communities service — GET / POST /communities.
// Mirrors the app-side feature services (see features/profile_setup/profile_setup_service.dart).

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import 'models/community.dart';

class CommunitiesService {
  const CommunitiesService(this._client);

  final ApiClient _client;

  /// GET /admin/communities — roster with member / post / report counts and
  /// assigned moderators.
  Future<List<Community>> fetchCommunities() async {
    debugPrint('🚀 [CommunitiesService] GET ${ApiEndpoints.adminCommunities}');
    final dynamic data = await _client.get(
      ApiEndpoints.adminCommunities,
      useCache: false,
    );
    return (data as List<dynamic>)
        .map((dynamic e) => Community.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /communities — create a group. `imageBase64` is the raw base64
  /// payload (no data: prefix) and is optional.
  Future<Community> createCommunity({
    required String name,
    required String slug,
    required String description,
    required CommunityVisibility visibility,
    String? imageBase64,
  }) async {
    final Map<String, dynamic> body = <String, dynamic>{
      'name': name,
      'slug': slug,
      'description': description,
      'visibility': visibility.query,
      if (imageBase64 != null && imageBase64.isNotEmpty)
        'imageBase64': imageBase64,
    };

    debugPrint('🚀 [CommunitiesService] POST ${ApiEndpoints.communities} ($name)');
    final dynamic data =
        await _client.post(ApiEndpoints.communities, body: body);
    return Community.fromJson(data as Map<String, dynamic>);
  }
}

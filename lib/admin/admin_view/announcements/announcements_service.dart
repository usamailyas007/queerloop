// Announcements service — GET /engagement/announcements, POST /admin/announcements.
// Mirrors the app-side feature services (see features/profile_setup/profile_setup_service.dart).

import 'package:flutter/foundation.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import 'models/announcement.dart';

class AnnouncementsService {
  const AnnouncementsService(this._client);

  final ApiClient _client;

  /// GET /engagement/announcements — the published feed, newest first.
  Future<List<Announcement>> fetchAnnouncements() async {
    debugPrint('🚀 [AnnouncementsService] GET ${ApiEndpoints.engagementAnnouncements}');
    final dynamic data = await _client.get(
      ApiEndpoints.engagementAnnouncements,
      useCache: false,
    );
    return (data as List<dynamic>)
        .map((dynamic e) => Announcement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /admin/announcements — publish a new announcement.
  Future<Announcement> createAnnouncement({
    required String title,
    required String body,
    required AnnouncementAudience audience,
    String? communityId,
  }) async {
    final Map<String, dynamic> payload = <String, dynamic>{
      'title': title,
      'body': body,
      'audience': audience.query,
      if (audience == AnnouncementAudience.community &&
          communityId != null &&
          communityId.isNotEmpty)
        'communityId': communityId,
    };

    debugPrint('🚀 [AnnouncementsService] POST ${ApiEndpoints.adminAnnouncements} ($title)');
    final dynamic data =
        await _client.post(ApiEndpoints.adminAnnouncements, body: payload);
    return Announcement.fromJson(data as Map<String, dynamic>);
  }
}

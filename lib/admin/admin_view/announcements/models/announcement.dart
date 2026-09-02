// Model for announcements — GET /engagement/announcements and the create response.

enum AnnouncementAudience { everyone, community, moderators }

extension AnnouncementAudienceX on AnnouncementAudience {
  /// Wire value the API expects / returns.
  String get query => name;

  String get label => switch (this) {
        AnnouncementAudience.everyone => 'Everyone',
        AnnouncementAudience.community => 'One community',
        AnnouncementAudience.moderators => 'Moderators',
      };

  static AnnouncementAudience parse(String? raw) => switch (raw) {
        'community' => AnnouncementAudience.community,
        'moderators' => AnnouncementAudience.moderators,
        _ => AnnouncementAudience.everyone,
      };
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.publishedAt,
    this.communityId,
    this.createdBy,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      audience: AnnouncementAudienceX.parse(json['audience'] as String?),
      communityId: json['communityId'] as String?,
      createdBy: json['createdBy'] as String?,
      publishedAt: DateTime.tryParse(json['publishedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final String id;
  final String title;
  final String body;
  final AnnouncementAudience audience;
  final String? communityId;
  final String? createdBy;
  final DateTime publishedAt;
}

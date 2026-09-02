// Model for /communities — list rows and the create response.

enum CommunityVisibility { public, private }

extension CommunityVisibilityX on CommunityVisibility {
  /// Wire value the API expects / returns.
  String get query => name;

  String get label =>
      this == CommunityVisibility.private ? 'Members only' : 'Public';

  static CommunityVisibility parse(String? raw) =>
      raw == 'private' ? CommunityVisibility.private : CommunityVisibility.public;
}

class CommunityModerator {
  const CommunityModerator({required this.userId, this.username, this.displayName});

  factory CommunityModerator.fromJson(Map<String, dynamic> json) {
    return CommunityModerator(
      userId: json['userId'] as String? ?? '',
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
    );
  }

  final String userId;
  final String? username;
  final String? displayName;

  String get name {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (username != null && username!.isNotEmpty) return username!;
    return 'Moderator';
  }
}

class Community {
  const Community({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
    required this.visibility,
    required this.createdAt,
    this.imageUrl,
    this.createdBy,
    this.memberCount = 0,
    this.postCount = 0,
    this.reportCount = 0,
    this.moderators = const <CommunityModerator>[],
  });

  factory Community.fromJson(Map<String, dynamic> json) {
    return Community(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      visibility: CommunityVisibilityX.parse(json['visibility'] as String?),
      createdBy: json['createdBy'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      postCount: (json['postCount'] as num?)?.toInt() ?? 0,
      reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
      moderators: (json['moderators'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) =>
              CommunityModerator.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String name;
  final String slug;
  final String description;
  final String? imageUrl;
  final CommunityVisibility visibility;
  final String? createdBy;
  final DateTime createdAt;
  final int memberCount;
  final int postCount;
  final int reportCount;
  final List<CommunityModerator> moderators;

  String get moderatorsLabel => moderators.isEmpty
      ? '—'
      : moderators.map((CommunityModerator m) => m.name).join(', ');
}

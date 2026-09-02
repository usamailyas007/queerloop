// Model for GET /admin/moderators.

class Moderator {
  const Moderator({
    required this.id,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.pending,
    required this.communities,
    required this.resolved30d,
    required this.reversed,
    this.username,
    this.displayName,
    this.avgResponseHours,
  });

  factory Moderator.fromJson(Map<String, dynamic> json) {
    return Moderator(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'moderator',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      pending: json['pending'] as bool? ?? false,
      communities: _parseCommunities(json['communities']),
      resolved30d: (json['resolved30d'] as num?)?.toInt() ?? 0,
      reversed: (json['reversed'] as num?)?.toInt() ?? 0,
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      avgResponseHours: (json['avgResponseHours'] as num?)?.toDouble(),
    );
  }

  final String id;
  final String email;
  final String role;
  final DateTime createdAt;
  final bool pending;

  /// Community names the moderator covers (may be empty).
  final List<String> communities;
  final int resolved30d;
  final int reversed;
  final String? username;
  final String? displayName;
  final double? avgResponseHours;

  String get name {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (username != null && username!.isNotEmpty) return username!;
    return email.split('@').first;
  }

  String get communitiesLabel =>
      communities.isEmpty ? 'All communities' : communities.join(', ');

  static List<String> _parseCommunities(dynamic raw) {
    if (raw is! List) {
      return const <String>[];
    }
    return raw
        .map<String>((dynamic e) {
          if (e is String) return e;
          if (e is Map<String, dynamic>) {
            return (e['name'] ?? e['slug'] ?? e['id'] ?? '').toString();
          }
          return e.toString();
        })
        .where((String s) => s.isNotEmpty)
        .toList();
  }
}

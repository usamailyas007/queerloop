// Models for GET /admin/users — one account row and one page of results.

enum AdminAccountStatus { active, suspended, banned }

extension AdminAccountStatusX on AdminAccountStatus {
  /// Value the API expects as the `?status=` filter.
  String get query => name;

  String get label => switch (this) {
        AdminAccountStatus.active => 'Active',
        AdminAccountStatus.suspended => 'Suspended',
        AdminAccountStatus.banned => 'Banned',
      };
}

class AdminUserAccount {
  AdminUserAccount({
    required this.id,
    required this.email,
    required this.createdAt,
    required this.status,
    required this.role,
    required this.postCount,
    required this.reportsAgainst,
    this.statusExpiresAt,
    this.username,
    this.displayName,
  });

  factory AdminUserAccount.fromJson(Map<String, dynamic> json) {
    return AdminUserAccount(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: _parseStatus(json['accountStatus'] as String?),
      statusExpiresAt: DateTime.tryParse(json['statusExpiresAt'] as String? ?? ''),
      role: json['role'] as String? ?? 'user',
      username: json['username'] as String?,
      displayName: json['displayName'] as String?,
      postCount: (json['postCount'] as num?)?.toInt() ?? 0,
      reportsAgainst: (json['reportsAgainst'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String email;
  final DateTime createdAt;
  final String role;
  final String? username;
  final String? displayName;
  final int postCount;
  final int reportsAgainst;

  // Mutable so the Manage menu can reflect a status change optimistically
  // until the corresponding admin mutation endpoint is wired.
  AdminAccountStatus status;
  DateTime? statusExpiresAt;

  /// `@handle` when a username exists, otherwise the email local-part.
  String get handle =>
      username != null && username!.isNotEmpty ? '@$username' : email.split('@').first;

  String get secondaryLine =>
      displayName != null && displayName!.isNotEmpty ? displayName! : email;

  static AdminAccountStatus _parseStatus(String? raw) {
    return switch (raw) {
      'suspended' => AdminAccountStatus.suspended,
      'banned' => AdminAccountStatus.banned,
      _ => AdminAccountStatus.active,
    };
  }
}

class AdminUsersPage {
  const AdminUsersPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory AdminUsersPage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawItems = json['items'] as List<dynamic>? ?? <dynamic>[];
    return AdminUsersPage(
      items: rawItems
          .map((dynamic e) =>
              AdminUserAccount.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? rawItems.length,
    );
  }

  final List<AdminUserAccount> items;
  final int total;
  final int page;
  final int limit;
}

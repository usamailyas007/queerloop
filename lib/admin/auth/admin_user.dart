enum AdminRole { moderator, admin }

class AdminUser {
  const AdminUser({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
    this.avatarUrl,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    final AdminRole? role = parseRole(json['role'] as String?);
    if (role == null) {
      throw const AdminAccessDeniedException();
    }
    return AdminUser(
      id: json['id'] as String,
      email: json['email'] as String,
      role: role,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String id;
  final String email;
  final AdminRole role;
  final String? displayName;
  final String? avatarUrl;

  static AdminRole? parseRole(String? raw) {
    return switch (raw) {
      'admin' => AdminRole.admin,
      'moderator' => AdminRole.moderator,
      _ => null,
    };
  }
}

class AdminSession {
  const AdminSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      user: AdminUser.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  final AdminUser user;
  final String accessToken;
  final String refreshToken;
}

class AdminAccessDeniedException implements Exception {
  const AdminAccessDeniedException([this.message = 'This account does not have admin access.']);

  final String message;

  @override
  String toString() => 'AdminAccessDeniedException: $message';
}

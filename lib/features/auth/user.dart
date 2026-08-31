// Auth models: the signed-in user and the full session returned by the API.

enum AccountStatus { active, suspended, banned }

class User {
  const User({
    required this.id,
    required this.email,
    required this.role,
    required this.accountStatus,
    required this.dobVerified,
    this.displayName,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      role: json['role'] as String? ?? 'user',
      accountStatus: _parseStatus(json['accountStatus'] as String?),
      dobVerified: json['dobVerified'] as bool? ?? false,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String id;
  final String email;
  final String role;
  final AccountStatus accountStatus;
  final bool dobVerified;
  final String? displayName;
  final String? avatarUrl;

  static AccountStatus _parseStatus(String? raw) {
    return switch (raw) {
      'suspended' => AccountStatus.suspended,
      'banned' => AccountStatus.banned,
      _ => AccountStatus.active,
    };
  }
}

// Full session object returned by /auth/register and /auth/login.
class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  final User user;
  final String accessToken;
  final String refreshToken;
}

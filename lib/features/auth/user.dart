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
    this.emailVerified,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: (json['id'] ?? json['_id'] ?? json['userId'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      role: (json['role'] ?? 'user').toString(),
      accountStatus: _parseStatus(json['accountStatus']?.toString()),
      dobVerified: json['dobVerified'] as bool? ??
          json['emailVerified'] as bool? ??
          false,
      displayName:
          (json['displayName'] ?? json['name'] ?? json['username']) as String?,
      avatarUrl: (json['avatarUrl'] ?? json['avatar'] ?? json['profilePic'])
          as String?,
      emailVerified: json['emailVerified'] as bool?,
    );
  }

  final String id;
  final String email;
  final String role;
  final AccountStatus accountStatus;
  final bool dobVerified;
  final String? displayName;
  final String? avatarUrl;
  final bool? emailVerified;

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
    final Map<String, dynamic> payload = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final Map<String, dynamic> userMap =
        (payload['user'] is Map<String, dynamic>)
            ? payload['user'] as Map<String, dynamic>
            : (payload['profile'] is Map<String, dynamic>
                ? payload['profile'] as Map<String, dynamic>
                : payload);

    final String accessToken = (payload['accessToken'] ??
            payload['access_token'] ??
            payload['token'] ??
            payload['jwt'] ??
            '')
        .toString();

    final String refreshToken = (payload['refreshToken'] ??
            payload['refresh_token'] ??
            (payload['tokens'] is Map ? payload['tokens']['refreshToken'] : null) ??
            '')
        .toString();

    return AuthSession(
      user: User.fromJson(userMap),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  final User user;
  final String accessToken;
  final String refreshToken;
}

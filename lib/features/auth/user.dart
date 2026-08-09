// Auth models: the signed in user and the session returned by sign in.

class User {
  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String id;
  final String email;
  final String? displayName;
  final String? avatarUrl;
}

class AuthSession {
  const AuthSession({required this.user, required this.token});

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
    );
  }

  final User user;
  final String token;
}

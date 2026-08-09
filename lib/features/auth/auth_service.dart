// Auth endpoints.

import '../../core/api/api_client.dart';
import '../../core/config/app_config.dart';
import 'user.dart';

class AuthService {
  const AuthService(this._client);

  final ApiClient _client;

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockApi) {
      return _mockSession(email);
    }

    final dynamic data = await _client.post(
      '/auth/login',
      body: <String, dynamic>{'email': email, 'password': password},
    );
    return AuthSession.fromJson(data as Map<String, dynamic>);
  }

  Future<void> signOut() async {
    if (AppConfig.useMockApi) {
      return;
    }
    await _client.post('/auth/logout');
  }

  Future<AuthSession> restore(String token) async {
    if (AppConfig.useMockApi) {
      return _mockSession(token);
    }

    final dynamic data = await _client.get('/auth/me');
    return AuthSession(
      user: User.fromJson(data as Map<String, dynamic>),
      token: token,
    );
  }

  AuthSession _mockSession(String email) {
    final String normalized = email.trim().toLowerCase();
    return AuthSession(
      user: User(id: normalized, email: normalized),
      token: 'mock-token',
    );
  }
}

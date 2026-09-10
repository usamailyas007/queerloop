import 'package:flutter/foundation.dart';
import '../../core/api/api_client.dart';
import '../../core/config/api_endpoints.dart';
import '../../core/config/app_config.dart';
import 'admin_session_store.dart';
import 'admin_user.dart';

abstract final class _StorageKey {
  static const String accessToken = 'admin.auth.accessToken';
  static const String refreshToken = 'admin.auth.refreshToken';
}

class AdminAuthService {
  AdminAuthService(this._client, {AdminSessionStore? storage})
    : _storage = storage ?? AdminSessionStore();

  final ApiClient _client;
  final AdminSessionStore _storage;

  // ── Sign in ───────────────────────────────────────────────────────────────

  Future<AdminSession> signIn({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint(
        'ℹ️ [AdminAuthService] Mock API is ON. Returning mock session.',
      );
      return _mockSession(email);
    }

    debugPrint('🚀 [AdminAuthService] Sending Login request for: $email');
    final dynamic data = await _client.post(
      ApiEndpoints.login,
      body: <String, dynamic>{'email': email, 'password': password},
    );
    debugPrint('📥 [AdminAuthService] Login Response: $data');
    final AdminSession session = AdminSession.fromJson(
      data as Map<String, dynamic>,
    );
    await _persistTokens(session);
    return session;
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  /// Revokes the session server-side (POST /auth/logout needs the Bearer access
  /// token + a `refreshToken` string body) then always clears local tokens.
  /// Returns true when the server call succeeded.
  Future<bool> signOut({String? refreshToken}) async {
    if (AppConfig.useMockApi) {
      await _clearTokens();
      return true;
    }

    final String refresh = (refreshToken != null && refreshToken.isNotEmpty)
        ? refreshToken
        : await _storage.read(key: _StorageKey.refreshToken) ?? '';

    bool ok = false;
    debugPrint('🚀 [AdminAuthService] POST ${ApiEndpoints.logout}');
    try {
      await _client.post(
        ApiEndpoints.logout,
        body: <String, dynamic>{'refreshToken': refresh},
      );
      debugPrint('📥 [AdminAuthService] Logout success');
      ok = true;
    } catch (e) {
      debugPrint('⚠️ [AdminAuthService] Logout error (clearing local session): $e');
    }

    await _clearTokens();
    return ok;
  }

  // ── Refresh ───────────────────────────────────────────────────────────────

  /// POST /auth/refresh — exchanges the stored refresh token for a fresh pair
  /// (the server rotates both). Persists the new tokens and returns them, or
  /// null when the refresh token is missing / rejected (caller signs out).
  Future<({String accessToken, String refreshToken})?> refreshSession() async {
    if (AppConfig.useMockApi) {
      return null;
    }

    final String? refresh = await _storage.read(key: _StorageKey.refreshToken);
    if (refresh == null || refresh.isEmpty) {
      return null;
    }

    try {
      debugPrint('🔄 [AdminAuthService] POST ${ApiEndpoints.refresh}');
      final dynamic data = await _client.postNoAuth(
        ApiEndpoints.refresh,
        body: <String, dynamic>{'refreshToken': refresh},
      );
      final Map<String, dynamic> map = data as Map<String, dynamic>;
      final String access = map['accessToken'] as String;
      final String newRefresh = map['refreshToken'] as String? ?? refresh;

      await Future.wait(<Future<void>>[
        _storage.write(key: _StorageKey.accessToken, value: access),
        _storage.write(key: _StorageKey.refreshToken, value: newRefresh),
      ]);

      return (accessToken: access, refreshToken: newRefresh);
    } catch (e) {
      debugPrint('⚠️ [AdminAuthService] Refresh failed: $e');
      return null;
    }
  }

  // ── Restore from secure storage ───────────────────────────────────────────
  // Called once at startup; returns null if no token is stored.

  Future<AdminSession?> restoreSession() async {
    if (AppConfig.useMockApi) {
      return null;
    }

    final String? accessToken = await _storage.read(
      key: _StorageKey.accessToken,
    );
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    _client.authToken = accessToken;

    // Verify the stored token is still valid by calling /auth/me. If the access
    // token has expired, the ApiClient transparently refreshes it mid-call and
    // rotates both tokens in storage — so re-read them afterwards.
    final dynamic data = await _client.get(ApiEndpoints.me, useCache: false);
    final AdminUser user = AdminUser.fromJson(data as Map<String, dynamic>);

    final String currentAccess =
        await _storage.read(key: _StorageKey.accessToken) ?? accessToken;
    final String? refreshToken = await _storage.read(
      key: _StorageKey.refreshToken,
    );

    return AdminSession(
      user: user,
      accessToken: currentAccess,
      refreshToken: refreshToken ?? '',
    );
  }

  // ── Token helpers ─────────────────────────────────────────────────────────

  Future<void> _persistTokens(AdminSession session) async {
    await Future.wait(<Future<void>>[
      _storage.write(key: _StorageKey.accessToken, value: session.accessToken),
      _storage.write(
        key: _StorageKey.refreshToken,
        value: session.refreshToken,
      ),
    ]);
  }

  Future<void> _clearTokens() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _StorageKey.accessToken),
      _storage.delete(key: _StorageKey.refreshToken),
    ]);
  }

  // ── Mock helpers ──────────────────────────────────────────────────────────

  AdminSession _mockSession(String email) {
    final String normalized = email.trim().toLowerCase();
    return AdminSession(
      user: AdminUser(
        id: normalized,
        email: normalized,
        role: normalized.contains('admin')
            ? AdminRole.admin
            : AdminRole.moderator,
      ),
      accessToken: 'mock-admin-access-token',
      refreshToken: 'mock-admin-refresh-token',
    );
  }
  
}

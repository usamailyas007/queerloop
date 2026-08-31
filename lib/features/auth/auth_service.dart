// Auth service: all API calls for authentication.
// Tokens are persisted to the device's secure enclave via flutter_secure_storage.

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api/api_client.dart';
import '../../core/config/api_endpoints.dart';
import '../../core/config/app_config.dart';
import 'user.dart';

/// Keys used in secure storage — centralised so we never typo them.
abstract final class _StorageKey {
  static const String accessToken = 'auth.accessToken';
  static const String refreshToken = 'auth.refreshToken';
}

class AuthService {
  AuthService(this._client, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient _client;
  final FlutterSecureStorage _storage;

  // ── Register ──────────────────────────────────────────────────────────────
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock API is ON. Returning mock register session.');
      return _mockSession(email);
    }

    debugPrint('🚀 [AuthService] Sending Register request for: $email');
    final dynamic data = await _client.post(
      ApiEndpoints.register,
      body: <String, dynamic>{'email': email, 'password': password},
    );
    debugPrint('📥 [AuthService] Register Response: $data');
    final AuthSession session =
        AuthSession.fromJson(data as Map<String, dynamic>);
    await _persistTokens(session);
    return session;
  }

  // ── Sign in ───────────────────────────────────────────────────────────────

  Future<AuthSession> signIn({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock API is ON. Returning mock sign-in session.');
      return _mockSession(email);
    }

    debugPrint('🚀 [AuthService] Sending Login request for: $email');
    final dynamic data = await _client.post(
      ApiEndpoints.login,
      body: <String, dynamic>{'email': email, 'password': password},
    );
    debugPrint('📥 [AuthService] Login Response: $data');
    final AuthSession session =
        AuthSession.fromJson(data as Map<String, dynamic>);
    await _persistTokens(session);
    return session;
  }

  // ── Password Reset ────────────────────────────────────────────────────────
  // 1. Request Password Reset / Resend OTP
  // POST /auth/password-reset/request  { email }

  Future<void> requestPasswordReset(String email) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock requestPasswordReset for $email');
      return;
    }

    debugPrint('🚀 [AuthService] Requesting Password Reset OTP for: $email');
    final dynamic data = await _client.post(
      ApiEndpoints.passwordResetRequest,
      body: <String, dynamic>{'email': email.trim()},
    );
    debugPrint('📥 [AuthService] Password Reset Request Response: $data');
  }

  // 2. Verify Password Reset OTP
  // POST /auth/password-reset/verify  { email, otp }
  // Returns: { resetTicket: "..." }

  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock verifyPasswordResetOtp');
      return 'mock-reset-ticket';
    }

    debugPrint('🚀 [AuthService] Verifying Password Reset OTP for: $email (OTP: $otp)');
    final dynamic data = await _client.post(
      ApiEndpoints.passwordResetVerify,
      body: <String, dynamic>{'email': email.trim(), 'otp': otp.trim()},
    );
    debugPrint('📥 [AuthService] OTP Verify Response: $data');
    final String resetTicket =
        (data as Map<String, dynamic>)['resetTicket'] as String? ?? '';
    return resetTicket;
  }

  // 3. Confirm Password Reset
  // POST /auth/password-reset/confirm  { resetTicket, newPassword }

  Future<void> confirmPasswordReset({
    required String resetTicket,
    required String newPassword,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock confirmPasswordReset');
      return;
    }

    debugPrint('🚀 [AuthService] Confirming Password Reset with ticket');
    final dynamic data = await _client.post(
      ApiEndpoints.passwordResetConfirm,
      body: <String, dynamic>{
        'resetTicket': resetTicket,
        'newPassword': newPassword,
      },
    );
    debugPrint('📥 [AuthService] Password Reset Confirm Response: $data');
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut({String? refreshToken}) async {
    if (!AppConfig.useMockApi) {
      final String? storedRefresh =
          refreshToken ?? await _storage.read(key: _StorageKey.refreshToken);
      debugPrint('🚀 [AuthService] Logging out user...');
      try {
        await _client.post(
          ApiEndpoints.logout,
          body: storedRefresh != null && storedRefresh.isNotEmpty
              ? <String, dynamic>{'refreshToken': storedRefresh}
              : null,
        );
        debugPrint('📥 [AuthService] Logout success');
      } catch (e) {
        debugPrint('⚠️ [AuthService] Logout error (clearing local session): $e');
      }
    }
    await _clearTokens();
  }

  // ── Restore from secure storage ───────────────────────────────────────────
  // Called once at startup; returns null if no token is stored.

  Future<AuthSession?> restoreSession() async {
    if (AppConfig.useMockApi) {
      return null;
    }

    final String? accessToken =
        await _storage.read(key: _StorageKey.accessToken);
    if (accessToken == null || accessToken.isEmpty) {
      return null;
    }

    // Verify the stored token is still valid by calling /auth/me.
    final dynamic data = await _client.get(ApiEndpoints.me);
    final User user = User.fromJson(data as Map<String, dynamic>);

    // Re-read the refresh token to rebuild the full session object.
    final String? refreshToken =
        await _storage.read(key: _StorageKey.refreshToken);

    return AuthSession(
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken ?? '',
    );
  }

  // ── Token helpers ─────────────────────────────────────────────────────────

  Future<void> _persistTokens(AuthSession session) async {
    await Future.wait(<Future<void>>[
      _storage.write(
          key: _StorageKey.accessToken, value: session.accessToken),
      _storage.write(
          key: _StorageKey.refreshToken, value: session.refreshToken),
    ]);
  }

  Future<void> _clearTokens() async {
    await Future.wait(<Future<void>>[
      _storage.delete(key: _StorageKey.accessToken),
      _storage.delete(key: _StorageKey.refreshToken),
    ]);
  }

  // ── Mock helpers ──────────────────────────────────────────────────────────

  AuthSession _mockSession(String email) {
    final String normalized = email.trim().toLowerCase();
    return AuthSession(
      user: User(
        id: normalized,
        email: normalized,
        role: 'user',
        accountStatus: AccountStatus.active,
        dobVerified: false,
      ),
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token',
    );
  }
}

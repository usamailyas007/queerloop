import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/cache/cache_manager.dart';
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

  Future<String?> getAccessToken() => _storage.read(key: _StorageKey.accessToken);
  Future<String?> getRefreshToken() => _storage.read(key: _StorageKey.refreshToken);

  // ── Register ──────────────────────────────────────────────────────────────
  Future<RegisterResponse> register({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock API is ON. Returning mock register response.');
      return RegisterResponse(
        verificationRequired: true,
        email: email,
        message: 'Mock verification code sent.',
      );
    }

    debugPrint('🚀 [AuthService] Sending Register request for: $email');
    final dynamic data = await _client.post(
      ApiEndpoints.register,
      body: <String, dynamic>{'email': email, 'password': password},
    );
    debugPrint('📥 [AuthService] Register Response: $data');
    if (data is Map<String, dynamic>) {
      return RegisterResponse.fromJson(data);
    }
    return RegisterResponse(
      verificationRequired: true,
      email: email,
      message: 'Verification code sent.',
    );
  }

  // ── Verify Email OTP ──────────────────────────────────────────────────────
  // POST /auth/verify-email
  // Body: { email, otp, staySignedIn?, deviceLabel? }
  // Returns: { accessToken, refreshToken, user: { ... } }

  Future<AuthSession> verifyEmail({
    required String email,
    required String otp,
    bool staySignedIn = false,
    String? deviceLabel,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock API is ON. Returning mock verify session.');
      return _mockSession(email);
    }

    debugPrint('🚀 [AuthService] Verifying Email OTP for: $email (OTP: $otp)');
    final Map<String, dynamic> body = <String, dynamic>{
      'email': email.trim(),
      'otp': otp.trim(),
      'staySignedIn': staySignedIn,
    };
    if (deviceLabel != null && deviceLabel.isNotEmpty) {
      body['deviceLabel'] = deviceLabel;
    }

    final dynamic data = await _client.post(
      ApiEndpoints.verifyEmail,
      body: body,
    );
    debugPrint('📥 [AuthService] Verify Email Response: $data');
    final AuthSession session =
        AuthSession.fromJson(data as Map<String, dynamic>);
    _client.authToken = session.accessToken;
    await _persistTokens(session);
    return session;
  }

  // ── Resend Email OTP ──────────────────────────────────────────────────────
  // POST /auth/verify-email/resend
  // Body: { email }
  // Returns: { message }

  Future<void> resendEmailOtp(String email) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock resendEmailOtp for $email');
      return;
    }

    debugPrint('🚀 [AuthService] Resending Email OTP for: $email');
    final dynamic data = await _client.post(
      ApiEndpoints.verifyEmailResend,
      body: <String, dynamic>{'email': email.trim()},
    );
    debugPrint('📥 [AuthService] Resend Email OTP Response: $data');
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
    _client.authToken = session.accessToken;
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

  // ── Refresh Token ──────────────────────────────────────────────────────────
  // POST /auth/refresh
  // Body: { "refreshToken": "..." }
  // Returns: { "accessToken": "...", "refreshToken"?: "..." }
  Future<String?> refreshToken([String? explicitRefreshToken]) async {
    final String? candidate =
        (explicitRefreshToken != null && explicitRefreshToken.trim().isNotEmpty)
            ? explicitRefreshToken.trim()
            : await _storage.read(key: _StorageKey.refreshToken);
    if (candidate == null || candidate.trim().isEmpty) {
      debugPrint('⚠️ [AuthService] No refresh token found in secure storage or memory.');
      return null;
    }

    final String cleanRefresh = candidate.trim();

    if (AppConfig.useMockApi) {
      const String mockAccess = 'mock-refreshed-access-token';
      await _storage.write(key: _StorageKey.accessToken, value: mockAccess);
      _client.authToken = mockAccess;
      return mockAccess;
    }

    try {
      debugPrint(
          '🔄 [AuthService] Calling POST ${ApiEndpoints.refresh} to refresh token...');
      final Dio refreshDio = Dio(
        BaseOptions(
          baseUrl: _client.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      Response<dynamic> response;
      try {
        response = await refreshDio.post<dynamic>(
          ApiEndpoints.refresh,
          data: <String, dynamic>{
            'refreshToken': cleanRefresh,
          },
        );
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 401 &&
            _client.authToken != null &&
            _client.authToken!.isNotEmpty) {
          debugPrint(
              '🔄 [AuthService] Refresh without header returned 401. Retrying with old accessToken Bearer...');
          response = await refreshDio.post<dynamic>(
            ApiEndpoints.refresh,
            data: <String, dynamic>{
              'refreshToken': cleanRefresh,
            },
            options: Options(
              headers: <String, String>{
                'Authorization': 'Bearer ${_client.authToken}',
              },
            ),
          );
        } else {
          rethrow;
        }
      }

      debugPrint(
          '📥 [AuthService] Refresh Token Response [${response.statusCode}]: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        dynamic data = response.data;
        if (data is Map<String, dynamic>) {
          if (data['data'] is Map<String, dynamic>) {
            data = data['data'] as Map<String, dynamic>;
          } else if (data['tokens'] is Map<String, dynamic>) {
            data = data['tokens'] as Map<String, dynamic>;
          }
          final String? newAccessToken = (data['accessToken'] as String?) ??
              (data['token'] as String?) ??
              (data['access_token'] as String?) ??
              (data['jwt'] as String?);
          final String? newRefreshToken = (data['refreshToken'] as String?) ??
              (data['refresh_token'] as String?);

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await _storage.write(
              key: _StorageKey.accessToken,
              value: newAccessToken,
            );
            _client.authToken = newAccessToken;

            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await _storage.write(
                key: _StorageKey.refreshToken,
                value: newRefreshToken,
              );
            }
            debugPrint(
                '🔑 [AuthService] Successfully refreshed and persisted new access token.');
            return newAccessToken;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ [AuthService] Token refresh API error: $e');
      return null;
    }
  }

  // ── Clear All Local Data ──────────────────────────────────────────────────
  Future<void> clearAllLocalData() async {
    debugPrint(
        '🧹 [AuthService] Clearing all local data (SecureStorage, SharedPreferences, Cache)...');
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error clearing secure storage: $e');
    }
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error clearing SharedPreferences: $e');
    }
    try {
      await CacheManager.instance.clearAll();
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error clearing CacheManager: $e');
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────
  Future<void> signOut({String? refreshToken}) async {
    final String? storedRefresh =
        refreshToken ?? await _storage.read(key: _StorageKey.refreshToken);
    if (!AppConfig.useMockApi) {
      debugPrint(
          '🚀 [AuthService] Logging out user (POST ${ApiEndpoints.logout})\n   Payload: {refreshToken: $storedRefresh}');
      try {
        final dynamic data = await _client.post(
          ApiEndpoints.logout,
          body: <String, dynamic>{'refreshToken': storedRefresh ?? ''},
        );
        debugPrint('📥 [AuthService] Logout success: $data');
      } catch (e) {
        debugPrint(
            '⚠️ [AuthService] Logout API error (clearing local session): $e');
      }
    }
    await clearAllLocalData();
  }

  // ── Restore from secure storage ───────────────────────────────────────────
  Future<AuthSession?> restoreSession() async {
    if (AppConfig.useMockApi) {
      return null;
    }

    final String? accessToken =
        await _storage.read(key: _StorageKey.accessToken);
    final String? refreshToken =
        await _storage.read(key: _StorageKey.refreshToken);

    if ((accessToken == null || accessToken.isEmpty) &&
        (refreshToken == null || refreshToken.isEmpty)) {
      return null;
    }

    // 1. Try with existing accessToken
    if (accessToken != null && accessToken.isNotEmpty) {
      _client.authToken = accessToken;
      try {
        final dynamic data = await _client.get(ApiEndpoints.me);
        final User user = User.fromJson(data as Map<String, dynamic>);
        return AuthSession(
          user: user,
          accessToken: accessToken,
          refreshToken: refreshToken ?? '',
        );
      } catch (e) {
        debugPrint(
            '⚠️ [AuthService] /auth/me failed with stored accessToken: $e');
      }
    }

    // 2. AccessToken expired or invalid -> Attempt refresh with refreshToken
    if (refreshToken != null && refreshToken.isNotEmpty) {
      final String? newAccessToken = await this.refreshToken();
      if (newAccessToken != null && newAccessToken.isNotEmpty) {
        try {
          _client.authToken = newAccessToken;
          final dynamic data = await _client.get(ApiEndpoints.me);
          final User user = User.fromJson(data as Map<String, dynamic>);
          final String updatedRefresh =
              await _storage.read(key: _StorageKey.refreshToken) ??
                  refreshToken;
          return AuthSession(
            user: user,
            accessToken: newAccessToken,
            refreshToken: updatedRefresh,
          );
        } catch (e) {
          debugPrint(
              '❌ [AuthService] /auth/me failed even after token refresh: $e');
        }
      }
    }

    // 3. Both tokens expired / invalid -> Clear everything
    debugPrint(
        '⚠️ [AuthService] Unable to restore session. Clearing local storage.');
    await clearAllLocalData();
    return null;
  }

  // ── Token helpers ─────────────────────────────────────────────────────────

  Future<void> _persistTokens(AuthSession session) async {
    debugPrint('💾 [AuthService] Persisting tokens to SecureStorage:');
    debugPrint(
        '   accessToken: ${session.accessToken.isNotEmpty ? "EXISTS (${session.accessToken.length} chars)" : "EMPTY"}');
    debugPrint(
        '   refreshToken: ${session.refreshToken.isNotEmpty ? "EXISTS (${session.refreshToken.length} chars)" : "EMPTY"}');
    await Future.wait(<Future<void>>[
      if (session.accessToken.isNotEmpty)
        _storage.write(
            key: _StorageKey.accessToken, value: session.accessToken),
      if (session.refreshToken.isNotEmpty)
        _storage.write(
            key: _StorageKey.refreshToken, value: session.refreshToken),
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

class RegisterResponse {
  const RegisterResponse({
    required this.verificationRequired,
    required this.email,
    required this.message,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      verificationRequired: json['verificationRequired'] as bool? ?? true,
      email: json['email'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  final bool verificationRequired;
  final String email;
  final String message;
}

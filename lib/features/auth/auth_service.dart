import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/cache/cache_manager.dart';
import '../../core/config/api_endpoints.dart';
import '../../core/config/app_config.dart';
import 'user.dart';

enum RefreshTokenStatus {
  success,
  invalidToken, // 401 or 403 explicitly on /auth/refresh
  transientError, // Connection timeout, network error, 500, 502, 503, etc.
}

class RefreshTokenResult {
  const RefreshTokenResult({
    required this.status,
    this.accessToken,
    this.refreshToken,
    this.errorMessage,
  });

  final RefreshTokenStatus status;
  final String? accessToken;
  final String? refreshToken;
  final String? errorMessage;

  bool get isSuccess =>
      status == RefreshTokenStatus.success &&
      accessToken != null &&
      accessToken!.isNotEmpty;
  bool get isInvalidToken => status == RefreshTokenStatus.invalidToken;
  bool get isTransientError => status == RefreshTokenStatus.transientError;
}

/// Keys used in secure storage — centralised so we never typo them.
abstract final class _StorageKey {
  static const String accessToken = 'auth.accessToken';
  static const String refreshToken = 'auth.refreshToken';
  static const String userData = 'auth.userData';
}

class AuthService {
  AuthService(this._client, {FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final ApiClient _client;
  final FlutterSecureStorage _storage;

  String? _inMemoryAccessToken;
  String? _inMemoryRefreshToken;

  Future<String?> getAccessToken() async {
    if (_inMemoryAccessToken != null && _inMemoryAccessToken!.isNotEmpty) {
      return _inMemoryAccessToken;
    }
    return _storage.read(key: _StorageKey.accessToken);
  }

  Future<String?> getRefreshToken() async {
    if (_inMemoryRefreshToken != null && _inMemoryRefreshToken!.isNotEmpty) {
      return _inMemoryRefreshToken;
    }
    return _storage.read(key: _StorageKey.refreshToken);
  }

  // ── Social Sign-In: Google ────────────────────────────────────────────
  // Triggers Google Sign-In SDK, gets idToken, posts to /auth/google.
  // Returns AuthSession on success.

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>['email', 'profile'],
    clientId: defaultTargetPlatform == TargetPlatform.iOS
        ? '494655940899-k47o7aedu4ggbq1bdabeinl69vma8vok.apps.googleusercontent.com'
        : (kIsWeb
            ? (AppConfig.googleServerClientId.isNotEmpty
                ? AppConfig.googleServerClientId
                : '494655940899-l61kvs2gq29cp6it6onb5buto8qtlnht.apps.googleusercontent.com')
            : null),
    serverClientId: AppConfig.googleServerClientId.isNotEmpty
        ? AppConfig.googleServerClientId
        : '494655940899-l61kvs2gq29cp6it6onb5buto8qtlnht.apps.googleusercontent.com',
  );

  Future<void> googleSignOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  Future<SocialSignInResult> signInWithGoogle() async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock Google sign-in.');
      final AuthSession session = _mockSession('mockgoogle@gmail.com');
      await _persistTokens(session);
      return SocialSignInResult.success(session);
    }

    try {
      // Force fresh account picker every time
      try {
        await _googleSignIn.signOut();
      } catch (_) {}
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        debugPrint('⚠️ [AuthService] Google sign-in cancelled by user.');
        return SocialSignInResult.cancelled();
      }

      final String email = account.email.trim();
      final String? displayName = account.displayName;
      final String? photoUrl = account.photoUrl;
      final String googleId = account.id.isNotEmpty
          ? account.id
          : account.email.hashCode.abs().toString();

      debugPrint('🔑 [AuthService] Google account selected: $email (Name: $displayName)');

      // Generate strong deterministic password for this Google account
      final String googleAuthPassword = 'GoogleAuth_${googleId}_!Aa9';

      // 1. Check if email exists by attempting login first
      try {
        debugPrint('🚀 [AuthService] Attempting Login with Google credentials for: $email');
        final AuthSession session = await signIn(
          email: email,
          password: googleAuthPassword,
        );
        debugPrint('✅ [AuthService] Google login successful for: $email');
        // Existing user logged in — go straight to home.
        // Profile setup is only needed for brand-new registrations.
        return SocialSignInResult.success(session);
      } catch (loginError) {
        debugPrint('ℹ️ [AuthService] Google login attempt failed: $loginError');

        // Case 1: Email not verified yet
        if (loginError is ApiException && loginError.code == 'EMAIL_NOT_VERIFIED') {
          debugPrint('⚠️ [AuthService] Email not verified. Resending OTP for: $email');
          try {
            await resendEmailOtp(email);
          } catch (_) {}
          return SocialSignInResult.needsVerification(
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
            message: 'Please verify your email address. A verification code has been sent.',
          );
        }

        // Case 2: User does not exist (or wrong password) -> Call Register API!
        debugPrint('🚀 [AuthService] Email does not exist or login failed. Attempting Register for: $email');
        try {
          final RegisterResponse reg = await register(
            email: email,
            password: googleAuthPassword,
          );
          debugPrint('✅ [AuthService] Google registration initiated for: $email');
          return SocialSignInResult.needsVerification(
            email: email,
            displayName: displayName,
            photoUrl: photoUrl,
            message: reg.message,
          );
        } catch (regError) {
          debugPrint('❌ [AuthService] Google register failed: $regError');

          if (regError is ApiException) {
            if (regError.code == 'OTP_COOLDOWN') {
              return SocialSignInResult.needsVerification(
                email: email,
                displayName: displayName,
                photoUrl: photoUrl,
                message: regError.message,
              );
            }
            if (regError.statusCode == 409 ||
                regError.message.toLowerCase().contains('already exists')) {
              debugPrint(
                  '⚠️ [AuthService] Email $email exists with a password account. Redirecting to password login.');
              return SocialSignInResult.accountExistsWithPassword(
                email: email,
                displayName: displayName,
              );
            }
            return SocialSignInResult.error(regError.message);
          }
          return SocialSignInResult.error(regError.toString());
        }
      }
    } catch (e) {
      debugPrint('❌ [AuthService] Google sign-in general error: $e');
      return SocialSignInResult.error(e.toString());
    }
  }

  // ── Social Sign-In: Apple ────────────────────────────────────────────
  // Triggers Apple Sign-In (iOS only), gets identityToken + email,
  // posts to /auth/apple. Returns AuthSession on success.

  Future<SocialSignInResult> signInWithApple() async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock Apple sign-in.');
      final AuthSession session = _mockSession('mockapple@icloud.com');
      await _persistTokens(session);
      return SocialSignInResult.success(session);
    }

    try {
      final AuthorizationCredentialAppleID credential =
          await SignInWithApple.getAppleIDCredential(
        scopes: <AppleIDAuthorizationScopes>[
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final String? identityToken = credential.identityToken;
      if (identityToken == null || identityToken.isEmpty) {
        debugPrint('❌ [AuthService] Apple sign-in: identityToken is null.');
        return SocialSignInResult.error('Failed to get Apple identity token.');
      }

      // Apple only sends email on first sign-in; subsequent sign-ins may be null.
      final String? email = credential.email;
      final String? firstName = credential.givenName;
      final String? lastName = credential.familyName;

      debugPrint('🚀 [AuthService] Posting Apple identityToken to ${ApiEndpoints.appleSignIn}');
      final Map<String, dynamic> body = <String, dynamic>{
        'identityToken': identityToken,
      };
      if (email != null && email.isNotEmpty) body['email'] = email;
      if (firstName != null && firstName.isNotEmpty) body['firstName'] = firstName;
      if (lastName != null && lastName.isNotEmpty) body['lastName'] = lastName;

      final dynamic data = await _client.post(
        ApiEndpoints.appleSignIn,
        body: body,
      );
      debugPrint('📥 [AuthService] Apple sign-in response: $data');
      final AuthSession session =
          AuthSession.fromJson(data as Map<String, dynamic>);
      _client.authToken = session.accessToken;
      await _persistTokens(session);
      return SocialSignInResult.success(session);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        debugPrint('⚠️ [AuthService] Apple sign-in cancelled by user.');
        return SocialSignInResult.cancelled();
      }
      debugPrint('❌ [AuthService] Apple sign-in error: ${e.message}');
      return SocialSignInResult.error(e.message);
    } catch (e) {
      debugPrint('❌ [AuthService] Apple sign-in error: $e');
      return SocialSignInResult.error(e.toString());
    }
  }

  // ── Register ──────────────────────────────────────────────────────────────
  Future<RegisterResponse> register({
    required String email,
    required String password,
  }) async {
    _client.authToken = null;
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
    _client.authToken = null;
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
    _client.authToken = null;
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
    _client.authToken = null;
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
    if (data is Map<String, dynamic>) {
      final bool isPendingDeletion = data['accountPendingDeletion'] == true ||
          data['code'] == 'ACCOUNT_PENDING_DELETION' ||
          (data['data'] is Map &&
              (data['data']['accountPendingDeletion'] == true ||
                  data['data']['code'] == 'ACCOUNT_PENDING_DELETION'));

      if (isPendingDeletion) {
        debugPrint(
            '⚠️ [AuthService] Account is pending deletion. Intercepting login response.');
        throw ApiException(
          data['message']?.toString() ??
              'Your account is currently scheduled for deletion.',
          statusCode: 200,
          code: 'ACCOUNT_PENDING_DELETION',
          data: data,
        );
      }
    }
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
    final RefreshTokenResult result =
        await refreshTokenDetailed(explicitRefreshToken);
    return result.isSuccess ? result.accessToken : null;
  }

  Future<RefreshTokenResult> refreshTokenDetailed([
    String? explicitRefreshToken,
  ]) async {
    final String? candidate = (explicitRefreshToken != null &&
            explicitRefreshToken.trim().isNotEmpty)
        ? explicitRefreshToken.trim()
        : (_inMemoryRefreshToken != null &&
                _inMemoryRefreshToken!.trim().isNotEmpty)
            ? _inMemoryRefreshToken!.trim()
            : await _storage.read(key: _StorageKey.refreshToken);

    if (candidate == null || candidate.trim().isEmpty) {
      debugPrint('⚠️ [AuthService] No refresh token found in memory or storage.');
      return const RefreshTokenResult(
        status: RefreshTokenStatus.invalidToken,
        errorMessage: 'No refresh token available',
      );
    }

    final String cleanRefresh = candidate.trim();

    if (AppConfig.useMockApi) {
      const String mockAccess = 'mock-refreshed-access-token';
      await _storage.write(key: _StorageKey.accessToken, value: mockAccess);
      _client.authToken = mockAccess;
      _inMemoryAccessToken = mockAccess;
      return const RefreshTokenResult(
        status: RefreshTokenStatus.success,
        accessToken: mockAccess,
        refreshToken: 'mock-refresh-token',
      );
    }

    try {
      debugPrint(
          '🔄 [AuthService] Calling POST ${ApiEndpoints.refresh} to refresh token...');
      final Dio refreshDio = Dio(
        BaseOptions(
          baseUrl: _client.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          receiveTimeout: const Duration(seconds: 20),
          headers: <String, String>{
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      final Response<dynamic> response = await refreshDio.post<dynamic>(
        ApiEndpoints.refresh,
        data: <String, dynamic>{
          'refreshToken': cleanRefresh,
        },
      );

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
          final String? newAccessToken = (data['accessToken'] ??
                  data['token'] ??
                  data['access_token'] ??
                  data['jwt'] ??
                  (data['tokens'] is Map ? data['tokens']['accessToken'] : null))
              ?.toString();
          final String? newRefreshToken = (data['refreshToken'] ??
                  data['refresh_token'] ??
                  (data['tokens'] is Map ? data['tokens']['refreshToken'] : null))
              ?.toString();

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            _client.authToken = newAccessToken;
            _inMemoryAccessToken = newAccessToken;
            await _storage.write(
              key: _StorageKey.accessToken,
              value: newAccessToken,
            );

            final String effectiveRefresh =
                (newRefreshToken != null && newRefreshToken.isNotEmpty)
                    ? newRefreshToken
                    : cleanRefresh;
            _inMemoryRefreshToken = effectiveRefresh;

            if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
              await _storage.write(
                key: _StorageKey.refreshToken,
                value: newRefreshToken,
              );
            }

            // Check if user object was returned in refresh response
            final dynamic userPayload = data['user'] ??
                data['profile'] ??
                (response.data is Map ? (response.data as Map)['user'] : null);
            if (userPayload is Map<String, dynamic>) {
              try {
                final User user = User.fromJson(userPayload);
                await _storage.write(
                  key: _StorageKey.userData,
                  value: jsonEncode(user.toJson()),
                );
              } catch (_) {}
            }

            debugPrint(
                '🔑 [AuthService] Successfully refreshed and persisted new access token.');
            return RefreshTokenResult(
              status: RefreshTokenStatus.success,
              accessToken: newAccessToken,
              refreshToken: effectiveRefresh,
            );
          }
        }
      }

      return const RefreshTokenResult(
        status: RefreshTokenStatus.transientError,
        errorMessage: 'Invalid or non-200 refresh response payload',
      );
    } on DioException catch (dioErr) {
      final int? status = dioErr.response?.statusCode;
      debugPrint(
          '⚠️ [AuthService] Token refresh DioException [Status $status]: ${dioErr.response?.data}');
      if (status == 401 || status == 403) {
        return RefreshTokenResult(
          status: RefreshTokenStatus.invalidToken,
          errorMessage: 'Refresh token rejected by server ($status)',
        );
      }
      return RefreshTokenResult(
        status: RefreshTokenStatus.transientError,
        errorMessage:
            'Network or server error during token refresh: ${dioErr.message}',
      );
    } catch (e) {
      debugPrint('❌ [AuthService] Token refresh unexpected error: $e');
      return RefreshTokenResult(
        status: RefreshTokenStatus.transientError,
        errorMessage: 'Unexpected error during token refresh: $e',
      );
    }
  }

  // ── Clear All Local Data ──────────────────────────────────────────────────
  Future<void> clearAllLocalData() async {
    debugPrint(
        '🧹 [AuthService] Clearing authentication credentials and temporary cache...');
    _client.authToken = null;
    _inMemoryAccessToken = null;
    _inMemoryRefreshToken = null;
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('⚠️ [AuthService] Error clearing secure storage: $e');
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

  // ── Request Account Deletion ──────────────────────────────────────────────
  // POST /users/me/delete
  // Body: { password, reason, feedback? }
  // Returns: { message, restorationToken?, scheduledFor? }
  // After calling: session is invalidated server-side. Clear local data.

  Future<AccountDeletionResult> requestAccountDeletion({
    required String password,
    required String reason,
    String? feedback,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock requestAccountDeletion.');
      await clearAllLocalData();
      return AccountDeletionResult(
        message: 'Your account is scheduled for deletion.',
        restorationToken: 'mock-restoration-token',
      );
    }

    debugPrint('🚀 [AuthService] Requesting account deletion...');
    final Map<String, dynamic> body = <String, dynamic>{
      'password': password,
      'reason': reason,
    };
    if (feedback != null && feedback.trim().isNotEmpty) {
      body['feedback'] = feedback.trim();
    }

    final dynamic data = await _client.post(
      ApiEndpoints.requestAccountDeletion,
      body: body,
    );
    debugPrint('📥 [AuthService] Account Deletion Response: $data');

    final Map<String, dynamic> payload =
        (data is Map<String, dynamic>) ? data : <String, dynamic>{};
    final Map<String, dynamic> inner =
        (payload['data'] is Map<String, dynamic>)
            ? payload['data'] as Map<String, dynamic>
            : payload;

    await clearAllLocalData();

    return AccountDeletionResult(
      message: inner['message']?.toString() ??
          'Your account is scheduled for deletion.',
      restorationToken: inner['restorationToken']?.toString(),
      scheduledFor: inner['scheduledFor']?.toString(),
    );
  }

  // ── Cancel Account Deletion ────────────────────────────────────────────────
  // POST /auth/cancel-deletion
  // Body: { restorationToken }
  // Returns: { accessToken, refreshToken, user } — restores session.

  Future<AuthSession> cancelAccountDeletion({
    required String restorationToken,
  }) async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock cancelAccountDeletion.');
      return _mockSession('restored@example.com');
    }

    debugPrint('🚀 [AuthService] Cancelling account deletion...');
    _client.authToken = null;
    final dynamic data = await _client.post(
      ApiEndpoints.cancelDeletion,
      body: <String, dynamic>{'restorationToken': restorationToken},
    );
    debugPrint('📥 [AuthService] Cancel Deletion Response: $data');
    final AuthSession session =
        AuthSession.fromJson(data as Map<String, dynamic>);
    _client.authToken = session.accessToken;
    await _persistTokens(session);
    return session;
  }

  // ── Get Account Deletion Status ───────────────────────────────────────────
  // GET /users/me/deletion-status
  Future<Map<String, dynamic>> getDeletionStatus() async {
    if (AppConfig.useMockApi) {
      debugPrint('ℹ️ [AuthService] Mock getDeletionStatus.');
      return <String, dynamic>{'accountPendingDeletion': false};
    }

    debugPrint('🚀 [AuthService] Fetching account deletion status...');
    final dynamic data = await _client.get(ApiEndpoints.deletionStatus);
    debugPrint('📥 [AuthService] Deletion Status Response: $data');
    if (data is Map<String, dynamic>) {
      return data;
    }
    return <String, dynamic>{};
  }

  // ── Decode JWT Helper ────────────────────────────────────────────────────
  Map<String, dynamic>? _decodeJwtPayload(String token) {
    try {
      final List<String> parts = token.split('.');
      if (parts.length != 3) return null;
      final String normalized = base64Url.normalize(parts[1]);
      final String decoded = utf8.decode(base64Url.decode(normalized));
      final dynamic json = jsonDecode(decoded);
      return json is Map<String, dynamic> ? json : null;
    } catch (_) {
      return null;
    }
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
    final String? rawUserData =
        await _storage.read(key: _StorageKey.userData);

    // If both tokens are absent, user has never logged in or explicitly signed out
    if ((accessToken == null || accessToken.trim().isEmpty) &&
        (refreshToken == null || refreshToken.trim().isEmpty)) {
      return null;
    }

    _inMemoryAccessToken = accessToken;
    _inMemoryRefreshToken = refreshToken;

    User? cachedUser;
    if (rawUserData != null && rawUserData.trim().isNotEmpty) {
      try {
        final dynamic decoded = jsonDecode(rawUserData);
        if (decoded is Map<String, dynamic>) {
          cachedUser = User.fromJson(decoded);
        }
      } catch (e) {
        debugPrint('⚠️ [AuthService] Failed to parse cached userData: $e');
      }
    }

    if (cachedUser == null || cachedUser.id.isEmpty) {
      final String? jwtSource = (accessToken != null && accessToken.isNotEmpty)
          ? accessToken
          : refreshToken;
      if (jwtSource != null) {
        final Map<String, dynamic>? jwtPayload = _decodeJwtPayload(jwtSource);
        if (jwtPayload != null) {
          cachedUser = User.fromJson(jwtPayload);
        }
      }
    }

    // 1. If refresh token is available, always generate a fresh access token on restart
    // as requested: "jb dare bar app reastart krain tu refersh tocken se new access token generate krwa lya kro"
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      debugPrint('🔄 [AuthService] Startup session restore: refreshing access token via refresh token...');
      final RefreshTokenResult refreshResult =
          await refreshTokenDetailed(refreshToken.trim());

      if (refreshResult.isSuccess &&
          refreshResult.accessToken != null &&
          refreshResult.accessToken!.isNotEmpty) {
        final String newAccessToken = refreshResult.accessToken!;
        final String effectiveRefresh =
            (refreshResult.refreshToken != null &&
                    refreshResult.refreshToken!.isNotEmpty)
                ? refreshResult.refreshToken!
                : refreshToken;

        _client.authToken = newAccessToken;
        _inMemoryAccessToken = newAccessToken;
        _inMemoryRefreshToken = effectiveRefresh;

        User effectiveUser = cachedUser ??
            User(
              id: 'user_${DateTime.now().millisecondsSinceEpoch}',
              email: '',
              role: 'user',
              accountStatus: AccountStatus.active,
              dobVerified: false,
            );

        // Try getting latest user info from /auth/me, but NEVER invalidate the session if it fails
        try {
          final dynamic data = await _client.get(ApiEndpoints.me);
          if (data is Map<String, dynamic>) {
            effectiveUser = User.fromJson(data);
            await _storage.write(
              key: _StorageKey.userData,
              value: jsonEncode(effectiveUser.toJson()),
            );
          }
        } catch (meError) {
          debugPrint(
              '⚠️ [AuthService] /auth/me after token refresh failed: $meError. Retaining cached user profile.');
        }

        final AuthSession session = AuthSession(
          user: effectiveUser,
          accessToken: newAccessToken,
          refreshToken: effectiveRefresh,
        );
        await _persistTokens(session);
        return session;
      }

      // ONLY evict session if the refresh token is permanently invalid/rejected (401/403)
      if (refreshResult.isInvalidToken) {
        debugPrint(
            '⛔ [AuthService] Refresh token is permanently invalid (${refreshResult.errorMessage}). Clearing local session.');
        await clearAllLocalData();
        return null;
      }

      // If refresh hit a transient error (offline, 5xx, timeout):
      debugPrint(
          '⚠️ [AuthService] Transient network/server error refreshing token (${refreshResult.errorMessage}). Preserving session.');
    }

    // 2. Fallback to existing accessToken if refresh was skipped or hit a transient error
    if (accessToken != null && accessToken.isNotEmpty) {
      _client.authToken = accessToken;
      try {
        final dynamic data = await _client.get(ApiEndpoints.me);
        if (data is Map<String, dynamic>) {
          final User user = User.fromJson(data);
          final AuthSession session = AuthSession(
            user: user,
            accessToken: accessToken,
            refreshToken: refreshToken ?? '',
          );
          await _persistTokens(session);
          return session;
        }
      } catch (meError) {
        debugPrint(
            '⚠️ [AuthService] /auth/me with existing access token: $meError');
      }

      if (cachedUser != null) {
        debugPrint('✅ [AuthService] Restoring session with cached user profile.');
        return AuthSession(
          user: cachedUser,
          accessToken: accessToken,
          refreshToken: refreshToken ?? '',
        );
      }
    }

    // 3. If offline/transient error and we have cachedUser and refreshToken, keep user signed in!
    if (cachedUser != null && refreshToken != null && refreshToken.isNotEmpty) {
      debugPrint('✅ [AuthService] Preserving user session offline with cached credentials.');
      return AuthSession(
        user: cachedUser,
        accessToken: accessToken ?? '',
        refreshToken: refreshToken,
      );
    }

    // No valid credentials exist
    debugPrint('⚠️ [AuthService] Unable to restore session. No valid credentials.');
    await clearAllLocalData();
    return null;
  }

  // ── Token helpers ─────────────────────────────────────────────────────────

  Future<void> _persistTokens(AuthSession session) async {
    debugPrint('💾 [AuthService] Persisting tokens and user data to SecureStorage:');
    debugPrint(
        '   accessToken: ${session.accessToken.isNotEmpty ? "EXISTS (${session.accessToken.length} chars)" : "EMPTY"}');
    debugPrint(
        '   refreshToken: ${session.refreshToken.isNotEmpty ? "EXISTS (${session.refreshToken.length} chars)" : "EMPTY"}');
    _inMemoryAccessToken = session.accessToken;
    _inMemoryRefreshToken = session.refreshToken;
    final String userJson = jsonEncode(session.user.toJson());
    await Future.wait(<Future<void>>[
      if (session.accessToken.isNotEmpty)
        _storage.write(
            key: _StorageKey.accessToken, value: session.accessToken),
      if (session.refreshToken.isNotEmpty)
        _storage.write(
            key: _StorageKey.refreshToken, value: session.refreshToken),
      _storage.write(key: _StorageKey.userData, value: userJson),
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

// ── Social Sign-In Result ─────────────────────────────────────────────────────

enum SocialSignInStatus {
  success,
  needsProfileSetup,
  needsVerification,
  cancelled,
  error,
  /// Email is registered with a password — user must log in via email/password.
  accountExistsWithPassword,
}

class SocialSignInResult {
  const SocialSignInResult._({
    required this.status,
    this.session,
    this.email,
    this.displayName,
    this.photoUrl,
    this.errorMessage,
  });

  factory SocialSignInResult.success(AuthSession session) =>
      SocialSignInResult._(
        status: SocialSignInStatus.success,
        session: session,
      );

  factory SocialSignInResult.needsProfileSetup(
    AuthSession session, {
    String? displayName,
    String? photoUrl,
  }) =>
      SocialSignInResult._(
        status: SocialSignInStatus.needsProfileSetup,
        session: session,
        displayName: displayName,
        photoUrl: photoUrl,
      );

  factory SocialSignInResult.needsVerification({
    required String email,
    String? displayName,
    String? photoUrl,
    String? message,
  }) =>
      SocialSignInResult._(
        status: SocialSignInStatus.needsVerification,
        email: email,
        displayName: displayName,
        photoUrl: photoUrl,
        errorMessage: message,
      );

  factory SocialSignInResult.cancelled() => const SocialSignInResult._(
        status: SocialSignInStatus.cancelled,
      );

  factory SocialSignInResult.error(String message) => SocialSignInResult._(
        status: SocialSignInStatus.error,
        errorMessage: message,
      );

  /// Use when the email is already registered with email/password (HTTP 409 during
  /// Google sign-in). The UI should redirect to the login screen with [email] prefilled.
  factory SocialSignInResult.accountExistsWithPassword({
    required String email,
    String? displayName,
  }) =>
      SocialSignInResult._(
        status: SocialSignInStatus.accountExistsWithPassword,
        email: email,
        displayName: displayName,
        errorMessage:
            'This email is already registered with a password. Please log in with your email and password.',
      );

  final SocialSignInStatus status;
  final AuthSession? session;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String? errorMessage;

  bool get isSuccess => status == SocialSignInStatus.success && session != null;
  bool get needsProfileSetup => status == SocialSignInStatus.needsProfileSetup;
  bool get needsVerification => status == SocialSignInStatus.needsVerification;
  bool get isCancelled => status == SocialSignInStatus.cancelled;
  bool get isError => status == SocialSignInStatus.error;
  bool get accountExistsWithPassword =>
      status == SocialSignInStatus.accountExistsWithPassword;
}

// ── Account Deletion Result ───────────────────────────────────────────────────

class AccountDeletionResult {
  const AccountDeletionResult({
    required this.message,
    this.restorationToken,
    this.scheduledFor,
  });

  final String message;

  /// Token used to cancel deletion within the grace period.
  final String? restorationToken;

  /// ISO-8601 date string indicating when the account will be permanently deleted.
  final String? scheduledFor;
}

// Owns the user session state.
// Uses selective notifyListeners() so only relevant widgets rebuild.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/cache/user_relationship_cache.dart';
import '../../core/services/push_notification_service.dart';
import '../home/services/reel_video_preloader.dart';
import 'auth_service.dart';
import 'user.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required ApiClient client, AuthService? service})
      : _client = client,
        _service = service ?? AuthService(client) {
    _client.onUnauthorized = _handleUnauthorized;
    _client.onTokenRefresh = _handleTokenRefresh;
  }

  final ApiClient _client;
  final AuthService _service;

  Future<String?> _handleTokenRefresh() async {
    final String? candidate =
        (_refreshToken != null && _refreshToken!.trim().isNotEmpty)
            ? _refreshToken
            : await _service.getRefreshToken();
    final RefreshTokenResult result =
        await _service.refreshTokenDetailed(candidate);

    if (result.isSuccess) {
      if (result.refreshToken != null && result.refreshToken!.isNotEmpty) {
        _refreshToken = result.refreshToken;
      }
      notifyListeners();
      return result.accessToken;
    }

    if (result.isInvalidToken) {
      debugPrint(
          '⛔ [AuthProvider] Refresh token is permanently invalid/expired (${result.errorMessage}). Evicting session.');
      final String? token = _client.authToken;
      if (token != null && token.isNotEmpty) {
        PushNotificationService.unregisterDeviceToken(_client, authToken: token).ignore();
      }
      _clearSession();
    } else {
      debugPrint(
          '⚠️ [AuthProvider] Transient error refreshing token (${result.errorMessage}). Retaining user session.');
    }
    return null;
  }

  void _handleUnauthorized() {
    final String? token = _client.authToken;
    if (token != null && token.isNotEmpty) {
      PushNotificationService.unregisterDeviceToken(_client, authToken: token).ignore();
    }
    _clearSession();
  }

  // ── Private state ─────────────────────────────────────────────────────────

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _refreshToken;
  String? _error;
  String? _errorCode;
  dynamic _errorData;
  int? _retryAfterSeconds;
  bool _isBusy = false;

  // ── Public getters ────────────────────────────────────────────────────────

  AuthStatus get status => _status;
  User? get user => _user;
  String? get userId => _user?.id;
  String? get username => _user?.displayName;
  String? get error => _error;
  String? get errorCode => _errorCode;
  dynamic get errorData => _errorData;
  String? get pendingDeletionRestorationToken => _pendingDeletionRestorationToken;
  String? get deletionScheduledAt => _deletionScheduledAt;
  int? get retryAfterSeconds => _retryAfterSeconds;
  bool get isBusy => _isBusy;
  bool get isSignedIn => _status == AuthStatus.signedIn;
  bool get isGuest => _status != AuthStatus.signedIn;

  // ── Session restore ───────────────────────────────────────────────────────
  // Called once from main — reads stored tokens and validates them with the API.

  Future<void> restoreSession() async {
    if (_status != AuthStatus.unknown) {
      return;
    }

    try {
      final AuthSession? session = await _service.restoreSession();
      if (session != null) {
        _applySession(session);
        return;
      }
    } on ApiException catch (e) {
      debugPrint('⚠️ [AuthProvider] ApiException during restoreSession: $e');
    } catch (e) {
      debugPrint('⚠️ [AuthProvider] Unexpected error during restoreSession: $e');
    }

    // Do NOT call _clearSession() here. Calling _clearSession() unconditionally wipes
    // all tokens and user data from storage on temporary network or startup hiccups.
    // _service.restoreSession() only clears storage when tokens are permanently invalid.
    _status = AuthStatus.signedOut;
    _user = null;
    _refreshToken = null;
    notifyListeners();
  }

  // ── Register ──────────────────────────────────────────────────────────────

  Future<bool> signUp({
    required String email,
    required String password,
  }) async {
    if (_isBusy) {
      return false;
    }
    if (!isValidEmail(email) || password.isEmpty) {
      _error = 'Enter a valid email and password.';
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return false;
    }

    _setBusy(true);

    try {
      await _service.register(
        email: email.trim(),
        password: password,
      );
      _error = null;
      _errorCode = null;
      _retryAfterSeconds = null;
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      _errorCode = failure.code;
      _retryAfterSeconds = failure.retryAfterSeconds;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Unable to complete sign up. Please try again.';
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Verify Email OTP ──────────────────────────────────────────────────────

  Future<bool> verifyEmailOtp({
    required String email,
    required String otp,
    bool staySignedIn = false,
  }) async {
    if (_isBusy) return false;
    if (otp.trim().length < 6) {
      _error = 'Please enter a 6-digit verification code.';
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return false;
    }

    _setBusy(true);
    try {
      final AuthSession session = await _service.verifyEmail(
        email: email.trim(),
        otp: otp.trim(),
        staySignedIn: staySignedIn,
      );
      _applySession(session);
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      _errorCode = failure.code;
      _retryAfterSeconds = failure.retryAfterSeconds;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Invalid or expired verification code. Please try again.';
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Resend Email OTP ──────────────────────────────────────────────────────

  Future<bool> resendEmailOtp(String email) async {
    if (_isBusy) return false;
    if (!isValidEmail(email)) {
      _error = 'Enter a valid email address.';
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return false;
    }

    _setBusy(true);
    try {
      await _service.resendEmailOtp(email.trim());
      _error = null;
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      _errorCode = failure.code;
      _retryAfterSeconds = failure.retryAfterSeconds;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to resend code. Please try again.';
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Sign in ───────────────────────────────────────────────────────────────

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (_isBusy) {
      return false;
    }
    if (!isValidEmail(email) || password.isEmpty) {
      _error = 'Enter a valid email and password.';
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return false;
    }

    _setBusy(true);

    try {
      final AuthSession session = await _service.signIn(
        email: email.trim(),
        password: password,
      );
      _error = null;
      _errorCode = null;
      _errorData = null;
      _pendingDeletionRestorationToken = null;
      _deletionScheduledAt = null;
      _applySession(session);
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      _errorCode = failure.code;
      _errorData = failure.data;
      _retryAfterSeconds = failure.retryAfterSeconds;
      if (failure.code == 'ACCOUNT_PENDING_DELETION') {
        if (failure.data is Map) {
          final Map map = failure.data as Map;
          final dynamic inner = (map['data'] is Map) ? map['data'] : map;
          final dynamic token = inner['restorationToken'];
          if (token != null) {
            _pendingDeletionRestorationToken = token.toString();
          }
          final dynamic scheduledAt =
              inner['deletionScheduledAt'] ?? inner['scheduledFor'];
          if (scheduledAt != null) {
            _deletionScheduledAt = scheduledAt.toString();
          }
        }
      }
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Unable to log in. Please check your credentials and try again.';
      _errorCode = null;
      _errorData = null;
      _pendingDeletionRestorationToken = null;
      _deletionScheduledAt = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Social Sign-In: Google ────────────────────────────────────────────

  Future<SocialSignInResult> signInWithGoogle() async {
    if (_isBusy) return SocialSignInResult.cancelled();
    _setBusy(true);
    try {
      final SocialSignInResult result = await _service.signInWithGoogle();
      if (result.isCancelled) {
        return result;
      }
      if (result.isError) {
        _error = result.errorMessage ?? 'Google sign-in failed. Please try again.';
        _errorCode = null;
        _retryAfterSeconds = null;
        notifyListeners();
        return result;
      }
      if (result.session != null) {
        _applySession(result.session!);
      }
      return result;
    } on ApiException catch (failure) {
      _error = failure.message;
      _errorCode = failure.code;
      _retryAfterSeconds = failure.retryAfterSeconds;
      notifyListeners();
      return SocialSignInResult.error(failure.message);
    } catch (e) {
      _error = 'Google sign-in failed. Please try again.';
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return SocialSignInResult.error(e.toString());
    } finally {
      _setBusy(false);
    }
  }

  // ── Social Sign-In: Apple ────────────────────────────────────────────

  Future<bool> signInWithApple() async {
    if (_isBusy) return false;
    _setBusy(true);
    try {
      final SocialSignInResult result = await _service.signInWithApple();
      if (result.isCancelled) {
        return false;
      }
      if (result.isError) {
        _error = result.errorMessage ?? 'Apple sign-in failed. Please try again.';
        _errorCode = null;
        _retryAfterSeconds = null;
        notifyListeners();
        return false;
      }
      _applySession(result.session!);
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      _errorCode = failure.code;
      _retryAfterSeconds = failure.retryAfterSeconds;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Apple sign-in failed. Please try again.';
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Password Reset ────────────────────────────────────────────────────────

  Future<bool> requestPasswordReset(String email) async {
    if (_isBusy) return false;
    if (!isValidEmail(email)) {
      _error = 'Enter a valid email address.';
      notifyListeners();
      return false;
    }

    _setBusy(true);
    try {
      await _service.requestPasswordReset(email.trim());
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to request password reset. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    if (_isBusy) return null;
    if (otp.trim().isEmpty) {
      _error = 'Enter the verification code.';
      notifyListeners();
      return null;
    }

    _setBusy(true);
    try {
      final String resetTicket = await _service.verifyPasswordResetOtp(
        email: email.trim(),
        otp: otp.trim(),
      );
      _error = null;
      notifyListeners();
      return resetTicket;
    } on ApiException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Invalid or expired code. Please try again.';
      notifyListeners();
      return null;
    } finally {
      _setBusy(false);
    }
  }

  Future<bool> confirmPasswordReset({
    required String resetTicket,
    required String newPassword,
  }) async {
    if (_isBusy) return false;
    if (newPassword.isEmpty || newPassword.length < 6) {
      _error = 'Password must be at least 6 characters.';
      notifyListeners();
      return false;
    }

    _setBusy(true);
    try {
      await _service.confirmPasswordReset(
        resetTicket: resetTicket,
        newPassword: newPassword,
      );
      _error = null;
      notifyListeners();
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to reset password. Please try again.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    ReelVideoPreloader.instance.setFeedVisible(false);
    ReelVideoPreloader.instance.pauseAll();
    ReelVideoPreloader.instance.muteAll();
    ReelVideoPreloader.instance.disposeAll();
    final String? currentToken = _client.authToken;
    try {
      // 1. Unregister push notification device token on backend while authenticated
      if (currentToken != null && currentToken.isNotEmpty) {
        await PushNotificationService.unregisterDeviceToken(_client, authToken: currentToken);
      }
      // 2. Invalidate refresh token on backend
      await _service.signOut(refreshToken: _refreshToken);
      // 3. Clear Google SDK session so next sign-in prompts fresh
      await _service.googleSignOut();
    } on ApiException catch (_) {
      // Best-effort logout — clear local state regardless.
    } catch (_) {
    } finally {
      _clearSession();
    }
  }

  // ── Account Deletion ──────────────────────────────────────────────────────

  /// restorationToken saved here when login returns ACCOUNT_PENDING_DELETION
  String? _pendingDeletionRestorationToken;
  String? _deletionScheduledAt;

  void setPendingDeletionToken(String token, {String? scheduledAt}) {
    _pendingDeletionRestorationToken = token;
    _deletionScheduledAt = scheduledAt;
  }

  void clearPendingDeletionToken() {
    _pendingDeletionRestorationToken = null;
    _deletionScheduledAt = null;
  }

  /// Get account deletion status: GET /users/me/deletion-status
  Future<Map<String, dynamic>> getDeletionStatus() async {
    try {
      return await _service.getDeletionStatus();
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Request account deletion. Clears session on success.
  Future<AccountDeletionResult?> requestAccountDeletion({
    required String password,
    required String reason,
    String? feedback,
  }) async {
    if (_isBusy) return null;
    _setBusy(true);
    try {
      final AccountDeletionResult result = await _service.requestAccountDeletion(
        password: password,
        reason: reason,
        feedback: feedback,
      );
      _clearSession();
      return result;
    } on ApiException catch (failure) {
      _error = failure.message;
      _errorCode = failure.code;
      _retryAfterSeconds = failure.retryAfterSeconds;
      notifyListeners();
      return null;
    } catch (e) {
      _error = 'Failed to request account deletion. Please try again.';
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return null;
    } finally {
      _setBusy(false);
    }
  }

  /// Cancel account deletion using the restorationToken.
  /// On success: restores the session and logs the user back in.
  Future<bool> cancelAccountDeletion({required String restorationToken}) async {
    if (_isBusy) return false;
    _setBusy(true);
    try {
      final AuthSession session = await _service.cancelAccountDeletion(
        restorationToken: restorationToken,
      );
      _pendingDeletionRestorationToken = null;
      _applySession(session);
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      _errorCode = failure.code;
      _retryAfterSeconds = failure.retryAfterSeconds;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to cancel deletion. The link may have expired.';
      _errorCode = null;
      _retryAfterSeconds = null;
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Error management ──────────────────────────────────────────────────────

  void clearError() {
    if (_error == null && _errorCode == null && _errorData == null) {
      return;
    }
    _error = null;
    _errorCode = null;
    _errorData = null;
    _retryAfterSeconds = null;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Apply a new session and notify listeners exactly once.
  void _applySession(AuthSession session) {
    _client.authToken = session.accessToken;
    _user = session.user;
    _refreshToken = session.refreshToken;
    _status = AuthStatus.signedIn;
    _error = null;
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      prefs.setBool('onboarding_seen', true);
    }).catchError((_) {});
    PushNotificationService.syncDeviceToken(_client).ignore();
    notifyListeners();
  }

  /// Clear all session state and notify listeners once.
  void _clearSession() {
    final String? currentToken = _client.authToken;
    if (currentToken != null && currentToken.isNotEmpty) {
      PushNotificationService.unregisterDeviceToken(_client, authToken: currentToken).ignore();
    }
    _client.authToken = null;
    _user = null;
    _refreshToken = null;
    _status = AuthStatus.signedOut;
    _error = null;
    _service.clearAllLocalData();
    // Silence and clear video + shared-post caches so next user starts fresh
    ReelVideoPreloader.instance.setFeedVisible(false);
    ReelVideoPreloader.instance.pauseAll();
    ReelVideoPreloader.instance.muteAll();
    ReelVideoPreloader.instance.disposeAll();
    ReelVideoPreloader.instance.clearAllCaches().ignore();
    UserRelationshipCache.clear();
    notifyListeners();
  }

  /// Toggle the busy flag without touching anything else — avoids redundant rebuilds.
  void _setBusy(bool value) {
    if (_isBusy == value) {
      return;
    }
    _isBusy = value;
    notifyListeners();
  }

  // ── Validation ────────────────────────────────────────────────────────────

  static bool isValidEmail(String email) {
    final String value = email.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}

import 'package:flutter/foundation.dart';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../admin_auth_service.dart';
import '../admin_user.dart';
export '../admin_user.dart' show AdminRole;

enum AdminAuthStatus { unknown, signedOut, signedIn }

class AdminAuthProvider extends ChangeNotifier {
  AdminAuthProvider({required ApiClient client, AdminAuthService? service})
      : _client = client,
        _service = service ?? AdminAuthService(client) {
    _client.onUnauthorized = _clearSession;
    _client.onTokenRefresh = _refreshAccessToken;
  }

  final ApiClient _client;
  final AdminAuthService _service;

  AdminAuthStatus _status = AdminAuthStatus.unknown;
  AdminUser? _user;
  String? _refreshToken;
  String? _error;
  bool _isBusy = false;

  AdminAuthStatus get status => _status;
  AdminUser? get user => _user;
  AdminRole get role => _user?.role ?? AdminRole.moderator;
  String? get email => _user?.email;
  String? get error => _error;
  bool get isBusy => _isBusy;
  bool get isSignedIn => _status == AdminAuthStatus.signedIn;

  Future<void> restoreSession() async {
    if (_status != AdminAuthStatus.unknown) {
      return;
    }

    try {
      final AdminSession? session = await _service.restoreSession();
      if (session != null) {
        _applySession(session);
        return;
      }
    } on ApiException catch (_) {
      
    } on AdminAccessDeniedException catch (_) {
    
    }

    _status = AdminAuthStatus.signedOut;
    notifyListeners();
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
      notifyListeners();
      return false;
    }

    _setBusy(true);

    try {
      final AdminSession session = await _service.signIn(
        email: email.trim(),
        password: password,
      );
      _applySession(session);
      return true;
    } on AdminAccessDeniedException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return false;
    } on ApiException catch (failure) {
      _error = failure.message;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Unable to sign in. Please check your credentials and try again.';
      notifyListeners();
      return false;
    } finally {
      _setBusy(false);
    }
  }

  // ── Sign out ──────────────────────────────────────────────────────────────

  /// Hits POST /auth/logout, then clears the session — which flips [status] to
  /// [AdminAuthStatus.signedOut] so the router shows the login screen.
  Future<void> signOut() async {
    await _service.signOut(refreshToken: _refreshToken);
    _clearSession();
  }

  // ── Error management ──────────────────────────────────────────────────────

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Apply a new session and notify listeners exactly once.
  void _applySession(AdminSession session) {
    _client.authToken = session.accessToken;
    _user = session.user;
    _refreshToken = session.refreshToken;
    _status = AdminAuthStatus.signedIn;
    _error = null;
    notifyListeners();
  }

  /// Wired to [ApiClient.onTokenRefresh]. On a 401 the client calls this once,
  /// retries the request with the returned token, and never signs the admin out
  /// as long as the refresh token is still valid. Returns null (and signs out
  /// here) when the refresh token is expired / revoked.
  Future<String?> _refreshAccessToken() async {
    final ({String accessToken, String refreshToken})? tokens =
        await _service.refreshSession();
    if (tokens == null) {
      _clearSession();
      return null;
    }
    _client.authToken = tokens.accessToken;
    _refreshToken = tokens.refreshToken;
    return tokens.accessToken;
  }

  /// Clear all session state and notify listeners once.
  void _clearSession() {
    _client.authToken = null;
    _user = null;
    _refreshToken = null;
    _status = AdminAuthStatus.signedOut;
    _error = null;
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

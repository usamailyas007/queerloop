// Owns the user session state.
// Uses selective notifyListeners() so only relevant widgets rebuild.

import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import 'auth_service.dart';
import 'user.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthProvider extends ChangeNotifier {
  AuthProvider({required ApiClient client, AuthService? service})
      : _client = client,
        _service = service ?? AuthService(client) {
    _client.onUnauthorized = _clearSession;
  }

  final ApiClient _client;
  final AuthService _service;

  // ── Private state ─────────────────────────────────────────────────────────

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _refreshToken;
  String? _error;
  String? _errorCode;
  int? _retryAfterSeconds;
  bool _isBusy = false;

  // ── Public getters ────────────────────────────────────────────────────────

  AuthStatus get status => _status;
  User? get user => _user;
  String? get userId => _user?.id;
  String? get error => _error;
  String? get errorCode => _errorCode;
  int? get retryAfterSeconds => _retryAfterSeconds;
  bool get isBusy => _isBusy;
  bool get isSignedIn => _status == AuthStatus.signedIn;

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
    } on ApiException catch (_) {
      // Stored token expired or network unavailable — fall through to signedOut.
    }

    _status = AuthStatus.signedOut;
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
      _applySession(session);
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      _errorCode = failure.code;
      _retryAfterSeconds = failure.retryAfterSeconds;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Unable to log in. Please check your credentials and try again.';
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
    try {
      await _service.signOut(refreshToken: _refreshToken);
    } on ApiException catch (_) {
      // Best-effort logout — clear local state regardless.
    } finally {
      _clearSession();
    }
  }

  // ── Error management ──────────────────────────────────────────────────────

  void clearError() {
    if (_error == null && _errorCode == null) {
      return;
    }
    _error = null;
    _errorCode = null;
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
    notifyListeners();
  }

  /// Clear all session state and notify listeners once.
  void _clearSession() {
    _client.authToken = null;
    _user = null;
    _refreshToken = null;
    _status = AuthStatus.signedOut;
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

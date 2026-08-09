// Owns the user session state.

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

  AuthStatus _status = AuthStatus.unknown;
  User? _user;
  String? _error;
  bool _isBusy = false;

  AuthStatus get status => _status;
  User? get user => _user;
  String? get userId => _user?.id;
  String? get error => _error;
  bool get isBusy => _isBusy;
  bool get isSignedIn => _status == AuthStatus.signedIn;

  Future<void> restoreSession() async {
    if (_status != AuthStatus.unknown) {
      return;
    }
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    if (_isBusy) {
      return false;
    }

    if (!isValidEmail(email) || password.isEmpty) {
      _error = 'Enter a valid email and password';
      notifyListeners();
      return false;
    }

    _isBusy = true;
    _error = null;
    notifyListeners();

    try {
      final AuthSession session = await _service.signIn(
        email: email.trim(),
        password: password,
      );
      _client.authToken = session.token;
      _user = session.user;
      _status = AuthStatus.signedIn;
      return true;
    } on ApiException catch (failure) {
      _error = failure.message;
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _service.signOut();
    } on ApiException catch (_) {
    } finally {
      _clearSession();
    }
  }

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  void _clearSession() {
    _client.authToken = null;
    _user = null;
    _error = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  static bool isValidEmail(String email) {
    final String value = email.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}

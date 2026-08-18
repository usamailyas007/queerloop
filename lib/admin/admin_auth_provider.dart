// Owns the admin session state, separate from the user app's AuthProvider.

import 'package:flutter/foundation.dart';

enum AdminAuthStatus { unknown, signedOut, signedIn }

enum AdminRole { moderator, admin }

class AdminAuthProvider extends ChangeNotifier {
  AdminAuthStatus _status = AdminAuthStatus.unknown;
  AdminRole _role = AdminRole.moderator;
  String? _email;
  String? _error;

  AdminAuthStatus get status => _status;
  AdminRole get role => _role;
  String? get email => _email;
  String? get error => _error;
  bool get isSignedIn => _status == AdminAuthStatus.signedIn;

  void restoreSession() {
    if (_status != AdminAuthStatus.unknown) {
      return;
    }
    _status = AdminAuthStatus.signedOut;
    notifyListeners();
  }

  bool signIn({required String email, required String password}) {
    if (!isValidEmail(email) || password.isEmpty) {
      _error = 'Enter a valid email and password';
      notifyListeners();
      return false;
    }

    _error = null;
    _email = email.trim().toLowerCase();
    _role = _email!.contains('admin') ? AdminRole.admin : AdminRole.moderator;
    _status = AdminAuthStatus.signedIn;
    notifyListeners();
    return true;
  }

  void signOut() {
    _email = null;
    _error = null;
    _role = AdminRole.moderator;
    _status = AdminAuthStatus.signedOut;
    notifyListeners();
  }

  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  static bool isValidEmail(String email) {
    final String value = email.trim();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  }
}

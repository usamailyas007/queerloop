// Where the admin console keeps its access / refresh tokens.
//
// flutter_secure_storage is unreliable on Flutter web (its WebCrypto backend
// throws `OperationError` when the AES key and ciphertext drift apart, e.g.
// after a hot restart mid-write). The admin console runs on web, so we use
// SharedPreferences there and keep the secure enclave on mobile / desktop.

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class AdminSessionStore {
  factory AdminSessionStore() =>
      kIsWeb ? _PrefsSessionStore() : _SecureSessionStore();

  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
}

class _SecureSessionStore implements AdminSessionStore {
  const _SecureSessionStore();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);
}

class _PrefsSessionStore implements AdminSessionStore {
  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  @override
  Future<String?> read({required String key}) async =>
      (await _prefs).getString(key);

  @override
  Future<void> write({required String key, required String value}) async =>
      (await _prefs).setString(key, value);

  @override
  Future<void> delete({required String key}) async =>
      (await _prefs).remove(key);
}

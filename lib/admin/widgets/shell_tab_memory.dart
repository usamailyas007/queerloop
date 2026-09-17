// Remembers which sidebar tab a shell (AdminShell / ModeratorShell) was on,
// so a browser refresh reopens the same tab instead of always landing back on
// Dashboard. Backed by the same cross-platform key/value store used for the
// session tokens (SharedPreferences on web).

import '../auth/admin_session_store.dart';

class ShellTabMemory {
  ShellTabMemory(this._storageKey) : _store = AdminSessionStore();

  final String _storageKey;
  final AdminSessionStore _store;

  /// Returns the remembered tab index, clamped to `[0, tabCount)`, or null if
  /// nothing was stored yet (or it's out of range for the current tab count).
  Future<int?> load(int tabCount) async {
    final String? raw = await _store.read(key: _storageKey);
    final int? index = raw == null ? null : int.tryParse(raw);
    if (index == null || index < 0 || index >= tabCount) {
      return null;
    }
    return index;
  }

  Future<void> save(int index) => _store.write(
        key: _storageKey,
        value: '$index',
      );
}

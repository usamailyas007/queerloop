import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_mode';

  ThemeProvider({ThemeMode initialMode = ThemeMode.light})
      : _themeMode = initialMode {
    _loadFromPrefs();
  }

  ThemeMode _themeMode;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  Future<void> _loadFromPrefs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? saved = prefs.getString(_prefKey);
      if (saved != null) {
        final ThemeMode loadedMode = switch (saved) {
          'dark' => ThemeMode.dark,
          'light' => ThemeMode.light,
          'system' => ThemeMode.system,
          _ => ThemeMode.light,
        };
        if (_themeMode != loadedMode) {
          _themeMode = loadedMode;
          notifyListeners();
        }
      }
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    _themeMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKey,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      notifyListeners();
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _prefKey,
          mode == ThemeMode.dark
              ? 'dark'
              : (mode == ThemeMode.light ? 'light' : 'system'),
        );
      } catch (_) {}
    }
  }
}

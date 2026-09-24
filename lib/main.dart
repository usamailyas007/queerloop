import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/cache/cache_manager.dart';
import 'core/config/app_config.dart';
import 'core/services/firebase_service.dart';
import 'features/messages/services/shared_post_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await FirebaseService.initialize();
  await CacheManager.instance.init();
  await SharedPostCache.init();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final String? savedTheme = prefs.getString('app_theme_mode');
  final ThemeMode initialThemeMode = switch (savedTheme) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    'system' => ThemeMode.system,
    _ => ThemeMode.light,
  };

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  AppConfig.assertValid();
  runApp(App(initialThemeMode: initialThemeMode));
}

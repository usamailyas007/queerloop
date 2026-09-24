import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'core/cache/cache_manager.dart';
import 'core/config/app_config.dart';
import 'core/services/firebase_service.dart';
import 'features/messages/services/shared_post_cache.dart';
import 'features/home/services/video_cache_service.dart';

void main() {
  // Completely silence all prints, debugPrints, socket logs, and API logs across the entire app
  // ONLY allow [VIDEO_SIZE] logs to be printed
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null && message.contains('[VIDEO_SIZE]')) {
      debugPrintSynchronously(message, wrapWidth: wrapWidth);
    }
  };

  runZonedGuarded(
    () async {
      // ensureInitialized() and runApp() must be called in the same zone.
      WidgetsFlutterBinding.ensureInitialized();

      await FirebaseService.initialize();
      await CacheManager.instance.init();
      await SharedPostCache.init();
      await VideoCacheService.instance.init();

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
    },
    (Object error, StackTrace stack) {},
    zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
        if (line.contains('[VIDEO_SIZE]')) {
          parent.print(zone, line);
        }
      },
    ),
  );
}

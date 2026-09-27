import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app.dart';
import 'core/cache/cache_manager.dart';
import 'core/config/app_config.dart';
import 'core/services/firebase_service.dart';
import 'features/messages/services/shared_post_cache.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Silence all logs except Feed API response ──────────────────────────────
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null && message.contains('[FeedAPI]')) {
      // ignore: avoid_print
      print(message);
    }
  };

  await FirebaseService.initialize();
  await CacheManager.instance.init();
  await SharedPostCache.init();
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
  runApp(const App());
}

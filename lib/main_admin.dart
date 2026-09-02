// Admin console entry point.

import 'package:flutter/material.dart';

import 'admin/admin_app.dart';
import 'core/cache/cache_manager.dart';
import 'core/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheManager.instance.init();
  AppConfig.assertValid();
  runApp(const AdminApp());
}


// Command for running admin staging web in sandbox

// flutter run -d chrome -t lib/main_admin.dart --dart-define-from-file=env/staging.json \
//   --web-browser-flag "--disable-web-security" \
//   --web-browser-flag "--user-data-dir=/tmp/ql-admin-dev"
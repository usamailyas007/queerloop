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

// User app entry point.

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';

void main() {
  AppConfig.assertValid();
  runApp(const App());
}

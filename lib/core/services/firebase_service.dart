import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

/// Centralized service to manage Firebase initialization and configuration.
abstract final class FirebaseService {
  static bool _initialized = false;

  /// Returns true if Firebase has been successfully initialized.
  static bool get isInitialized => _initialized;

  /// Initializes Firebase with platform-specific options.
  ///
  /// Safely catches platform unsupported errors (e.g., when running on desktop
  /// during local development) without crashing the application startup.
  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _initialized = true;
      debugPrint('🔥 [FirebaseService] Firebase initialized successfully.');
    } on UnsupportedError catch (e) {
      debugPrint('⚠️ [FirebaseService] Firebase not configured for this platform: ${e.message}');
    } catch (e, stackTrace) {
      debugPrint('⚠️ [FirebaseService] Firebase initialization failed: $e');
      if (kDebugMode) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}

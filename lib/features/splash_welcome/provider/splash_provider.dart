import 'package:flutter/foundation.dart';
import '../../auth/auth_provider.dart';

enum SplashState { initializing, completed }

class SplashProvider extends ChangeNotifier {
  SplashState _state = SplashState.initializing;

  /// Set to true once the user has finished or skipped the onboarding flow.
  /// In production this would be persisted in SharedPreferences / secure storage.
  bool _onboardingSeen = false;

  SplashState get state => _state;
  bool get isInitializing => _state == SplashState.initializing;
  bool get onboardingSeen => _onboardingSeen;

  Future<void> initialize(AuthProvider authProvider) async {
    _state = SplashState.initializing;
    notifyListeners();

    // Ensure session is restored while providing smooth splash timing.
    await Future.wait(<Future<dynamic>>[
      authProvider.restoreSession(),
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);

    _state = SplashState.completed;
    notifyListeners();
  }

  /// Call when the user completes or skips onboarding.
  void markOnboardingSeen() {
    if (_onboardingSeen) return;
    _onboardingSeen = true;
    notifyListeners();
  }
}


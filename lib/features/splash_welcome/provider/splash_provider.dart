import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/auth_provider.dart';
import '../../home/provider/home_feed_provider.dart';
import '../../home/services/reel_video_preloader.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile_setup/provider/profile_setup_provider.dart';

enum SplashState { initializing, completed }

class SplashProvider extends ChangeNotifier {
  SplashState _state = SplashState.initializing;

  /// Set to true once the user has finished or skipped the onboarding flow.
  bool _onboardingSeen = false;

  SplashState get state => _state;
  bool get isInitializing => _state == SplashState.initializing;
  bool get onboardingSeen => _onboardingSeen;

  Future<void> initialize(
    AuthProvider authProvider, [
    ProfileProvider? profileProvider,
    HomeFeedProvider? homeFeedProvider,
    ProfileSetupProvider? profileSetupProvider,
  ]) async {
    _state = SplashState.initializing;
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    } catch (_) {}

    // Pre-warm communities API so it's already cached and renders immediately!
    if (profileSetupProvider != null) {
      profileSetupProvider.fetchCommunities().catchError((_) {});
    }

    // Ensure session is restored while providing smooth splash timing.
    await Future.wait(<Future<dynamic>>[
      authProvider.restoreSession(),
      Future<void>.delayed(const Duration(seconds: 2)),
    ]);

    if (authProvider.isSignedIn) {
      markOnboardingSeen();
      final String? uid = authProvider.userId;
      final List<Future<dynamic>> warmUpTasks = <Future<dynamic>>[];

      // 1. Fetch own profile, communities, and user posts/reels
      if (uid != null && uid.isNotEmpty && profileProvider != null) {
        warmUpTasks.add(profileProvider.fetchProfile(uid).catchError((_) {}));
      }

      // 2. Fetch home feed (reels & posts) and buffer first reel video
      if (homeFeedProvider != null) {
        warmUpTasks.add(() async {
          try {
            await homeFeedProvider.loadFeed();
            if (homeFeedProvider.reels.isNotEmpty) {
              final firstReel = homeFeedProvider.reels.first;
              if (firstReel.videoUrl != null && firstReel.videoUrl!.isNotEmpty) {
                final controller =
                    await ReelVideoPreloader.instance.getOrCreate(firstReel);
                if (controller != null && !controller.value.isInitialized) {
                  await controller.initialize().timeout(
                        const Duration(seconds: 4),
                        onTimeout: () => controller,
                      );
                }
              }
            }
          } catch (_) {}
        }());
      }

      if (warmUpTasks.isNotEmpty) {
        await Future.wait(warmUpTasks).timeout(
          const Duration(seconds: 5),
          onTimeout: () => <dynamic>[],
        );
      }
    }

    _state = SplashState.completed;
    notifyListeners();
  }

  /// Call when the user completes or skips onboarding.
  void markOnboardingSeen() {
    if (!_onboardingSeen) {
      _onboardingSeen = true;
      notifyListeners();
    }
    SharedPreferences.getInstance().then((SharedPreferences prefs) {
      prefs.setBool('onboarding_seen', true);
    }).catchError((_) {});
  }
}


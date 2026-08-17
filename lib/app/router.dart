// Picks the screen for the current auth state.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/home/home_screen.dart';
import '../features/splash_welcome/provider/splash_provider.dart';
import '../features/splash_welcome/screens/splash_screen.dart';
import '../features/splash_welcome/screens/welcome_screen.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthStatus authStatus = context.select<AuthProvider, AuthStatus>(
      (AuthProvider p) => p.status,
    );
    final SplashProvider splashProvider = context.watch<SplashProvider>();

    // 1. Splash — session being restored
    if (splashProvider.state == SplashState.initializing ||
        authStatus == AuthStatus.unknown) {
      return const SplashScreen();
    }

    // 2. Onboarding — first-time signed-out user
    if (authStatus == AuthStatus.signedOut && !splashProvider.onboardingSeen) {
      return WelcomeScreen(
        onFinish: () => splashProvider.markOnboardingSeen(),
      );
    }

    // 3. Auth gate
    return switch (authStatus) {
      AuthStatus.signedIn => const HomeScreen(),
      _ => const RegisterScreen(),
    };
  }
}

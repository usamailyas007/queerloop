// Picks the screen for the current auth state.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/auth/auth_provider.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/splash_screen.dart';
import '../features/home/home_screen.dart';

class AppRouter extends StatelessWidget {
  const AppRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthStatus status = context.select<AuthProvider, AuthStatus>(
      (AuthProvider provider) => provider.status,
    );

    return switch (status) {
      AuthStatus.unknown => const SplashScreen(),
      AuthStatus.signedOut => const LoginScreen(),
      AuthStatus.signedIn => const HomeScreen(),
    };
  }
}

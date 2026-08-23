// Admin console root: theme, provider wiring, and the auth gate.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'auth/provider/admin_auth_provider.dart';
import 'auth/screens/admin_login_screen.dart';
import 'admin_view/admin_shell.dart';
import 'moderator_view/moderator_shell.dart';

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AdminAuthProvider>(
          create: (BuildContext context) => AdminAuthProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'QueerLoop+ Admin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.admin,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const _AdminRouter(),
      ),
    );
  }
}

class _AdminRouter extends StatelessWidget {
  const _AdminRouter();

  @override
  Widget build(BuildContext context) {
    final (AdminAuthStatus, AdminRole) state =
        context.select<AdminAuthProvider, (AdminAuthStatus, AdminRole)>(
      (AdminAuthProvider provider) => (provider.status, provider.role),
    );
    final (AdminAuthStatus status, AdminRole role) = state;

    return switch (status) {
      AdminAuthStatus.unknown => const _AdminSplash(),
      AdminAuthStatus.signedOut => const AdminLoginScreen(),
      AdminAuthStatus.signedIn => switch (role) {
          AdminRole.admin => const AdminShell(),
          AdminRole.moderator => const ModeratorShell(),
        },
    };
  }
}

class _AdminSplash extends StatefulWidget {
  const _AdminSplash();

  @override
  State<_AdminSplash> createState() => _AdminSplashState();
}

class _AdminSplashState extends State<_AdminSplash> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<AdminAuthProvider>().restoreSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: SizedBox(
          width: AppSizes.iconLg,
          height: AppSizes.iconLg,
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
    );
  }
}

// User app root: theme, provider wiring, and the non-prod env ribbon.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api/api_client.dart';
import '../core/config/app_config.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/auth_provider.dart';
import 'router.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ApiClient>(
          create: (BuildContext context) => ApiClient(),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (BuildContext context) => AuthProvider(
            client: context.read<ApiClient>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'QueerLoop+',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.app,
        builder: (BuildContext context, Widget? child) {
          return GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
            child: _EnvBanner(child: child ?? const SizedBox.shrink()),
          );
        },
        home: const AppRouter(),
      ),
    );
  }
}

class _EnvBanner extends StatelessWidget {
  const _EnvBanner({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (AppConfig.isProd) {
      return child;
    }

    return Banner(
      message: AppConfig.envLabel,
      location: BannerLocation.topEnd,
      child: child,
    );
  }
}

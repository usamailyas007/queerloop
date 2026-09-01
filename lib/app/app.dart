import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/api/api_client.dart';
import '../core/config/app_config.dart';
import '../core/network/network_info.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../core/widgets/offline_banner.dart';
import '../features/auth/auth_provider.dart';
import '../features/create_post/provider/create_post_provider.dart';
import '../features/home/provider/home_feed_provider.dart';
import '../features/messages/provider/messages_provider.dart';
import '../features/profile/provider/profile_provider.dart';
import '../features/profile_setup/profile_setup_service.dart';
import '../features/profile_setup/provider/profile_setup_provider.dart';
import '../features/splash_welcome/provider/splash_provider.dart';
import '../l10n/app_localizations.dart';
import 'router.dart';
import 'routes.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<NetworkInfo>(
          create: (_) => NetworkInfo(),
        ),
        Provider<ApiClient>(create: (_) => ApiClient()),
        ChangeNotifierProvider<AuthProvider>(
          create: (BuildContext ctx) =>
              AuthProvider(client: ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<SplashProvider>(
            create: (_) => SplashProvider()),
        ChangeNotifierProvider<ProfileSetupProvider>(
          create: (BuildContext ctx) => ProfileSetupProvider(
            service: ProfileSetupService(ctx.read<ApiClient>()),
          ),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (BuildContext ctx) => ProfileProvider(
            client: ctx.read<ApiClient>(),
          ),
        ),
        ChangeNotifierProvider<HomeFeedProvider>(
            create: (_) => HomeFeedProvider()),
        ChangeNotifierProvider<CreatePostProvider>(
            create: (_) => CreatePostProvider()),
        ChangeNotifierProvider<MessagesProvider>(
            create: (_) => MessagesProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (BuildContext context, ThemeProvider themeProvider, _) {
          return MaterialApp(
            title: 'QueerLoop+',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: themeProvider.themeMode,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
            builder: (BuildContext context, Widget? child) {
              return GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: _EnvBanner(
                  child: OfflineBanner(child: child ?? const SizedBox.shrink()),
                ),
              );
            },
            home: const AppRouter(),
          );
        },
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

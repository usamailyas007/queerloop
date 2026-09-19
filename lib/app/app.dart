import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../admin/admin_view/community_spotlight/provider/spotlights_provider.dart';
import '../core/api/api_client.dart';
import '../core/config/app_config.dart';
import '../core/network/network_info.dart';
import '../core/theme/app_theme.dart';
import '../core/theme/theme_provider.dart';
import '../core/widgets/offline_banner.dart';
import '../features/auth/auth_provider.dart';
import '../features/create_post/provider/create_post_provider.dart';
import '../features/create_post/services/media_upload_service.dart';
import '../features/create_post/services/post_content_service.dart';
import '../features/discover/provider/cotd_provider.dart';
import '../features/discover/provider/discover_provider.dart';
import '../features/discover/services/cotd_service.dart';
import '../features/discover/services/discover_service.dart';
import '../features/home/provider/home_feed_provider.dart';
import '../features/messages/provider/messages_provider.dart';
import '../features/messages/services/conversations_service.dart';
import '../features/profile/provider/profile_provider.dart';
import '../features/profile/services/user_relationship_service.dart';
import '../features/profile_setup/profile_setup_service.dart';
import '../features/profile_setup/provider/profile_setup_provider.dart';
import '../features/reports/provider/report_provider.dart';
import '../features/reports/services/report_service.dart';
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
        ChangeNotifierProxyProvider<AuthProvider, ProfileSetupProvider>(
          create: (BuildContext ctx) => ProfileSetupProvider(
            service: ProfileSetupService(ctx.read<ApiClient>()),
          ),
          update: (BuildContext ctx, AuthProvider auth, ProfileSetupProvider? existing) {
            final ProfileSetupProvider provider = existing ??
                ProfileSetupProvider(
                  service: ProfileSetupService(ctx.read<ApiClient>()),
                );
            // Jab bhi user sign out kare, wizard ko Step 1 pe reset karo
            if (auth.status == AuthStatus.signedOut) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                provider.reset();
              });
            }
            return provider;
          },
        ),
        Provider<UserRelationshipService>(
          create: (BuildContext ctx) =>
              UserRelationshipService(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (BuildContext ctx) => ProfileProvider(
            client: ctx.read<ApiClient>(),
            relationshipService: ctx.read<UserRelationshipService>(),
          ),
        ),
        ChangeNotifierProxyProvider<AuthProvider, HomeFeedProvider>(
          create: (BuildContext ctx) => HomeFeedProvider(
            contentService: PostContentService(ctx.read<ApiClient>()),
            mediaService: MediaUploadService(ctx.read<ApiClient>()),
          ),
          update: (BuildContext ctx, AuthProvider auth, HomeFeedProvider? feed) {
            final HomeFeedProvider provider = feed ??
                HomeFeedProvider(
                  contentService: PostContentService(ctx.read<ApiClient>()),
                  mediaService: MediaUploadService(ctx.read<ApiClient>()),
                );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.updateUser(auth.userId);
            });
            return provider;
          },
        ),
        ChangeNotifierProvider<CreatePostProvider>(
          create: (BuildContext ctx) => CreatePostProvider(
            uploadService: MediaUploadService(ctx.read<ApiClient>()),
            contentService: PostContentService(ctx.read<ApiClient>()),
          ),
        ),
        Provider<ConversationsService>(
          create: (BuildContext ctx) =>
              ConversationsService(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProxyProvider<AuthProvider, MessagesProvider>(
          create: (BuildContext ctx) => MessagesProvider(
            service: ConversationsService(ctx.read<ApiClient>()),
          ),
          update: (BuildContext ctx, AuthProvider auth,
              MessagesProvider? existing) {
            final MessagesProvider provider = existing ??
                MessagesProvider(
                  service: ctx.read<ConversationsService>(),
                  currentUserId: auth.userId,
                );
            WidgetsBinding.instance.addPostFrameCallback((_) {
              provider.updateAuth(
                userId: auth.userId,
                service: ctx.read<ConversationsService>(),
              );
            });
            return provider;
          },
        ),
        Provider<ReportService>(
          create: (BuildContext ctx) =>
              ReportService(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<ReportProvider>(
          create: (BuildContext ctx) => ReportProvider(
            service: ctx.read<ReportService>(),
          ),
        ),
        Provider<DiscoverService>(
          create: (BuildContext ctx) =>
              DiscoverService(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<DiscoverProvider>(
          create: (BuildContext ctx) => DiscoverProvider(
            discoverService: ctx.read<DiscoverService>(),
          ),
        ),
        Provider<CotdService>(
          create: (BuildContext ctx) => CotdService(ctx.read<ApiClient>()),
        ),
        ChangeNotifierProvider<CotdProvider>(
          create: (BuildContext ctx) => CotdProvider(
            service: ctx.read<CotdService>(),
          ),
        ),
        ChangeNotifierProvider<SpotlightsProvider>(
          create: (BuildContext ctx) =>
              SpotlightsProvider(client: ctx.read<ApiClient>()),
        ),
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
            navigatorObservers: <NavigatorObserver>[appRouteObserver],
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

import 'package:flutter/material.dart';

import '../features/auth/screens/account_created_success_screen.dart';
import '../features/auth/screens/code_expired_screen.dart';
import '../features/auth/screens/create_new_password_screen.dart';
import '../features/auth/screens/forgot_password_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/password_reset_success_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/verify_code_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile_setup/screens/all_communities_screen.dart';
import '../features/profile_setup/screens/allow_messages_from_screen.dart';
import '../features/profile_setup/screens/profile_setup_flow_screen.dart';
import '../features/profile_setup/screens/profile_visibility_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/splash_welcome/screens/splash_screen.dart';
import '../features/splash_welcome/screens/welcome_screen.dart';

abstract final class AppRoutes {
  static const String splash = '/splash';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String verifyCode = '/verify-code';
  static const String codeExpired = '/code-expired';
  static const String createNewPassword = '/create-new-password';
  static const String passwordResetSuccess = '/password-reset-success';
  static const String accountCreatedSuccess = '/account-created-success';
  static const String profileSetup = '/profile-setup';
  static const String allCommunities = '/all-communities';
  static const String allowMessagesFrom = '/allow-messages-from';
  static const String profileVisibility = '/profile-visibility';
  static const String home = '/home';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';

  static Map<String, WidgetBuilder> get routes => <String, WidgetBuilder>{
        splash: (BuildContext context) => const SplashScreen(),
        welcome: (BuildContext context) => const WelcomeScreen(),
        login: (BuildContext context) => const LoginScreen(),
        register: (BuildContext context) => const RegisterScreen(),
        forgotPassword: (BuildContext context) => const ForgotPasswordScreen(),
        verifyCode: (BuildContext context) => const VerifyCodeScreen(),
        createNewPassword: (BuildContext context) =>
            const CreateNewPasswordScreen(),
        passwordResetSuccess: (BuildContext context) =>
            const PasswordResetSuccessScreen(),
        accountCreatedSuccess: (BuildContext context) =>
            const AccountCreatedSuccessScreen(),
        profileSetup: (BuildContext context) =>
            const ProfileSetupFlowScreen(),
        allCommunities: (BuildContext context) =>
            const AllCommunitiesScreen(),
        allowMessagesFrom: (BuildContext context) =>
            const AllowMessagesFromScreen(),
        profileVisibility: (BuildContext context) =>
            const ProfileVisibilityScreen(),
        settings: (BuildContext context) => const SettingsScreen(),
        editProfile: (BuildContext context) => const EditProfileScreen(),
      };

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == codeExpired) {
      final String? code = settings.arguments as String?;
      return MaterialPageRoute<void>(
        builder: (BuildContext context) => CodeExpiredScreen(expiredCode: code),
        settings: settings,
      );
    } else if (settings.name == home) {
      final bool isGuest = (settings.arguments as bool?) ?? false;
      return MaterialPageRoute<void>(
        builder: (BuildContext context) => HomeScreen(isGuest: isGuest),
        settings: settings,
      );
    }
    final WidgetBuilder? builder = routes[settings.name];
    if (builder != null) {
      return MaterialPageRoute<void>(
        builder: builder,
        settings: settings,
      );
    }
    return MaterialPageRoute<void>(
      builder: (BuildContext context) => const RegisterScreen(),
      settings: settings,
    );
  }
}

// Alias for convenience across screens
typedef Routes = AppRoutes;

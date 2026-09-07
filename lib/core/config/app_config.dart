// Compile-time environment values injected via --dart-define-from-file.

enum Env { staging, prod }

abstract final class AppConfig {
  static const String _envName = String.fromEnvironment(
    'ENV',
    defaultValue: 'staging',
  );

  static const String baseUrl = String.fromEnvironment('BASE_URL');

  static const bool useMockApi = bool.fromEnvironment(
    'USE_MOCK_API',
    defaultValue: false,
  );

  static Env get env => _envName == 'prod' ? Env.prod : Env.staging;

  static bool get isProd => env == Env.prod;

  static String get envLabel => _envName.toUpperCase();

  static void assertValid() {
    assert(
      baseUrl.isNotEmpty,
      'BASE_URL is empty. Run with --dart-define-from-file=env/staging.json',
    );
    assert(
      !(isProd && useMockApi),
      'USE_MOCK_API must be false in a production build.',
    );
  }

  /// Builds a full URL for a microservice with a specific port (e.g., 3014 for Media, 3013 for Content).
  static String serviceUrl(int port, String path) {
    if (baseUrl.isEmpty) return path;
    try {
      final Uri uri = Uri.parse(baseUrl);
      if (uri.hasPort) {
        return uri.replace(port: port, path: path).toString();
      }
      final String cleanBase = baseUrl.replaceAll(RegExp(r'/+$'), '');
      return '$cleanBase$path';
    } catch (_) {
      return '$baseUrl$path';
    }
  }
}

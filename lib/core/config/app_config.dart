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
    defaultValue: true,
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
}

// Central registry of every API path used by the app.
// Import this file wherever you need a path — never hard-code strings elsewhere.

abstract final class ApiEndpoints {
  // ── Auth ──────────────────────────────────────────────────────────────────
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String logoutAll = '/auth/logout-all';
  static const String refresh = '/auth/refresh';
  static const String me = '/auth/me';
  static const String sessions = '/auth/sessions';
  static const String verifyAge = '/auth/verify-age';

  // ── Auth › Password Reset ─────────────────────────────────────────────────
  static const String passwordResetRequest = '/auth/password-reset/request';
  static const String passwordResetVerify = '/auth/password-reset/verify';
  static const String passwordResetConfirm = '/auth/password-reset/confirm';

  // ── Users ─────────────────────────────────────────────────────────────────
  /// Replace :id at call site: ApiEndpoints.user('abc-123')
  static String user(String id) => '/users/$id';
  static const String usernameAvailable = '/users/username-available';

  // ── Admin ─────────────────────────────────────────────────────────────────
  /// Paginated account list for the admin console. GET /admin/users
  static const String adminUsers = '/admin/users';

  // ── Communities ───────────────────────────────────────────────────────────
  /// Replace :id at call site: ApiEndpoints.joinCommunity('comm-id')
  static String joinCommunity(String communityId) =>
      '/communities/$communityId/join';
}

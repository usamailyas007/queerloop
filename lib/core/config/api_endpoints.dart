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

  /// Aggregate counts for the Users tab. GET /admin/users/stats
  static const String adminUsersStats = '/admin/users/stats';

  /// Suspend / reactivate an account. PATCH /admin/users/:id/status
  static String adminUserStatus(String id) => '/admin/users/$id/status';

  /// Moderator roster + invites. GET / POST /admin/moderators
  static const String adminModerators = '/admin/moderators';
  static String adminModeratorResendInvite(String id) =>
      '/admin/moderators/$id/resend-invite';

  /// Publish an announcement. POST /admin/announcements
  static const String adminAnnouncements = '/admin/announcements';

  /// Community roster with admin metrics. GET /admin/communities
  static const String adminCommunities = '/admin/communities';

  /// Conversation of the day. POST /admin/cotd · GET /admin/cotd/history
  static const String adminCotd = '/admin/cotd';
  static const String adminCotdHistory = '/admin/cotd/history';

  /// Community spotlight. POST /admin/spotlights · PATCH/rerun by id.
  static const String adminSpotlights = '/admin/spotlights';
  static String adminSpotlight(String id) => '/admin/spotlights/$id';
  static String adminSpotlightRerun(String id) => '/admin/spotlights/$id/rerun';

  /// Content moderation. GET /admin/posts · PATCH /admin/posts/:id/{hide,restore}
  static const String adminPosts = '/admin/posts';
  static String adminPostHide(String id) => '/admin/posts/$id/hide';
  static String adminPostRestore(String id) => '/admin/posts/$id/restore';
  static String adminCotdAnswerFeature(String answerId) =>
      '/admin/cotd/answers/$answerId/feature';

  /// Analytics overview & dashboard. GET /admin/analytics/overview · GET /admin/analytics/dashboard
  static const String adminAnalyticsOverview = '/admin/analytics/overview';
  static const String adminAnalyticsDashboard = '/admin/analytics/dashboard';
  static String adminCotdAnswerHide(String answerId) =>
      '/admin/cotd/answers/$answerId/hide';

  // ── Moderator (Reports) ───────────────────────────────────────────────────
  static const String modDashboard = '/mod/dashboard';
  static const String modReports = '/mod/reports';
  static String modReport(String id) => '/mod/reports/$id';
  static String modAccountHistory(String userId) =>
      '/mod/accounts/$userId/history';
  static String modReportAssign(String id) => '/mod/reports/$id/assign';
  static String modReportDecision(String id) => '/mod/reports/$id/decision';
  static String modReportReopen(String id) => '/mod/reports/$id/reopen';

  // ── Engagement ────────────────────────────────────────────────────────────
  /// Published announcement feed. GET /engagement/announcements
  static const String engagementAnnouncements = '/engagement/announcements';

  /// Answers to a conversation-of-the-day question. GET /engagement/cotd/:id/answers
  static String cotdAnswers(String questionId) =>
      '/engagement/cotd/$questionId/answers';

  /// Community spotlight feed. GET /engagement/spotlights (optional ?search=)
  static const String engagementSpotlights = '/engagement/spotlights';

  // ── Posts / Media ─────────────────────────────────────────────────────────
  /// Trending posts. GET /posts/trending
  static const String postsTrending = '/posts/trending';

  /// Resolve a media reference to its URLs. GET /media/:id
  static String media(String id) => '/media/$id';

  // ── Communities ───────────────────────────────────────────────────────────
  /// List / create communities. GET / POST /communities
  static const String communities = '/communities';

  /// Replace :id at call site: ApiEndpoints.joinCommunity('comm-id')
  static String joinCommunity(String communityId) =>
      '/communities/$communityId/join';
}

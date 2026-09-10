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
  static const String verifyEmail = '/auth/verify-email';
  static const String verifyEmailResend = '/auth/verify-email/resend';

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

  /// Batch join communities. POST /communities/join
  static const String joinCommunities = '/communities/join';

  /// Replace :id at call site: ApiEndpoints.joinCommunity('comm-id')
  static String joinCommunity(String communityId) =>
      '/communities/$communityId/join';

  /// Leave a community. DELETE /communities/:id/leave
  static String leaveCommunity(String communityId) =>
      '/communities/$communityId/leave';

  /// User joined communities. GET /users/:id/communities
  static String userCommunities(String userId) => '/users/$userId/communities';

  /// Alternative singular route fallback. GET /user/:id/communities
  static String userCommunitiesAlt(String userId) => '/user/$userId/communities';

  // ── Media Service ──────────────────────────────────────────────────────────
  /// Request pre-signed S3 upload URL. POST /media/upload-url
  static const String mediaUploadUrl = '/media/upload-url';

  /// Complete upload (image-only / mock-mode). POST /media/:id/complete
  static String mediaComplete(String id) => '/media/$id/complete';

  /// Poll media status (e.g. ready / transcoding / failed). GET /media/:id
  static String mediaStatus(String id) => '/media/$id';

  // ── Content Service ────────────────────────────────────────────────────────
  /// Create / list posts. POST / GET /posts
  static const String posts = '/posts';

  /// Read one post. GET /posts/:id
  static String post(String id) => '/posts/$id';

  /// List posts by author. GET /posts?authorId=:authorId
  static String postsByAuthor(String authorId) => '/posts?authorId=$authorId';

  /// Trending posts (video-only). GET /posts/trending
  static const String trendingPosts = '/posts/trending';

  /// Record a view on a post. POST /posts/:id/view
  static String postView(String id) => '/posts/$id/view';

  /// Like a post. POST /posts/:id/like · Unlike: DELETE /posts/:id/like
  static String postLike(String id) => '/posts/$id/like';

  /// Comments for a post. GET / POST /posts/:id/comments
  static String postComments(String id) => '/posts/$id/comments';

  // ── Reports ────────────────────────────────────────────────────────────────
  /// File a user report. POST /reports
  static const String reports = '/reports';
}

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
  static const String cancelDeletion = '/auth/cancel-deletion';

  // ── Auth › Password Reset ─────────────────────────────────────────────────
  static const String passwordResetRequest = '/auth/password-reset/request';
  static const String passwordResetVerify = '/auth/password-reset/verify';
  static const String passwordResetConfirm = '/auth/password-reset/confirm';

  // ── Auth › Social ─────────────────────────────────────────────────────────
  static const String googleSignIn = '/auth/google';
  static const String appleSignIn = '/auth/apple';

  // ── Users › Account Deletion ─────────────────────────────────────────────────
  static const String requestAccountDeletion = '/users/me/delete';
  static const String deletionStatus = '/users/me/deletion-status';

  // ── Users ─────────────────────────────────────────────────────────────────
  /// Replace :id at call site: ApiEndpoints.user('abc-123')
  static String user(String id) => '/users/$id';
  static const String usernameAvailable = '/users/username-available';

  // ── User Relationships ────────────────────────────────────────────────────
  /// Follow user (A follows B, or request to follow private account): POST /users/:id/follow
  /// Unfollow user: DELETE /users/:id/follow
  static String userFollow(String userId) => '/users/$userId/follow';

  /// List user's followers (public): GET /users/:id/followers
  static String userFollowers(String userId) => '/users/$userId/followers';

  /// List user's following (public): GET /users/:id/following
  static String userFollowing(String userId) => '/users/$userId/following';

  /// Block user: POST /users/:id/block · Unblock: DELETE /users/:id/block
  static String userBlock(String userId) => '/users/$userId/block';

  /// Restrict user: POST /users/:id/restrict · Unrestrict: DELETE /users/:id/restrict
  static String userRestrict(String userId) => '/users/$userId/restrict';

  /// List current user's restricted accounts: GET /users/me/restricted
  static const String userRestricted = '/users/me/restricted';

  /// Mute user: POST /users/:id/mute · Unmute: DELETE /users/:id/mute
  static String userMute(String userId) => '/users/$userId/mute';

  /// Remove user as a follower: DELETE /users/me/followers/:userId
  static String userRemoveFollower(String userId) => '/users/me/followers/$userId';

  /// List current user's follow requests: GET /users/me/follow-requests
  static const String userFollowRequests = '/users/me/follow-requests';

  /// Accept follow request: POST /users/me/follow-requests/:id/accept
  static String userFollowRequestAccept(String requestId) =>
      '/users/me/follow-requests/$requestId/accept';

  /// Reject follow request: POST /users/me/follow-requests/:id/reject
  static String userFollowRequestReject(String requestId) =>
      '/users/me/follow-requests/$requestId/reject';

  /// List current user's muted accounts: GET /users/me/muted
  static const String userMuted = '/users/me/muted';

  /// List current user's blocked accounts: GET /users/me/blocked
  static const String userBlocked = '/users/me/blocked';

  // ── Admin ─────────────────────────────────────────────────────────────────
  /// Paginated account list for the admin console. GET /admin/users
  static const String adminUsers = '/admin/users';

  /// Aggregate counts for the Users tab. GET /admin/users/stats
  static const String adminUsersStats = '/admin/users/stats';

  /// Suspend / reactivate an account. PATCH /admin/users/:id/status
  static String adminUserStatus(String id) => '/admin/users/$id/status';

  /// Hard-delete an account. DELETE /admin/users/:id
  static String adminUser(String id) => '/admin/users/$id';

  /// Moderator roster + invites. GET / POST /admin/moderators
  static const String adminModerators = '/admin/moderators';
  static String adminModeratorResendInvite(String id) =>
      '/admin/moderators/$id/resend-invite';

  /// Hard-delete a moderator. DELETE /admin/moderators/:id
  static String adminModerator(String id) => '/admin/moderators/$id';

  /// Publish an announcement. POST /admin/announcements
  static const String adminAnnouncements = '/admin/announcements';

  /// Delete an announcement. DELETE /admin/announcements/:id
  static String adminAnnouncement(String id) => '/admin/announcements/$id';

  /// Community roster with admin metrics. GET /admin/communities
  static const String adminCommunities = '/admin/communities';

  /// Hard-delete a community. DELETE /admin/communities/:id
  static String adminCommunity(String id) => '/admin/communities/$id';

  /// Conversation of the day. POST /admin/cotd · GET /admin/cotd/history
  static const String adminCotd = '/admin/cotd';
  static const String adminCotdHistory = '/admin/cotd/history';

  /// Delete a question (cascades its answers). DELETE /admin/cotd/:id
  static String adminCotdQuestion(String id) => '/admin/cotd/$id';

  /// Delete a single answer. DELETE /admin/cotd/answers/:id
  static String adminCotdAnswer(String answerId) =>
      '/admin/cotd/answers/$answerId';

  /// Community spotlight. POST /admin/spotlights · PATCH/rerun/delete by id.
  static const String adminSpotlights = '/admin/spotlights';
  static String adminSpotlight(String id) => '/admin/spotlights/$id';
  static String adminSpotlightRerun(String id) => '/admin/spotlights/$id/rerun';

  /// Content moderation. GET /admin/posts · PATCH /admin/posts/:id/{hide,restore}
  /// · DELETE /admin/posts/:id (bypasses ownership check)
  static const String adminPosts = '/admin/posts';
  static String adminPost(String id) => '/admin/posts/$id';
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

  /// Current Conversation of the Day. GET /engagement/cotd/current
  static const String cotdCurrent = '/engagement/cotd/current';

  /// Submit an answer to a CotD question. POST /engagement/cotd/:id/answers
  static String cotdAnswerSubmit(String questionId) =>
      '/engagement/cotd/$questionId/answers';

  /// Answers to a conversation-of-the-day question. GET /engagement/cotd/:id/answers
  static String cotdAnswers(String questionId) =>
      '/engagement/cotd/$questionId/answers';

  /// Single spotlight detail. GET /engagement/spotlights/:id
  static String engagementSpotlight(String id) => '/engagement/spotlights/$id';

  /// Community spotlight feed. GET /engagement/spotlights (optional ?search=)
  static const String engagementSpotlights = '/engagement/spotlights';

  // ── Feeds ─────────────────────────────────────────────────────────────────
  /// Following feed. GET /feed/following
  static const String feedFollowing = '/feed/following';

  /// Community feed. GET /feed/community?communityId=:id or ?scope=joined
  static String feedCommunity({String? communityId, String? scope}) {
    final Map<String, String> query = <String, String>{};
    if (communityId != null && communityId.isNotEmpty) {
      query['communityId'] = communityId;
    }
    if (scope != null && scope.isNotEmpty) {
      query['scope'] = scope;
    }
    if (query.isEmpty) return '/feed/community';
    final String queryStr =
        query.entries.map((MapEntry<String, String> e) => '${e.key}=${e.value}').join('&');
    return '/feed/community?$queryStr';
  }

  // ── Posts / Media ─────────────────────────────────────────────────────────
  /// Trending posts. GET /posts/trending
  static const String postsTrending = '/posts/trending';

  /// Resolve a media reference to its URLs. GET /media/:id
  static String media(String id) => '/media/$id';

  // ── Communities ───────────────────────────────────────────────────────────
  /// List / create communities. GET / POST /communities
  static const String communities = '/communities';

  /// Communities to Explore: GET /communities/explore
  static String communitiesExplore({
    bool excludeJoined = true,
    String sort = 'trending',
    String? category,
    int page = 1,
    int limit = 10,
  }) {
    final Map<String, String> query = <String, String>{
      'excludeJoined': excludeJoined.toString(),
      'sort': sort,
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category != null && category.isNotEmpty) {
      query['category'] = category;
    }
    final String queryStr =
        query.entries.map((MapEntry<String, String> e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return '/communities/explore?$queryStr';
  }

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

  /// Save a post. POST /posts/:id/save · Unsave: DELETE /posts/:id/save
  static String postSave(String id) => '/posts/$id/save';

  /// Comments for a post. GET / POST /posts/:id/comments
  static String postComments(String id) => '/posts/$id/comments';

  /// Single comment operations (Delete). DELETE /comments/:commentId
  static String comment(String commentId) => '/comments/$commentId';

  /// Like / unlike a comment. POST /comments/:commentId/like · DELETE /comments/:commentId/like
  static String commentLike(String commentId) => '/comments/$commentId/like';

  /// List posts by community. GET /posts?communityId=:communityId
  static String postsByCommunity(String communityId) =>
      '/posts?communityId=$communityId';

  /// User's liked posts. GET /users/me/likes
  static const String userLikes = '/users/me/likes';

  /// User's saved posts. GET /users/me/saved
  static const String userSaved = '/users/me/saved';

  // ── Reports ────────────────────────────────────────────────────────────────
  /// File a user report. POST /reports
  static const String reports = '/reports';

  // ── Discover & Search ──────────────────────────────────────────────────────
  /// Search Posts: GET /search?q=:query&limit=:limit
  static String searchPosts({required String query, int limit = 10}) =>
      '/search?q=${Uri.encodeQueryComponent(query)}&limit=$limit';

  /// Multi-Tab Search: GET /discover/search?query=:query&tab=:tab
  static String discoverSearch({required String query, String tab = 'all'}) =>
      '/discover/search?query=${Uri.encodeQueryComponent(query)}&tab=${Uri.encodeQueryComponent(tab)}';

  /// Trending Hashtags (public): GET /discover/trending
  static const String discoverTrending = '/discover/trending';

  /// Creators: GET /discover/creators?type=:type (to_watch | new)
  static String discoverCreators({required String type}) =>
      '/discover/creators?type=$type';

  /// Recent Searches: GET / POST / DELETE /discover/recent-searches
  static const String discoverRecentSearches = '/discover/recent-searches';

  /// Delete one recent search: DELETE /discover/recent-searches/:id
  static String discoverRecentSearch(String id) =>
      '/discover/recent-searches/$id';

  // ── Conversations & Messages ───────────────────────────────────────────────
  /// List conversations or Start conversation: GET / POST /conversations
  static const String conversations = '/conversations';

  /// Fan-out share post/reel across conversations or recipients: POST /conversations/share
  static const String conversationShare = '/conversations/share';

  /// Clear/delete conversation for self: DELETE /conversations/:id
  static String conversation(String id) => '/conversations/$id';

  /// Message requests: GET /conversations/requests
  static const String conversationRequests = '/conversations/requests';

  /// Accept message request: POST /conversations/:id/accept
  static String conversationAccept(String id) => '/conversations/$id/accept';

  /// Reject message request: POST /conversations/:id/reject
  static String conversationReject(String id) => '/conversations/$id/reject';

  /// List messages or Send message: GET / POST /conversations/:id/messages
  static String conversationMessages(String id) =>
      '/conversations/$id/messages';

  /// Unsend message: DELETE /conversations/:id/messages/:messageId
  static String conversationMessage(String id, String messageId) =>
      '/conversations/$id/messages/$messageId';

  /// Mark message read: POST /conversations/:id/messages/:messageId/read
  static String conversationMessageRead(String id, String messageId) =>
      '/conversations/$id/messages/$messageId/read';

  /// Mute / Unmute conversation: POST / DELETE /conversations/:id/mute
  static String conversationMute(String id) => '/conversations/$id/mute';

  /// React to message: POST /conversations/:id/messages/:messageId/reactions
  static String conversationMessageReactions(String id, String messageId) =>
      '/conversations/$id/messages/$messageId/reactions';

  /// Remove reaction: DELETE /conversations/:id/messages/:messageId/reactions?emoji=:emoji
  static String conversationMessageReaction(
    String id,
    String messageId,
    String emoji,
  ) =>
      '/conversations/$id/messages/$messageId/reactions?emoji=${Uri.encodeQueryComponent(emoji)}';

  // ── Device Push Tokens ─────────────────────────────────────────────────────
  /// Register a device push token: POST /users/me/device-tokens
  static const String deviceTokens = '/users/me/device-tokens';

  /// Unregister device push token: DELETE /users/me/device-tokens/:token
  static String deviceToken(String token) =>
      '/users/me/device-tokens/${Uri.encodeComponent(token)}';

  // ── Notifications ──────────────────────────────────────────────────────────
  /// List notifications: GET /notifications
  static const String notifications = '/notifications';

  /// Unread notifications count: GET /notifications/unread-count
  static const String notificationsUnreadCount = '/notifications/unread-count';

  /// Mark single notification as read: PATCH /notifications/:id/read
  static String notificationRead(String id) => '/notifications/$id/read';

  /// Mark all notifications as read: POST /notifications/mark-all-read
  static const String notificationsMarkAllRead = '/notifications/mark-all-read';
}

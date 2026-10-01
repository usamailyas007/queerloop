import 'package:flutter/foundation.dart';

/// Centralized in-memory cache of following status, enabling instant
/// visibility filtering across feeds, search, and communities without
/// circular dependencies between providers.
class UserRelationshipCache {
  UserRelationshipCache._();

  static final Set<String> _followingUserIds = <String>{};
  static final Set<String> _followingUsernames = <String>{};
  static final Set<String> _followerUserIds = <String>{};
  static final Set<String> _followerUsernames = <String>{};

  /// Adds a user to the following cache.
  static void add({String? userId, String? username}) {
    if (userId != null && userId.trim().isNotEmpty) {
      _followingUserIds.add(userId.trim().toLowerCase());
    }
    if (username != null && username.trim().isNotEmpty) {
      _followingUsernames.add(username.replaceAll('@', '').trim().toLowerCase());
    }
  }

  /// Removes a user from the following cache.
  static void remove({String? userId, String? username}) {
    if (userId != null && userId.trim().isNotEmpty) {
      _followingUserIds.remove(userId.trim().toLowerCase());
    }
    if (username != null && username.trim().isNotEmpty) {
      _followingUsernames.remove(username.replaceAll('@', '').trim().toLowerCase());
    }
  }

  /// Checks if the current user is following the author (by ID or username).
  static bool isFollowing({String? userId, String? username}) {
    if (userId != null && userId.trim().isNotEmpty) {
      if (_followingUserIds.contains(userId.trim().toLowerCase())) return true;
    }
    if (username != null && username.trim().isNotEmpty) {
      final String cleanUsername =
          username.replaceAll('@', '').trim().toLowerCase();
      if (_followingUsernames.contains(cleanUsername)) return true;
    }
    return false;
  }

  /// Adds a user who follows the current user.
  static void addFollower({String? userId, String? username}) {
    if (userId != null && userId.trim().isNotEmpty) {
      _followerUserIds.add(userId.trim().toLowerCase());
    }
    if (username != null && username.trim().isNotEmpty) {
      _followerUsernames.add(username.replaceAll('@', '').trim().toLowerCase());
    }
  }

  /// Removes a user who was following the current user.
  static void removeFollower({String? userId, String? username}) {
    if (userId != null && userId.trim().isNotEmpty) {
      _followerUserIds.remove(userId.trim().toLowerCase());
    }
    if (username != null && username.trim().isNotEmpty) {
      _followerUsernames.remove(username.replaceAll('@', '').trim().toLowerCase());
    }
  }

  /// Checks if another user is following the current user (author follows viewer).
  static bool isFollowedBy({String? userId, String? username}) {
    if (userId != null && userId.trim().isNotEmpty) {
      if (_followerUserIds.contains(userId.trim().toLowerCase())) return true;
    }
    if (username != null && username.trim().isNotEmpty) {
      final String cleanUsername =
          username.replaceAll('@', '').trim().toLowerCase();
      if (_followerUsernames.contains(cleanUsername)) return true;
    }
    return false;
  }

  /// Syncs an entire batch of following user IDs/usernames.
  static void sync({
    Iterable<String>? ids,
    Iterable<String>? usernames,
  }) {
    if (ids != null) {
      for (final String id in ids) {
        if (id.trim().isNotEmpty) {
          _followingUserIds.add(id.trim().toLowerCase());
        }
      }
    }
    if (usernames != null) {
      for (final String uname in usernames) {
        if (uname.trim().isNotEmpty) {
          _followingUsernames.add(uname.replaceAll('@', '').trim().toLowerCase());
        }
      }
    }
  }

  /// Syncs an entire batch of follower user IDs/usernames.
  static void syncFollowers({
    Iterable<String>? ids,
    Iterable<String>? usernames,
  }) {
    if (ids != null) {
      for (final String id in ids) {
        if (id.trim().isNotEmpty) {
          _followerUserIds.add(id.trim().toLowerCase());
        }
      }
    }
    if (usernames != null) {
      for (final String uname in usernames) {
        if (uname.trim().isNotEmpty) {
          _followerUsernames.add(uname.replaceAll('@', '').trim().toLowerCase());
        }
      }
    }
  }

  static final Set<String> _privateUserIds = <String>{};
  static final Set<String> _privateUsernames = <String>{};

  /// Records or updates an author's private status in cache.
  static void markPrivate(String? userId, {String? username, bool isPrivate = true}) {
    if (userId != null && userId.trim().isNotEmpty) {
      final String u = userId.trim().toLowerCase();
      if (isPrivate) {
        _privateUserIds.add(u);
      } else {
        _privateUserIds.remove(u);
      }
    }
    if (username != null && username.trim().isNotEmpty) {
      final String un = username.replaceAll('@', '').trim().toLowerCase();
      if (isPrivate) {
        _privateUsernames.add(un);
      } else {
        _privateUsernames.remove(un);
      }
    }
  }

  /// Checks if an author's account is known to be private in cache.
  static bool isUserPrivate({String? userId, String? username}) {
    if (userId != null && userId.trim().isNotEmpty) {
      if (_privateUserIds.contains(userId.trim().toLowerCase())) return true;
    }
    if (username != null && username.trim().isNotEmpty) {
      final String un = username.replaceAll('@', '').trim().toLowerCase();
      if (_privateUsernames.contains(un)) return true;
    }
    return false;
  }

  /// Checks if both users follow each other.
  static bool isMutual({String? userId, String? username}) {
    return isFollowing(userId: userId, username: username) &&
        isFollowedBy(userId: userId, username: username);
  }

  /// Clears cache on logout.
  static void clear() {
    _followingUserIds.clear();
    _followingUsernames.clear();
    _followerUserIds.clear();
    _followerUsernames.clear();
    _privateUserIds.clear();
    _privateUsernames.clear();
  }
}

/// Centralized evaluator for user profile privacy rules:
/// 1. Profile photo visibility (`profileVisibility`):
///    - 'everyone' / default: visible to all users.
///    - 'nobody': hidden from other users (shows default avatar).
///    - 'mutual' / 'mutuals': visible only if mutual follows.
///    - 'following' / 'people you follow': visible only to users in a following relationship.
/// 2. Message permission (`allowMessagesFrom`):
///    - 'everyone' / default: all users can message.
///    - 'nobody': no message option on profile for other users.
///    - 'mutual' / 'mutuals': message option only if mutual follows.
///    - 'following' / 'people you follow': message option only if in a following relationship.
class UserPrivacyPolicy {
  UserPrivacyPolicy._();

  static bool canViewProfilePhoto({
    required String? profileVisibility,
    required String? targetUserId,
    required String? targetUsername,
    bool isOwnProfile = false,
    bool isViewerFollowing = false,
    bool isTargetFollowing = false,
  }) {
    if (isOwnProfile) return true;

    final String vis = (profileVisibility ?? 'everyone').trim().toLowerCase();

    // 1. 'nobody': hide profile photo
    if (vis == 'nobody' || vis.contains('nobody')) {
      return false;
    }

    // 2. 'mutual' / 'mutuals': visible only if both follow each other
    if (vis.contains('mutual')) {
      final bool viewerFollowing = isViewerFollowing ||
          UserRelationshipCache.isFollowing(
            userId: targetUserId,
            username: targetUsername,
          );
      final bool targetFollowing = isTargetFollowing ||
          UserRelationshipCache.isFollowedBy(
            userId: targetUserId,
            username: targetUsername,
          );
      return viewerFollowing && targetFollowing;
    }

    // 3. 'following' / 'people you follow': visible if in a following relationship
    if (vis.contains('follow')) {
      final bool viewerFollowing = isViewerFollowing ||
          UserRelationshipCache.isFollowing(
            userId: targetUserId,
            username: targetUsername,
          );
      final bool targetFollowing = isTargetFollowing ||
          UserRelationshipCache.isFollowedBy(
            userId: targetUserId,
            username: targetUsername,
          );
      return viewerFollowing || targetFollowing;
    }

    // 4. 'everyone' / default: visible to all
    return true;
  }

  static bool canMessage({
    required String? allowMessagesFrom,
    required String? targetUserId,
    required String? targetUsername,
    bool isOwnProfile = false,
    bool isViewerFollowing = false,
    bool isTargetFollowing = false,
  }) {
    if (isOwnProfile) return false;

    final String rule = (allowMessagesFrom ?? 'everyone').trim().toLowerCase();

    // 1. 'nobody': no message option
    if (rule == 'nobody' || rule.contains('nobody')) {
      return false;
    }

    // 2. 'mutual' / 'mutuals': message option only if mutual follows
    if (rule.contains('mutual')) {
      final bool viewerFollowing = isViewerFollowing ||
          UserRelationshipCache.isFollowing(
            userId: targetUserId,
            username: targetUsername,
          );
      final bool targetFollowing = isTargetFollowing ||
          UserRelationshipCache.isFollowedBy(
            userId: targetUserId,
            username: targetUsername,
          );
      return viewerFollowing && targetFollowing;
    }

    // 3. 'following' / 'people you follow': message option if in following relationship
    if (rule.contains('follow')) {
      final bool viewerFollowing = isViewerFollowing ||
          UserRelationshipCache.isFollowing(
            userId: targetUserId,
            username: targetUsername,
          );
      final bool targetFollowing = isTargetFollowing ||
          UserRelationshipCache.isFollowedBy(
            userId: targetUserId,
            username: targetUsername,
          );
      return viewerFollowing || targetFollowing;
    }

    // 4. 'everyone' / default: message option enabled
    return true;
  }
}

/// Evaluates post visibility according to the backend schema:
/// - "EVERYONE": visible to all users (unless author is private).
/// - "FOLLOWERS": visible ONLY if current user follows the author OR is the author.
/// - "COMMUNITY_ONLY": visible within communities.
/// - other/private: visible only to author.
class PostVisibilityFilter {
  PostVisibilityFilter._();

  static bool canViewPost({
    required String? visibility,
    required String? authorId,
    required String? authorUsername,
    String? currentUserId,
    String? currentUsername,
    bool isGuest = false,
    bool isFollowing = false,
    bool isAuthorPrivate = false,
    bool isCommunityPost = false,
  }) {
    // 1. Author can ALWAYS see their own post (even if private or FOLLOWERS only)
    final bool isCurrentUserAuthor = !isGuest && (
      (currentUserId != null &&
          currentUserId.trim().isNotEmpty &&
          authorId != null &&
          authorId.trim().toLowerCase() == currentUserId.trim().toLowerCase()) ||
      (currentUsername != null &&
          currentUsername.trim().isNotEmpty &&
          authorUsername != null &&
          authorUsername.replaceAll('@', '').trim().toLowerCase() ==
              currentUsername.replaceAll('@', '').trim().toLowerCase())
    );

    if (isCurrentUserAuthor) {
      return true;
    }

    // 2. Private Account Enforcement:
    // If the author's account is private, it must NEVER be shown to non-followers or guests,
    // anywhere in the app (Feed, Discover, Hashtags, Search, Liked/Saved).
    final bool resolvedAuthorPrivate = isAuthorPrivate ||
        UserRelationshipCache.isUserPrivate(
          userId: authorId,
          username: authorUsername,
        );

    if (resolvedAuthorPrivate) {
      if (isGuest || currentUserId == null || currentUserId.trim().isEmpty) {
        return false;
      }
      final bool following = isFollowing ||
          UserRelationshipCache.isFollowing(
            userId: authorId,
            username: authorUsername,
          );
      if (!following) {
        return false;
      }
    }

    // 3. Community posts: visible to followers/public users browsing communities
    if (isCommunityPost) {
      return true;
    }

    final String vis = (visibility ?? 'EVERYONE').trim().toUpperCase();

    // 3. Everyone / Public / Default
    if (vis.isEmpty || vis == 'EVERYONE' || vis == 'PUBLIC') {
      return true;
    }

    // 4. Followers-only visibility
    if (vis == 'FOLLOWERS') {
      // Guests cannot see followers-only content
      if (isGuest || currentUserId == null || currentUserId.trim().isEmpty) {
        return false;
      }

      // If already confirmed following
      if (isFollowing) {
        return true;
      }

      // Check relationship cache
      return UserRelationshipCache.isFollowing(
        userId: authorId,
        username: authorUsername,
      );
    }

    // 5. Community-only visibility
    if (vis == 'COMMUNITY_ONLY') {
      return true;
    }

    return false;
  }
}

/// Centralized in-memory registry of deleted posts and reels.
/// Guarantees that once a post or reel is deleted in any part of the app
/// (feeds, profile, safety sheet, discover, hashtags), it is immediately
/// hidden everywhere and never resurrected by stale search/hashtag caches.
class DeletedPostsRegistry {
  DeletedPostsRegistry._();

  static final Set<String> _deletedIds = <String>{};

  static void markDeleted(String? id) {
    if (id == null) return;
    final String clean = id.trim();
    if (clean.isNotEmpty) {
      _deletedIds.add(clean);
    }
  }

  static bool isDeleted(String? id) {
    if (id == null) return false;
    final String clean = id.trim();
    if (clean.isEmpty) return false;
    return _deletedIds.contains(clean);
  }

  static Set<String> get allDeletedIds => Set<String>.unmodifiable(_deletedIds);

  static void clear() {
    _deletedIds.clear();
  }
}

class RegistryNotifier extends ChangeNotifier {
  void notify() => notifyListeners();
}

/// Centralized in-memory registry for exact post and reel comment counts.
/// Ensures that verified comment counts from CommentsBottomSheet or user actions
/// are preserved across feeds, profile tabs, and re-fetches, preventing
/// count mismatches or visual jumps.
class CommentCountRegistry {
  CommentCountRegistry._();

  static final Map<String, int> _counts = <String, int>{};
  static final RegistryNotifier notifier = RegistryNotifier();

  static void set(String? postId, int count) {
    if (postId == null) return;
    final String clean = postId.trim();
    if (clean.isNotEmpty) {
      _counts[clean] = count.clamp(0, 999999);
      notifier.notify();
    }
  }

  static int? get(String? postId) {
    if (postId == null) return null;
    final String clean = postId.trim();
    if (clean.isEmpty) return null;
    return _counts[clean];
  }

  static int getOr(String? postId, int fallback) {
    return get(postId) ?? fallback;
  }

  static int increment(String? postId) {
    if (postId == null) return 0;
    final String clean = postId.trim();
    if (clean.isNotEmpty) {
      final int cur = (_counts[clean] ?? 0) + 1;
      _counts[clean] = cur;
      notifier.notify();
      return cur;
    }
    return 0;
  }

  static void decrement(String? postId) {
    if (postId == null) return;
    final String clean = postId.trim();
    if (clean.isNotEmpty) {
      final int cur = _counts[clean] ?? 1;
      _counts[clean] = (cur - 1).clamp(0, 999999);
      notifier.notify();
    }
  }

  static void clear() {
    _counts.clear();
    notifier.notify();
  }

  /// Seeds count only if not already set by a user action. No notification.
  static void seedIfAbsent(String? postId, int count) {
    if (postId == null) return;
    final String clean = postId.trim();
    if (clean.isNotEmpty && !_counts.containsKey(clean)) {
      _counts[clean] = count.clamp(0, 999999);
    }
  }
}

/// Centralized in-memory registry for like and save states across the entire application.
/// Ensures that server state (likedByMe, savedByMe) is cleanly respected on fetch/reload,
/// and that any user like/unlike/save/unsave action immediately propagates to all screens
/// (Profile, Saved tab, Liked tab, Discover, Search, Chat, Other User Profile, Home Feeds)
/// with zero lag and without getting reverted by stale model fields.
class PostInteractionRegistry {
  PostInteractionRegistry._();

  static final Map<String, bool> _likedOverrides = <String, bool>{};
  static final Map<String, bool> _savedOverrides = <String, bool>{};
  static final Map<String, int> _likesCountOverrides = <String, int>{};
  static final Map<String, int> _viewsCountOverrides = <String, int>{};
  static final Set<String> _hiddenLikeCountIds = <String>{};
  static final Map<String, Set<String>> _idEquivalents = <String, Set<String>>{};
  static final RegistryNotifier notifier = RegistryNotifier();

  /// Links multiple IDs together so that any like/save/count on one immediately reflects on all.
  static void linkIds(Iterable<String?> ids) {
    final Set<String> cleanSet = <String>{};
    for (final String? id in ids) {
      if (id == null) continue;
      final String clean = id.trim().toLowerCase();
      if (clean.isNotEmpty) {
        cleanSet.add(clean);
        final String withoutMedia = clean.replaceAll(RegExp(r'^/+|^media/'), '');
        if (withoutMedia.isNotEmpty) cleanSet.add(withoutMedia);
        if (_idEquivalents.containsKey(clean)) {
          cleanSet.addAll(_idEquivalents[clean]!);
        }
        if (_idEquivalents.containsKey(withoutMedia)) {
          cleanSet.addAll(_idEquivalents[withoutMedia]!);
        }
      }
    }
    if (cleanSet.length < 2) return;
    for (final String id in cleanSet) {
      _idEquivalents[id] = cleanSet;
    }

    // Sync any existing state across all linked IDs
    bool? existingLiked;
    bool? existingSaved;
    int? existingLikesCount;
    int? existingViewsCount;

    for (final String id in cleanSet) {
      if (_likedOverrides[id] == true) {
        existingLiked = true;
      }
      if (_savedOverrides[id] == true) {
        existingSaved = true;
      }
      if (existingLikesCount == null && _likesCountOverrides.containsKey(id)) {
        existingLikesCount = _likesCountOverrides[id];
      } else if (existingLikesCount != null && _likesCountOverrides.containsKey(id)) {
        final int c = _likesCountOverrides[id]!;
        if (c > existingLikesCount) existingLikesCount = c;
      }
      if (existingViewsCount == null && _viewsCountOverrides.containsKey(id)) {
        existingViewsCount = _viewsCountOverrides[id];
      } else if (existingViewsCount != null && _viewsCountOverrides.containsKey(id)) {
        final int v = _viewsCountOverrides[id]!;
        if (v > existingViewsCount) existingViewsCount = v;
      }
    }

    for (final String id in cleanSet) {
      if (existingLiked != null) _likedOverrides[id] = existingLiked;
      if (existingSaved != null) _savedOverrides[id] = existingSaved;
      if (existingLikesCount != null) _likesCountOverrides[id] = existingLikesCount;
      if (existingViewsCount != null) _viewsCountOverrides[id] = existingViewsCount;
    }
  }

  /// Returns whether like count is explicitly hidden (null or hidden by author).
  static bool isLikeCountHidden(String? postId) {
    if (postId == null) return false;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return false;
    return _hiddenLikeCountIds.contains(clean);
  }

  /// Sets whether like count should be hidden for a post/reel.
  static void setLikeCountHidden(String? postId, bool hidden) {
    if (postId == null) return;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return;
    if (hidden) {
      _hiddenLikeCountIds.add(clean);
    } else {
      _hiddenLikeCountIds.remove(clean);
    }
  }

  /// Returns views count if recorded, otherwise [fallback].
  static int getViewsCount(String? postId, {int fallback = 0}) {
    if (postId == null) return fallback;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return fallback;
    if (_viewsCountOverrides.containsKey(clean)) {
      final int cached = _viewsCountOverrides[clean]!;
      return cached > fallback ? cached : fallback;
    }
    final String withoutMedia = clean.replaceAll(RegExp(r'^/+|^media/'), '');
    if (_viewsCountOverrides.containsKey(withoutMedia)) {
      final int cached = _viewsCountOverrides[withoutMedia]!;
      return cached > fallback ? cached : fallback;
    }
    final Set<String>? equivs = _idEquivalents[clean] ?? _idEquivalents[withoutMedia];
    if (equivs != null) {
      for (final String eq in equivs) {
        if (_viewsCountOverrides.containsKey(eq)) {
          final int cached = _viewsCountOverrides[eq]!;
          _viewsCountOverrides[clean] = cached;
          return cached > fallback ? cached : fallback;
        }
      }
    }
    return fallback;
  }

  /// Sets or updates views count for a post/reel.
  static void setViewsCount(String? postId, int views) {
    if (postId == null || views <= 0) return;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return;
    final String withoutMedia = clean.replaceAll(RegExp(r'^/+|^media/'), '');
    final Set<String> targetIds = <String>{
      clean,
      if (withoutMedia.isNotEmpty) withoutMedia,
      ...?_idEquivalents[clean],
      if (withoutMedia.isNotEmpty) ...?_idEquivalents[withoutMedia],
    };
    bool updated = false;
    for (final String id in targetIds) {
      final int existing = _viewsCountOverrides[id] ?? 0;
      if (views > existing) {
        _viewsCountOverrides[id] = views;
        updated = true;
      }
    }
    if (updated) {
      notifier.notify();
    }
  }

  /// Returns whether a post is liked. Prioritizes explicit session state,
  /// otherwise uses [fallback] from the model or backend response.
  static bool isLiked(String? postId, {bool fallback = false}) {
    if (postId == null) return fallback;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return fallback;
    if (_likedOverrides.containsKey(clean)) {
      return _likedOverrides[clean]!;
    }
    final String withoutMedia = clean.replaceAll(RegExp(r'^/+|^media/'), '');
    if (_likedOverrides.containsKey(withoutMedia)) {
      return _likedOverrides[withoutMedia]!;
    }
    final Set<String>? equivs = _idEquivalents[clean] ?? _idEquivalents[withoutMedia];
    if (equivs != null) {
      for (final String eq in equivs) {
        if (_likedOverrides.containsKey(eq)) {
          final bool val = _likedOverrides[eq]!;
          _likedOverrides[clean] = val;
          return val;
        }
      }
    }
    return fallback;
  }

  /// Returns whether a post is saved. Prioritizes explicit session state,
  /// otherwise uses [fallback] from the model or backend response.
  static bool isSaved(String? postId, {bool fallback = false}) {
    if (postId == null) return fallback;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return fallback;
    if (_savedOverrides.containsKey(clean)) {
      return _savedOverrides[clean]!;
    }
    final String withoutMedia = clean.replaceAll(RegExp(r'^/+|^media/'), '');
    if (_savedOverrides.containsKey(withoutMedia)) {
      return _savedOverrides[withoutMedia]!;
    }
    final Set<String>? equivs = _idEquivalents[clean] ?? _idEquivalents[withoutMedia];
    if (equivs != null) {
      for (final String eq in equivs) {
        if (_savedOverrides.containsKey(eq)) {
          final bool val = _savedOverrides[eq]!;
          _savedOverrides[clean] = val;
          return val;
        }
      }
    }
    return fallback;
  }

  /// Returns adjusted like count if modified in session, otherwise [fallback].
  static int getLikeCount(String? postId, {int fallback = 0}) {
    if (postId == null) return fallback;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return fallback;
    if (_likesCountOverrides.containsKey(clean)) {
      return _likesCountOverrides[clean]!;
    }
    final String withoutMedia = clean.replaceAll(RegExp(r'^/+|^media/'), '');
    if (_likesCountOverrides.containsKey(withoutMedia)) {
      return _likesCountOverrides[withoutMedia]!;
    }
    final Set<String>? equivs = _idEquivalents[clean] ?? _idEquivalents[withoutMedia];
    if (equivs != null) {
      for (final String eq in equivs) {
        if (_likesCountOverrides.containsKey(eq)) {
          final int val = _likesCountOverrides[eq]!;
          _likesCountOverrides[clean] = val;
          return val;
        }
      }
    }
    return fallback;
  }

  /// Explicitly sets the liked state and adjusts likes count.
  static void setLiked(String? postId, bool liked, {int? newCount, int? count}) {
    if (postId == null) return;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return;
    final String withoutMedia = clean.replaceAll(RegExp(r'^/+|^media/'), '');
    final Set<String> targetIds = <String>{
      clean,
      if (withoutMedia.isNotEmpty) withoutMedia,
      ...?_idEquivalents[clean],
      if (withoutMedia.isNotEmpty) ...?_idEquivalents[withoutMedia],
    };
    final int? targetCount = newCount ?? count;
    for (final String id in targetIds) {
      _likedOverrides[id] = liked;
      if (targetCount != null) {
        _likesCountOverrides[id] = targetCount.clamp(0, 9999999);
      } else {
        final int cur = _likesCountOverrides[id] ?? 0;
        _likesCountOverrides[id] = (liked ? cur + 1 : (cur > 0 ? cur - 1 : 0)).clamp(0, 9999999);
      }
    }
    notifier.notify();
  }

  /// Explicitly sets the saved state.
  static void setSaved(String? postId, bool saved) {
    if (postId == null) return;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return;
    final String withoutMedia = clean.replaceAll(RegExp(r'^/+|^media/'), '');
    final Set<String> targetIds = <String>{
      clean,
      if (withoutMedia.isNotEmpty) withoutMedia,
      ...?_idEquivalents[clean],
      if (withoutMedia.isNotEmpty) ...?_idEquivalents[withoutMedia],
    };
    for (final String id in targetIds) {
      _savedOverrides[id] = saved;
    }
    notifier.notify();
  }

  /// Registers post state directly from backend response (e.g., likedByMe, savedByMe).
  /// Always overwrites (use when you trust the server is authoritative, e.g. initial load).
  static void registerServerPost(
    String? postId, {
    required bool isLiked,
    required bool isSaved,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
  }) {
    if (postId == null) return;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return;
    final String withoutMedia = clean.replaceAll(RegExp(r'^/+|^media/'), '');
    final Set<String> targetIds = <String>{
      clean,
      if (withoutMedia.isNotEmpty) withoutMedia,
      ...?_idEquivalents[clean],
      if (withoutMedia.isNotEmpty) ...?_idEquivalents[withoutMedia],
    };
    for (final String id in targetIds) {
      _likedOverrides[id] = isLiked;
      _savedOverrides[id] = isSaved;
      if (likesCount != null) {
        _likesCountOverrides[id] = likesCount.clamp(0, 9999999);
      }
      if (commentsCount != null) {
        CommentCountRegistry.set(id, commentsCount);
      }
      if (viewsCount != null && viewsCount > 0) {
        setViewsCount(id, viewsCount);
      }
    }
    notifier.notify();
  }

  /// Seeds persisted user likes/saves loaded from SharedPreferences on startup.
  static void seedPersisted(
    String? postId, {
    bool? isLiked,
    bool? isSaved,
    int? likesCount,
  }) {
    if (postId == null) return;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return;
    if (isLiked != null && !_likedOverrides.containsKey(clean)) {
      if (isLiked) {
        _likedOverrides[clean] = true;
      }
    }
    if (isSaved != null && !_savedOverrides.containsKey(clean)) {
      if (isSaved) {
        _savedOverrides[clean] = true;
      }
    }
    if (likesCount != null && !_likesCountOverrides.containsKey(clean)) {
      _likesCountOverrides[clean] = likesCount.clamp(0, 9999999);
    }
  }

  /// Seeds post state from backend without overwriting existing user session overrides.
  /// Call this during feed parsing so counts/states are available immediately as fallbacks.
  static void seedFromServer(
    String? postId, {
    required bool isLiked,
    required bool isSaved,
    int? likesCount,
    int? commentsCount,
    int? viewsCount,
  }) {
    if (postId == null) return;
    final String clean = postId.trim().toLowerCase();
    if (clean.isEmpty) return;
    // Server confirms liked: only seed if user has not interacted with it in this session
    if (isLiked && !_likedOverrides.containsKey(clean)) {
      _likedOverrides[clean] = true;
    }
    if (isSaved && !_savedOverrides.containsKey(clean)) {
      _savedOverrides[clean] = true;
    }
    if (likesCount != null) {
      if (!_likesCountOverrides.containsKey(clean)) {
        _likesCountOverrides[clean] = likesCount.clamp(0, 9999999);
      } else if (likesCount > _likesCountOverrides[clean]!) {
        _likesCountOverrides[clean] = likesCount.clamp(0, 9999999);
      }
    }
    // If the post is marked liked, ensure like count is at least 1
    if (_likedOverrides[clean] == true && (_likesCountOverrides[clean] ?? 0) < 1) {
      _likesCountOverrides[clean] = 1;
    }
    if (commentsCount != null) {
      CommentCountRegistry.seedIfAbsent(clean, commentsCount);
    }
    if (viewsCount != null && viewsCount > 0) {
      final int existing = _viewsCountOverrides[clean] ?? 0;
      if (viewsCount > existing) {
        _viewsCountOverrides[clean] = viewsCount;
      }
    }
    // No notification needed — this is a background seed
  }

  static void clear() {
    _likedOverrides.clear();
    _savedOverrides.clear();
    _likesCountOverrides.clear();
    notifier.notify();
  }
}

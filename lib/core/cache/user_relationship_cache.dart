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

  /// Clears cache on logout.
  static void clear() {
    _followingUserIds.clear();
    _followingUsernames.clear();
    _followerUserIds.clear();
    _followerUsernames.clear();
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
    // 0. Community posts: Posts published to a community are visible to all users
    // browsing communities (both on "All Communities" and filtered community feeds).
    if (isCommunityPost) {
      return true;
    }

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
    // even if post-level visibility was set to 'EVERYONE'.
    if (isAuthorPrivate) {
      if (isGuest || currentUserId == null || currentUserId.trim().isEmpty) {
        return false;
      }
      if (isFollowing) {
        return true;
      }
      return UserRelationshipCache.isFollowing(
        userId: authorId,
        username: authorUsername,
      );
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
  static final RegistryNotifier notifier = RegistryNotifier();

  /// Returns whether like count is explicitly hidden (null or hidden by author).
  static bool isLikeCountHidden(String? postId) {
    if (postId == null) return false;
    final String clean = postId.trim();
    if (clean.isEmpty) return false;
    return _hiddenLikeCountIds.contains(clean);
  }

  /// Sets whether like count should be hidden for a post/reel.
  static void setLikeCountHidden(String? postId, bool hidden) {
    if (postId == null) return;
    final String clean = postId.trim();
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
    final String clean = postId.trim();
    if (clean.isEmpty) return fallback;
    if (_viewsCountOverrides.containsKey(clean)) {
      final int cached = _viewsCountOverrides[clean]!;
      return cached > fallback ? cached : fallback;
    }
    return fallback;
  }

  /// Sets or updates views count for a post/reel.
  static void setViewsCount(String? postId, int views) {
    if (postId == null || views <= 0) return;
    final String clean = postId.trim();
    if (clean.isEmpty) return;
    final int existing = _viewsCountOverrides[clean] ?? 0;
    if (views > existing) {
      _viewsCountOverrides[clean] = views;
      notifier.notify();
    }
  }

  /// Returns whether a post is liked. Prioritizes explicit session state,
  /// otherwise uses [fallback] from the model or backend response.
  static bool isLiked(String? postId, {bool fallback = false}) {
    if (postId == null) return fallback;
    final String clean = postId.trim();
    if (clean.isEmpty) return fallback;
    if (_likedOverrides.containsKey(clean)) {
      final bool val = _likedOverrides[clean]!;
      return val || fallback;
    }
    return fallback;
  }

  /// Returns whether a post is saved. Prioritizes explicit session state,
  /// otherwise uses [fallback] from the model or backend response.
  static bool isSaved(String? postId, {bool fallback = false}) {
    if (postId == null) return fallback;
    final String clean = postId.trim();
    if (clean.isEmpty) return fallback;
    if (_savedOverrides.containsKey(clean)) {
      final bool val = _savedOverrides[clean]!;
      return val || fallback;
    }
    return fallback;
  }

  /// Returns adjusted like count if modified in session, otherwise [fallback].
  static int getLikeCount(String? postId, {int fallback = 0}) {
    if (postId == null) return fallback;
    final String clean = postId.trim();
    if (clean.isEmpty) return fallback;
    if (_likesCountOverrides.containsKey(clean)) {
      return _likesCountOverrides[clean]!;
    }
    return fallback;
  }

  /// Explicitly sets the liked state and adjusts likes count.
  static void setLiked(String? postId, bool liked, {int? newCount, int? count}) {
    if (postId == null) return;
    final String clean = postId.trim();
    if (clean.isEmpty) return;
    _likedOverrides[clean] = liked;
    final int? targetCount = newCount ?? count;
    if (targetCount != null) {
      _likesCountOverrides[clean] = targetCount.clamp(0, 9999999);
    } else {
      final int cur = _likesCountOverrides[clean] ?? 0;
      _likesCountOverrides[clean] = (liked ? cur + 1 : (cur > 0 ? cur - 1 : 0)).clamp(0, 9999999);
    }
    notifier.notify();
  }

  /// Explicitly sets the saved state.
  static void setSaved(String? postId, bool saved) {
    if (postId == null) return;
    final String clean = postId.trim();
    if (clean.isEmpty) return;
    _savedOverrides[clean] = saved;
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
    final String clean = postId.trim();
    if (clean.isEmpty) return;
    if (isLiked) {
      _likedOverrides[clean] = true;
    }
    if (isSaved) {
      _savedOverrides[clean] = true;
    }
    if (likesCount != null) {
      _likesCountOverrides[clean] = likesCount.clamp(0, 9999999);
    }
    if (commentsCount != null) {
      CommentCountRegistry.set(clean, commentsCount);
    }
    if (viewsCount != null && viewsCount > 0) {
      setViewsCount(clean, viewsCount);
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
    final String clean = postId.trim();
    if (clean.isEmpty) return;
    if (isLiked != null) {
      if (isLiked) {
        _likedOverrides[clean] = true;
      }
    }
    if (isSaved != null) {
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
    final String clean = postId.trim();
    if (clean.isEmpty) return;
    // Server confirms liked: always update to true
    if (isLiked) {
      _likedOverrides[clean] = true;
    }
    if (isSaved) {
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

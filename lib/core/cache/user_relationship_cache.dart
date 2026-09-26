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

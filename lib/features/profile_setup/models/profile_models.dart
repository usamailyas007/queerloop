// Domain models returned by the Profile Setup API.

/// Full user profile as returned by GET /users/:id and PATCH /users/:id.
/// All fields are nullable because individual PATCH steps return partial data.
class UserProfile {
  const UserProfile({
    required this.id,
    this.email,
    this.displayName,
    this.username,
    this.bio,
    this.avatarUrl,
    this.pronouns,
    this.pronounsPrivate,
    this.interests,
    this.isPrivate,
    this.showInDiscover,
    this.allowMessagesFrom,
    this.allowCommentsFrom,
    this.hideMyLikes,
    this.profileVisibility,
    this.showActivityStatus,
    this.sendReadReceipts,
    this.notifyOnLike,
    this.notifyOnComment,
    this.notifyOnFollow,
    this.notifyOnMessage,
    this.notifyOnFollowRequests,
    this.notifyOnCommunityPosts,
    this.notifyOnAnnouncementsFeatures,
    this.notifyOnSafetyModerationUpdates,
    this.createdAt,
    this.updatedAt,
    this.followersCount,
    this.followingCount,
    this.postsCount,
    this.relationship,
    this.isFollowing,
    this.isPending,
    this.isBlocked,
    this.isMuted,
    this.isRestricted,
  });

  factory UserProfile.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> json =
        (rawJson['data'] is Map<String, dynamic>)
            ? rawJson['data'] as Map<String, dynamic>
            : ((rawJson['user'] is Map<String, dynamic>)
                ? rawJson['user'] as Map<String, dynamic>
                : ((rawJson['profile'] is Map<String, dynamic>)
                    ? rawJson['profile'] as Map<String, dynamic>
                    : rawJson));

    final dynamic rawFollowers = json['followersCount'] ??
        json['followerCount'] ??
        json['followers_count'] ??
        json['follower_count'] ??
        (json['_count'] is Map ? json['_count']['followers'] : null) ??
        (json['counts'] is Map ? json['counts']['followers'] : null) ??
        (json['stats'] is Map ? json['stats']['followers'] : null) ??
        (json['metrics'] is Map ? json['metrics']['followers'] : null) ??
        json['followers'];

    final dynamic rawFollowing = json['followingCount'] ??
        json['followingsCount'] ??
        json['following_count'] ??
        json['followings_count'] ??
        (json['_count'] is Map ? json['_count']['following'] ?? json['_count']['followings'] : null) ??
        (json['counts'] is Map ? json['counts']['following'] ?? json['counts']['followings'] : null) ??
        (json['stats'] is Map ? json['stats']['following'] ?? json['stats']['followings'] : null) ??
        (json['metrics'] is Map ? json['metrics']['following'] ?? json['metrics']['followings'] : null) ??
        json['following'] ??
        json['followings'];

    final dynamic rawPosts = json['postsCount'] ??
        json['postCount'] ??
        json['posts_count'] ??
        json['post_count'] ??
        (json['_count'] is Map ? json['_count']['posts'] : null) ??
        (json['counts'] is Map ? json['counts']['posts'] : null) ??
        (json['stats'] is Map ? json['stats']['posts'] : null) ??
        (json['metrics'] is Map ? json['metrics']['posts'] : null) ??
        json['posts'];

    return UserProfile(
      id: (json['userId'] ?? json['id'] ?? json['_id'] ?? '').toString(),
      email: json['email'] as String?,
      displayName: (json['displayName'] ?? json['name'] ?? json['fullName']) as String?,
      username: (json['username'] ?? json['handle']) as String?,
      bio: (json['bio'] ?? json['description'] ?? json['about']) as String?,
      avatarUrl: (json['avatarUrl'] ?? json['avatar'] ?? json['profilePic'] ?? json['image']) as String?,
      pronouns: (json['pronouns'] as List<dynamic>?)
          ?.map((dynamic e) => e as String)
          .toList(),
      pronounsPrivate: json['pronounsPrivate'] as bool?,
      interests: (json['interests'] as List<dynamic>?)
          ?.map((dynamic e) => e as String)
          .toList(),
      isPrivate: json['isPrivate'] as bool? ??
          (json['private'] as bool?) ??
          (json['privacySettings'] is Map
              ? (json['privacySettings']['isPrivate'] ??
                      json['privacySettings']['private']) as bool?
              : null) ??
          false,
      showInDiscover: json['showInDiscover'] as bool? ??
          json['show_in_discover'] as bool?,
      allowMessagesFrom: json['allowMessagesFrom'] as String? ??
          json['allow_messages_from'] as String? ??
          json['whoCanMessage'] as String? ??
          json['who_can_message'] as String? ??
          (json['privacySettings'] is Map
              ? (json['privacySettings']['allowMessagesFrom'] ??
                      json['privacySettings']['allow_messages_from'] ??
                      json['privacySettings']['whoCanMessage'])
                  as String?
              : null),
      allowCommentsFrom: json['allowCommentsFrom'] as String? ??
          json['allow_comments_from'] as String? ??
          json['whoCanComment'] as String? ??
          (json['privacySettings'] is Map
              ? (json['privacySettings']['allowCommentsFrom'] ??
                      json['privacySettings']['allow_comments_from'])
                  as String?
              : null),
      hideMyLikes: json['hideMyLikes'] as bool? ??
          json['hide_my_likes'] as bool? ??
          (json['privacySettings'] is Map
              ? (json['privacySettings']['hideMyLikes'] ??
                      json['privacySettings']['hide_my_likes'])
                  as bool?
              : null),
      profileVisibility: json['profileVisibility'] as String? ??
          json['profile_visibility'] as String? ??
          (json['privacySettings'] is Map
              ? (json['privacySettings']['profileVisibility'] ??
                      json['privacySettings']['profile_visibility'])
                  as String?
              : null),
      showActivityStatus: json['showActivityStatus'] as bool? ??
          json['show_activity_status'] as bool? ??
          (json['privacySettings'] is Map
              ? (json['privacySettings']['showActivityStatus'] ??
                      json['privacySettings']['show_activity_status'])
                  as bool?
              : null),
      sendReadReceipts: json['sendReadReceipts'] as bool? ??
          json['send_read_receipts'] as bool? ??
          (json['privacySettings'] is Map
              ? (json['privacySettings']['sendReadReceipts'] ??
                      json['privacySettings']['send_read_receipts'])
                  as bool?
              : null),
      notifyOnLike: json['notifyOnLike'] as bool? ??
          json['notify_on_like'] as bool? ??
          (json['notificationSettings'] is Map
              ? (json['notificationSettings']['notifyOnLike'] ??
                      json['notificationSettings']['notify_on_like'])
                  as bool?
              : null),
      notifyOnComment: json['notifyOnComment'] as bool? ??
          json['notify_on_comment'] as bool? ??
          (json['notificationSettings'] is Map
              ? (json['notificationSettings']['notifyOnComment'] ??
                      json['notificationSettings']['notify_on_comment'])
                  as bool?
              : null),
      notifyOnFollow: json['notifyOnFollow'] as bool? ??
          json['notify_on_follow'] as bool? ??
          (json['notificationSettings'] is Map
              ? (json['notificationSettings']['notifyOnFollow'] ??
                      json['notificationSettings']['notify_on_follow'])
                  as bool?
              : null),
      notifyOnMessage: json['notifyOnMessage'] as bool? ??
          json['notify_on_message'] as bool? ??
          json['directMessages'] as bool? ??
          json['direct_messages'] as bool? ??
          (json['notificationSettings'] is Map
              ? (json['notificationSettings']['notifyOnMessage'] ??
                      json['notificationSettings']['notify_on_message'] ??
                      json['notificationSettings']['directMessages'] ??
                      json['notificationSettings']['direct_messages'])
                  as bool?
              : null),
      notifyOnFollowRequests: json['notifyOnFollowRequests'] as bool? ??
          json['notify_on_follow_requests'] as bool? ??
          (json['notificationSettings'] is Map
              ? (json['notificationSettings']['notifyOnFollowRequests'] ??
                      json['notificationSettings']['notify_on_follow_requests'])
                  as bool?
              : null),
      notifyOnCommunityPosts: json['notifyOnCommunityPosts'] as bool? ??
          json['notify_on_community_posts'] as bool? ??
          (json['notificationSettings'] is Map
              ? (json['notificationSettings']['notifyOnCommunityPosts'] ??
                      json['notificationSettings']['notify_on_community_posts'])
                  as bool?
              : null),
      notifyOnAnnouncementsFeatures:
          json['notifyOnAnnouncementsFeatures'] as bool? ??
              json['notify_on_announcements_features'] as bool? ??
              (json['notificationSettings'] is Map
                  ? (json['notificationSettings']['notifyOnAnnouncementsFeatures'] ??
                          json['notificationSettings']['notify_on_announcements_features'])
                      as bool?
                  : null),
      notifyOnSafetyModerationUpdates:
          json['notifyOnSafetyModerationUpdates'] as bool? ??
              json['notify_on_safety_moderation_updates'] as bool? ??
              (json['notificationSettings'] is Map
                  ? (json['notificationSettings']['notifyOnSafetyModerationUpdates'] ??
                          json['notificationSettings']['notify_on_safety_moderation_updates'])
                      as bool?
                  : null),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      followersCount: rawFollowers is num
          ? rawFollowers.toInt()
          : (rawFollowers is List
              ? rawFollowers.length
              : int.tryParse(rawFollowers?.toString() ?? '0')),
      followingCount: rawFollowing is num
          ? rawFollowing.toInt()
          : (rawFollowing is List
              ? rawFollowing.length
              : int.tryParse(rawFollowing?.toString() ?? '0')),
      postsCount: rawPosts is num
          ? rawPosts.toInt()
          : (rawPosts is List
              ? rawPosts.length
              : int.tryParse(rawPosts?.toString() ?? '0')),
      relationship: (json['relationship'] ??
              json['relationshipStatus'] ??
              rawJson['relationship'])
          ?.toString(),
      isFollowing: json['isFollowing'] == true ||
          rawJson['isFollowing'] == true ||
          (json['relationship'] == 'following'),
      isPending: json['isPending'] == true ||
          rawJson['isPending'] == true ||
          (json['relationship'] == 'pending'),
      isBlocked: json['isBlocked'] == true ||
          rawJson['isBlocked'] == true ||
          (json['relationship'] == 'blocked'),
      isMuted: json['isMuted'] == true ||
          rawJson['isMuted'] == true ||
          (json['relationship'] == 'muted'),
      isRestricted: json['isRestricted'] == true ||
          rawJson['isRestricted'] == true ||
          json['restricted'] == true ||
          rawJson['restricted'] == true ||
          (json['relationship'] == 'restricted'),
    );
  }

  final String id;
  final String? email;
  final String? displayName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final List<String>? pronouns;
  final bool? pronounsPrivate;
  final List<String>? interests;
  final bool? isPrivate;
  final bool? showInDiscover;
  final String? allowMessagesFrom;
  final String? allowCommentsFrom;
  final bool? hideMyLikes;
  final String? profileVisibility;
  final bool? showActivityStatus;
  final bool? sendReadReceipts;
  final bool? notifyOnLike;
  final bool? notifyOnComment;
  final bool? notifyOnFollow;
  final bool? notifyOnMessage;
  final bool? notifyOnFollowRequests;
  final bool? notifyOnCommunityPosts;
  final bool? notifyOnAnnouncementsFeatures;
  final bool? notifyOnSafetyModerationUpdates;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? followersCount;
  final int? followingCount;
  final int? postsCount;
  final String? relationship;
  final bool? isFollowing;
  final bool? isPending;
  final bool? isBlocked;
  final bool? isMuted;
  final bool? isRestricted;

  String get formattedPronouns {
    if (pronounsPrivate == true || pronouns == null || pronouns!.isEmpty) {
      return '';
    }
    return pronouns!.join(' / ');
  }

  UserProfile copyWith({
    String? id,
    String? email,
    String? displayName,
    String? username,
    String? bio,
    String? avatarUrl,
    List<String>? pronouns,
    bool? pronounsPrivate,
    List<String>? interests,
    bool? isPrivate,
    bool? showInDiscover,
    String? allowMessagesFrom,
    String? allowCommentsFrom,
    bool? hideMyLikes,
    String? profileVisibility,
    bool? showActivityStatus,
    bool? sendReadReceipts,
    bool? notifyOnLike,
    bool? notifyOnComment,
    bool? notifyOnFollow,
    bool? notifyOnMessage,
    bool? notifyOnFollowRequests,
    bool? notifyOnCommunityPosts,
    bool? notifyOnAnnouncementsFeatures,
    bool? notifyOnSafetyModerationUpdates,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? followersCount,
    int? followingCount,
    int? postsCount,
    String? relationship,
    bool? isFollowing,
    bool? isPending,
    bool? isBlocked,
    bool? isMuted,
    bool? isRestricted,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pronouns: pronouns ?? this.pronouns,
      pronounsPrivate: pronounsPrivate ?? this.pronounsPrivate,
      interests: interests ?? this.interests,
      isPrivate: isPrivate ?? this.isPrivate,
      showInDiscover: showInDiscover ?? this.showInDiscover,
      allowMessagesFrom: allowMessagesFrom ?? this.allowMessagesFrom,
      allowCommentsFrom: allowCommentsFrom ?? this.allowCommentsFrom,
      hideMyLikes: hideMyLikes ?? this.hideMyLikes,
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showActivityStatus: showActivityStatus ?? this.showActivityStatus,
      sendReadReceipts: sendReadReceipts ?? this.sendReadReceipts,
      notifyOnLike: notifyOnLike ?? this.notifyOnLike,
      notifyOnComment: notifyOnComment ?? this.notifyOnComment,
      notifyOnFollow: notifyOnFollow ?? this.notifyOnFollow,
      notifyOnMessage: notifyOnMessage ?? this.notifyOnMessage,
      notifyOnFollowRequests:
          notifyOnFollowRequests ?? this.notifyOnFollowRequests,
      notifyOnCommunityPosts:
          notifyOnCommunityPosts ?? this.notifyOnCommunityPosts,
      notifyOnAnnouncementsFeatures:
          notifyOnAnnouncementsFeatures ?? this.notifyOnAnnouncementsFeatures,
      notifyOnSafetyModerationUpdates: notifyOnSafetyModerationUpdates ??
          this.notifyOnSafetyModerationUpdates,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      postsCount: postsCount ?? this.postsCount,
      relationship: relationship ?? this.relationship,
      isFollowing: isFollowing ?? this.isFollowing,
      isPending: isPending ?? this.isPending,
      isBlocked: isBlocked ?? this.isBlocked,
      isRestricted: isRestricted ?? this.isRestricted,
    );
  }

  /// Merge an incoming partial response into the current profile.
  /// Caller uses this to fold server responses into the accumulated state.
  UserProfile merge(UserProfile other) {
    return UserProfile(
      id: other.id.isNotEmpty ? other.id : id,
      email: other.email ?? email,
      displayName: other.displayName ?? displayName,
      username: other.username ?? username,
      bio: other.bio ?? bio,
      avatarUrl: other.avatarUrl ?? avatarUrl,
      pronouns: other.pronouns ?? pronouns,
      pronounsPrivate: other.pronounsPrivate ?? pronounsPrivate,
      interests: other.interests ?? interests,
      isPrivate: other.isPrivate ?? isPrivate,
      showInDiscover: other.showInDiscover ?? showInDiscover,
      allowMessagesFrom: other.allowMessagesFrom ?? allowMessagesFrom,
      allowCommentsFrom: other.allowCommentsFrom ?? allowCommentsFrom,
      hideMyLikes: other.hideMyLikes ?? hideMyLikes,
      profileVisibility: other.profileVisibility ?? profileVisibility,
      showActivityStatus: other.showActivityStatus ?? showActivityStatus,
      sendReadReceipts: other.sendReadReceipts ?? sendReadReceipts,
      notifyOnLike: other.notifyOnLike ?? notifyOnLike,
      notifyOnComment: other.notifyOnComment ?? notifyOnComment,
      notifyOnFollow: other.notifyOnFollow ?? notifyOnFollow,
      notifyOnMessage: other.notifyOnMessage ?? notifyOnMessage,
      notifyOnFollowRequests:
          other.notifyOnFollowRequests ?? notifyOnFollowRequests,
      notifyOnCommunityPosts:
          other.notifyOnCommunityPosts ?? notifyOnCommunityPosts,
      notifyOnAnnouncementsFeatures:
          other.notifyOnAnnouncementsFeatures ?? notifyOnAnnouncementsFeatures,
      notifyOnSafetyModerationUpdates:
          other.notifyOnSafetyModerationUpdates ??
              notifyOnSafetyModerationUpdates,
      createdAt: other.createdAt ?? createdAt,
      updatedAt: other.updatedAt ?? updatedAt,
      followersCount: other.followersCount ?? followersCount,
      followingCount: other.followingCount ?? followingCount,
      postsCount: other.postsCount ?? postsCount,
      relationship: other.relationship ?? relationship,
      isFollowing: other.isFollowing ?? isFollowing,
      isPending: other.isPending ?? isPending,
      isBlocked: other.isBlocked ?? isBlocked,
      isMuted: other.isMuted ?? isMuted,
    );
  }
}

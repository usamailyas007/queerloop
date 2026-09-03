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
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['userId'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      pronouns: (json['pronouns'] as List<dynamic>?)
          ?.map((dynamic e) => e as String)
          .toList(),
      pronounsPrivate: json['pronounsPrivate'] as bool?,
      interests: (json['interests'] as List<dynamic>?)
          ?.map((dynamic e) => e as String)
          .toList(),
      isPrivate: json['isPrivate'] as bool?,
      showInDiscover: json['showInDiscover'] as bool?,
      allowMessagesFrom: json['allowMessagesFrom'] as String?,
      allowCommentsFrom: json['allowCommentsFrom'] as String?,
      hideMyLikes: json['hideMyLikes'] as bool?,
      profileVisibility: json['profileVisibility'] as String?,
      showActivityStatus: json['showActivityStatus'] as bool?,
      sendReadReceipts: json['sendReadReceipts'] as bool?,
      notifyOnLike: json['notifyOnLike'] as bool?,
      notifyOnComment: json['notifyOnComment'] as bool?,
      notifyOnFollow: json['notifyOnFollow'] as bool?,
      notifyOnMessage: json['notifyOnMessage'] as bool?,
      notifyOnFollowRequests: json['notifyOnFollowRequests'] as bool?,
      notifyOnCommunityPosts: json['notifyOnCommunityPosts'] as bool?,
      notifyOnAnnouncementsFeatures:
          json['notifyOnAnnouncementsFeatures'] as bool?,
      notifyOnSafetyModerationUpdates:
          json['notifyOnSafetyModerationUpdates'] as bool?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
      followersCount: json['followersCount'] as int? ??
          json['followerCount'] as int?,
      followingCount: json['followingCount'] as int?,
      postsCount:
          json['postsCount'] as int? ?? json['postCount'] as int?,
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

  String get formattedPronouns {
    if (pronounsPrivate == true || pronouns == null || pronouns!.isEmpty) {
      return '';
    }
    return pronouns!.join(' · ');
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
    );
  }
}

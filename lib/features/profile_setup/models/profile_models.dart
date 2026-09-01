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
    this.hideMyLikes,
    this.profileVisibility,
    this.notifyOnLike,
    this.notifyOnComment,
    this.notifyOnFollow,
    this.notifyOnMessage,
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
      hideMyLikes: json['hideMyLikes'] as bool?,
      profileVisibility: json['profileVisibility'] as String?,
      notifyOnLike: json['notifyOnLike'] as bool?,
      notifyOnComment: json['notifyOnComment'] as bool?,
      notifyOnFollow: json['notifyOnFollow'] as bool?,
      notifyOnMessage: json['notifyOnMessage'] as bool?,
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
  final bool? hideMyLikes;
  final String? profileVisibility;
  final bool? notifyOnLike;
  final bool? notifyOnComment;
  final bool? notifyOnFollow;
  final bool? notifyOnMessage;
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
      hideMyLikes: other.hideMyLikes ?? hideMyLikes,
      profileVisibility: other.profileVisibility ?? profileVisibility,
      notifyOnLike: other.notifyOnLike ?? notifyOnLike,
      notifyOnComment: other.notifyOnComment ?? notifyOnComment,
      notifyOnFollow: other.notifyOnFollow ?? notifyOnFollow,
      notifyOnMessage: other.notifyOnMessage ?? notifyOnMessage,
      createdAt: other.createdAt ?? createdAt,
      updatedAt: other.updatedAt ?? updatedAt,
      followersCount: other.followersCount ?? followersCount,
      followingCount: other.followingCount ?? followingCount,
      postsCount: other.postsCount ?? postsCount,
    );
  }
}

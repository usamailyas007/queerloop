// Domain models returned by the Profile Setup API.

/// Full user profile as returned by GET /users/:id and PATCH /users/:id.
/// All fields are nullable because individual PATCH steps return partial data.
class UserProfile {
  const UserProfile({
    required this.id,
    this.displayName,
    this.username,
    this.bio,
    this.avatarUrl,
    this.pronouns,
    this.pronounsPrivate,
    this.isPrivate,
    this.showInDiscover,
    this.allowMessagesFrom,
    this.hideMyLikes,
    this.profileVisibility,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      displayName: json['displayName'] as String?,
      username: json['username'] as String?,
      bio: json['bio'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      pronouns: (json['pronouns'] as List<dynamic>?)
          ?.map((dynamic e) => e as String)
          .toList(),
      pronounsPrivate: json['pronounsPrivate'] as bool?,
      isPrivate: json['isPrivate'] as bool?,
      showInDiscover: json['showInDiscover'] as bool?,
      allowMessagesFrom: json['allowMessagesFrom'] as String?,
      hideMyLikes: json['hideMyLikes'] as bool?,
      profileVisibility: json['profileVisibility'] as String?,
    );
  }

  final String id;
  final String? displayName;
  final String? username;
  final String? bio;
  final String? avatarUrl;
  final List<String>? pronouns;
  final bool? pronounsPrivate;
  final bool? isPrivate;
  final bool? showInDiscover;
  final String? allowMessagesFrom;
  final bool? hideMyLikes;
  final String? profileVisibility;

  /// Merge an incoming partial response into the current profile.
  /// Caller uses this to fold server responses into the accumulated state.
  UserProfile merge(UserProfile other) {
    return UserProfile(
      id: other.id.isNotEmpty ? other.id : id,
      displayName: other.displayName ?? displayName,
      username: other.username ?? username,
      bio: other.bio ?? bio,
      avatarUrl: other.avatarUrl ?? avatarUrl,
      pronouns: other.pronouns ?? pronouns,
      pronounsPrivate: other.pronounsPrivate ?? pronounsPrivate,
      isPrivate: other.isPrivate ?? isPrivate,
      showInDiscover: other.showInDiscover ?? showInDiscover,
      allowMessagesFrom: other.allowMessagesFrom ?? allowMessagesFrom,
      hideMyLikes: other.hideMyLikes ?? hideMyLikes,
      profileVisibility: other.profileVisibility ?? profileVisibility,
    );
  }
}

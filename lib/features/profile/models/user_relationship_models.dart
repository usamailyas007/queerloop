// Domain models for User Relationships (Followers, Following, Requests, Blocked, Muted)

class UserRelationItem {
  const UserRelationItem({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.pronouns,
    this.bio,
    this.isFollowing = false,
    this.isPending = false,
  });

  factory UserRelationItem.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> json =
        (rawJson['user'] is Map<String, dynamic>)
            ? rawJson['user'] as Map<String, dynamic>
            : (rawJson['follower'] is Map<String, dynamic>)
                ? rawJson['follower'] as Map<String, dynamic>
                : (rawJson['following'] is Map<String, dynamic>)
                    ? rawJson['following'] as Map<String, dynamic>
                    : rawJson;

    final String id = (json['userId'] ??
            json['id'] ??
            json['_id'] ??
            rawJson['userId'] ??
            rawJson['id'] ??
            '')
        .toString();

    final String username = (json['username'] ??
            json['handle'] ??
            rawJson['username'] ??
            'user')
        .toString()
        .replaceAll('@', '');

    final String displayName = (json['displayName'] ??
            json['name'] ??
            json['fullName'] ??
            rawJson['displayName'] ??
            username)
        .toString();

    final String? avatar = (json['avatarUrl'] ??
            json['avatar'] ??
            json['profilePic'] ??
            rawJson['avatarUrl'] ??
            rawJson['avatar'])
        ?.toString();

    final dynamic rawPronouns = json['pronouns'] ?? rawJson['pronouns'];
    String? pronouns;
    if (rawPronouns is List && rawPronouns.isNotEmpty) {
      pronouns = rawPronouns.join(' / ');
    } else if (rawPronouns is String) {
      pronouns = rawPronouns;
    }

    final bool isFollowing = json['isFollowing'] == true ||
        rawJson['isFollowing'] == true ||
        json['is_following'] == true ||
        rawJson['is_following'] == true ||
        json['relationship'] == 'following' ||
        rawJson['relationship'] == 'following';

    final bool isPending = json['isPending'] == true ||
        rawJson['isPending'] == true ||
        json['is_pending'] == true ||
        rawJson['is_pending'] == true ||
        json['relationship'] == 'pending' ||
        rawJson['relationship'] == 'pending';

    return UserRelationItem(
      userId: id,
      username: username,
      displayName: displayName,
      avatarUrl: avatar,
      pronouns: pronouns,
      bio: json['bio'] as String? ?? rawJson['bio'] as String?,
      isFollowing: isFollowing,
      isPending: isPending,
    );
  }

  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? pronouns;
  final String? bio;
  final bool isFollowing;
  final bool isPending;

  UserRelationItem copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? avatarUrl,
    String? pronouns,
    String? bio,
    bool? isFollowing,
    bool? isPending,
  }) {
    return UserRelationItem(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      pronouns: pronouns ?? this.pronouns,
      bio: bio ?? this.bio,
      isFollowing: isFollowing ?? this.isFollowing,
      isPending: isPending ?? this.isPending,
    );
  }
}

class FollowRequestItem {
  const FollowRequestItem({
    required this.id,
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.createdAt,
  });

  factory FollowRequestItem.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> userMap =
        (rawJson['requester'] is Map<String, dynamic>)
            ? rawJson['requester'] as Map<String, dynamic>
            : (rawJson['user'] is Map<String, dynamic>)
                ? rawJson['user'] as Map<String, dynamic>
                : rawJson;

    final String reqId =
        (rawJson['id'] ?? rawJson['requestId'] ?? rawJson['_id'] ?? '').toString();

    final String userId = (userMap['userId'] ??
            userMap['id'] ??
            userMap['_id'] ??
            rawJson['requesterId'] ??
            reqId)
        .toString();

    final String username =
        (userMap['username'] ?? userMap['handle'] ?? rawJson['username'] ?? 'user')
            .toString()
            .replaceAll('@', '');

    final String displayName = (userMap['displayName'] ??
            userMap['name'] ??
            rawJson['displayName'] ??
            username)
        .toString();

    final String? avatar = (userMap['avatarUrl'] ??
            userMap['avatar'] ??
            rawJson['avatarUrl'] ??
            rawJson['avatar'])
        ?.toString();

    DateTime? createdAt;
    final dynamic rawDate = rawJson['createdAt'] ?? userMap['createdAt'];
    if (rawDate != null) {
      createdAt = DateTime.tryParse(rawDate.toString());
    }

    return FollowRequestItem(
      id: reqId.isNotEmpty ? reqId : userId,
      userId: userId,
      username: username,
      displayName: displayName,
      avatarUrl: avatar,
      createdAt: createdAt,
    );
  }

  final String id;
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final DateTime? createdAt;
}

class BlockedAccountItem {
  const BlockedAccountItem({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.blockedAt,
  });

  factory BlockedAccountItem.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> userMap =
        (rawJson['blockedUser'] is Map<String, dynamic>)
            ? rawJson['blockedUser'] as Map<String, dynamic>
            : (rawJson['user'] is Map<String, dynamic>)
                ? rawJson['user'] as Map<String, dynamic>
                : rawJson;

    final String userId = (userMap['userId'] ??
            userMap['id'] ??
            userMap['_id'] ??
            rawJson['blockedUserId'] ??
            rawJson['userId'] ??
            rawJson['id'] ??
            '')
        .toString();

    final String username =
        (userMap['username'] ?? userMap['handle'] ?? rawJson['username'] ?? 'user')
            .toString()
            .replaceAll('@', '');

    final String? displayName = (userMap['displayName'] ??
            userMap['name'] ??
            rawJson['displayName'])
        ?.toString();

    final String? avatar = (userMap['avatarUrl'] ??
            userMap['avatar'] ??
            rawJson['avatarUrl'] ??
            rawJson['avatar'])
        ?.toString();

    DateTime? blockedAt;
    final dynamic rawDate = rawJson['blockedAt'] ??
        rawJson['createdAt'] ??
        userMap['blockedAt'] ??
        userMap['createdAt'];
    if (rawDate != null) {
      blockedAt = DateTime.tryParse(rawDate.toString());
    }

    return BlockedAccountItem(
      userId: userId,
      username: username,
      displayName: displayName ?? username,
      avatarUrl: avatar,
      blockedAt: blockedAt,
    );
  }

  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? blockedAt;
}

class MutedAccountItem {
  const MutedAccountItem({
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.mutedUntil,
    this.scope,
  });

  factory MutedAccountItem.fromJson(Map<String, dynamic> rawJson) {
    final Map<String, dynamic> userMap =
        (rawJson['mutedUser'] is Map<String, dynamic>)
            ? rawJson['mutedUser'] as Map<String, dynamic>
            : (rawJson['user'] is Map<String, dynamic>)
                ? rawJson['user'] as Map<String, dynamic>
                : rawJson;

    final String userId = (userMap['userId'] ??
            userMap['id'] ??
            userMap['_id'] ??
            rawJson['mutedUserId'] ??
            rawJson['userId'] ??
            rawJson['id'] ??
            '')
        .toString();

    final String username =
        (userMap['username'] ?? userMap['handle'] ?? rawJson['username'] ?? 'user')
            .toString()
            .replaceAll('@', '');

    final String? displayName = (userMap['displayName'] ??
            userMap['name'] ??
            rawJson['displayName'])
        ?.toString();

    final String? avatar = (userMap['avatarUrl'] ??
            userMap['avatar'] ??
            rawJson['avatarUrl'] ??
            rawJson['avatar'])
        ?.toString();

    DateTime? mutedUntil;
    final dynamic rawUntil = rawJson['mutedUntil'] ??
        rawJson['expiresAt'] ??
        userMap['mutedUntil'];
    if (rawUntil != null) {
      mutedUntil = DateTime.tryParse(rawUntil.toString());
    }

    final String? scope =
        (rawJson['scope'] ?? userMap['scope'])?.toString();

    return MutedAccountItem(
      userId: userId,
      username: username,
      displayName: displayName ?? username,
      avatarUrl: avatar,
      mutedUntil: mutedUntil,
      scope: scope ?? 'posts',
    );
  }

  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final DateTime? mutedUntil;
  final String? scope;
}

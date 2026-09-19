// Data models for Discover / Search screens with resilient JSON parsing

import '../widgets/search_tag_tile.dart';

class DiscoverSearchResult {
  const DiscoverSearchResult({
    required this.imageAsset,
    this.id,
    this.authorId,
    this.viewCount,
    this.caption,
    this.authorUsername,
    this.authorAvatar,
    this.likesCount,
    this.commentsCount,
    this.type,
    this.communityId,
    this.isLiked = false,
  });

  final String imageAsset;
  final String? id;
  final String? authorId;
  final String? viewCount;
  final String? caption;
  final String? authorUsername;
  final String? authorAvatar;
  final int? likesCount;
  final int? commentsCount;
  final String? type;
  final String? communityId;
  final bool isLiked;

  factory DiscoverSearchResult.fromJson(Map<String, dynamic> json) {
    String thumb = '';
    if (json['mediaRefs'] is List && (json['mediaRefs'] as List).isNotEmpty) {
      thumb = (json['mediaRefs'] as List).first.toString();
    } else if (json['attachments'] is List && (json['attachments'] as List).isNotEmpty) {
      thumb = (json['attachments'] as List).first.toString();
    } else if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      thumb = (json['images'] as List).first.toString();
    } else if (json['thumbnailUrl'] != null) {
      thumb = json['thumbnailUrl'].toString();
    } else if (json['mediaUrl'] != null) {
      thumb = json['mediaUrl'].toString();
    } else if (json['imageUrl'] != null) {
      thumb = json['imageUrl'].toString();
    }

    final int views = json['viewsCount'] is num
        ? (json['viewsCount'] as num).toInt()
        : (int.tryParse(json['viewsCount']?.toString() ?? '') ?? 0);

    final String? resolvedAuthorId = (json['authorId'] ??
            json['author_id'] ??
            json['ownerId'] ??
            json['owner_id'] ??
            json['creatorId'] ??
            json['creator_id'] ??
            json['userId'] ??
            json['user_id'] ??
            (json['author'] is Map
                ? (json['author']['id'] ??
                    json['author']['_id'] ??
                    json['author']['userId'])
                : null) ??
            (json['user'] is Map
                ? (json['user']['id'] ??
                    json['user']['_id'] ??
                    json['user']['userId'])
                : null))
        ?.toString();

    return DiscoverSearchResult(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      authorId: resolvedAuthorId,
      imageAsset: thumb,
      viewCount: views > 1000
          ? '${(views / 1000).toStringAsFixed(1)}K'
          : (views > 0 ? '$views' : null),
      caption: (json['body'] ??
              json['caption'] ??
              json['content'] ??
              json['text'] ??
              '')
          .toString(),
      authorUsername: json['authorName']?.toString() ??
          json['author']?['username']?.toString(),
      authorAvatar: json['authorAvatar']?.toString() ??
          json['author']?['avatarUrl']?.toString(),
      likesCount:
          json['likesCount'] is num ? (json['likesCount'] as num).toInt() : null,
      commentsCount: json['commentsCount'] is num
          ? (json['commentsCount'] as num).toInt()
          : null,
      type: json['type']?.toString(),
      communityId: json['communityId']?.toString(),
      isLiked: json['isLiked'] == true,
    );
  }
}

class DiscoverPerson {
  const DiscoverPerson({
    required this.avatarAsset,
    required this.username,
    required this.pronouns,
    required this.followers,
    required this.isFollowing,
    this.id,
    this.displayName,
    this.bio,
  });

  final String avatarAsset;
  final String username;
  final String pronouns;
  final String followers;
  final bool isFollowing;
  final String? id;
  final String? displayName;
  final String? bio;

  factory DiscoverPerson.fromJson(Map<String, dynamic> json) {
    final String unameRaw = (json['username'] ??
            json['handle'] ??
            json['name'] ??
            'user')
        .toString();
    final String uname = unameRaw.startsWith('@') ? unameRaw : '@$unameRaw';
    final int fCount = json['followersCount'] is num
        ? (json['followersCount'] as num).toInt()
        : (int.tryParse(json['followersCount']?.toString() ??
                json['followerCount']?.toString() ??
                '') ??
            0);
    final String fStr = fCount > 1000
        ? '${(fCount / 1000).toStringAsFixed(1)}K followers'
        : '$fCount followers';

    final String? resolvedId = (json['id'] ??
            json['_id'] ??
            json['userId'] ??
            json['user_id'] ??
            json['participantId'] ??
            json['creatorId'] ??
            json['authorId'] ??
            (json['user'] is Map
                ? (json['user']['id'] ??
                    json['user']['_id'] ??
                    json['user']['userId'])
                : null) ??
            (json['profile'] is Map
                ? (json['profile']['id'] ??
                    json['profile']['_id'] ??
                    json['profile']['userId'])
                : null))
        ?.toString();

    return DiscoverPerson(
      id: resolvedId,
      avatarAsset: (json['avatarUrl'] ??
              json['avatar'] ??
              json['profilePicture'] ??
              '')
          .toString(),
      username: uname,
      displayName: json['displayName']?.toString() ?? json['name']?.toString(),
      pronouns: (json['pronouns'] ?? json['pronoun'] ?? '').toString(),
      followers: fStr,
      isFollowing: json['isFollowing'] == true,
      bio: json['bio']?.toString(),
    );
  }
}

class DiscoverCommunity {
  const DiscoverCommunity({
    required this.imageAsset,
    required this.name,
    required this.description,
    required this.isJoined,
    this.id,
    this.membersCount,
  });

  final String imageAsset;
  final String name;
  final String description;
  final bool isJoined;
  final String? id;
  final int? membersCount;

  factory DiscoverCommunity.fromJson(Map<String, dynamic> json) {
    return DiscoverCommunity(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      description: (json['description'] ?? json['desc'] ?? '').toString(),
      imageAsset: (json['imageUrl'] ??
              json['iconUrl'] ??
              json['avatarUrl'] ??
              json['image'] ??
              '')
          .toString(),
      isJoined: json['isJoined'] == true || json['joined'] == true,
      membersCount: json['membersCount'] is num
          ? (json['membersCount'] as num).toInt()
          : int.tryParse(json['membersCount']?.toString() ?? ''),
    );
  }
}

class DiscoverCreator {
  const DiscoverCreator({
    required this.avatarAsset,
    required this.username,
    this.id,
    this.displayName,
    this.followerCount,
    this.bio,
    this.isFollowing = false,
  });

  final String avatarAsset;
  final String username;
  final String? id;
  final String? displayName;
  final int? followerCount;
  final String? bio;
  final bool isFollowing;

  factory DiscoverCreator.fromJson(Map<String, dynamic> json) {
    final String unameRaw = (json['username'] ??
            json['handle'] ??
            json['name'] ??
            'creator')
        .toString();
    final String uname = unameRaw.startsWith('@') ? unameRaw : '@$unameRaw';
    final String avatar = (json['avatarUrl'] ??
            json['avatar'] ??
            json['profilePicture'] ??
            '')
        .toString();

    final String? resolvedId = (json['id'] ??
            json['_id'] ??
            json['userId'] ??
            json['user_id'] ??
            json['creatorId'] ??
            json['authorId'] ??
            json['participantId'] ??
            (json['user'] is Map
                ? (json['user']['id'] ??
                    json['user']['_id'] ??
                    json['user']['userId'])
                : null) ??
            (json['profile'] is Map
                ? (json['profile']['id'] ??
                    json['profile']['_id'] ??
                    json['profile']['userId'])
                : null))
        ?.toString();

    return DiscoverCreator(
      id: resolvedId,
      username: uname,
      displayName: json['displayName']?.toString() ?? json['name']?.toString(),
      avatarAsset: avatar,
      followerCount: json['followerCount'] is num
          ? (json['followerCount'] as num).toInt()
          : int.tryParse(json['followerCount']?.toString() ??
              json['followersCount']?.toString() ??
              ''),
      bio: json['bio']?.toString(),
      isFollowing: json['isFollowing'] == true,
    );
  }
}

class TrendingItem {
  const TrendingItem({
    required this.rank,
    required this.hashtag,
    required this.postsCount,
    required this.thumbnailAsset,
    this.id,
    this.tag,
  });

  final String rank;
  final String hashtag;
  final String postsCount;
  final String thumbnailAsset;
  final String? id;
  final String? tag;

  factory TrendingItem.fromJson(Map<String, dynamic> json, {int index = 0}) {
    final String tagRaw =
        (json['tag'] ?? json['hashtag'] ?? json['name'] ?? '').toString();
    final String hashtagStr = tagRaw.startsWith('#')
        ? tagRaw
        : (tagRaw.isNotEmpty ? '#$tagRaw' : '#trending');
    final int count = json['postsCount'] is num
        ? (json['postsCount'] as num).toInt()
        : (int.tryParse(json['postsCount']?.toString() ?? '') ??
            int.tryParse(json['count']?.toString() ?? '') ??
            0);
    final String countFormatted = count > 1000
        ? '${(count / 1000).toStringAsFixed(1)}K posts'
        : (count > 0 ? '$count posts' : 'Trending');
    final String rankStr = (index + 1).toString().padLeft(2, '0');
    final String thumb = (json['thumbnailUrl'] ??
            json['image'] ??
            json['thumbnailAsset'] ??
            '')
        .toString();

    return TrendingItem(
      rank: rankStr,
      hashtag: hashtagStr,
      postsCount: countFormatted,
      thumbnailAsset: thumb,
      id: json['id']?.toString() ?? json['_id']?.toString(),
      tag: tagRaw,
    );
  }
}

class RecentSearchItem {
  const RecentSearchItem({
    required this.id,
    required this.query,
    this.createdAt,
  });

  final String id;
  final String query;
  final String? createdAt;

  factory RecentSearchItem.fromJson(dynamic item) {
    if (item is String) {
      return RecentSearchItem(id: item, query: item);
    }
    if (item is Map<String, dynamic>) {
      final String idStr = (item['id'] ??
              item['_id'] ??
              item['recentSearchId'] ??
              item['query'] ??
              '')
          .toString();
      final String q = (item['query'] ??
              item['search'] ??
              item['term'] ??
              item['keyword'] ??
              '')
          .toString();
      return RecentSearchItem(
        id: idStr.isNotEmpty ? idStr : q,
        query: q.isNotEmpty ? q : idStr,
        createdAt: item['createdAt']?.toString(),
      );
    }
    return RecentSearchItem(id: item.toString(), query: item.toString());
  }
}

class MultiTabSearchResults {
  const MultiTabSearchResults({
    this.posts = const <DiscoverSearchResult>[],
    this.people = const <DiscoverPerson>[],
    this.tags = const <TagSearchResultItem>[],
    this.communities = const <DiscoverCommunity>[],
  });

  final List<DiscoverSearchResult> posts;
  final List<DiscoverPerson> people;
  final List<TagSearchResultItem> tags;
  final List<DiscoverCommunity> communities;

  bool get isEmpty =>
      posts.isEmpty && people.isEmpty && tags.isEmpty && communities.isEmpty;
  bool get isNotEmpty => !isEmpty;

  MultiTabSearchResults copyWith({
    List<DiscoverSearchResult>? posts,
    List<DiscoverPerson>? people,
    List<TagSearchResultItem>? tags,
    List<DiscoverCommunity>? communities,
  }) {
    return MultiTabSearchResults(
      posts: posts ?? this.posts,
      people: people ?? this.people,
      tags: tags ?? this.tags,
      communities: communities ?? this.communities,
    );
  }
}

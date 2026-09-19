// Data models for Discover / Search screens with resilient JSON parsing

import '../widgets/search_tag_tile.dart';

import '../../../core/theme/app_images.dart';
import '../../home/models/post_item_model.dart';
import '../../home/models/reel_item_model.dart';

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
    this.videoUrl,
    this.thumbnailUrl,
    this.mediaRefs = const <String>[],
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
  final String? videoUrl;
  final String? thumbnailUrl;
  final List<String> mediaRefs;

  bool get isReel {
    final String t = (type ?? '').toUpperCase().trim();
    if (t == 'VIDEO' || t == 'REEL' || t == 'REELS') return true;
    if (videoUrl != null && videoUrl!.trim().isNotEmpty) return true;
    final String img = imageAsset.trim();
    if (img.endsWith('.mp4') ||
        img.endsWith('.m3u8') ||
        img.contains('video') ||
        img.contains('/videos/')) {
      return true;
    }
    final String thumb = (thumbnailUrl ?? '').trim();
    if (thumb.endsWith('.mp4') ||
        thumb.endsWith('.m3u8') ||
        thumb.contains('video') ||
        thumb.contains('/videos/')) {
      return true;
    }
    return false;
  }

  DiscoverSearchResult copyWith({
    String? imageAsset,
    String? videoUrl,
    String? thumbnailUrl,
    String? id,
    String? authorId,
    String? viewCount,
    String? caption,
    String? authorUsername,
    String? authorAvatar,
    int? likesCount,
    int? commentsCount,
    String? type,
    String? communityId,
    bool? isLiked,
    List<String>? mediaRefs,
  }) {
    return DiscoverSearchResult(
      imageAsset: imageAsset ?? this.imageAsset,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      viewCount: viewCount ?? this.viewCount,
      caption: caption ?? this.caption,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      type: type ?? this.type,
      communityId: communityId ?? this.communityId,
      isLiked: isLiked ?? this.isLiked,
      mediaRefs: mediaRefs ?? this.mediaRefs,
    );
  }

  factory DiscoverSearchResult.fromPostItem(PostItemModel post) {
    String img = (post.postImageUrl ?? post.postImageAsset ?? '').trim();
    if (img.isEmpty) {
      final int hash = post.id.hashCode.abs() % 6;
      img = <String>[
        AppImages.searchResult1,
        AppImages.searchResult2,
        AppImages.searchResult3,
        AppImages.searchResult4,
        AppImages.searchResult5,
        AppImages.searchResult6,
      ][hash];
    }
    return DiscoverSearchResult(
      id: post.id,
      authorId: post.authorId,
      imageAsset: img,
      thumbnailUrl: img.isNotEmpty ? img : null,
      caption: post.content,
      authorUsername: post.username,
      authorAvatar: post.avatarAsset,
      likesCount: post.likesCount,
      commentsCount: post.commentsCount,
      type: 'PHOTO',
      communityId: post.communityId,
      isLiked: post.isLiked,
    );
  }

  factory DiscoverSearchResult.fromReelItem(ReelItemModel reel) {
    final String thumb = reel.thumbnailUrl ??
        (reel.videoUrl != null &&
                !reel.videoUrl!.endsWith('.mp4') &&
                !reel.videoUrl!.endsWith('.m3u8')
            ? reel.videoUrl!
            : '');
    return DiscoverSearchResult(
      id: reel.id,
      authorId: reel.authorId,
      imageAsset: thumb.isNotEmpty ? thumb : (reel.videoUrl ?? reel.videoAsset),
      videoUrl: reel.videoUrl,
      thumbnailUrl: reel.thumbnailUrl,
      caption: reel.caption,
      authorUsername: reel.username,
      authorAvatar: reel.avatarAsset,
      likesCount: reel.likesCount,
      commentsCount: reel.commentsCount,
      type: 'VIDEO',
      communityId: reel.communityId,
      isLiked: reel.isLiked,
    );
  }

  factory DiscoverSearchResult.fromJson(Map<String, dynamic> json) {
    String directUrl = '';
    String? resolvedVideoUrl;
    String? resolvedThumbnailUrl;

    if (json['videoUrl'] != null && json['videoUrl'].toString().trim().isNotEmpty) {
      resolvedVideoUrl = json['videoUrl'].toString().trim();
    }
    if (json['thumbnailUrl'] != null && json['thumbnailUrl'].toString().trim().isNotEmpty) {
      resolvedThumbnailUrl = json['thumbnailUrl'].toString().trim();
    }

    final List<String> extractedMediaRefs = <String>[];

    bool isHttpOrAsset(String s) =>
        s.startsWith('http://') || s.startsWith('https://') || s.startsWith('assets/');

    // Prioritize direct imageUrl or mediaUrl
    final dynamic rawImg = json['imageUrl'] ?? json['photoUrl'] ?? json['mediaUrl'];
    if (rawImg != null && rawImg.toString().trim().isNotEmpty) {
      final String s = rawImg.toString().trim();
      if (isHttpOrAsset(s)) {
        directUrl = s;
      }
    }

    // Inspect mediaRefs / attachments / images
    final dynamic rawMedia = json['mediaRefs'] ??
        json['mediarefs'] ??
        json['media'] ??
        json['images'] ??
        json['attachments'];

    if (rawMedia is List) {
      for (final dynamic item in rawMedia) {
        if (item is String && item.trim().isNotEmpty) {
          final String s = item.trim();
          extractedMediaRefs.add(s);
          if (directUrl.isEmpty && isHttpOrAsset(s)) {
            directUrl = s;
          }
        } else if (item is Map) {
          final dynamic u = item['url'] ??
              item['downloadUrl'] ??
              item['mediaUrl'] ??
              item['thumbnailUrl'];
          final dynamic thumb = item['thumbnailUrl'];
          if (u != null && isHttpOrAsset(u.toString().trim())) {
            if (directUrl.isEmpty) directUrl = u.toString().trim();
            extractedMediaRefs.add(u.toString().trim());
          }
          if (thumb != null && isHttpOrAsset(thumb.toString().trim())) {
            resolvedThumbnailUrl ??= thumb.toString().trim();
          }
        }
      }
    } else if (rawMedia is String && rawMedia.trim().isNotEmpty) {
      final String s = rawMedia.trim();
      extractedMediaRefs.add(s);
      if (directUrl.isEmpty && isHttpOrAsset(s)) {
        directUrl = s;
      }
    }

    if (directUrl.isEmpty && resolvedThumbnailUrl != null && resolvedThumbnailUrl.isNotEmpty) {
      directUrl = resolvedThumbnailUrl;
    }

    if (directUrl.isEmpty && extractedMediaRefs.isNotEmpty) {
      directUrl = extractedMediaRefs.first;
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

    final String? resolvedAuthorUsername = json['authorName']?.toString() ??
        json['authorUsername']?.toString() ??
        (json['author'] is Map
            ? (json['author']['username'] ??
                json['author']['name'] ??
                json['author']['displayName'])
            : null)?.toString() ??
        (json['user'] is Map
            ? (json['user']['username'] ??
                json['user']['name'] ??
                json['user']['displayName'])
            : null)?.toString();

    final String? resolvedAuthorAvatar = json['authorAvatar']?.toString() ??
        json['authorAvatarUrl']?.toString() ??
        json['avatarUrl']?.toString() ??
        (json['author'] is Map
            ? (json['author']['avatarUrl'] ??
                json['author']['avatar'] ??
                json['author']['profilePicture'])
            : null)?.toString() ??
        (json['user'] is Map
            ? (json['user']['avatarUrl'] ??
                json['user']['avatar'] ??
                json['user']['profilePicture'])
            : null)?.toString();

    final String postType = (json['type'] ?? json['postType'] ?? '').toString().toUpperCase();

    if (postType == 'VIDEO' && resolvedVideoUrl == null && directUrl.startsWith('http')) {
      if (directUrl.endsWith('.mp4') || directUrl.endsWith('.m3u8') || directUrl.contains('video')) {
        resolvedVideoUrl = directUrl;
      }
    }

    if (postType != 'VIDEO' && directUrl.isEmpty) {
      final String safeId = (json['id'] ?? json['_id'] ?? '').toString();
      final int hash = safeId.hashCode.abs() % 6;
      directUrl = <String>[
        AppImages.searchResult1,
        AppImages.searchResult2,
        AppImages.searchResult3,
        AppImages.searchResult4,
        AppImages.searchResult5,
        AppImages.searchResult6,
      ][hash];
    }

    return DiscoverSearchResult(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      authorId: resolvedAuthorId,
      imageAsset: directUrl,
      videoUrl: resolvedVideoUrl,
      thumbnailUrl: resolvedThumbnailUrl,
      mediaRefs: extractedMediaRefs,
      viewCount: views > 1000
          ? '${(views / 1000).toStringAsFixed(1)}K'
          : (views > 0 ? '$views' : null),
      caption: (json['body'] ??
              json['caption'] ??
              json['content'] ??
              json['text'] ??
              '')
          .toString(),
      authorUsername: resolvedAuthorUsername,
      authorAvatar: resolvedAuthorAvatar,
      likesCount:
          json['likesCount'] is num ? (json['likesCount'] as num).toInt() : null,
      commentsCount: json['commentsCount'] is num
          ? (json['commentsCount'] as num).toInt()
          : null,
      type: postType.isNotEmpty ? postType : null,
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

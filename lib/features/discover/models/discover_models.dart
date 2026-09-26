// Data models for Discover / Search screens with resilient JSON parsing

import '../widgets/search_tag_tile.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_images.dart';
import '../../home/models/post_item_model.dart';
import '../../home/models/reel_item_model.dart';

class DiscoverSearchResult {
  const DiscoverSearchResult({
    required this.imageAsset,
    this.id,
    this.refId,
    this.authorId,
    this.viewCount,
    this.viewsCount = 0,
    this.caption,
    this.authorUsername,
    this.authorAvatar,
    this.likesCount,
    this.commentsCount,
    this.type,
    this.communityId,
    this.isLiked = false,
    this.isSaved = false,
    this.videoUrl,
    this.thumbnailUrl,
    this.mediaRefs = const <String>[],
    this.visibility,
    this.allowComments = true,
    this.allowCommentsFrom = 'everyone',
    this.isAuthorPrivate = false,
  });

  final String imageAsset;
  final String? id;
  final String? refId;
  final String? authorId;
  final String? viewCount;
  final int viewsCount;
  final String? caption;
  final String? authorUsername;
  final String? authorAvatar;
  final int? likesCount;
  final int? commentsCount;
  final String? type;
  final String? communityId;
  final bool isLiked;
  final bool isSaved;
  final String? videoUrl;
  final String? thumbnailUrl;
  final List<String> mediaRefs;
  final String? visibility;
  final bool allowComments;
  final String allowCommentsFrom;
  final bool isAuthorPrivate;

  bool get isReel {
    final String t = (type ?? '').toUpperCase().trim();
    if (t == 'VIDEO' || t == 'REEL' || t == 'REELS') return true;
    if (t == 'PHOTO' || t == 'TEXT') return false;
    if (videoUrl != null && videoUrl!.trim().isNotEmpty) return true;
    final String img = imageAsset.trim();
    if (img.endsWith('.mp4') ||
        img.endsWith('.m3u8') ||
        img.contains('/videos/') ||
        img.contains('video')) {
      return true;
    }
    final String thumb = (thumbnailUrl ?? '').trim();
    if (thumb.endsWith('.mp4') ||
        thumb.endsWith('.m3u8') ||
        thumb.contains('/videos/') ||
        thumb.contains('video')) {
      return true;
    }
    return false;
  }

  DiscoverSearchResult copyWith({
    String? imageAsset,
    String? videoUrl,
    String? thumbnailUrl,
    String? id,
    String? refId,
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
    bool? isSaved,
    List<String>? mediaRefs,
    String? visibility,
    int? viewsCount,
    bool? allowComments,
    String? allowCommentsFrom,
    bool? isAuthorPrivate,
  }) {
    return DiscoverSearchResult(
      imageAsset: imageAsset ?? this.imageAsset,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      id: id ?? this.id,
      refId: refId ?? this.refId,
      authorId: authorId ?? this.authorId,
      viewCount: viewCount ?? this.viewCount,
      viewsCount: viewsCount ?? this.viewsCount,
      caption: caption ?? this.caption,
      authorUsername: authorUsername ?? this.authorUsername,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      type: type ?? this.type,
      communityId: communityId ?? this.communityId,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      mediaRefs: mediaRefs ?? this.mediaRefs,
      visibility: visibility ?? this.visibility,
      allowComments: allowComments ?? this.allowComments,
      allowCommentsFrom: allowCommentsFrom ?? this.allowCommentsFrom,
      isAuthorPrivate: isAuthorPrivate ?? this.isAuthorPrivate,
    );
  }

  factory DiscoverSearchResult.fromPostItem(PostItemModel post) {
    final String img = (post.postImageUrl ?? post.postImageAsset ?? '').trim();
    return DiscoverSearchResult(
      id: post.id,
      refId: null,
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
      isSaved: post.isSaved,
      visibility: post.visibility,
    );
  }

  factory DiscoverSearchResult.fromReelItem(ReelItemModel reel) {
    String thumb = (reel.thumbnailUrl != null && reel.thumbnailUrl!.isNotEmpty)
        ? reel.thumbnailUrl!
        : '';
    if (thumb.isEmpty && reel.videoUrl != null && reel.videoUrl!.contains('/videos/processed/')) {
      thumb = reel.videoUrl!.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg');
    }
    if (thumb.contains('/videos/processed/') && thumb.endsWith('/thumbnail.jpg')) {
      thumb = thumb.replaceAll('/thumbnail.jpg', '/thumb.0000000.jpg');
    }
    return DiscoverSearchResult(
      id: reel.id,
      refId: null,
      authorId: reel.authorId,
      imageAsset: thumb.isNotEmpty ? thumb : (reel.videoUrl ?? reel.videoAsset),
      videoUrl: reel.videoUrl,
      thumbnailUrl: thumb.isNotEmpty ? thumb : null,
      caption: reel.caption,
      authorUsername: reel.username,
      authorAvatar: reel.avatarAsset,
      likesCount: reel.likesCount,
      commentsCount: reel.commentsCount,
      type: 'VIDEO',
      communityId: reel.communityId,
      isLiked: reel.isLiked,
      isSaved: reel.isSaved,
      visibility: reel.visibility,
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

    // Prioritize direct imageUrl or mediaUrl — also check postImageUrl (backend field)
    final dynamic rawImg = json['postImageUrl'] ??
        json['imageUrl'] ??
        json['photoUrl'] ??
        json['mediaUrl'] ??
        json['postThumbnailUrl'] ??
        json['thumbnailAsset'];
    if (rawImg != null && rawImg.toString().trim().isNotEmpty) {
      final String s = rawImg.toString().trim();
      if (isHttpOrAsset(s)) {
        directUrl = s;
        // If it looks like an image, use as thumbnail
        if (!s.endsWith('.mp4') && !s.endsWith('.m3u8') && !s.contains('/videos/processed/')) {
          resolvedThumbnailUrl ??= s;
        }
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

    // 1. Resolve refId (media reference ID from search API)
    final String? refId = (json['refId'] ??
            json['ref_id'] ??
            json['mediaRef'] ??
            json['mediaId'])
        ?.toString()
        .trim();

    // 2. Resolve Author details
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

    // 3. Resolve postType: prioritize postType ('PHOTO', 'VIDEO', 'TEXT') over generic type ('post')
    final String rawPostType =
        (json['postType'] ?? '').toString().toUpperCase().trim();
    final String rawType =
        (json['type'] ?? '').toString().toUpperCase().trim();
    String postType = rawPostType.isNotEmpty
        ? rawPostType
        : (rawType != 'POST' && rawType.isNotEmpty ? rawType : '');

    final String? primaryMediaRef = (refId != null && refId.isNotEmpty)
        ? refId
        : (extractedMediaRefs.isNotEmpty ? extractedMediaRefs.first : null);

    // 4. Resolve CDN URLs from primaryMediaRef
    if (primaryMediaRef != null && primaryMediaRef.isNotEmpty) {
      final String cleanRef = primaryMediaRef
          .replaceAll(RegExp(r'^/+'), '')
          .replaceAll(RegExp(r'^media/'), '');

      final bool isExplicitVideo = postType == 'VIDEO' ||
          postType == 'REEL' ||
          cleanRef.endsWith('.mp4') ||
          cleanRef.endsWith('.m3u8') ||
          cleanRef.contains('video') ||
          cleanRef.contains('/videos/');

      if (isExplicitVideo) {
        postType = 'VIDEO';
        resolvedVideoUrl ??=
            '${AppConfig.cdnUrl}/videos/processed/$cleanRef/master.m3u8';
        resolvedThumbnailUrl ??=
            '${AppConfig.cdnUrl}/videos/processed/$cleanRef/thumb.0000000.jpg';
        directUrl = resolvedThumbnailUrl;
        if (!extractedMediaRefs.contains(cleanRef)) {
          extractedMediaRefs.add(cleanRef);
        }
      } else {
        if (postType.isEmpty || postType == 'POST') {
          postType = 'PHOTO';
        }
        if (primaryMediaRef.startsWith('http://') ||
            primaryMediaRef.startsWith('https://')) {
          directUrl = primaryMediaRef;
        } else if (resolvedAuthorId != null && resolvedAuthorId.isNotEmpty) {
          directUrl =
              '${AppConfig.cdnUrl}/images/original/$resolvedAuthorId/$cleanRef.jpg';
        } else {
          directUrl = '${AppConfig.cdnUrl}/images/original/$cleanRef.jpg';
        }
        resolvedThumbnailUrl ??= directUrl;
        if (!extractedMediaRefs.contains(cleanRef)) {
          extractedMediaRefs.add(cleanRef);
        }
      }
    } else if (directUrl.isNotEmpty &&
        (directUrl.startsWith('http://') || directUrl.startsWith('https://'))) {
      final bool isVid = directUrl.endsWith('.mp4') ||
          directUrl.endsWith('.m3u8') ||
          directUrl.contains('/videos/');
      if (isVid) {
        postType = 'VIDEO';
        resolvedVideoUrl ??= directUrl;
      } else if (postType.isEmpty || postType == 'POST') {
        postType = 'PHOTO';
      }
    } else {
      // Pure text post with no attached media
      postType = 'TEXT';
      directUrl = '';
      resolvedThumbnailUrl = null;
      resolvedVideoUrl = null;
    }

    if (postType == 'VIDEO' &&
        resolvedVideoUrl == null &&
        directUrl.startsWith('http')) {
      if (directUrl.endsWith('.mp4') ||
          directUrl.endsWith('.m3u8') ||
          directUrl.contains('video')) {
        resolvedVideoUrl = directUrl;
      }
    }

    // 5. Views Count parsing (strictly from API)
    final dynamic rawViews = json['viewsCount'] ??
        json['viewCount'] ??
        json['views'] ??
        json['playCount'] ??
        json['playsCount'] ??
        json['plays'] ??
        (json['_count'] is Map
            ? (json['_count']['views'] ?? json['_count']['plays'])
            : null);
    final int views = rawViews is num
        ? rawViews.toInt()
        : (int.tryParse(rawViews?.toString() ?? '') ?? 0);

    final String? formattedViews = views >= 1000000
        ? '${(views / 1000000).toStringAsFixed(1)}M'
        : (views >= 1000
            ? '${(views / 1000).toStringAsFixed(1)}K'
            : (views > 0 ? '$views' : (rawViews != null ? '0' : null)));

    return DiscoverSearchResult(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      refId: refId,
      authorId: resolvedAuthorId,
      imageAsset: directUrl,
      videoUrl: resolvedVideoUrl,
      thumbnailUrl: resolvedThumbnailUrl,
      mediaRefs: extractedMediaRefs,
      viewCount: formattedViews,
      viewsCount: views,
      caption: (json['body'] ??
              json['caption'] ??
              json['content'] ??
              json['text'] ??
              '')
          .toString(),
      authorUsername: resolvedAuthorUsername,
      authorAvatar: resolvedAuthorAvatar,
      likesCount: (json['likesCount'] is num)
          ? (json['likesCount'] as num).toInt()
          : ((json['likeCount'] is num)
              ? (json['likeCount'] as num).toInt()
              : (json['likes'] is num ? (json['likes'] as num).toInt() : null)),
      commentsCount: json['commentsCount'] is num
          ? (json['commentsCount'] as num).toInt()
          : null,
      type: postType.isNotEmpty ? postType : null,
      communityId: json['communityId']?.toString(),
      isLiked: () {
        final dynamic raw = json['isLiked'] ??
            json['is_liked'] ??
            json['userLiked'] ??
            json['user_liked'] ??
            json['liked'] ??
            json['hasLiked'] ??
            json['has_liked'] ??
            json['likedByMe'] ??
            json['liked_by_me'] ??
            json['isLikedByMe'] ??
            json['is_liked_by_me'] ??
            (json['viewer'] is Map
                ? (json['viewer']['isLiked'] ?? json['viewer']['liked'])
                : null) ??
            (json['metadata'] is Map
                ? (json['metadata']['isLiked'] ??
                    json['metadata']['is_liked'])
                : null);
        return raw == true || raw == 1 || raw == 'true';
      }(),
      isSaved: () {
        final dynamic raw = json['isSaved'] ??
            json['is_saved'] ??
            json['userSaved'] ??
            json['user_saved'] ??
            json['saved'] ??
            json['hasSaved'] ??
            json['has_saved'] ??
            json['savedByMe'] ??
            json['saved_by_me'] ??
            json['isSavedByMe'] ??
            json['is_saved_by_me'] ??
            (json['viewer'] is Map
                ? (json['viewer']['isSaved'] ?? json['viewer']['saved'])
                : null) ??
            (json['metadata'] is Map
                ? (json['metadata']['isSaved'] ??
                    json['metadata']['is_saved'])
                : null);
        return raw == true || raw == 1 || raw == 'true';
      }(),
      visibility: json['visibility']?.toString(),
      allowComments: (json['allowComments'] ?? json['allowComment']) as bool? ?? true,
      allowCommentsFrom: ((json['allowCommentsFrom'] ??
                  json['allow_comments_from'] ??
                  (json['author'] is Map
                      ? (json['author']['allowCommentsFrom'] ??
                          json['author']['allow_comments_from'])
                      : null) ??
                  (json['user'] is Map
                      ? (json['user']['allowCommentsFrom'] ??
                          json['user']['allow_comments_from'])
                      : null) ??
                  'everyone')
              .toString())
          .trim()
          .toLowerCase(),
      isAuthorPrivate: (json['author'] is Map
              ? (json['author']['isPrivate'] ?? json['author']['is_private'])
              : null) ==
          true ||
          (json['user'] is Map
              ? (json['user']['isPrivate'] ?? json['user']['is_private'])
              : null) ==
          true ||
          json['isPrivate'] == true ||
          json['is_private'] == true ||
          json['isAuthorPrivate'] == true,
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
    final String name = (json['name'] ?? json['title'] ?? '').toString();
    final String rawImage = (json['imageUrl'] ??
            json['iconUrl'] ??
            json['avatarUrl'] ??
            json['avatarAsset'] ??
            json['image'] ??
            '')
        .toString();
    final String image = rawImage.isNotEmpty ? rawImage : _matchAvatarAsset(name);

    return DiscoverCommunity(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      name: name,
      description: (json['description'] ?? json['desc'] ?? '').toString(),
      imageAsset: image,
      isJoined: json['isJoined'] == true || json['joined'] == true,
      membersCount: json['membersCount'] is num
          ? (json['membersCount'] as num).toInt()
          : int.tryParse(json['membersCount']?.toString() ?? ''),
    );
  }

  static String _matchAvatarAsset(String name) {
    final String lower = name.toLowerCase().trim();
    if (lower.contains('lesbian')) return AppImages.lesbian;
    if (lower.contains('gay')) return AppImages.gay;
    if (lower.contains('bi')) return AppImages.bisexual;
    if (lower.contains('transgender') || lower == 'trans') {
      return AppImages.transgender;
    }
    if (lower.contains('non-binary') || lower.contains('nonbinary')) {
      return AppImages.nonBinary;
    }
    if (lower.contains('queer')) return AppImages.queer;
    if (lower.contains('pansexual') || lower.contains('pan')) {
      return AppImages.pansexual;
    }
    if (lower.contains('asexual') || lower.contains('ace')) {
      return AppImages.asexual;
    }
    if (lower.contains('aromantic') || lower.contains('aro')) {
      return AppImages.aromantic;
    }
    if (lower.contains('intersex')) return AppImages.intersex;
    if (lower.contains('genderfluid')) return AppImages.genderfluid;
    if (lower.contains('transmasc')) return AppImages.transmasc;
    if (lower.contains('transfemme')) return AppImages.transfemme;
    if (lower.contains('allies') || lower.contains('ally')) {
      return AppImages.allies;
    }
    return AppImages.queer;
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

  TrendingItem copyWith({
    String? rank,
    String? hashtag,
    String? postsCount,
    String? thumbnailAsset,
    String? id,
    String? tag,
  }) {
    return TrendingItem(
      rank: rank ?? this.rank,
      hashtag: hashtag ?? this.hashtag,
      postsCount: postsCount ?? this.postsCount,
      thumbnailAsset: thumbnailAsset ?? this.thumbnailAsset,
      id: id ?? this.id,
      tag: tag ?? this.tag,
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
    this.reels = const <DiscoverSearchResult>[],
    this.people = const <DiscoverPerson>[],
    this.tags = const <TagSearchResultItem>[],
    this.communities = const <DiscoverCommunity>[],
  });

  final List<DiscoverSearchResult> posts;
  final List<DiscoverSearchResult> reels;
  final List<DiscoverPerson> people;
  final List<TagSearchResultItem> tags;
  final List<DiscoverCommunity> communities;

  bool get isEmpty =>
      posts.isEmpty &&
      reels.isEmpty &&
      people.isEmpty &&
      tags.isEmpty &&
      communities.isEmpty;
  bool get isNotEmpty => !isEmpty;

  MultiTabSearchResults copyWith({
    List<DiscoverSearchResult>? posts,
    List<DiscoverSearchResult>? reels,
    List<DiscoverPerson>? people,
    List<TagSearchResultItem>? tags,
    List<DiscoverCommunity>? communities,
  }) {
    return MultiTabSearchResults(
      posts: posts ?? this.posts,
      reels: reels ?? this.reels,
      people: people ?? this.people,
      tags: tags ?? this.tags,
      communities: communities ?? this.communities,
    );
  }
}

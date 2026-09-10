// Models for the admin Content tab — /admin/posts, /posts/trending, /media/:id.

enum ContentPostType { photo, video, text, unknown }

extension ContentPostTypeX on ContentPostType {
  String get label => switch (this) {
        ContentPostType.photo => 'Photo',
        ContentPostType.video => 'Video',
        ContentPostType.text => 'Text',
        ContentPostType.unknown => '—',
      };

  static ContentPostType parse(String? raw) => switch (raw?.toUpperCase()) {
        'PHOTO' || 'IMAGE' => ContentPostType.photo,
        'VIDEO' => ContentPostType.video,
        'TEXT' => ContentPostType.text,
        _ => ContentPostType.unknown,
      };
}

class PostAuthor {
  const PostAuthor({
    required this.userId,
    this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory PostAuthor.fromJson(Map<String, dynamic> json) => PostAuthor(
        userId: json['userId'] as String? ?? '',
        username: json['username'] as String?,
        displayName: json['displayName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );

  final String userId;
  final String? username;
  final String? displayName;
  final String? avatarUrl;

  String get handle =>
      (username != null && username!.isNotEmpty) ? '@$username' : 'Unknown';
  String get name =>
      (displayName != null && displayName!.isNotEmpty) ? displayName! : handle;
}

class ContentPost {
  const ContentPost({
    required this.id,
    required this.type,
    required this.body,
    required this.mediaRefs,
    required this.tags,
    required this.status,
    required this.likeCount,
    required this.commentCount,
    required this.viewCount,
    required this.reportCount,
    required this.createdAt,
    required this.author,
    this.visibility,
    this.communityId,
    this.deletedAt,
  });

  factory ContentPost.fromJson(Map<String, dynamic> json) {
    return ContentPost(
      id: json['id'] as String,
      type: ContentPostTypeX.parse(json['type'] as String?),
      body: json['body'] as String? ?? '',
      mediaRefs: (json['mediaRefs'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(),
      tags: (json['tags'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e.toString())
          .toList(),
      visibility: json['visibility'] as String?,
      communityId: json['communityId'] as String?,
      status: json['status'] as String? ?? 'published',
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      commentCount: (json['commentCount'] as num?)?.toInt() ?? 0,
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      reportCount: (json['reportCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      deletedAt: DateTime.tryParse(json['deletedAt'] as String? ?? ''),
      author: PostAuthor.fromJson(
        json['author'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      ),
    );
  }

  final String id;
  final ContentPostType type;
  final String body;
  final List<String> mediaRefs;
  final List<String> tags;
  final String? visibility;
  final String? communityId;
  final String status; // published | removed
  final int likeCount;
  final int commentCount;
  final int viewCount;
  final int reportCount;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final PostAuthor author;

  /// `removed` (via the hide endpoint) or a non-null `deletedAt`.
  bool get isHidden =>
      status.toLowerCase() == 'removed' || deletedAt != null;

  String? get primaryMediaRef => mediaRefs.isEmpty ? null : mediaRefs.first;

  String get statusLabel => isHidden ? 'Hidden' : 'Live';
}

class ContentPostsPage {
  const ContentPostsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  factory ContentPostsPage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> raw = json['items'] as List<dynamic>? ?? <dynamic>[];
    return ContentPostsPage(
      items: raw
          .map((dynamic e) => ContentPost.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? raw.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? raw.length,
    );
  }

  final List<ContentPost> items;
  final int total;
  final int page;
  final int limit;
}

class MediaAsset {
  const MediaAsset({
    required this.id,
    required this.type,
    this.url,
    this.thumbnailUrl,
    this.objectKey,
    this.durationSeconds,
  });

  factory MediaAsset.fromJson(Map<String, dynamic> json) => MediaAsset(
        id: json['id'] as String? ?? '',
        type: (json['type'] as String? ?? '').toLowerCase(),
        url: json['url'] as String?,
        thumbnailUrl: json['thumbnailUrl'] as String?,
        objectKey: json['objectKey'] as String?,
        durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      );

  final String id;
  final String type; // image | video
  final String? url; // images: the image; videos: an HLS .m3u8 (Safari only)
  final String? thumbnailUrl;
  final String? objectKey; // e.g. videos/original/<owner>/<id>.mp4
  final int? durationSeconds;

  bool get isVideo => type == 'video';

  /// Best URL to show as a still image.
  String? get posterUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) return thumbnailUrl;
    if (!isVideo && url != null && url!.isNotEmpty) return url;
    return null;
  }

  /// URL to hand to a video player. The API's `url` is HLS, which only Safari
  /// plays in a browser — but the original progressive `.mp4` is served from
  /// the same CDN at `<origin>/<objectKey>` and plays everywhere.
  String? get playableUrl {
    if (!isVideo) return url;
    final String? key = objectKey;
    if (key != null && key.endsWith('.mp4')) {
      final Uri? cdn = Uri.tryParse(url ?? thumbnailUrl ?? '');
      if (cdn != null && cdn.hasScheme && cdn.host.isNotEmpty) {
        return Uri(
          scheme: cdn.scheme,
          host: cdn.host,
          path: '/${key.replaceFirst(RegExp(r'^/'), '')}',
        ).toString();
      }
    }
    return url; // fall back to HLS (works on Safari)
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/cache/user_relationship_cache.dart';
import '../../../core/config/app_config.dart';
import '../../auth/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../create_post/models/create_post_models.dart';
import '../../create_post/services/post_content_service.dart';
import '../../profile/provider/profile_provider.dart';
import '../../discover/models/discover_models.dart';
import '../../discover/services/discover_service.dart';
import '../../discover/provider/discover_provider.dart';
import '../models/post_item_model.dart';
import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/post_feed_card.dart';
import 'reels_feed_view.dart';

class HashtagPostsScreen extends StatefulWidget {
  const HashtagPostsScreen({
    required this.hashtag,
    required this.postsCount,
    required this.rankColor,
    super.key,
  });

  final String hashtag;
  final String postsCount;
  final Color rankColor;

  @override
  State<HashtagPostsScreen> createState() => _HashtagPostsScreenState();
}

class _HashtagPostsScreenState extends State<HashtagPostsScreen>
    with SingleTickerProviderStateMixin {
  List<PostItemModel> _posts = <PostItemModel>[];
  List<ReelItemModel> _reels = <ReelItemModel>[];
  bool _isLoading = true;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final String rawTag = widget.hashtag.trim();
    final String cleanTag = rawTag.startsWith('#') ? rawTag.substring(1) : rawTag;
    final String hashTag = '#$cleanTag';
    final String tagLower = cleanTag.toLowerCase();

    final List<PostItemModel> photoPosts = <PostItemModel>[];
    final List<ReelItemModel> videoReels = <ReelItemModel>[];
    final Set<String> seenIds = <String>{};

    final ApiClient client = context.read<ApiClient>();
    final AuthProvider auth = context.read<AuthProvider>();
    final ProfileProvider profile = context.read<ProfileProvider>();
    final String? curUserId = auth.userId ?? profile.profile?.id;
    final String? curUsername = profile.profile?.username ?? auth.user?.displayName;
    final bool isGuest = auth.isGuest;
    final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();

    // 1. Primary: Query the Discover Search API with query = hashTag ('#tag')
    try {
      final DiscoverService discoverService = DiscoverService(client);
      final MultiTabSearchResults searchResults = await discoverService.search(
        query: hashTag,
        tab: 'all',
      );

      for (final DiscoverSearchResult p in searchResults.posts) {
        if (!p.isPublished) continue;
        final String searchDocId = (p.id ?? '').trim().toLowerCase();
        final String refId = (p.refId ?? '').trim().toLowerCase().replaceAll(RegExp(r'^/+|^media/'), '');
        final String effectiveId = (p.refId != null && p.refId!.trim().isNotEmpty)
            ? p.refId!.trim()
            : (p.id ?? '');
        if (effectiveId.isEmpty || DeletedPostsRegistry.isDeleted(effectiveId) || DeletedPostsRegistry.isDeleted(searchDocId)) continue;
        if (!PostVisibilityFilter.canViewPost(
          visibility: p.visibility,
          authorId: p.authorId,
          authorUsername: p.authorUsername,
          currentUserId: curUserId,
          currentUsername: curUsername,
          isGuest: isGuest,
          isFollowing: UserRelationshipCache.isFollowing(
            userId: p.authorId,
            username: p.authorUsername,
          ),
          isAuthorPrivate: p.isAuthorPrivate,
        )) {
          continue;
        }

        if (seenIds.contains(effectiveId.toLowerCase()) ||
            (searchDocId.isNotEmpty && seenIds.contains(searchDocId)) ||
            (refId.isNotEmpty && seenIds.contains(refId))) {
          continue;
        }

        seenIds.add(effectiveId.toLowerCase());
        if (searchDocId.isNotEmpty) seenIds.add(searchDocId);
        if (refId.isNotEmpty) seenIds.add(refId);
        for (final String m in p.mediaRefs) {
          final String cleanM = m.trim().toLowerCase().replaceAll(RegExp(r'^/+|^media/'), '');
          if (cleanM.isNotEmpty) seenIds.add(cleanM);
        }

        final bool isPostLiked = p.isLiked || homeFeed.isPostLiked(effectiveId) || profile.isPostLiked(effectiveId);
        final bool isPostSaved = p.isSaved || homeFeed.isPostSaved(effectiveId) || profile.isPostSaved(effectiveId);
        final int rawLikes = p.likesCount ?? 0;
        final int postLikes = isPostLiked ? (rawLikes > 0 ? rawLikes : 1) : rawLikes;
        final bool isText = p.imageAsset.trim().isEmpty;

        final int postViews = PostInteractionRegistry.getViewsCount(
          effectiveId,
          fallback: PostInteractionRegistry.getViewsCount(
            refId,
            fallback: searchDocId.isNotEmpty
                ? PostInteractionRegistry.getViewsCount(searchDocId, fallback: p.viewsCount)
                : p.viewsCount,
          ),
        );
        if (postViews > 0) {
          PostInteractionRegistry.setViewsCount(effectiveId, postViews);
          if (refId.isNotEmpty) PostInteractionRegistry.setViewsCount(refId, postViews);
          if (searchDocId.isNotEmpty) PostInteractionRegistry.setViewsCount(searchDocId, postViews);
        }

        photoPosts.add(PostItemModel(
          id: effectiveId,
          authorId: p.authorId,
          authorDisplayName: (p.authorUsername != null && p.authorUsername!.trim().isNotEmpty)
              ? p.authorUsername!.trim()
              : 'Creator',
          username: (p.authorUsername != null && p.authorUsername!.trim().isNotEmpty)
              ? (p.authorUsername!.startsWith('@') ? p.authorUsername!.trim() : '@${p.authorUsername!.trim()}')
              : '@creator',
          pronounsTime: 'they/them · recent',
          avatarAsset: (p.authorAvatar != null && p.authorAvatar!.trim().isNotEmpty)
              ? p.authorAvatar!.trim()
              : AppImages.user1,
          content: p.caption ?? '',
          likesCount: postLikes,
          commentsCount: p.commentsCount ?? 0,
          viewsCount: postViews,
          postImageUrl: !isText ? p.imageAsset : null,
          postType: isText ? 'TEXT' : 'PHOTO',
          communityId: p.communityId,
          isLiked: isPostLiked,
          isSaved: isPostSaved,
          allowComments: p.allowComments,
          allowCommentsFrom: p.allowCommentsFrom,
          isAuthorPrivate: p.isAuthorPrivate,
          status: p.status,
        ));
      }

      for (final DiscoverSearchResult r in searchResults.reels) {
        if (!r.isPublished) continue;
        final String searchDocId = (r.id ?? '').trim().toLowerCase();
        final String refId = (r.refId ?? '').trim().toLowerCase().replaceAll(RegExp(r'^/+|^media/'), '');
        final String effectiveId = (r.refId != null && r.refId!.trim().isNotEmpty)
            ? r.refId!.trim()
            : (r.id ?? '');
        if (effectiveId.isEmpty || DeletedPostsRegistry.isDeleted(effectiveId) || DeletedPostsRegistry.isDeleted(searchDocId)) continue;
        if (!PostVisibilityFilter.canViewPost(
          visibility: r.visibility,
          authorId: r.authorId,
          authorUsername: r.authorUsername,
          currentUserId: curUserId,
          currentUsername: curUsername,
          isGuest: isGuest,
          isFollowing: UserRelationshipCache.isFollowing(
            userId: r.authorId,
            username: r.authorUsername,
          ),
          isAuthorPrivate: r.isAuthorPrivate,
        )) {
          continue;
        }

        if (seenIds.contains(effectiveId.toLowerCase()) ||
            (searchDocId.isNotEmpty && seenIds.contains(searchDocId)) ||
            (refId.isNotEmpty && seenIds.contains(refId))) {
          continue;
        }

        seenIds.add(effectiveId.toLowerCase());
        if (searchDocId.isNotEmpty) seenIds.add(searchDocId);
        if (refId.isNotEmpty) seenIds.add(refId);
        for (final String m in r.mediaRefs) {
          final String cleanM = m.trim().toLowerCase().replaceAll(RegExp(r'^/+|^media/'), '');
          if (cleanM.isNotEmpty) seenIds.add(cleanM);
        }

        final bool isReelLiked = r.isLiked || homeFeed.isPostLiked(effectiveId) || profile.isPostLiked(effectiveId);
        final bool isReelSaved = r.isSaved || homeFeed.isPostSaved(effectiveId) || profile.isPostSaved(effectiveId);
        final int rawLikes = r.likesCount ?? 0;
        final int reelLikes = isReelLiked ? (rawLikes > 0 ? rawLikes : 1) : rawLikes;

        final int reelViews = PostInteractionRegistry.getViewsCount(
          effectiveId,
          fallback: PostInteractionRegistry.getViewsCount(
            refId,
            fallback: searchDocId.isNotEmpty
                ? PostInteractionRegistry.getViewsCount(searchDocId, fallback: r.viewsCount)
                : r.viewsCount,
          ),
        );
        if (reelViews > 0) {
          PostInteractionRegistry.setViewsCount(effectiveId, reelViews);
          if (refId.isNotEmpty) PostInteractionRegistry.setViewsCount(refId, reelViews);
          if (searchDocId.isNotEmpty) PostInteractionRegistry.setViewsCount(searchDocId, reelViews);
        }

        videoReels.add(ReelItemModel(
          id: effectiveId,
          authorId: r.authorId,
          authorDisplayName: (r.authorUsername != null && r.authorUsername!.trim().isNotEmpty)
              ? r.authorUsername!.trim()
              : 'Creator',
          username: (r.authorUsername != null && r.authorUsername!.trim().isNotEmpty)
              ? (r.authorUsername!.startsWith('@') ? r.authorUsername!.trim() : '@${r.authorUsername!.trim()}')
              : '@creator',
          pronounsTime: 'they/them · recent',
          avatarAsset: (r.authorAvatar != null && r.authorAvatar!.trim().isNotEmpty)
              ? r.authorAvatar!.trim()
              : AppImages.user1,
          videoAsset: '',
          videoUrl: r.videoUrl,
          thumbnailUrl: r.thumbnailUrl ?? (r.imageAsset.isNotEmpty ? r.imageAsset : null),
          caption: r.caption ?? '',
          likesCount: reelLikes,
          commentsCount: r.commentsCount ?? 0,
          viewsCount: reelViews,
          isLiked: isReelLiked,
          isSaved: isReelSaved,
          communityId: r.communityId,
          allowComments: r.allowComments,
          allowCommentsFrom: r.allowCommentsFrom,
          isAuthorPrivate: r.isAuthorPrivate,
          status: r.status,
        ));
      }
    } catch (e) {
      debugPrint('⚠️ [HashtagPostsScreen] Error querying search API for hashtag: $e');
    }

    // 2. Scan live feed posts for matching hashtag
    try {
      for (final PostItemModel p in homeFeed.posts) {
        if (!p.isPublished) continue;
        if (DeletedPostsRegistry.isDeleted(p.id)) continue;
        final String contentLower = p.content.toLowerCase();
        if (contentLower.contains(hashTag.toLowerCase()) ||
            contentLower.contains(tagLower)) {
          if (seenIds.add(p.id.toLowerCase())) {
            final bool isVid = p.postType.toUpperCase().trim() == 'VIDEO' ||
                p.postType.toLowerCase().trim() == 'reel' ||
                (p.postImageUrl != null &&
                    (p.postImageUrl!.endsWith('.mp4') ||
                        p.postImageUrl!.endsWith('.m3u8') ||
                        p.postImageUrl!.contains('video') ||
                        p.postImageUrl!.contains('/videos/')));
            final int feedItemViews = PostInteractionRegistry.getViewsCount(
              p.id,
              fallback: p.viewsCount,
            );
            if (feedItemViews > 0) {
              PostInteractionRegistry.setViewsCount(p.id, feedItemViews);
            }
            if (isVid) {
              final String? thumb = (p.postImageUrl != null && p.postImageUrl!.contains('/videos/processed/'))
                  ? p.postImageUrl!.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg')
                  : p.postImageUrl;
              videoReels.add(ReelItemModel(
                id: p.id,
                authorId: p.authorId,
                authorDisplayName: p.authorDisplayName ?? p.username,
                username: p.username,
                pronounsTime: p.pronounsTime,
                avatarAsset: p.avatarAsset,
                videoAsset: '',
                videoUrl: p.postImageUrl,
                thumbnailUrl: thumb,
                caption: p.content,
                likesCount: p.likesCount,
                commentsCount: p.commentsCount,
                viewsCount: feedItemViews,
                isLiked: p.isLiked || homeFeed.isPostLiked(p.id) || profile.isPostLiked(p.id),
                isSaved: p.isSaved || homeFeed.isPostSaved(p.id) || profile.isPostSaved(p.id),
                communityId: p.communityId,
              ));
            } else {
              photoPosts.add(p.copyWith(
                viewsCount: feedItemViews,
                isLiked: p.isLiked || homeFeed.isPostLiked(p.id) || profile.isPostLiked(p.id),
                isSaved: p.isSaved || homeFeed.isPostSaved(p.id) || profile.isPostSaved(p.id),
              ));
            }
          }
        }
      }
      // Scan live reels for matching hashtag – keep as reels
      for (final ReelItemModel r in homeFeed.reels) {
        if (!r.isPublished) continue;
        if (DeletedPostsRegistry.isDeleted(r.id)) continue;
        final String captionLower = r.caption.toLowerCase();
        final bool hasTag = r.tags.any(
          (String t) => t.toLowerCase().replaceAll('#', '') == tagLower,
        );
        if (hasTag ||
            captionLower.contains(hashTag.toLowerCase()) ||
            captionLower.contains(tagLower)) {
          if (seenIds.add(r.id.toLowerCase())) {
            final int liveReelViews = PostInteractionRegistry.getViewsCount(
              r.id,
              fallback: r.viewsCount,
            );
            if (liveReelViews > 0) {
              PostInteractionRegistry.setViewsCount(r.id, liveReelViews);
            }
            videoReels.add(r.copyWith(
              viewsCount: liveReelViews,
              isLiked: r.isLiked || homeFeed.isPostLiked(r.id) || profile.isPostLiked(r.id),
              isSaved: r.isSaved || homeFeed.isPostSaved(r.id) || profile.isPostSaved(r.id),
            ));
          }
        }
      }
    } catch (_) {}

    // 3. Query Posts API for existing posts containing this hashtag fallback
    try {
      final PostContentService postService = PostContentService(client);
      final List<PostResponseModel> livePosts = await postService.getFeedPosts();

      for (final PostResponseModel p in livePosts) {
        if (!p.isPublished) continue;
        if (DeletedPostsRegistry.isDeleted(p.id)) continue;

        if (!PostVisibilityFilter.canViewPost(
          visibility: p.visibility,
          authorId: p.authorId,
          authorUsername: p.authorName,
          currentUserId: curUserId,
          currentUsername: curUsername,
          isGuest: isGuest,
          isFollowing: UserRelationshipCache.isFollowing(
            userId: p.authorId,
            username: p.authorName,
          ),
          isAuthorPrivate: p.isAuthorPrivate,
        )) {
          continue;
        }

        // Only show posts whose tags contain the searched tag (or caption has #tag)
        final bool hasTag = p.tags.any(
          (String t) => t.replaceAll('#', '').trim().toLowerCase() == tagLower,
        ) || p.caption.toLowerCase().contains(hashTag.toLowerCase())
          || p.caption.toLowerCase().contains('#$tagLower');

        if (!hasTag) continue;

        if (!seenIds.add(p.id.toLowerCase())) continue;

        final bool isVid = p.type.toUpperCase().trim() == 'VIDEO' ||
            p.type.toLowerCase().trim() == 'reel' ||
            (p.postImageUrl != null &&
                (p.postImageUrl!.endsWith('.mp4') ||
                    p.postImageUrl!.endsWith('.m3u8') ||
                    p.postImageUrl!.contains('video') ||
                    p.postImageUrl!.contains('/videos/')));

        if (isVid) {
          String? videoUrl = p.postImageUrl;
          String? thumb;
          if (p.mediaRefs.isNotEmpty) {
            final String firstRef =
                p.mediaRefs.first.replaceAll(RegExp(r'^/+|^media/'), '').trim();
            if (firstRef.startsWith('http')) {
              videoUrl ??= firstRef;
              if (firstRef.contains('/videos/processed/')) {
                thumb ??= firstRef.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg');
              }
            } else {
              videoUrl ??=
                  '${AppConfig.cdnUrl}/videos/processed/$firstRef/master.m3u8';
              thumb ??=
                  '${AppConfig.cdnUrl}/videos/processed/$firstRef/thumb.0000000.jpg';
            }
          }
          thumb ??= (videoUrl != null && videoUrl.contains('/videos/processed/'))
              ? videoUrl.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg')
              : null;

          final bool isReelLiked = p.isLiked || homeFeed.isPostLiked(p.id) || profile.isPostLiked(p.id);
          final bool isReelSaved = p.isSaved || homeFeed.isPostSaved(p.id) || profile.isPostSaved(p.id);
          final int reelLikes = p.likesCount;
          final int reelViews = PostInteractionRegistry.getViewsCount(
            p.id,
            fallback: p.viewsCount,
          );
          if (reelViews > 0) {
            PostInteractionRegistry.setViewsCount(p.id, reelViews);
          }

          videoReels.add(ReelItemModel(
            id: p.id,
            authorId: p.authorId,
            authorDisplayName: p.authorDisplayName ?? p.authorName ?? 'Creator',
            username: (p.authorName != null && p.authorName!.trim().isNotEmpty)
                ? (p.authorName!.startsWith('@')
                    ? p.authorName!.trim()
                    : '@${p.authorName!.trim()}')
                : '@creator',
            pronounsTime: 'they/them · recent',
            avatarAsset: (p.authorAvatar != null &&
                    p.authorAvatar!.trim().isNotEmpty)
                ? p.authorAvatar!.trim()
                : AppImages.user1,
            videoAsset: '',
            videoUrl: videoUrl,
            thumbnailUrl: thumb,
            caption: p.caption,
            likesCount: reelLikes,
            commentsCount: p.commentsCount,
            viewsCount: reelViews,
            isLiked: isReelLiked,
            isSaved: isReelSaved,
            communityId: p.communityId,
            tags: p.tags,
            allowComments: p.allowComments,
            allowCommentsFrom: p.allowCommentsFrom,
            isAuthorPrivate: p.isAuthorPrivate,
            status: p.status,
          ));
        } else {
          String? imgUrl = p.postImageUrl;
          if ((imgUrl == null || imgUrl.isEmpty) && p.mediaRefs.isNotEmpty) {
            final String firstRef =
                p.mediaRefs.first.replaceAll(RegExp(r'^/+|^media/'), '').trim();
            if (firstRef.startsWith('http')) {
              imgUrl = firstRef;
            } else if (p.authorId != null && p.authorId!.isNotEmpty) {
              imgUrl =
                  '${AppConfig.cdnUrl}/images/original/${p.authorId}/$firstRef.jpg';
            } else {
              imgUrl = '${AppConfig.cdnUrl}/images/original/$firstRef.jpg';
            }
          }
          final bool isText = p.type.toUpperCase().trim() == 'TEXT' ||
              (imgUrl == null && p.mediaRefs.isEmpty);

          final bool isPostLiked = p.isLiked || homeFeed.isPostLiked(p.id) || profile.isPostLiked(p.id);
          final bool isPostSaved = p.isSaved || homeFeed.isPostSaved(p.id) || profile.isPostSaved(p.id);
          final int postLikes = p.likesCount;
          final int postViews = PostInteractionRegistry.getViewsCount(
            p.id,
            fallback: p.viewsCount,
          );
          if (postViews > 0) {
            PostInteractionRegistry.setViewsCount(p.id, postViews);
          }

          photoPosts.add(PostItemModel(
            id: p.id,
            authorId: p.authorId,
            authorDisplayName: p.authorDisplayName ?? p.authorName,
            username: (p.authorName != null && p.authorName!.trim().isNotEmpty)
                ? (p.authorName!.startsWith('@')
                    ? p.authorName!.trim()
                    : '@${p.authorName!.trim()}')
                : '@queer_creator',
            pronounsTime: 'they/them · recent',
            avatarAsset: (p.authorAvatar != null &&
                    p.authorAvatar!.trim().isNotEmpty)
                ? p.authorAvatar!.trim()
                : AppImages.user1,
            content: p.caption,
            likesCount: postLikes,
            commentsCount: p.commentsCount,
            viewsCount: postViews,
            postImageUrl: !isText ? imgUrl : null,
            postType: isText ? 'TEXT' : (p.type.isNotEmpty ? p.type : 'PHOTO'),
            communityId: p.communityId,
            isLiked: isPostLiked,
            isSaved: isPostSaved,
            allowComments: p.allowComments,
            allowCommentsFrom: p.allowCommentsFrom,
            isAuthorPrivate: p.isAuthorPrivate,
            status: p.status,
          ));
        }
      }
    } catch (e) {
      debugPrint('⚠️ [HashtagPostsScreen] Error fetching hashtag posts: $e');
    }

    if (mounted) {
      setState(() {
        _posts = photoPosts;
        _reels = videoReels;
        _isLoading = false;
      });

      final int totalLoaded = photoPosts.length + videoReels.length;
      try {
        context
            .read<DiscoverProvider>()
            .updateHashtagCount(widget.hashtag, totalLoaded);
      } catch (_) {}
    }
  }

  void _openReelPlayer(int initialIndex) async {
    final List<ReelItemModel> preparedReels = _reels.map((ReelItemModel r) => r.copyWith(
      isLiked: PostInteractionRegistry.isLiked(r.id, fallback: r.isLiked),
      isSaved: PostInteractionRegistry.isSaved(r.id, fallback: r.isSaved),
      likesCount: PostInteractionRegistry.getLikeCount(r.id, fallback: r.likesCount),
      commentsCount: CommentCountRegistry.getOr(r.id, r.commentsCount),
      viewsCount: PostInteractionRegistry.getViewsCount(r.id, fallback: r.viewsCount),
    )).toList();

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: <Widget>[
              ReelsFeedView(
                initialPage: initialIndex,
                customReels: preparedReels,
                hasBottomBar: false,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => Navigator.of(routeContext).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _reels.removeWhere((ReelItemModel r) => DeletedPostsRegistry.isDeleted(r.id));
        _posts.removeWhere((PostItemModel p) => DeletedPostsRegistry.isDeleted(p.id));
        for (int i = 0; i < _reels.length; i++) {
          final String id = _reels[i].id;
          _reels[i] = _reels[i].copyWith(
            isLiked: PostInteractionRegistry.isLiked(id, fallback: _reels[i].isLiked),
            isSaved: PostInteractionRegistry.isSaved(id, fallback: _reels[i].isSaved),
            likesCount: PostInteractionRegistry.getLikeCount(id, fallback: _reels[i].likesCount),
            commentsCount: CommentCountRegistry.getOr(id, _reels[i].commentsCount),
            viewsCount: PostInteractionRegistry.getViewsCount(id, fallback: _reels[i].viewsCount),
          );
        }
        for (int i = 0; i < _posts.length; i++) {
          final String id = _posts[i].id;
          _posts[i] = _posts[i].copyWith(
            isLiked: PostInteractionRegistry.isLiked(id, fallback: _posts[i].isLiked),
            isSaved: PostInteractionRegistry.isSaved(id, fallback: _posts[i].isSaved),
            likesCount: PostInteractionRegistry.getLikeCount(id, fallback: _posts[i].likesCount),
            commentsCount: CommentCountRegistry.getOr(id, _posts[i].commentsCount),
            viewsCount: PostInteractionRegistry.getViewsCount(id, fallback: _posts[i].viewsCount),
          );
        }
      });
    }
  }

  void _toggleLike(String id) {
    final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
    final ProfileProvider profile = context.read<ProfileProvider>();
    final int itemIndex = _posts.indexWhere((PostItemModel p) => p.id == id);
    final PostItemModel? currentItem = itemIndex != -1 ? _posts[itemIndex] : null;
    final bool currentlyLiked = PostInteractionRegistry.isLiked(id, fallback: currentItem?.isLiked ?? false);
    final bool newLiked = !currentlyLiked;
    final int baseCount = PostInteractionRegistry.getLikeCount(id, fallback: currentItem?.likesCount ?? 0);
    final int newCount = newLiked ? baseCount + 1 : (baseCount > 0 ? baseCount - 1 : 0);

    PostInteractionRegistry.setLiked(id, newLiked, count: newCount);

    PostItemModel? target;
    setState(() {
      if (itemIndex != -1) {
        _posts[itemIndex] = _posts[itemIndex].copyWith(
          isLiked: newLiked,
          likesCount: newCount,
        );
        target = _posts[itemIndex];
      }
    });
    try {
      homeFeed.toggleLikePost(id, fallbackPost: target, explicitLiked: newLiked);
      profile.updateLikedPost(
        id,
        isLiked: newLiked,
        likesCount: newCount,
        fallbackPost: target,
      );
    } catch (_) {}
  }

  void _toggleSave(String id) {
    final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
    final ProfileProvider profile = context.read<ProfileProvider>();
    final int itemIndex = _posts.indexWhere((PostItemModel p) => p.id == id);
    final PostItemModel? currentItem = itemIndex != -1 ? _posts[itemIndex] : null;
    final bool currentlySaved = PostInteractionRegistry.isSaved(id, fallback: currentItem?.isSaved ?? false);
    final bool newSaved = !currentlySaved;

    PostInteractionRegistry.setSaved(id, newSaved);

    PostItemModel? target;
    setState(() {
      if (itemIndex != -1) {
        _posts[itemIndex] = _posts[itemIndex].copyWith(isSaved: newSaved);
        target = _posts[itemIndex];
      }
    });
    try {
      homeFeed.toggleSavePost(id, fallbackPost: target, explicitSaved: newSaved);
      profile.updateSavedPost(
        id,
        isSaved: newSaved,
        fallbackPost: target,
      );
    } catch (_) {}
  }

  void _showCommentsSheet(BuildContext context, PostItemModel post) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return CommentsBottomSheet(
          postId: post.id,
          postAuthorId: post.authorId,
          communityId: post.communityId,
          totalComments: CommentCountRegistry.getOr(post.id, post.commentsCount),
          allowComments: post.allowComments,
          allowCommentsFrom: post.allowCommentsFrom,
          authorUsername: post.username,
          onCommentAdded: () {
            final int newCount = CommentCountRegistry.increment(post.id);
            setState(() {
              final int i = _posts.indexWhere((PostItemModel p) => p.id == post.id);
              if (i != -1) {
                _posts[i] = _posts[i].copyWith(
                  commentsCount: newCount,
                );
              }
            });
            try {
              context.read<HomeFeedProvider>().incrementCommentCount(post.id);
            } catch (_) {}
            try {
              context.read<ProfileProvider>().incrementCommentCount(post.id);
            } catch (_) {}
          },
          onCommentDeleted: (int deletedCount, int remainingCount) {
            CommentCountRegistry.set(post.id, remainingCount);
            setState(() {
              final int i = _posts.indexWhere((PostItemModel p) => p.id == post.id);
              if (i != -1) {
                _posts[i] = _posts[i].copyWith(
                  commentsCount: remainingCount,
                );
              }
            });
            try {
              context.read<HomeFeedProvider>().setCommentCount(post.id, remainingCount);
            } catch (_) {}
            try {
              context.read<ProfileProvider>().updatePostCommentCount(post.id, remainingCount);
            } catch (_) {}
          },
          onCommentCountChanged: (int count) {
            CommentCountRegistry.set(post.id, count);
            setState(() {
              final int i = _posts.indexWhere((PostItemModel p) => p.id == post.id);
              if (i != -1) {
                _posts[i] = _posts[i].copyWith(
                  commentsCount: count,
                );
              }
            });
            try {
              context.read<HomeFeedProvider>().setCommentCount(post.id, count);
            } catch (_) {}
            try {
              context.read<ProfileProvider>().updatePostCommentCount(post.id, count);
            } catch (_) {}
          },
        );
      },
    );
  }

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = _posts.length + _reels.length;
    final String postCountText = _isLoading
        ? widget.postsCount
        : '$totalCount ${totalCount == 1 ? 'post' : 'posts'}';

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: ListenableBuilder(
        listenable: Listenable.merge([
          PostInteractionRegistry.notifier,
          CommentCountRegistry.notifier,
        ]),
        builder: (BuildContext context, _) {
          return SafeArea(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.screenPaddingHorizontal,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: AppSizes.backButtonSize,
                      height: AppSizes.backButtonSize,
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.12)
                              : context.themeBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: context.themeIcon,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ShaderMask(
                          shaderCallback: (Rect bounds) =>
                              AppColors.primaryGradientButton.createShader(
                            bounds,
                          ),
                          child: Text(
                            widget.hashtag,
                            style: AppTextStyles.headingMedium.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          postCountText,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.themeTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Tab Bar (Posts / Reels) ─────────────────────────────────────
            TabBar(
              controller: _tabController,
              indicatorColor: widget.rankColor,
              labelColor: widget.rankColor,
              unselectedLabelColor: context.themeTextMuted,
              labelStyle: AppTextStyles.bodyMedium.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              tabs: <Tab>[
                Tab(
                  text: _isLoading
                      ? 'Posts'
                      : 'Posts (${_posts.length})',
                ),
                Tab(
                  text: _isLoading
                      ? 'Reels'
                      : 'Reels (${_reels.length})',
                ),
              ],
            ),

            Divider(height: 1, color: context.themeDivider),

            // ── Content ─────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gradientPink,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: <Widget>[
                        // ── Posts Tab ──────────────────────────────────────
                        _buildPostsTab(),

                        // ── Reels Tab ──────────────────────────────────────
                        _buildReelsTab(),
                      ],
                    ),
            ),
          ],
        ),
      );
    },
  ),
);
  }

  Widget _buildPostsTab() {
    if (_posts.isEmpty) {
      return _buildEmpty(
        icon: Icons.article_outlined,
        title: 'No posts yet for ${widget.hashtag}',
        subtitle:
            'Text and photo posts tagging ${widget.hashtag} will appear here.',
      );
    }

    return RefreshIndicator(
      color: AppColors.gradientPink,
      backgroundColor: context.themeCardBackground,
      onRefresh: _loadPosts,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(
          top: AppSpacing.sm,
          bottom: AppSpacing.xxxxxl,
        ),
        itemCount: _posts.length,
        itemBuilder: (BuildContext context, int index) {
          final PostItemModel post = _posts[index];
          return PostFeedCard(
            post: post,
            onCardTap: () => PostFeedCard.openFullscreen(context, post),
            onLikeToggle: () => _toggleLike(post.id),
            onSaveToggle: () => _toggleSave(post.id),
            onOpenComments: () => _showCommentsSheet(context, post),
            onPostDeleted: () {
              setState(() {
                _posts.removeWhere((PostItemModel p) => p.id == post.id);
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildReelsTab() {
    if (_reels.isEmpty) {
      return _buildEmpty(
        icon: Icons.videocam_outlined,
        title: 'No reels yet for ${widget.hashtag}',
        subtitle: 'Videos tagging ${widget.hashtag} will appear here.',
      );
    }

    return RefreshIndicator(
      color: AppColors.gradientPink,
      backgroundColor: context.themeCardBackground,
      onRefresh: _loadPosts,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.all(AppSpacing.sm),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: _reels.length,
        itemBuilder: (BuildContext context, int index) {
          final ReelItemModel reel = _reels[index];
          final int views = PostInteractionRegistry.getViewsCount(
            reel.id,
            fallback: reel.viewsCount,
          );
          return GestureDetector(
            onTap: () => _openReelPlayer(index),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // Thumbnail
                  if (reel.thumbnailUrl != null &&
                      reel.thumbnailUrl!.isNotEmpty)
                    Image.network(
                      reel.thumbnailUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _reelFallback(),
                    )
                  else
                    _reelFallback(),

                  // Dark gradient bottom overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),

                  // Play count at bottom left (matching profile screen)
                  Positioned(
                    bottom: 6,
                    left: 6,
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          _formatCount(views),
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _reelFallback() {
    return Container(
      color: const Color(0xFF1E1B26),
      child: Center(
        child: Icon(
          Icons.play_circle_outline_rounded,
          color: widget.rankColor.withValues(alpha: 0.5),
          size: 36,
        ),
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.5,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.rankColor.withValues(alpha: 0.12),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        size: 32,
                        color: widget.rankColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.themeTextMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

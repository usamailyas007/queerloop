import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';
import '../../../core/services/media_download_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/auth_provider.dart';
import '../../create_post/models/create_post_models.dart';
import '../../create_post/services/post_content_service.dart';
import '../../messages/models/message_models.dart';
import '../../profile/provider/profile_provider.dart';
import '../models/post_item_model.dart';
import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/post_feed_card.dart';
import 'post_fullscreen_image_viewer_screen.dart';
import 'reels_feed_view.dart';

class SinglePostViewScreen extends StatefulWidget {
  const SinglePostViewScreen({
    required this.postId,
    this.initialPost,
    this.chatMessage,
    super.key,
  });

  final String postId;
  final PostItemModel? initialPost;
  final ChatMessageModel? chatMessage;

  @override
  State<SinglePostViewScreen> createState() => _SinglePostViewScreenState();
}

class _SinglePostViewScreenState extends State<SinglePostViewScreen> {
  PostItemModel? _post;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isReel = false;
  String? _resolvedVideoUrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialPost != null) {
      _post = widget.initialPost;
      _isReel = widget.initialPost!.postType.toUpperCase() == 'VIDEO' ||
          widget.initialPost!.postType.toLowerCase() == 'reel';
      _isLoading = false;
    } else {
      _loadPost();
    }
  }

  Future<void> _loadPost() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final ApiClient client = context.read<ApiClient>();
      final PostContentService postService = PostContentService(client);

      final PostResponseModel raw = await postService.getPost(widget.postId);
      final String rawType = raw.type.trim().toUpperCase();
      final bool isVideoType = rawType == 'VIDEO' || rawType == 'REEL' ||
          (widget.chatMessage?.postType == 'reel');
      _isReel = isVideoType;

      String? mediaUrl;
      String? thumbUrl;

      if (raw.mediaRefs.isNotEmpty) {
        final String firstRef = raw.mediaRefs.first.trim();
        if (firstRef.startsWith('http://') || firstRef.startsWith('https://')) {
          mediaUrl = firstRef;
          thumbUrl = firstRef;
        } else {
          final String cleanRef = firstRef
              .replaceAll(RegExp(r'^/+'), '')
              .replaceAll(RegExp(r'^media/'), '');
          if (isVideoType) {
            mediaUrl = '${AppConfig.cdnUrl}/videos/processed/$cleanRef/master.m3u8';
            // ⚠️ Don't set thumbUrl to .../thumb.0000000.jpg speculatively —
            // CloudFront returns HTTP 403 XML for untranscoded videos which crashes
            // Android's ImageDecoder with 'unimplemented'. Leave null for now;
            // if raw.postImageUrl is set it will be picked up below.
            thumbUrl = null;
          } else if (raw.authorId != null && raw.authorId!.isNotEmpty) {
            mediaUrl = '${AppConfig.cdnUrl}/images/original/${raw.authorId}/$cleanRef.jpg';
            thumbUrl = mediaUrl;
          } else {
            mediaUrl = '${AppConfig.baseUrl.replaceAll(RegExp(r"/+$"), "")}/media/$cleanRef';
            thumbUrl = mediaUrl;
          }
        }
      }

      mediaUrl ??= widget.chatMessage?.postThumbnailAsset;
      // Prefer the backend-supplied postImageUrl for video thumbnails.
      // It's a verified CDN URL — safe for ImageDecoder.
      if (thumbUrl == null &&
          raw.postImageUrl != null &&
          raw.postImageUrl!.isNotEmpty) {
        thumbUrl = raw.postImageUrl;
      }
      thumbUrl ??= mediaUrl;
      _resolvedVideoUrl = mediaUrl;

      final String? rawDisplayName = (raw.authorDisplayName != null && raw.authorDisplayName!.trim().isNotEmpty)
          ? raw.authorDisplayName!.trim()
          : null;

      final String resolvedAuthor = (raw.authorName != null && raw.authorName!.isNotEmpty)
          ? (raw.authorName!.startsWith('@') ? raw.authorName! : '@${raw.authorName!}')
          : (rawDisplayName != null
              ? '@${rawDisplayName.toLowerCase().replaceAll(' ', '_')}'
              : (widget.chatMessage?.postAuthor ?? '@creator'));

      final String resolvedDisplayName = rawDisplayName ??
          ((raw.authorName != null && raw.authorName!.isNotEmpty)
              ? raw.authorName!
              : (widget.chatMessage?.postAuthor?.replaceAll('@', '') ?? 'Creator'));

      final String resolvedAvatar = (raw.authorAvatar != null && raw.authorAvatar!.isNotEmpty)
          ? raw.authorAvatar!
          : (widget.chatMessage?.postAuthorAvatarUrl ?? AppImages.user1);

      if (mounted) {
        setState(() {
          _post = PostItemModel(
            id: raw.id,
            authorId: raw.authorId,
            authorDisplayName: resolvedDisplayName,
            username: resolvedAuthor,
            pronounsTime: raw.createdAt != null && raw.createdAt!.isNotEmpty
                ? raw.createdAt!
                : (widget.chatMessage?.timestamp ?? 'Recently'),
            avatarAsset: resolvedAvatar,
            content: raw.caption.isNotEmpty
                ? raw.caption
                : (widget.chatMessage?.postCaption ?? ''),
            likesCount: raw.likesCount > 0
                ? raw.likesCount
                : (widget.chatMessage?.postLikes ?? 0),
            commentsCount: raw.commentsCount > 0
                ? raw.commentsCount
                : (widget.chatMessage?.postComments ?? 0),
            postImageUrl: isVideoType ? thumbUrl : (mediaUrl ?? thumbUrl),
            postType: isVideoType ? 'VIDEO' : 'IMAGE',
            isLiked: raw.isLiked,
            isSaved: raw.isSaved,
            allowComments: raw.allowComments,
            allowDownloads: raw.allowDownloads,
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Fallback to chat message data if network fetch failed
        if (widget.chatMessage != null) {
          final ChatMessageModel m = widget.chatMessage!;
          setState(() {
            _isReel = m.postType == 'reel';
            _resolvedVideoUrl = m.postThumbnailAsset;
            _post = PostItemModel(
              id: widget.postId,
              authorId: m.senderId,
              username: m.postAuthor ?? '@creator',
              pronounsTime: m.timestamp.isNotEmpty ? m.timestamp : 'Recently',
              avatarAsset: m.postAuthorAvatarUrl ?? AppImages.user1,
              content: m.postCaption ?? '',
              likesCount: m.postLikes ?? 0,
              commentsCount: m.postComments ?? 0,
              postImageUrl: m.postThumbnailAsset,
              postType: m.postType == 'reel' ? 'VIDEO' : 'IMAGE',
            );
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = 'Could not load post: $e';
            _isLoading = false;
          });
        }
      }
    }
  }

  void _openFullscreenReel() async {
    if (_post == null) return;
    final ReelItemModel reel = ReelItemModel(
      id: _post!.id,
      authorId: _post!.authorId,
      username: _post!.username,
      pronounsTime: _post!.pronounsTime,
      avatarAsset: _post!.avatarAsset,
      videoAsset: '',
      videoUrl: _resolvedVideoUrl ?? _post!.postImageUrl,
      thumbnailUrl: _post!.postImageUrl,
      caption: _post!.content,
      likesCount: _post!.likesCount,
      commentsCount: _post!.commentsCount,
      isLiked: _post!.isLiked,
      isSaved: _post!.isSaved,
    );

    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: <Widget>[
              ReelsFeedView(
                initialPage: 0,
                customReels: <ReelItemModel>[reel],
                hasBottomBar: false,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white24,
                        ),
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

    if (mounted && _post != null) {
      final HomeFeedProvider hFeed = context.read<HomeFeedProvider>();
      setState(() {
        _post = _post!.copyWith(
          isLiked: hFeed.isPostLiked(_post!.id),
          isSaved: hFeed.isPostSaved(_post!.id),
        );
      });
    }
  }

  void _openFullscreenImage() async {
    if (_post == null) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PostFullscreenImageViewerScreen(post: _post!),
      ),
    );

    if (mounted && _post != null) {
      final HomeFeedProvider hFeed = context.read<HomeFeedProvider>();
      setState(() {
        _post = _post!.copyWith(
          isLiked: hFeed.isPostLiked(_post!.id),
          isSaved: hFeed.isPostSaved(_post!.id),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      appBar: AppBar(
        backgroundColor: context.themeBackground,
        elevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.themeCardBackground,
              border: Border.all(
                color: context.themeBorder,
              ),
            ),
            child: Icon(
              Icons.chevron_left_rounded,
              color: context.themeIcon,
              size: 24,
            ),
          ),
        ),
        title: Text(
          _isReel ? 'Reel' : 'Post',
          style: AppTextStyles.headingMedium.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: context.themeTextPrimary,
          ),
        ),
        actions: <Widget>[
          if ((_post?.postImageUrl != null ||
                  _post?.postImageAsset != null ||
                  _resolvedVideoUrl != null) &&
              (_post?.allowDownloads ?? false))
            IconButton(
              icon: Icon(
                Icons.download_rounded,
                color: context.themeIcon,
                size: 22,
              ),
              onPressed: () {
                final AuthProvider auth = context.read<AuthProvider>();
                final bool isCreator = (_post?.authorId != null &&
                    auth.userId != null &&
                    _post!.authorId!.toLowerCase() == auth.userId!.toLowerCase());
                MediaDownloadService.downloadMedia(
                  context: context,
                  mediaUrl: _resolvedVideoUrl ?? _post?.postImageUrl ?? _post?.postImageAsset,
                  title: _post?.username ?? 'queerloop_post',
                  authorId: _post?.authorId,
                  isVideo: _isReel,
                  allowDownloads: _post?.allowDownloads ?? true,
                  isCreator: isCreator,
                );
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: AppColors.gradientCyan,
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.error_outline_rounded,
                          color: context.themeTextMuted,
                          size: 48,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.themeTextSecondary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        ElevatedButton(
                          onPressed: _loadPost,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gradientCyan,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Retry',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : _post == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
                      child: Column(
                        children: <Widget>[
                          PostFeedCard(
                            post: _post!,
                            onLikeToggle: () {
                              final bool nowLiked = !_post!.isLiked;
                              final int newCount = _post!.likesCount + (nowLiked ? 1 : -1);
                              setState(() {
                                _post = _post!.copyWith(
                                  isLiked: nowLiked,
                                  likesCount: newCount,
                                );
                              });
                              try {
                                context.read<HomeFeedProvider>().toggleLikePost(
                                  _post!.id,
                                  fallbackPost: _post,
                                );
                              } catch (_) {}
                              try {
                                context.read<ProfileProvider>().updateLikedPost(
                                  _post!.id,
                                  isLiked: nowLiked,
                                  likesCount: newCount,
                                  fallbackPost: _post,
                                );
                              } catch (_) {}
                            },
                            onSaveToggle: () {
                              final bool nowSaved = !_post!.isSaved;
                              setState(() {
                                _post = _post!.copyWith(isSaved: nowSaved);
                              });
                              try {
                                context.read<HomeFeedProvider>().toggleSavePost(
                                  _post!.id,
                                  fallbackPost: _post,
                                );
                              } catch (_) {}
                              try {
                                context.read<ProfileProvider>().updateSavedPost(
                                  _post!.id,
                                  isSaved: nowSaved,
                                  fallbackPost: _post,
                                );
                              } catch (_) {}
                            },
                            onOpenComments: () {
                              showModalBottomSheet<void>(
                                context: context,
                                isScrollControlled: true,
                                backgroundColor: Colors.transparent,
                                builder: (_) => CommentsBottomSheet(
                                  postId: _post!.id,
                                  postAuthorId: _post!.authorId,
                                  totalComments: _post!.commentsCount,
                                  allowComments: _post?.allowComments ?? true,
                                  onCommentAdded: () {
                                    setState(() {
                                      _post = _post!.copyWith(
                                        commentsCount: _post!.commentsCount + 1,
                                      );
                                    });
                                    try {
                                      context
                                          .read<HomeFeedProvider>()
                                          .incrementCommentCount(_post!.id);
                                    } catch (_) {}
                                  },
                                ),
                              );
                            },
                          ),
                          if (_isReel)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              child: GestureDetector(
                                onTap: _openFullscreenReel,
                                child: Container(
                                  width: double.infinity,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradientButton,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: AppColors.gradientPink.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Watch Full Reel',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else if ((_post!.postImageUrl != null && _post!.postImageUrl!.isNotEmpty) ||
                              (_post!.postImageAsset != null && _post!.postImageAsset!.isNotEmpty))
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                                vertical: AppSpacing.md,
                              ),
                              child: GestureDetector(
                                onTap: _openFullscreenImage,
                                child: Container(
                                  width: double.infinity,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: AppColors.secondaryGradientButton,
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: AppColors.gradientCyan.withValues(alpha: 0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Icon(
                                        Icons.fullscreen_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'View Full Photo',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../discover/models/discover_models.dart';
import '../../discover/services/discover_service.dart';
import '../models/post_item_model.dart';
import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/post_feed_card.dart';

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

class _HashtagPostsScreenState extends State<HashtagPostsScreen> {
  List<PostItemModel> _posts = <PostItemModel>[];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  Future<void> _loadPosts() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final String rawTag = widget.hashtag.trim();
    final String cleanTag = rawTag.startsWith('#') ? rawTag.substring(1) : rawTag;
    final String hashTag = '#$cleanTag';
    final String tagLower = cleanTag.toLowerCase();

    final List<PostItemModel> results = <PostItemModel>[];
    final Set<String> seenIds = <String>{};

    // 1. Scan live feed posts and reels that match this hashtag
    try {
      final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
      for (final PostItemModel p in homeFeed.posts) {
        final String contentLower = p.content.toLowerCase();
        if (contentLower.contains(hashTag.toLowerCase()) ||
            contentLower.contains(tagLower)) {
          if (seenIds.add(p.id)) {
            results.add(p);
          }
        }
      }
      for (final ReelItemModel r in homeFeed.reels) {
        final String captionLower = r.caption.toLowerCase();
        final bool hasTag = r.tags.any(
          (String t) => t.toLowerCase().replaceAll('#', '') == tagLower,
        );
        if (hasTag ||
            captionLower.contains(hashTag.toLowerCase()) ||
            captionLower.contains(tagLower)) {
          if (seenIds.add(r.id)) {
            results.add(
              PostItemModel(
                id: r.id,
                authorId: r.authorId,
                username: r.username,
                pronounsTime: r.pronounsTime,
                avatarAsset: r.avatarAsset,
                content: r.caption,
                likesCount: r.likesCount,
                commentsCount: r.commentsCount,
                postImageUrl: r.thumbnailUrl ?? r.videoUrl,
                postImageAsset:
                    r.videoAsset.isNotEmpty ? r.videoAsset : null,
                postType: 'VIDEO',
                isLiked: r.isLiked,
                isSaved: r.isSaved,
              ),
            );
          }
        }
      }
    } catch (_) {}

    // 2. Query backend search API dynamically for this specific hashtag
    try {
      final ApiClient client = context.read<ApiClient>();
      final DiscoverService service = DiscoverService(client);

      MultiTabSearchResults searchRes = await service.search(
        query: rawTag,
        tab: 'posts',
      );

      if (searchRes.posts.isEmpty && cleanTag != rawTag) {
        searchRes = await service.search(
          query: cleanTag,
          tab: 'posts',
        );
      }

      for (final DiscoverSearchResult item in searchRes.posts) {
        final String id = item.id ?? 'search_${item.caption.hashCode}';
        if (seenIds.add(id)) {
          final String img = (item.imageAsset.isNotEmpty
                  ? item.imageAsset
                  : (item.thumbnailUrl ?? ''))
              .trim();
          final bool isHttp =
              img.startsWith('http://') || img.startsWith('https://');
          final bool isAsset = img.startsWith('assets/');

          results.add(
            PostItemModel(
              id: id,
              authorId: item.authorId,
              username: (item.authorUsername != null &&
                      item.authorUsername!.trim().isNotEmpty)
                  ? (item.authorUsername!.startsWith('@')
                      ? item.authorUsername!.trim()
                      : '@${item.authorUsername!.trim()}')
                  : '@queer_creator',
              pronounsTime: 'they/them · recent',
              avatarAsset: (item.authorAvatar != null &&
                      item.authorAvatar!.trim().isNotEmpty)
                  ? item.authorAvatar!.trim()
                  : AppImages.user1,
              content: (item.caption != null && item.caption!.trim().isNotEmpty)
                  ? item.caption!
                  : 'Post about $hashTag',
              likesCount: item.likesCount ?? 0,
              commentsCount: item.commentsCount ?? 0,
              postImageUrl: isHttp ? img : null,
              postImageAsset: isAsset ? img : null,
              postType: item.isReel ? 'VIDEO' : 'PHOTO',
              communityId: item.communityId,
              isLiked: item.isLiked,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('⚠️ [HashtagPostsScreen] Error fetching hashtag posts: $e');
    }

    if (mounted) {
      setState(() {
        _posts = results;
        _isLoading = false;
      });
    }
  }

  void _toggleLike(String id) {
    setState(() {
      final int i = _posts.indexWhere((PostItemModel p) => p.id == id);
      if (i != -1) {
        final PostItemModel item = _posts[i];
        final bool newLiked = !item.isLiked;
        _posts[i] = item.copyWith(
          isLiked: newLiked,
          likesCount: newLiked
              ? item.likesCount + 1
              : (item.likesCount > 0 ? item.likesCount - 1 : 0),
        );
      }
    });
    try {
      context.read<HomeFeedProvider>().toggleLikePost(id);
    } catch (_) {}
  }

  void _toggleSave(String id) {
    setState(() {
      final int i = _posts.indexWhere((PostItemModel p) => p.id == id);
      if (i != -1) {
        _posts[i] = _posts[i].copyWith(isSaved: !_posts[i].isSaved);
      }
    });
    try {
      context.read<HomeFeedProvider>().toggleSavePost(id);
    } catch (_) {}
  }

  void _showCommentsSheet(BuildContext context, int totalComments) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return CommentsBottomSheet(totalComments: totalComments);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String postCountText = _posts.isNotEmpty
        ? '${_posts.length} ${_posts.length == 1 ? 'post' : 'posts'}'
        : widget.postsCount;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
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
                  // Back button
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
                  // Search icon
                  SvgPicture.asset(
                    AppIcons.search,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(
                      context.themeIconMuted,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────────────────────
            Divider(
              height: 1,
              color: context.themeDivider,
            ),

            // ── Posts Feed ───────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gradientPink,
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.gradientPink,
                      backgroundColor: context.themeCardBackground,
                      onRefresh: _loadPosts,
                      child: _posts.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: <Widget>[
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.55,
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 32,
                                      ),
                                      child: Column(
                                        mainAxisAlignment:
                                          MainAxisAlignment.center,
                                        children: <Widget>[
                                          Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: widget.rankColor
                                                  .withValues(alpha: 0.12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                '#',
                                                style: TextStyle(
                                                  fontSize: 36,
                                                  fontWeight: FontWeight.w900,
                                                  color: widget.rankColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 18),
                                          Text(
                                            'No posts yet for ${widget.hashtag}',
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.titleMedium
                                                .copyWith(
                                              color: context.themeTextPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 17,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Posts and videos tagging ${widget.hashtag} will appear here.',
                                            textAlign: TextAlign.center,
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: context.themeTextMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
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
                                  onLikeToggle: () => _toggleLike(post.id),
                                  onSaveToggle: () => _toggleSave(post.id),
                                  onOpenComments: () => _showCommentsSheet(
                                    context,
                                    post.commentsCount,
                                  ),
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

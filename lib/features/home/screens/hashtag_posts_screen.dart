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
import '../../discover/provider/discover_provider.dart';
import '../../discover/services/discover_service.dart';
import '../models/post_item_model.dart';
import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/post_feed_card.dart';
import 'reels_feed_view.dart';
import 'single_post_view_screen.dart';

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

    // 1. Scan live feed posts for matching hashtag
    try {
      final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
      for (final PostItemModel p in homeFeed.posts) {
        final String contentLower = p.content.toLowerCase();
        if (contentLower.contains(hashTag.toLowerCase()) ||
            contentLower.contains(tagLower)) {
          if (seenIds.add(p.id)) {
            final bool isVid = p.postType.toUpperCase().trim() == 'VIDEO' ||
                p.postType.toLowerCase().trim() == 'reel' ||
                (p.postImageUrl != null &&
                    (p.postImageUrl!.endsWith('.mp4') ||
                        p.postImageUrl!.endsWith('.m3u8') ||
                        p.postImageUrl!.contains('video') ||
                        p.postImageUrl!.contains('/videos/')));
            if (isVid) {
              videoReels.add(ReelItemModel(
                id: p.id,
                authorId: p.authorId,
                authorDisplayName: p.authorDisplayName ?? p.username,
                username: p.username,
                pronounsTime: p.pronounsTime,
                avatarAsset: p.avatarAsset,
                videoAsset: '',
                videoUrl: p.postImageUrl,
                thumbnailUrl: p.postImageUrl,
                caption: p.content,
                likesCount: p.likesCount,
                commentsCount: p.commentsCount,
                isLiked: p.isLiked,
                isSaved: p.isSaved,
                communityId: p.communityId,
              ));
            } else {
              photoPosts.add(p);
            }
          }
        }
      }
      // Scan live reels for matching hashtag – keep as reels
      for (final ReelItemModel r in homeFeed.reels) {
        final String captionLower = r.caption.toLowerCase();
        final bool hasTag = r.tags.any(
          (String t) => t.toLowerCase().replaceAll('#', '') == tagLower,
        );
        if (hasTag ||
            captionLower.contains(hashTag.toLowerCase()) ||
            captionLower.contains(tagLower)) {
          if (seenIds.add(r.id)) {
            videoReels.add(r);
          }
        }
      }
    } catch (_) {}

    // 2. Query backend search API for this hashtag
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
        if (!seenIds.add(id)) continue;

        final String img = (item.imageAsset.isNotEmpty
                ? item.imageAsset
                : (item.thumbnailUrl ?? ''))
            .trim();
        final bool isHttp =
            img.startsWith('http://') || img.startsWith('https://');
        final bool isAsset = img.startsWith('assets/');

        final bool isVid = item.isReel ||
            item.type?.toUpperCase() == 'VIDEO' ||
            item.type?.toUpperCase() == 'REEL' ||
            (item.videoUrl != null && item.videoUrl!.isNotEmpty) ||
            img.endsWith('.mp4') ||
            img.endsWith('.m3u8') ||
            img.contains('video') ||
            img.contains('/videos/');

        if (isVid) {
          // Build a ReelItemModel for video results
          videoReels.add(ReelItemModel(
            id: id,
            authorId: item.authorId,
            authorDisplayName: item.authorUsername ?? 'Creator',
            username: (item.authorUsername != null &&
                    item.authorUsername!.trim().isNotEmpty)
                ? (item.authorUsername!.startsWith('@')
                    ? item.authorUsername!.trim()
                    : '@${item.authorUsername!.trim()}')
                : '@creator',
            pronounsTime: 'they/them · recent',
            avatarAsset: (item.authorAvatar != null &&
                    item.authorAvatar!.trim().isNotEmpty)
                ? item.authorAvatar!.trim()
                : AppImages.user1,
            videoAsset: '',
            videoUrl: isHttp ? (item.videoUrl ?? img) : null,
            thumbnailUrl: isHttp ? (item.thumbnailUrl ?? img) : null,
            caption: (item.caption != null && item.caption!.trim().isNotEmpty)
                ? item.caption!
                : 'Reel about $hashTag',
            likesCount: item.likesCount ?? 0,
            commentsCount: item.commentsCount ?? 0,
            isLiked: item.isLiked,
            communityId: item.communityId,
          ));
        } else {
          photoPosts.add(PostItemModel(
            id: id,
            authorId: item.authorId,
            authorDisplayName: item.authorUsername,
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
            postType: 'PHOTO',
            communityId: item.communityId,
            isLiked: item.isLiked,
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

  void _openReelPlayer(int initialIndex) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          body: Stack(
            children: <Widget>[
              ReelsFeedView(
                initialPage: initialIndex,
                customReels: _reels,
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

  static String _formatCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final int totalCount = _posts.length + _reels.length;
    final String postCountText = !_isLoading && totalCount > 0
        ? '$totalCount ${totalCount == 1 ? 'post' : 'posts'}'
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
            onCardTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => SinglePostViewScreen(
                    postId: post.id,
                    initialPost: post,
                  ),
                ),
              );
            },
            onLikeToggle: () => _toggleLike(post.id),
            onSaveToggle: () => _toggleSave(post.id),
            onOpenComments: () =>
                _showCommentsSheet(context, post.commentsCount),
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
                          _formatCount(reel.likesCount > 0 ? reel.likesCount : 0),
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

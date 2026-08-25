import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/post_item_model.dart';
import '../widgets/comments_bottom_sheet.dart';
import '../widgets/post_feed_card.dart';

/// Dummy per-hashtag post data
Map<String, List<PostItemModel>> _hashtagPosts = <String, List<PostItemModel>>{
  '#chosenfamily': <PostItemModel>[
    PostItemModel(
      id: 'cf_1',
      username: '@jules.does',
      pronounsTime: 'she/they · 1h',
      avatarAsset: AppImages.user1,
      content:
          'Chosen family showed up at 2am with snacks and no questions asked. This is what love looks like 🏳️‍🌈 #chosenfamily',
      postImageAsset: AppImages.forYouImg,
      likesCount: 4200,
      commentsCount: 214,
    ),
    PostItemModel(
      id: 'cf_2',
      username: '@nadia.builds',
      pronounsTime: 'she/her · 3h',
      avatarAsset: AppImages.user1,
      content:
          'Five years ago I had nobody at my birthday. Last night 12 people surprised me. Chosen family is real. #chosenfamily',
      likesCount: 8700,
      commentsCount: 512,
    ),
    PostItemModel(
      id: 'cf_3',
      username: '@rowankeeps',
      pronounsTime: 'they/them · 5h',
      avatarAsset: AppImages.user2,
      content:
          'The family you choose loves you for exactly who you are, no edits required 🤍 #chosenfamily',
      postImageAsset: AppImages.communityImg,
      likesCount: 3100,
      commentsCount: 98,
    ),
  ],
  '#prideprep2026': <PostItemModel>[
    PostItemModel(
      id: 'pp_1',
      username: '@moss.and.oat',
      pronounsTime: 'she/her · 2h',
      avatarAsset: AppImages.user3,
      content:
          'Already planning my Pride 2026 outfit and we still have 8 months 😭✨ #prideprep2026',
      postImageAsset: AppImages.followingImg,
      likesCount: 2900,
      commentsCount: 177,
    ),
    PostItemModel(
      id: 'pp_2',
      username: '@theo.vance',
      pronounsTime: 'he/him · 4h',
      avatarAsset: AppImages.user4,
      content:
          'Booking the hotel NOW before prices go crazy. Who\'s coming to Pride 2026? 🏳️‍🌈 #prideprep2026',
      likesCount: 5600,
      commentsCount: 341,
    ),
  ],
  '#binderfitcheck': <PostItemModel>[
    PostItemModel(
      id: 'bf_1',
      username: '@rowankeeps',
      pronounsTime: 'they/them · 30m',
      avatarAsset: AppImages.user2,
      content:
          'New binder just dropped and I look incredible. Six months post-op and thriving 💙 #binderfitcheck',
      postImageAsset: AppImages.forYouImg,
      likesCount: 6800,
      commentsCount: 429,
    ),
    PostItemModel(
      id: 'bf_2',
      username: '@nadia.builds',
      pronounsTime: 'she/her · 2h',
      avatarAsset: AppImages.user1,
      content:
          'Day 1 of my binder journey. Nervous but excited 🤍 Drop your tips below! #binderfitcheck',
      likesCount: 3400,
      commentsCount: 267,
    ),
  ],
  '#queerbooktok': <PostItemModel>[
    PostItemModel(
      id: 'qb_1',
      username: '@jules.does',
      pronounsTime: 'she/they · 1h',
      avatarAsset: AppImages.user1,
      content:
          'Just finished "Giovanni\'s Room" and I need to lie down for a week. 10/10 highly recommend crying #queerbooktok',
      postImageAsset: AppImages.communityImg,
      likesCount: 4100,
      commentsCount: 302,
    ),
    PostItemModel(
      id: 'qb_2',
      username: '@moss.and.oat',
      pronounsTime: 'she/her · 4h',
      avatarAsset: AppImages.user3,
      content:
          'Queer books that changed my life thread 🧵👇 Reply with yours! #queerbooktok',
      likesCount: 7200,
      commentsCount: 891,
    ),
  ],
};

List<PostItemModel> _postsForHashtag(String hashtag) {
  return _hashtagPosts[hashtag] ??
      <PostItemModel>[
        PostItemModel(
          id: 'generic_1',
          username: '@queerloop',
          pronounsTime: '· just now',
          avatarAsset: AppImages.user1,
          content: 'No posts yet for $hashtag. Be the first! 🌈',
          likesCount: 0,
          commentsCount: 0,
        ),
      ];
}

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
  late List<PostItemModel> _posts;

  @override
  void initState() {
    super.initState();
    _posts = _postsForHashtag(widget.hashtag)
        .map((PostItemModel p) => p.copyWith())
        .toList();
  }

  void _toggleLike(String id) {
    setState(() {
      final int i = _posts.indexWhere((PostItemModel p) => p.id == id);
      if (i != -1) {
        final PostItemModel item = _posts[i];
        final bool newLiked = !item.isLiked;
        _posts[i] = item.copyWith(
          isLiked: newLiked,
          likesCount: newLiked ? item.likesCount + 1 : item.likesCount - 1,
        );
      }
    });
  }

  void _toggleSave(String id) {
    setState(() {
      final int i = _posts.indexWhere((PostItemModel p) => p.id == id);
      if (i != -1) {
        _posts[i] = _posts[i].copyWith(isSaved: !_posts[i].isSaved);
      }
    });
  }

  void _showCommentsSheet(BuildContext context, int totalComments) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return CommentsBottomSheet(totalComments: totalComments);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                        color: const Color(0xFF1E1B26),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
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
                          widget.postsCount,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white54,
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
                    colorFilter: const ColorFilter.mode(
                      Colors.white54,
                      BlendMode.srcIn,
                    ),
                  ),
                ],
              ),
            ),

            // ── Divider ──────────────────────────────────────────────────────
            Container(
              height: 1,
              color: Colors.white.withValues(alpha: 0.06),
            ),

            // ── Posts Feed ───────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
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
                    onOpenComments: () =>
                        _showCommentsSheet(context, post.commentsCount),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

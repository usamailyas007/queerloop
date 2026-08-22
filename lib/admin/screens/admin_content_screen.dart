import 'package:flutter/material.dart';

import '../../core/theme/app_images.dart';
import '../../core/theme/app_spacing.dart';

enum _PostStatus { live, hidden, inReview }

class _ContentPost {
  _ContentPost({
    required this.thumbnail,
    required this.views,
    required this.handle,
    required this.pronoun,
    required this.status,
    this.reportCount = 0,
  });

  final String thumbnail;
  final String views;
  final String handle;
  final String pronoun;
  _PostStatus status;
  final int reportCount;
}

class _TrendingPost {
  const _TrendingPost({
    required this.rank,
    required this.thumbnail,
    required this.views,
    required this.handle,
    required this.pronoun,
  });

  final int rank;
  final String thumbnail;
  final String views;
  final String handle;
  final String pronoun;
}

class AdminContentScreen extends StatefulWidget {
  const AdminContentScreen({super.key});

  @override
  State<AdminContentScreen> createState() => _AdminContentScreenState();
}

class _AdminContentScreenState extends State<AdminContentScreen> {
  final List<_ContentPost> _posts = <_ContentPost>[
    _ContentPost(
      thumbnail: AppImages.searchResult1,
      views: '12.4K',
      handle: '@rowankeeps',
      pronoun: 'Transgender',
      status: _PostStatus.live,
    ),
    _ContentPost(
      thumbnail: AppImages.searchResult2,
      views: '0',
      handle: '@truth_ftw',
      pronoun: 'Queer',
      status: _PostStatus.hidden,
    ),
    _ContentPost(
      thumbnail: AppImages.searchResult3,
      views: '0',
      handle: '@jules.does',
      pronoun: 'Queer',
      status: _PostStatus.live,
    ),
    _ContentPost(
      thumbnail: AppImages.searchResult4,
      views: '228K',
      handle: '@kj.after.dark',
      pronoun: 'Gay',
      status: _PostStatus.inReview,
      reportCount: 3,
    ),
    _ContentPost(
      thumbnail: AppImages.searchResult5,
      views: '0',
      handle: '@nadia.builds',
      pronoun: 'Queer',
      status: _PostStatus.live,
    ),
    _ContentPost(
      thumbnail: AppImages.searchResult6,
      views: '54K',
      handle: '@ashinorbit',
      pronoun: 'General',
      status: _PostStatus.live,
    ),
  ];

  static const List<_TrendingPost> _trending = <_TrendingPost>[
    _TrendingPost(
      rank: 1,
      thumbnail: AppImages.searchResult6,
      views: '412K',
      handle: '@rowankeeps',
      pronoun: 'Transgender',
    ),
    _TrendingPost(
      rank: 2,
      thumbnail: AppImages.searchResult4,
      views: '228K',
      handle: '@nadia.builds',
      pronoun: 'Queer',
    ),
    _TrendingPost(
      rank: 3,
      thumbnail: AppImages.searchResult3,
      views: '176K',
      handle: '@jules.does',
      pronoun: 'Queer',
    ),
    _TrendingPost(
      rank: 4,
      thumbnail: AppImages.searchResult2,
      views: '121K',
      handle: '@ashinorbit',
      pronoun: 'General',
    ),
    _TrendingPost(
      rank: 5,
      thumbnail: AppImages.searchResult1,
      views: '88K',
      handle: '@kj.after.dark',
      pronoun: 'Gay',
    ),
    _TrendingPost(
      rank: 6,
      thumbnail: AppImages.searchResult5,
      views: '54K',
      handle: '@rowankeeps',
      pronoun: 'Non-binary',
    ),
  ];

  void _toggleHidden(_ContentPost post) {
    setState(() {
      post.status =
          post.status == _PostStatus.hidden ? _PostStatus.live : _PostStatus.hidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Content',
                style: TextStyle(
                  color: Color(0xFFF3EFF7),
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _posts.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 0.62,
                    ),
                    itemBuilder: (_, int index) =>
                        _ContentCard(post: _posts[index], onToggleHidden: () => _toggleHidden(_posts[index])),
                  );
                },
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFF141119),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(Icons.local_fire_department_rounded,
                            size: 16, color: Color(0xFFFFB45C)),
                        SizedBox(width: 6),
                        Text(
                          'Trending videos',
                          style: TextStyle(
                              color: Color(0xFFF3EFF7),
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _trending.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        mainAxisSpacing: AppSpacing.md,
                        crossAxisSpacing: AppSpacing.md,
                        childAspectRatio: 0.72,
                      ),
                      itemBuilder: (_, int index) =>
                          _TrendingCard(post: _trending[index]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.post, required this.onToggleHidden});

  final _ContentPost post;
  final VoidCallback onToggleHidden;

  @override
  Widget build(BuildContext context) {
    final (String label, Color color) = switch (post.status) {
      _PostStatus.live => ('Live', const Color(0xFF3FE0AE)),
      _PostStatus.hidden => ('Hidden', const Color(0xFFFF3B77)),
      _PostStatus.inReview => ('In review', const Color(0xFFFFB45C)),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(post.thumbnail, fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      post.status == _PostStatus.inReview
                          ? 'Reported x${post.reportCount}'
                          : label,
                      style: const TextStyle(
                        color: Color(0xFFF3EFF7),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.remove_red_eye_outlined,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        post.views,
                        style: const TextStyle(
                            color: Color(0xFFF3EFF7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${post.handle} · ${post.pronoun}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF948CA3), fontSize: 11),
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Expanded(
              child: _MiniButton(label: 'View', onTap: () {}),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: _MiniButton(
                label: post.status == _PostStatus.hidden ? 'Restore' : 'Hide',
                danger: post.status != _PostStatus.hidden,
                onTap: onToggleHidden,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendingCard extends StatelessWidget {
  const _TrendingCard({required this.post});

  final _TrendingPost post;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Image.asset(post.thumbnail, fit: BoxFit.cover),
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${post.rank}',
                      style: const TextStyle(
                        color: Color(0xFFF3EFF7),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.remove_red_eye_outlined,
                          size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        post.views,
                        style: const TextStyle(
                            color: Color(0xFFF3EFF7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${post.handle} · ${post.pronoun}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF948CA3), fontSize: 11),
        ),
      ],
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: danger
              ? const Color(0xFFFF3B77).withValues(alpha: 0.14)
              : const Color(0xFF1C1824),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: danger
                ? const Color(0xFFFF3B77).withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: danger ? const Color(0xFFFF3B77) : Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

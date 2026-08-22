import 'package:flutter/material.dart';

import '../../core/theme/app_images.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_gradient_button.dart';
import 'admin_spotlight_form_screen.dart';

class _SpotlightPost {
  const _SpotlightPost({
    required this.thumbnail,
    required this.handle,
    required this.community,
    required this.postedAgo,
    required this.isLive,
  });

  final String thumbnail;
  final String handle;
  final String community;
  final String postedAgo;
  final bool isLive;
}

class AdminSpotlightScreen extends StatefulWidget {
  const AdminSpotlightScreen({super.key});

  @override
  State<AdminSpotlightScreen> createState() => _AdminSpotlightScreenState();
}

class _AdminSpotlightScreenState extends State<AdminSpotlightScreen> {
  bool _isAdding = false;

  static const List<_SpotlightPost> _past = <_SpotlightPost>[
    _SpotlightPost(
      thumbnail: AppImages.searchResult1,
      handle: '@rowankeeps',
      community: 'Transgender',
      postedAgo: '3 Aug',
      isLive: true,
    ),
    _SpotlightPost(
      thumbnail: AppImages.searchResult2,
      handle: '@jules.does',
      community: 'Queer',
      postedAgo: '27 Jul',
      isLive: false,
    ),
    _SpotlightPost(
      thumbnail: AppImages.searchResult3,
      handle: '@ashinorbit',
      community: 'General',
      postedAgo: '20 Jul',
      isLive: false,
    ),
    _SpotlightPost(
      thumbnail: AppImages.searchResult4,
      handle: '@kj.after.dark',
      community: 'Gay',
      postedAgo: '13 Jul',
      isLive: false,
    ),
    _SpotlightPost(
      thumbnail: AppImages.searchResult5,
      handle: '@nadia.builds',
      community: 'Bisexual',
      postedAgo: '6 Jul',
      isLive: false,
    ),
    _SpotlightPost(
      thumbnail: AppImages.searchResult6,
      handle: '@rowankeeps',
      community: 'Non-binary',
      postedAgo: '29 Jun',
      isLive: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_isAdding) {
      return AdminSpotlightFormScreen(
        onBack: () => setState(() => _isAdding = false),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Community spotlight',
                          style: TextStyle(
                            color: Color(0xFFF3EFF7),
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Featured member stories shown on the Discover tab',
                          style: TextStyle(
                            color: Color(0xFF948CA3),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150,
                    height: 44,
                    child: AppGradientButton(
                      text: 'New spotlight',
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      onPressed: () => setState(() => _isAdding = true),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141119),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.09),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Past spotlights',
                        style: TextStyle(
                          color: Color(0xFFF3EFF7),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: GridView.builder(
                          itemCount: _past.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                mainAxisSpacing: AppSpacing.md,
                                crossAxisSpacing: AppSpacing.md,
                                childAspectRatio: 0.62,
                              ),
                          itemBuilder: (_, int index) =>
                              _SpotlightCard(post: _past[index]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({required this.post});

  final _SpotlightPost post;

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (post.isLive
                                  ? const Color(0xFF3FE0AE)
                                  : const Color(0xFF948CA3))
                              .withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      post.isLive ? 'Live' : 'Ended',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${post.handle} · ${post.community}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Color(0xFF948CA3), fontSize: 11),
        ),
        Text(
          post.postedAgo,
          style: const TextStyle(color: Color(0xFF635C72), fontSize: 10),
        ),
      ],
    );
  }
}

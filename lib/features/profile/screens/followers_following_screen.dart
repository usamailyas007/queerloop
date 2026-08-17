import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../widgets/follow_user_tile.dart';

class FollowersFollowingScreen extends StatefulWidget {
  const FollowersFollowingScreen({
    this.initialTabIndex = 0,
    super.key,
  });

  final int initialTabIndex;

  @override
  State<FollowersFollowingScreen> createState() =>
      _FollowersFollowingScreenState();
}

class _FollowersFollowingScreenState extends State<FollowersFollowingScreen> {
  late int _selectedTab;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTabIndex;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  static final List<Map<String, String>> _requests = <Map<String, String>>[
    <String, String>{
      'username': 'sam.arroyo',
      'name': 'Sam',
      'avatar': AppImages.user4,
      'subtitle': 'Wants to follow you',
    },
    <String, String>{
      'username': 'finn.rides',
      'name': 'Finn',
      'avatar': AppImages.user2,
      'subtitle': 'Wants to follow you',
    },
    <String, String>{
      'username': 'parker.osei',
      'name': 'Parker',
      'avatar': AppImages.user1,
      'subtitle': 'Wants to follow you',
    },
    <String, String>{
      'username': 'dg_returns',
      'name': 'DG',
      'avatar': AppImages.user3,
      'subtitle': 'Wants to follow you',
    },
  ];

  static const List<Map<String, String>> _users = <Map<String, String>>[
    <String, String>{
      'username': 'jules.does',
      'name': 'Jules',
      'pronouns': 'she/they',
      'avatar': AppImages.user2,
      'isFollowing': 'true',
    },
    <String, String>{
      'username': 'rowankeeps',
      'name': 'Rowan',
      'pronouns': 'they/them',
      'avatar': AppImages.user1,
      'isFollowing': 'false',
    },
    <String, String>{
      'username': 'moss.and.oat',
      'name': 'Moss',
      'pronouns': 'she/her',
      'avatar': AppImages.user3,
      'isFollowing': 'true',
    },
    <String, String>{
      'username': 'theo.vance',
      'name': 'Theo',
      'pronouns': 'he/him',
      'avatar': AppImages.user4,
      'isFollowing': 'false',
    },
    <String, String>{
      'username': 'nadia.builds',
      'name': 'Nadia',
      'pronouns': 'she/her',
      'avatar': AppImages.user4,
      'isFollowing': 'true',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> filteredUsers = _selectedTab == 1
        ? _users.where((Map<String, String> u) => u['isFollowing'] == 'true').toList()
        : _users;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar (Back button + Username "ashinorbit") ──────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Center(
                      child: Text(
                        'ashinorbit',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),

            // ── 3 Tabs (Followers, Following, Requests 4) ────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  // 1. Followers Tab
                  GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Followers',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: _selectedTab == 0
                                ? Colors.white
                                : Colors.white54,
                            fontWeight: _selectedTab == 0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2.5,
                          width: 48,
                          color: _selectedTab == 0
                              ? AppColors.gradientPink
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.xl),

                  // 2. Following Tab
                  GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Column(
                      children: <Widget>[
                        Text(
                          'Following',
                          style: AppTextStyles.titleSmall.copyWith(
                            color: _selectedTab == 1
                                ? Colors.white
                                : Colors.white54,
                            fontWeight: _selectedTab == 1
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2.5,
                          width: 48,
                          color: _selectedTab == 1
                              ? AppColors.gradientPink
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.xl),

                  // 3. Requests Tab (with Pink Count Badge)
                  GestureDetector(
                    onTap: () => setState(() => _selectedTab = 2),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              'Requests',
                              style: AppTextStyles.titleSmall.copyWith(
                                color: _selectedTab == 2
                                    ? Colors.white
                                    : Colors.white54,
                                fontWeight: _selectedTab == 2
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 18,
                              height: 18,
                              decoration: const BoxDecoration(
                                color: AppColors.gradientPink,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${_requests.length}',
                                  style: AppTextStyles.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2.5,
                          width: 48,
                          color: _selectedTab == 2
                              ? AppColors.gradientPink
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF2A2733), height: 1),

            const SizedBox(height: AppSpacing.md),

            // ── Search Input Field ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppTextField(
                controller: _searchController,
                hintText: 'Search',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── List Body ───────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  // Tab 2: Requests ONLY
                  if (_selectedTab == 2) ...<Widget>[
                    ..._requests.map((Map<String, String> req) {
                      return Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            ClipOval(
                              child: Image.asset(
                                req['avatar']!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    req['username']!,
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    req['subtitle']!,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            AppGradientButton(
                              text: 'Accept',
                              height: 32,
                              width: 76,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              onPressed: () {
                                setState(() {
                                  _requests.removeWhere(
                                      (r) => r['username'] == req['username']);
                                });
                              },
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            AppOutlineButton(
                              text: 'Decline',
                              height: 32,
                              width: 76,
                              onPressed: () {
                                setState(() {
                                  _requests.removeWhere(
                                      (r) => r['username'] == req['username']);
                                });
                              },
                            ),
                          ],
                        ),
                      );
                    }),
                  ]

                  // Tab 0 & 1: Followers / Following List
                  else ...<Widget>[
                    ...filteredUsers.map((Map<String, String> user) {
                      return FollowUserTile(
                        username: user['username']!,
                        name: user['name']!,
                        pronouns: user['pronouns']!,
                        avatarAsset: user['avatar']!,
                        isFollowing: user['isFollowing'] == 'true',
                        onTapUser: () {},
                        onToggleFollow: () {},
                      );
                    }),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

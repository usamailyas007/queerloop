import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_follow_button.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_text_field.dart';

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

  static final List<Map<String, String>> _users = <Map<String, String>>[
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
    final bool isDark = context.isDarkMode;

    final List<Map<String, String>> filteredUsers = _selectedTab == 1
        ? _users.where((Map<String, String> u) => u['isFollowing'] == 'true').toList()
        : _users;

    return Scaffold(
      backgroundColor: context.themeBackground,
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
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : context.themeBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: context.themeIcon,
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
                          color: context.themeTextPrimary,
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
                                ? context.themeTextPrimary
                                : context.themeTextMuted,
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
                              ? (_selectedTab == 0 && !isDark
                                  ? const Color(0xFF12101A)
                                  : AppColors.gradientPink)
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
                                ? context.themeTextPrimary
                                : context.themeTextMuted,
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
                              ? (_selectedTab == 1 && !isDark
                                  ? const Color(0xFF12101A)
                                  : AppColors.gradientPink)
                              : Colors.transparent,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.xl),

                  // 3. Requests Tab
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
                                    ? context.themeTextPrimary
                                    : context.themeTextMuted,
                                fontWeight: _selectedTab == 2
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gradientPink,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                '4',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          height: 2.5,
                          width: 58,
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

            Divider(color: context.themeDivider, height: 1),

            const SizedBox(height: AppSpacing.md),

            // ── Search Input Field ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: AppTextField(
                controller: _searchController,
                hintText: _selectedTab == 2
                    ? 'Search requests'
                    : 'Search',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.themeIconMuted,
                  size: 20,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Body List ───────────────────────────────────────────────────
            Expanded(
              child: _selectedTab == 2
                  ? ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      itemCount: _requests.length,
                      separatorBuilder: (BuildContext context, int index) =>
                          const SizedBox(height: AppSpacing.md),
                      itemBuilder: (BuildContext context, int index) {
                        final Map<String, String> req = _requests[index];

                        return Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: context.themeCardBackground,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                            border: Border.all(
                              color: context.themeBorder,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          '@${req['username']}',
                                          style: AppTextStyles.titleSmall
                                              .copyWith(
                                            color: context.themeTextPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          req['subtitle']!,
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                            color: context.themeTextSecondary,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: AppGradientButton(
                                      text: 'Accept',
                                      height: 36,
                                      onPressed: () {
                                        setState(() {
                                          _requests.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: AppOutlineButton(
                                      text: 'Decline',
                                      height: 36,
                                      onPressed: () {
                                        setState(() {
                                          _requests.removeAt(index);
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.xs,
                      ),
                      children: <Widget>[
                        // Top Request Banner in Followers Tab (Matching Image 2)
                        if (_selectedTab == 0 && _requests.isNotEmpty) ...<Widget>[
                          Container(
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm + 2,
                            ),
                            decoration: BoxDecoration(
                              color: context.themeCardBackground,
                              borderRadius: BorderRadius.circular(AppRadius.card),
                              border: Border.all(
                                color: context.themeBorder,
                              ),
                            ),
                            child: Row(
                              children: <Widget>[
                                ClipOval(
                                  child: Image.asset(
                                    _requests.first['avatar']!,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        _requests.first['username']!,
                                        style: AppTextStyles.titleSmall.copyWith(
                                          color: context.themeTextPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        _requests.first['subtitle']!,
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: context.themeTextSecondary,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                AppFollowButton(
                                  isFollowing: false,
                                  onTap: () {
                                    setState(() {
                                      _requests.removeAt(0);
                                    });
                                  },
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                AppOutlineButton(
                                  text: 'Decline',
                                  height: 30,
                                  width: 68,
                                  fontSize: 11,
                                  onPressed: () {
                                    setState(() {
                                      _requests.removeAt(0);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],

                        // Follow List
                        ...filteredUsers.map((Map<String, String> user) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            child: Row(
                              children: <Widget>[
                                ClipOval(
                                  child: Image.asset(
                                    user['avatar']!,
                                    width: 44,
                                    height: 44,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        user['username']!,
                                        style: AppTextStyles.titleSmall.copyWith(
                                          color: context.themeTextPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${user['name']} • ${user['pronouns']}',
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: context.themeTextSecondary,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                AppFollowButton(
                                  isFollowing: user['isFollowing'] == 'true',
                                  onTap: () {
                                    setState(() {
                                      user['isFollowing'] =
                                          user['isFollowing'] == 'true'
                                              ? 'false'
                                              : 'true';
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

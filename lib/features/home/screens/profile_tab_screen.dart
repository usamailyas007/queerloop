import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../profile/screens/edit_profile_screen.dart';
import '../../profile/screens/followers_following_screen.dart';
import '../../profile/screens/notifications_screen.dart';
import '../../profile/screens/settings_screen.dart';
import '../../profile/widgets/profile_feed_tabs_widget.dart';
import '../../profile/widgets/profile_header_stats_widget.dart';
import '../../profile/widgets/profile_media_grid_widget.dart';

class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({super.key});

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  int _selectedTabIndex = 0; // Default: Posts

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar (ashinorbit + password.svg lock icon & Bell/Settings Icons)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    'ashinorbit',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(width: 6),
                  SvgPicture.asset(
                    AppIcons.password,
                    width: 14,
                    height: 14,
                    colorFilter: const ColorFilter.mode(
                      Colors.white70,
                      BlendMode.srcIn,
                    ),
                  ),
                  const Spacer(),

                  // Bell Icon (Notifications) -> Opens NotificationsScreen
                  GestureDetector(
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          AppIcons.bell,
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Settings Icon -> Opens Settings
                  GestureDetector(
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const SettingsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          AppIcons.settings,
                          width: 20,
                          height: 20,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Scrollable Profile Body ─────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  // Profile Header & Stats Widget
                  ProfileHeaderStatsWidget(
                    avatarAsset: AppImages.user2,
                    name: 'Ash Mercado',
                    bio:
                        'Film nerd, softball catcher, chronically making playlists.',
                    postsCount: '128',
                    followersCount: '4,290',
                    followingCount: '311',
                    onFollowersTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const FollowersFollowingScreen(
                            initialTabIndex: 0,
                          ),
                        ),
                      );
                    },
                    onFollowingTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const FollowersFollowingScreen(
                            initialTabIndex: 1,
                          ),
                        ),
                      );
                    },
                    actionButtons: Row(
                      children: <Widget>[
                        Expanded(
                          child: AppOutlineButton(
                            text: 'Edit profile',
                            onPressed: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const EditProfileScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppOutlineButton(
                            text: 'Share profile',
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Profile Feed Tabs (Posts, Reels, Saved, Liked)
                  ProfileFeedTabsWidget(
                    selectedIndex: _selectedTabIndex,
                    isOwnProfile: true,
                    onTabSelected: (int index) {
                      setState(() => _selectedTabIndex = index);
                    },
                  ),

                  // Tab 0: Posts
                  if (_selectedTabIndex == 0) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      margin: const EdgeInsets.only(bottom: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              ClipOval(
                                child: Image.asset(
                                  AppImages.user2,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    '@ashinorbit',
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    'she/they • 2h',
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white54,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'Golden hour film photography practice in the park today 🌻✨',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              AppImages.searchResult1,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Tab 1: Reels Grid
                  if (_selectedTabIndex == 1)
                    const ProfileMediaGridWidget(showPlayCounts: true),

                  // Tab 2: Saved Grid
                  if (_selectedTabIndex == 2)
                    const ProfileMediaGridWidget(showPlayCounts: false),

                  // Tab 3: Liked Grid
                  if (_selectedTabIndex == 3)
                    const ProfileMediaGridWidget(showPlayCounts: false),

                  // Extra Bottom Safety Clearance for Floating Nav Bar
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/api_endpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../messages/models/message_models.dart';
import '../../messages/screens/chat_screen.dart';
import '../../profile_setup/models/profile_models.dart';
import '../widgets/profile_feed_tabs_widget.dart';
import '../widgets/profile_header_stats_widget.dart';
import '../widgets/profile_media_grid_widget.dart';
import '../widgets/user_profile_options_bottom_sheet.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({
    this.userId,
    this.username = 'rowankeeps',
    this.name = 'Rowan',
    this.avatarAsset = AppImages.user1,
    this.isPrivate = false,
    super.key,
  });

  final String? userId;
  final String username;
  final String name;
  final String avatarAsset;
  final bool isPrivate;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  int _selectedTabIndex = 1; // Default: Reels
  bool _isRequested = false; // Default: Not requested (shows Follow initially)
  bool _isFollowing = false; // Default: Not following (shows Follow initially)
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    if (widget.userId != null && widget.userId!.isNotEmpty) {
      _fetchUserProfile(widget.userId!);
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      final ApiClient client = context.read<ApiClient>();
      final dynamic data = await client.get(ApiEndpoints.user(userId));
      if (mounted && data is Map<String, dynamic>) {
        setState(() {
          _profile = UserProfile.fromJson(data);
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool isPrivateAccount =
        _profile?.isPrivate ?? (widget.isPrivate || widget.username.contains('kit.lumen'));
    final String currentUsername = _profile?.username ?? widget.username;
    final String currentName = _profile?.displayName ?? widget.name;
    final String currentAvatar = _profile?.avatarUrl ?? widget.avatarAsset;
    final String currentBio = _profile?.bio ??
        (isPrivateAccount
            ? 'Private account.'
            : 'Documenting recovery, one honest video at a time. Ask me anything about scar care.');
    final String currentPronouns = _profile?.formattedPronouns ??
        (isPrivateAccount ? 'he / him' : '');

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar (Back chevron < + Username + 3-dots Menu) ────
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            currentUsername.startsWith('@')
                                ? currentUsername
                                : '@$currentUsername',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: context.themeTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                            ),
                          ),
                          if (isPrivateAccount) ...<Widget>[
                            const SizedBox(width: 6),
                            SvgPicture.asset(
                              AppIcons.password,
                              width: 14,
                              height: 14,
                              colorFilter: ColorFilter.mode(
                                context.themeIconMuted,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // 3-dots Options Menu -> Opens UserProfileOptionsBottomSheet
                  GestureDetector(
                    onTap: () {
                      UserProfileOptionsBottomSheet.show(
                        context,
                        username: currentUsername,
                      );
                    },
                    child: Container(
                      width: 36,
                      height: 36,
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
                      child: Icon(
                        Icons.more_vert_rounded,
                        color: context.themeIcon,
                        size: 20,
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
                    avatarAsset: currentAvatar,
                    name: currentName,
                    bio: currentBio,
                    postsCount: _profile?.postsCount != null
                        ? '${_profile!.postsCount}'
                        : (isPrivateAccount ? '64' : '402'),
                    followersCount: _profile?.followersCount != null
                        ? '${_profile!.followersCount}'
                        : (isPrivateAccount ? '1,102' : '41.2K'),
                    followingCount: _profile?.followingCount != null
                        ? '${_profile!.followingCount}'
                        : (isPrivateAccount ? '228' : '190'),
                    onFollowersTap: () {},
                    onFollowingTap: () {},
                    pronounsPill: currentPronouns,
                    pronounsList: _profile?.pronouns ??
                        (isPrivateAccount
                            ? const <String>[]
                            : const <String>['they/them']),
                    identityList: isPrivateAccount
                        ? const <String>[]
                        : const <String>['Transgender', 'Queer'],
                    interestsList: _profile?.interests ?? const <String>[],
                    actionButtons: Row(
                      children: <Widget>[
                        Expanded(
                          child: isPrivateAccount
                              ? (_isRequested
                                  ? GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _isRequested = false;
                                        });
                                      },
                                      child: Container(
                                        height: 42,
                                        decoration: BoxDecoration(
                                          color: context.themeCardBackground,
                                          borderRadius: BorderRadius.circular(
                                              AppRadius.card),
                                          border: Border.all(
                                            color: AppColors.gradientCyan,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            const Icon(
                                              Icons.access_time_rounded,
                                              color: AppColors.gradientCyan,
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'Requested',
                                              style: AppTextStyles.bodyMedium
                                                  .copyWith(
                                                color: AppColors.gradientCyan,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : AppGradientButton(
                                      text: 'Follow',
                                      onPressed: () {
                                        setState(() {
                                          _isRequested = true;
                                        });
                                      },
                                    ))
                              : (_isFollowing
                                  ? AppOutlineButton(
                                      text: 'Following',
                                      onPressed: () {
                                        setState(() {
                                          _isFollowing = false;
                                        });
                                      },
                                    )
                                  : AppGradientButton(
                                      text: 'Follow',
                                      onPressed: () {
                                        setState(() {
                                          _isFollowing = true;
                                        });
                                      },
                                    )),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppOutlineButton(
                            text: 'Message',
                            onPressed: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => ChatScreen(
                                    conversation: ConversationModel(
                                      id: 'c2',
                                      username: widget.username,
                                      avatarAsset: widget.avatarAsset,
                                      lastMessage: 'Active now',
                                      timeAgo: 'Just now',
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── If Private Account -> Show Centered Private Placeholder (Image 1) ──
                  if (isPrivateAccount) ...<Widget>[
                    const SizedBox(height: AppSpacing.xxl),
                    Center(
                      child: Column(
                        children: <Widget>[
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              color: context.themeCardBackground,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: context.themeBorder,
                              ),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                AppIcons.password,
                                width: 26,
                                height: 26,
                                colorFilter: ColorFilter.mode(
                                  context.themeIcon,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'This account is private',
                            style: AppTextStyles.titleMedium.copyWith(
                              color: context.themeTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              "Kit approves followers one by one. You'll get a notification if your request is accepted.",
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.themeTextSecondary,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ]

                  // ── If Public Account -> Show Feed Tabs & Media Grid ───────
                  else ...<Widget>[
                    ProfileFeedTabsWidget(
                      selectedIndex: _selectedTabIndex,
                      isOwnProfile: false,
                      onTabSelected: (int index) {
                        setState(() => _selectedTabIndex = index);
                      },
                    ),

                    // Tab 0: Posts Feed Cards
                    if (_selectedTabIndex == 0) ...<Widget>[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: context.themeCardBackground,
                          borderRadius: BorderRadius.circular(20),
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
                                    widget.avatarAsset,
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
                                      '@${widget.username}',
                                      style: AppTextStyles.titleSmall.copyWith(
                                        color: context.themeTextPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      'they/them • 18m',
                                      style: AppTextStyles.caption.copyWith(
                                        color: context.themeTextMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'Told my grandma about Dev over the phone and she said "finally, you sounded lonely in December." Eleven months of rehearsing a speech for nothing.',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: context.themeTextPrimary,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                AppImages.searchResult2,
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
                  ],

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

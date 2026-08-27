import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import 'followers_following_screen.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int _selectedFilterIndex = 0;

  static const List<String> _filters = <String>[
    'All',
    'Likes',
    'Comments',
    'Follows',
    'Safety',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar (Back button + "Notifications" + "Mark all read") ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  // Back button chevron
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
                  Text(
                    'Notifications',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('All notifications marked as read.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text(
                      'Mark all read',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.gradientCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Horizontal Scrollable Filter Pills ───────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: List<Widget>.generate(_filters.length, (int index) {
                  final bool isSelected = _selectedFilterIndex == index;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedFilterIndex = index),
                    child: Container(
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppColors.primaryGradientButton
                            : null,
                        color: isSelected ? null : context.themeCardBackground,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: context.themeBorder,
                              ),
                      ),
                      child: Text(
                        _filters[index],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : context.themeTextSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Main Scrollable Notifications Feed ───────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  // Top Safety Report Status Banner Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: context.themeCyanBadgeBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: AppColors.gradientCyan,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: SvgPicture.asset(
                            AppIcons.safety,
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              AppColors.gradientCyan,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Your report was actioned',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'QL-84213 — the comment was removed and the account warned.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.themeTextMuted,
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // TODAY Section Header
                  Text(
                    'TODAY',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 1. Likes notification
                  Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const UserProfileScreen(
                                username: 'jules.does',
                                name: 'Jules',
                                avatarAsset: AppImages.user2,
                              ),
                            ),
                          );
                        },
                        child: ClipOval(
                          child: Image.asset(
                            AppImages.user2,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.themeTextSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'jules.does ',
                                style: TextStyle(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(
                                  text: 'and 240 others liked your post\n'),
                              TextSpan(
                                text: '2h',
                                style: TextStyle(
                                  color: context.themeTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          AppImages.forYouImg,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 2. Follow Request Card (Sam Arroyo)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          GestureDetector(
                            onTap: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) => const UserProfileScreen(
                                    username: 'sam.arroyo',
                                    name: 'Sam',
                                    avatarAsset: AppImages.user4,
                                  ),
                                ),
                              );
                            },
                            child: ClipOval(
                              child: Image.asset(
                                AppImages.user4,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.themeTextSecondary,
                                  fontSize: 13,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: 'sam.arroyo ',
                                    style: TextStyle(
                                      color: context.themeTextPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const TextSpan(
                                      text: 'requested to follow you\n'),
                                  TextSpan(
                                    text: '4h',
                                    style: TextStyle(
                                      color: context.themeTextMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          AppGradientButton(
                            text: 'Accept',
                            height: 32,
                            width: 76,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            onPressed: () {},
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          AppOutlineButton(
                            text: 'Decline',
                            height: 32,
                            width: 76,
                            onPressed: () {},
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Padding(
                        padding: const EdgeInsets.only(left: 52),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => const FollowersFollowingScreen(
                                  initialTabIndex: 2,
                                ),
                              ),
                            );
                          },
                          child: Row(
                            children: <Widget>[
                              Text(
                                'See all 4 requests',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.gradientCyan,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.gradientCyan,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 3. Comment reply notification
                  Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const UserProfileScreen(
                                username: 'moss.and.oat',
                                name: 'Moss',
                                avatarAsset: AppImages.user3,
                              ),
                            ),
                          );
                        },
                        child: ClipOval(
                          child: Image.asset(
                            AppImages.user3,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.themeTextSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'moss.and.oat ',
                                style: TextStyle(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(
                                  text: 'replied: "sending this to my sister*"\n'),
                              TextSpan(
                                text: '5h',
                                style: TextStyle(
                                  color: context.themeTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          AppImages.searchResult2,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // THIS WEEK Section Header
                  Text(
                    'THIS WEEK',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // 1. Follow notification (Nadia builds)
                  Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () {
                          Navigator.push<void>(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => const UserProfileScreen(
                                username: 'nadia.builds',
                                name: 'Nadia',
                                avatarAsset: AppImages.user4,
                              ),
                            ),
                          );
                        },
                        child: ClipOval(
                          child: Image.asset(
                            AppImages.user4,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.themeTextSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'nadia.builds ',
                                style: TextStyle(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: 'started following you\n'),
                              TextSpan(
                                text: 'Tue',
                                style: TextStyle(
                                  color: context.themeTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 88,
                          maxWidth: 110,
                        ),
                        child: AppOutlineButton(
                          text: 'Follow back',
                          height: 32,
                          fontSize: 12,
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // 2. QueerLoop+ Community Rules System Announcement
                  Row(
                    children: <Widget>[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: context.themeCyanBadgeBackground,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                AppColors.gradientCyan.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.volume_up_outlined,
                          color: AppColors.gradientCyan,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.themeTextSecondary,
                              fontSize: 13,
                              height: 1.3,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'QueerLoop+ ',
                                style: TextStyle(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(
                                  text:
                                      'Community rules updated — comment filters are on by default\n'),
                              TextSpan(
                                text: 'Mon',
                                style: TextStyle(
                                  color: context.themeTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

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

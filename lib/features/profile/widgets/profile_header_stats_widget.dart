import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ProfileHeaderStatsWidget extends StatelessWidget {
  const ProfileHeaderStatsWidget({
    required this.avatarAsset,
    required this.name,
    required this.bio,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    required this.onFollowersTap,
    required this.onFollowingTap,
    this.pronounsPill = '',
    this.pronounsList = const <String>[],
    this.identityList = const <String>['Lesbian', 'Bisexual', 'Non-binary'],
    this.interestsList = const <String>[],
    this.interestsText =
        'Music • Gaming • Fashion • Fitness • Travel • Art • Movies',
    this.actionButtons,
    super.key,
  });

  final String avatarAsset;
  final String name;
  final String bio;
  final String postsCount;
  final String followersCount;
  final String followingCount;
  final VoidCallback onFollowersTap;
  final VoidCallback onFollowingTap;
  final String pronounsPill;
  final List<String> pronounsList;
  final List<String> identityList;
  final List<String> interestsList;
  final String interestsText;
  final Widget? actionButtons;

  Widget _buildStatColumn({
    required BuildContext context,
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Text(
            count,
            style: AppTextStyles.titleMedium.copyWith(
              color: context.themeTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: context.themeTextMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(
    BuildContext context,
    String text,
    Color borderColor,
    Color textColor,
    Color backgroundColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.6),
          width: 1.1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    final Color pinkPillBg =
        isDark ? const Color(0xFF2A1622) : const Color(0xFFFFF0F5);
    final Color cyanPillBg =
        isDark ? const Color(0xFF0F262A) : const Color(0xFFE8FAF8);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: AppSpacing.sm),

        // Avatar + Stats Row
        Row(
          children: <Widget>[
            // Avatar with Story Gradient Ring
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradientButton,
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.themeBackground,
                ),
                child: ClipOval(
                  child: avatarAsset.startsWith('http')
                      ? Image.network(
                          avatarAsset,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            BuildContext ctx,
                            Object err,
                            StackTrace? trace,
                          ) => Container(
                            width: 76,
                            height: 76,
                            color: context.themeCardBackground,
                            child: const Icon(
                              Icons.person,
                              color: AppColors.gradientPink,
                            ),
                          ),
                        )
                      : Image.asset(
                          avatarAsset,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (
                            BuildContext ctx,
                            Object err,
                            StackTrace? trace,
                          ) => Container(
                            width: 76,
                            height: 76,
                            color: context.themeCardBackground,
                            child: const Icon(
                              Icons.person,
                              color: AppColors.gradientPink,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xl),

            // Stats Column
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: <Widget>[
                  _buildStatColumn(
                    context: context,
                    count: postsCount,
                    label: 'Posts',
                    onTap: () {},
                  ),
                  _buildStatColumn(
                    context: context,
                    count: followersCount,
                    label: 'Followers',
                    onTap: onFollowersTap,
                  ),
                  _buildStatColumn(
                    context: context,
                    count: followingCount,
                    label: 'Following',
                    onTap: onFollowingTap,
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Name + Pill Badge (e.g. Ash Mercado  she / they)
        Row(
          children: <Widget>[
            Text(
              name,
              style: AppTextStyles.titleMedium.copyWith(
                color: context.themeTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (pronounsPill.isNotEmpty) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFEBEBF0),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  pronounsPill,
                  style: TextStyle(
                    color: isDark
                        ? Colors.white70
                        : const Color(0xFF6E6E78),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 4),

        // Bio Text
        Text(
          bio,
          style: AppTextStyles.bodySmall.copyWith(
            color: context.themeTextSecondary,
            fontSize: 13,
            height: 1.35,
          ),
        ),

        // PRONOUNS Row
        if (pronounsList.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 80,
                child: Text(
                  'PRONOUNS',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.themeTextMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: pronounsList
                      .map(
                        (String item) => _buildPillBadge(
                          context,
                          item,
                          AppColors.gradientPink,
                          AppColors.gradientPink,
                          pinkPillBg,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],

        // IDENTITY Row
        if (identityList.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              SizedBox(
                width: 80,
                child: Text(
                  'IDENTITY',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: context.themeTextMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: identityList
                      .map(
                        (String item) => _buildPillBadge(
                          context,
                          item,
                          AppColors.gradientCyan,
                          AppColors.gradientCyan,
                          cyanPillBg,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ],

        // INTERESTS Row
        if (interestsList.isNotEmpty || interestsText.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 80,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'INTERESTS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  interestsList.isNotEmpty
                      ? interestsList.join(' • ')
                      : interestsText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.themeTextSecondary,
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ],

        if (actionButtons != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          actionButtons!,
        ],
      ],
    );
  }
}

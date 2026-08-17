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
    this.pronounsPill = 'she / they',
    this.pronounsList = const <String>['she/her', 'they/them'],
    this.identityList = const <String>['Lesbian', 'Bisexual', 'Non-binary'],
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
  final String interestsText;
  final Widget? actionButtons;

  Widget _buildStatColumn({
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
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillBadge(String text, Color borderColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
                child: ClipOval(
                  child: Image.asset(
                    avatarAsset,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
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
                    count: postsCount,
                    label: 'Posts',
                    onTap: () {},
                  ),
                  _buildStatColumn(
                    count: followersCount,
                    label: 'Followers',
                    onTap: onFollowersTap,
                  ),
                  _buildStatColumn(
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

        // Name + Pill Badge
        Row(
          children: <Widget>[
            Text(
              name,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            if (pronounsPill.isNotEmpty) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  pronounsPill,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 4),

        Text(
          bio,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white70,
            fontSize: 13,
            height: 1.35,
          ),
        ),

        // PRONOUNS Row
        if (pronounsList.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Text(
                'PRONOUNS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ...pronounsList.map(
                (String item) => _buildPillBadge(
                  item,
                  AppColors.gradientPink,
                  AppColors.gradientPink,
                ),
              ),
            ],
          ),
        ],

        // IDENTITY Row
        if (identityList.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Text(
                'IDENTITY',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ...identityList.map(
                (String item) => _buildPillBadge(
                  item,
                  AppColors.gradientCyan,
                  AppColors.gradientCyan,
                ),
              ),
            ],
          ),
        ],

        // INTERESTS Row
        if (interestsText.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Text(
                'INTERESTS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white38,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  interestsText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
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

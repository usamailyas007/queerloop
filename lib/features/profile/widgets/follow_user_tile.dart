import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';

class FollowUserTile extends StatelessWidget {
  const FollowUserTile({
    required this.username,
    required this.name,
    required this.pronouns,
    required this.avatarAsset,
    required this.isFollowing,
    required this.onTapUser,
    required this.onToggleFollow,
    super.key,
  });

  final String username;
  final String name;
  final String pronouns;
  final String avatarAsset;
  final bool isFollowing;
  final VoidCallback onTapUser;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: onTapUser,
              child: Row(
                children: <Widget>[
                  ClipOval(
                    child: Image.asset(
                      avatarAsset,
                      width: 44,
                      height: 44,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          username,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: context.themeTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$name • $pronouns',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.themeTextSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (isFollowing)
            AppOutlineButton(
              text: 'Following',
              height: 32,
              width: 90,
              onPressed: onToggleFollow,
            )
          else
            AppGradientButton(
              text: 'Follow',
              height: 32,
              width: 90,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onPressed: onToggleFollow,
            ),
        ],
      ),
    );
  }
}

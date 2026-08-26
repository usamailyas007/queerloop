import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/discover_models.dart';
import 'discover_join_pill.dart';

/// Row tile showing a community image, name, description, and Join pill.
/// Used in both the Discover main screen and Search idle state.
class DiscoverCommunityTile extends StatelessWidget {
  const DiscoverCommunityTile({
    required this.community,
    required this.isJoined,
    required this.onJoin,
    super.key,
  });

  final DiscoverCommunity community;
  final bool isJoined;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: Image.asset(
              community.imageAsset,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  community.name,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.themeTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  community.description,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.themeTextMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          DiscoverJoinPill(isJoined: isJoined, onTap: onJoin),
        ],
      ),
    );
  }
}

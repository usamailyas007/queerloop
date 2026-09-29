import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_user_avatar.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/discover_models.dart';

/// Circular avatar + username column — used in "Creators to Watch",
/// "New Creators", and "You Might Like" sections.
class DiscoverCreatorCircle extends StatelessWidget {
  const DiscoverCreatorCircle({
    required this.creator,
    super.key,
    this.size = 56,
    this.hasGradientBorder = true,
  });

  final DiscoverCreator creator;
  final double size;
  final bool hasGradientBorder;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => UserProfileScreen(
              userId: creator.id,
              username: creator.username.replaceAll('@', ''),
              name: (creator.displayName != null && creator.displayName!.trim().isNotEmpty)
                  ? creator.displayName!.trim()
                  : creator.username.replaceAll('@', '').split('.').first,
              avatarAsset: creator.avatarAsset,
              isPrivate: creator.isPrivate,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppUserAvatar(
            imageAsset: creator.avatarAsset,
            size: size,
            hasGradientBorder: hasGradientBorder,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Flexible(
                child: Text(
                  creator.username,
                  style: AppTextStyles.caption.copyWith(
                    color: context.themeTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (creator.isPrivate) ...<Widget>[
                const SizedBox(width: 2),
                Icon(
                  Icons.lock_outline_rounded,
                  size: 11,
                  color: context.themeTextSecondary,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

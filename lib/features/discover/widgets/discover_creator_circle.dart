import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/cache/user_relationship_cache.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_user_avatar.dart';
import '../../auth/auth_provider.dart';
import '../../profile/provider/profile_provider.dart';
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
    final String myId = context.read<AuthProvider>().userId ?? '';
    final String myUsername = (context.read<AuthProvider>().user?.displayName ??
            context.read<ProfileProvider>().username)
        .replaceAll('@', '')
        .trim()
        .toLowerCase();
    final String creatorCleanName =
        creator.username.replaceAll('@', '').trim().toLowerCase();
    final bool isMe = (myId.isNotEmpty && creator.id != null && creator.id == myId) ||
        (myUsername.isNotEmpty && creatorCleanName == myUsername);

    final bool canSeePhoto = isMe ||
        UserPrivacyPolicy.canViewProfilePhoto(
          profileVisibility: creator.profileVisibility,
          targetUserId: creator.id,
          targetUsername: creator.username,
          isViewerFollowing: creator.isFollowing,
        );

    final String effectiveAvatar =
        canSeePhoto ? creator.avatarAsset : AppImages.defaultAvatar;

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
              avatarAsset: effectiveAvatar,
              isPrivate: creator.isPrivate,
              profileVisibility: creator.profileVisibility,
              allowMessagesFrom: creator.allowMessagesFrom,
              allowCommentsFrom: creator.allowCommentsFrom,
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          AppUserAvatar(
            imageAsset: effectiveAvatar,
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

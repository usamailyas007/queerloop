import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_follow_button.dart';
import '../../../core/widgets/app_user_avatar.dart';
import '../../auth/auth_provider.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/discover_models.dart';

/// Person row tile with avatar, username, pronouns, follower count, Follow button.
class SearchPersonTile extends StatelessWidget {
  const SearchPersonTile({
    required this.person,
    required this.isFollowing,
    required this.onFollow,
    super.key,
  });

  final DiscoverPerson person;
  final bool isFollowing;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    final String myId = context.read<AuthProvider>().userId ?? '';
    final String myUsername = (context.read<AuthProvider>().user?.displayName ??
            context.read<ProfileProvider>().username)
        .replaceAll('@', '')
        .trim()
        .toLowerCase();
    final String tileUsername =
        person.username.replaceAll('@', '').trim().toLowerCase();

    final bool isMe = (myId.isNotEmpty && person.id != null && person.id == myId) ||
        (myUsername.isNotEmpty && tileUsername == myUsername);
    return Row(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => UserProfileScreen(
                    userId: person.id,
                    username: person.username,
                    name: (person.displayName != null && person.displayName!.trim().isNotEmpty)
                        ? person.displayName!.trim()
                        : person.username.replaceAll('@', '').split('.').first,
                    avatarAsset: person.avatarAsset,
                    isPrivate: person.isPrivate,
                  ),
                ),
              );
            },
            child: Row(
              children: <Widget>[
                AppUserAvatar(
                  imageAsset: person.avatarAsset,
                  size: AppSizes.avatarMd,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Flexible(
                            child: Text(
                              person.username,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (person.isPrivate) ...<Widget>[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 14,
                              color: context.themeTextSecondary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${person.pronouns} · ${person.followers}',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: context.themeTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isMe)
          AppFollowButton(isFollowing: isFollowing, onTap: onFollow),
      ],
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_follow_button.dart';
import '../../../core/widgets/app_user_avatar.dart';
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
    return Row(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => UserProfileScreen(
                    username: person.username,
                    name: person.username.replaceAll('@', '').split('.').first,
                    avatarAsset: person.avatarAsset,
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
                      Text(
                        person.username,
                        style: AppTextStyles.titleSmall
                            .copyWith(color: Colors.white),
                      ),
                      Text(
                        '${person.pronouns} · ${person.followers}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AppFollowButton(isFollowing: isFollowing, onTap: onFollow),
      ],
    );
  }
}

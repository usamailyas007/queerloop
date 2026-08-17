import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';

class MutedUserItem {
  const MutedUserItem({
    required this.username,
    required this.mutedDate,
    required this.avatarAsset,
  });

  final String username;
  final String mutedDate;
  final String avatarAsset;
}

class MutedAccountsScreen extends StatefulWidget {
  const MutedAccountsScreen({super.key});

  @override
  State<MutedAccountsScreen> createState() => _MutedAccountsScreenState();
}

class _MutedAccountsScreenState extends State<MutedAccountsScreen> {
  String _searchQuery = '';

  final List<MutedUserItem> _mutedUsers = <MutedUserItem>[
    const MutedUserItem(
      username: '@nightowl_j',
      mutedDate: 'Muted 9 Jul',
      avatarAsset: AppImages.user1,
    ),
    const MutedUserItem(
      username: '@ramble.rae',
      mutedDate: 'Muted 2 Jul',
      avatarAsset: AppImages.user2,
    ),
    const MutedUserItem(
      username: '@quietriot',
      mutedDate: 'Muted 21 Jun',
      avatarAsset: AppImages.user3,
    ),
  ];

  void _unmuteUser(MutedUserItem user) {
    setState(() {
      _mutedUsers.remove(user);
    });

    AppSnackBar.show(
      context,
      title: '${user.username} unmuted',
      subtitle: 'You will now see their posts in your feed',
      icon: SvgPicture.asset(
        AppIcons.mute,
        width: 18,
        height: 18,
        colorFilter: const ColorFilter.mode(
          AppColors.gradientCyan,
          BlendMode.srcIn,
        ),
      ),
      actionLabel: 'Undo',
      onAction: () {
        setState(() {
          _mutedUsers.add(user);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<MutedUserItem> filtered = _mutedUsers.where((MutedUserItem user) {
      return _searchQuery.isEmpty ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar ──────────────────────────────────────────────
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
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Muted accounts',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38), // Balance spacing
                ],
              ),
            ),

            // ── Main Content Body ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  // Search Bar Input Field using AppTextField
                  AppTextField(
                    hintText: 'Search muted accounts',
                    prefixIconPath: AppIcons.searchSvg,
                    onChanged: (String val) =>
                        setState(() => _searchQuery = val),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Subtitle Description
                  Text(
                    "Muted accounts can still see and interact with your posts — you just won't see theirs.",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Muted Accounts List
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No muted accounts found.',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ...filtered.map((MutedUserItem user) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          children: <Widget>[
                            // User Avatar
                            ClipOval(
                              child: Image.asset(
                                user.avatarAsset,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),

                            // Username & Muted Date
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    user.username,
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    user.mutedDate,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Unmute Button
                            GestureDetector(
                              onTap: () => _unmuteUser(user),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Text(
                                  'Unmute',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snackbar.dart';

class BlockedUserItem {
  const BlockedUserItem({
    required this.username,
    required this.blockedDate,
    required this.avatarAsset,
  });

  final String username;
  final String blockedDate;
  final String avatarAsset;
}

class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  String _searchQuery = '';

  final List<BlockedUserItem> _blockedUsers = <BlockedUserItem>[
    const BlockedUserItem(
      username: '@dg_returns',
      blockedDate: 'Blocked 12 Jun',
      avatarAsset: AppImages.user1,
    ),
    const BlockedUserItem(
      username: '@hexnine1',
      blockedDate: 'Blocked 3 Jun',
      avatarAsset: AppImages.user2,
    ),
    const BlockedUserItem(
      username: '@m.callahan',
      blockedDate: 'Blocked 28 May',
      avatarAsset: AppImages.user3,
    ),
    const BlockedUserItem(
      username: '@truth_ftw',
      blockedDate: 'Blocked 19 May',
      avatarAsset: AppImages.user4,
    ),
  ];

  void _unblockUser(BlockedUserItem user) {
    setState(() {
      _blockedUsers.remove(user);
    });

    AppSnackBar.show(
      context,
      title: '${user.username} unblocked',
      subtitle: 'They can now find your profile and message you',
      actionLabel: 'Undo',
      onAction: () {
        setState(() {
          _blockedUsers.add(user);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<BlockedUserItem> filtered = _blockedUsers.where((BlockedUserItem user) {
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
                      'Blocked accounts',
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
                  // Search Bar Input Field
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: TextField(
                      onChanged: (String val) =>
                          setState(() => _searchQuery = val),
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: const InputDecoration(
                        hintText: 'Search blocked accounts',
                        hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                        icon: Icon(Icons.search_rounded,
                            color: Colors.white38, size: 20),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Subtitle Description
                  Text(
                    "Blocked people can't find your profile, message you, or see anything you post. They are not told.",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Blocked Accounts List
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No blocked accounts found.',
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ),
                    )
                  else
                    ...filtered.map((BlockedUserItem user) {
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

                            // Username & Blocked Date
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
                                    user.blockedDate,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: Colors.white38,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Unblock Button
                            GestureDetector(
                              onTap: () => _unblockUser(user),
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
                                  'Unblock',
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

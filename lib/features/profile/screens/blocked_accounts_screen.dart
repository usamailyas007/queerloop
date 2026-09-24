import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/user_relationship_models.dart';
import '../provider/profile_provider.dart';

class BlockedAccountsScreen extends StatefulWidget {
  const BlockedAccountsScreen({super.key});

  @override
  State<BlockedAccountsScreen> createState() => _BlockedAccountsScreenState();
}

class _BlockedAccountsScreenState extends State<BlockedAccountsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileProvider>().loadBlockedAccounts();
      }
    });
  }

  void _unblockUser(BlockedAccountItem user) {
    final ProfileProvider provider = context.read<ProfileProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    provider.unblockUser(user.userId);

    AppSnackBar.show(
      context,
      messenger: messenger,
      title: '@${user.username} unblocked',
      subtitle: 'They can now find your profile and message you',
      actionLabel: 'Undo',
      onAction: () {
        provider.blockUser(
          user.userId,
          username: user.username,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
        );
      },
    );
  }

  String _formatBlockedDate(DateTime? date) {
    if (date == null) return 'Blocked';
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Blocked ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final ProfileProvider provider = context.watch<ProfileProvider>();
    final List<BlockedAccountItem> blockedList = provider.blockedAccounts;
    final bool isLoading = provider.isLoadingBlocked;

    final List<BlockedAccountItem> filtered = blockedList.where((BlockedAccountItem user) {
      return _searchQuery.isEmpty ||
          user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (user.displayName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: context.themeBackground,
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
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.12)
                              : context.themeBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: context.themeIcon,
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Blocked accounts',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
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
              child: RefreshIndicator(
                color: AppColors.gradientPink,
                onRefresh: () => provider.loadBlockedAccounts(forceRefresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: <Widget>[
                    // Search Bar Input Field using AppTextField
                    AppTextField(
                      hintText: 'Search blocked accounts',
                      prefixIconPath: AppIcons.searchSvg,
                      onChanged: (String val) =>
                          setState(() => _searchQuery = val),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Subtitle Description
                    Text(
                      "Blocked people can't find your profile, message you, or see anything you post. They are not told.",
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.themeTextSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Blocked Accounts List / Loader / Empty State
                    if (isLoading && blockedList.isEmpty)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gradientPink,
                          ),
                        ),
                      )
                    else if (filtered.isEmpty)
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.45,
                        child: Center(
                          child: Text(
                            blockedList.isEmpty
                                ? 'No blocked accounts.'
                                : 'No blocked accounts found.',
                            style: TextStyle(
                              color: context.themeTextMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filtered.map((BlockedAccountItem user) {
                        final String avatar = user.avatarUrl ?? '';
                        return Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Row(
                            children: <Widget>[
                              // User Avatar
                              ClipOval(
                                child: avatar.startsWith('http')
                                    ? Image.network(
                                        avatar,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Image.asset(
                                            AppImages.defaultAvatar,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                          ),
                                      )
                                    : Image.asset(
                                        avatar.isNotEmpty
                                            ? avatar
                                            : AppImages.defaultAvatar,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) => Image.asset(
                                            AppImages.defaultAvatar,
                                            width: 44,
                                            height: 44,
                                            fit: BoxFit.cover,
                                          ),
                                      ),
                              ),
                              const SizedBox(width: AppSpacing.md),

                              // Username & Blocked Date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      '@${user.username}',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: context.themeTextPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _formatBlockedDate(user.blockedAt),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: context.themeTextMuted,
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
                                    color: context.themeCardBackground,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: context.themeBorder,
                                    ),
                                  ),
                                  child: Text(
                                    'Unblock',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: context.themeTextPrimary,
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
            ),
          ],
        ),
      ),
    );
  }
}

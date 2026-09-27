import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class MutedAccountsScreen extends StatefulWidget {
  const MutedAccountsScreen({super.key});

  @override
  State<MutedAccountsScreen> createState() => _MutedAccountsScreenState();
}

class _MutedAccountsScreenState extends State<MutedAccountsScreen> {
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ProfileProvider>().loadMutedAccounts();
      }
    });
  }

  void _unmuteUser(MutedAccountItem user) {
    final ProfileProvider provider = context.read<ProfileProvider>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    provider.unmuteUser(user.userId);

    AppSnackBar.show(
      context,
      messenger: messenger,
      title: '@${user.username} unmuted',
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
        provider.muteUser(
          user.userId,
          username: user.username,
          displayName: user.displayName,
          avatarUrl: user.avatarUrl,
          scope: user.scope ?? 'posts',
        );
      },
    );
  }

  String _formatMutedText(DateTime? date) {
    if (date == null) return 'Muted';
    const List<String> months = <String>[
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return 'Until ${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final ProfileProvider provider = context.watch<ProfileProvider>();
    final List<MutedAccountItem> mutedList = provider.mutedAccounts;
    final bool isLoading = provider.isLoadingMuted;

    final List<MutedAccountItem> filtered = mutedList.where((MutedAccountItem user) {
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
                      'Muted accounts',
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
                onRefresh: () => provider.loadMutedAccounts(forceRefresh: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
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
                      'Muted accounts remain in your following list, but their posts and comments are hidden from your feeds. They are not told.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.themeTextSecondary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Muted Accounts List / Loader / Empty State
                    if (isLoading && mutedList.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gradientPink,
                          ),
                        ),
                      )
                    else if (filtered.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: Text(
                            mutedList.isEmpty
                                ? 'No muted accounts.'
                                : 'No muted accounts found.',
                            style: TextStyle(
                              color: context.themeTextMuted,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      )
                    else
                      ...filtered.map((MutedAccountItem user) {
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
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.person, size: 44),
                                      )
                                    : Image.asset(
                                        avatar.isNotEmpty
                                            ? avatar
                                            : AppImages.user1,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const Icon(Icons.person, size: 44),
                                      ),
                              ),
                              const SizedBox(width: AppSpacing.md),

                              // Username & Muted Date / Scope
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
                                      _formatMutedText(user.mutedUntil),
                                      style: AppTextStyles.bodySmall.copyWith(
                                        color: context.themeTextMuted,
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
                                    color: context.themeCardBackground,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: context.themeBorder,
                                    ),
                                  ),
                                  child: Text(
                                    'Unmute',
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

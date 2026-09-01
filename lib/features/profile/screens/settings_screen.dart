import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../auth/auth_provider.dart';
import '../../home/provider/home_feed_provider.dart';
import '../provider/profile_provider.dart';

import '../widgets/logout_confirmation_modal_dialog.dart';
import 'blocked_accounts_screen.dart';
import 'delete_account_screen.dart';
import 'edit_profile_screen.dart';
import 'muted_accounts_screen.dart';
import 'notifications_settings_screen.dart';
import 'privacy_policy_screen.dart';
import 'privacy_settings_screen.dart';
import 'terms_of_service_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    this.name = 'Ash Mercado',
    this.handleWithPronouns = '@ashinorbit · she/they',
    this.avatarAsset = AppImages.user1,
    super.key,
  });

  final String name;
  final String handleWithPronouns;
  final String avatarAsset;

  Widget _buildOptionTile({
    required BuildContext context,
    required Widget iconWidget,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md - 2,
        ),
        decoration: BoxDecoration(
          color: context.themeBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: <Widget>[
            iconWidget,
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: context.themeTextPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (trailingText != null && trailingText.isNotEmpty) ...<Widget>[
              Text(
                trailingText,
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.themeTextMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            Icon(
              Icons.chevron_right_rounded,
              color: context.themeIconMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;
    final ProfileProvider profileProvider = context.watch<ProfileProvider>();
    final String currentName =
        profileProvider.displayName.isNotEmpty ? profileProvider.displayName : name;
    final String currentAvatar =
        profileProvider.avatarUrl.isNotEmpty ? profileProvider.avatarUrl : avatarAsset;
    final String handle = profileProvider.username.isNotEmpty
        ? (profileProvider.username.startsWith('@')
            ? profileProvider.username
            : '@${profileProvider.username}')
        : '@user';
    final String pronouns = profileProvider.pronounsFormatted;
    final String currentHandleWithPronouns = pronouns.isNotEmpty
        ? '$handle · $pronouns'
        : handle;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar (Back button + Settings Title + Theme Toggle) ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.12)
                              : context.themeBorder,
                          width: 1.1,
                        ),
                      ),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        color: context.themeTextPrimary,
                        size: 24,
                      ),
                    ),
                  ),

                  // Center title
                  Expanded(
                    child: Text(
                      'Settings',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),

                  // Top-Right Global Theme Toggle Button
                  Consumer<ThemeProvider>(
                    builder: (BuildContext ctx, ThemeProvider themeProvider, _) {
                      final bool dark = themeProvider.isDarkMode;
                      return GestureDetector(
                        onTap: () => themeProvider.toggleTheme(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: dark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.transparent,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: dark
                                  ? Colors.white.withValues(alpha: 0.12)
                                  : context.themeBorder,
                              width: 1.1,
                            ),
                          ),
                          child: Icon(
                            dark
                                ? Icons.wb_sunny_outlined
                                : Icons.nightlight_round,
                            color: context.themeTextPrimary,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Main Content Body ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  const SizedBox(height: AppSpacing.xs),

                  // Top User Summary Card (Navigates to Edit Profile Screen)
                  GestureDetector(
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.themeCardBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: context.themeBorder,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          ClipOval(
                            child: currentAvatar.startsWith('http')
                                ? Image.network(
                                    currentAvatar,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (
                                      BuildContext ctx,
                                      Object err,
                                      StackTrace? trace,
                                    ) =>
                                        Image.asset(
                                      AppImages.user1,
                                      width: 48,
                                      height: 48,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    currentAvatar,
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
                                  currentName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: context.themeTextPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  currentHandleWithPronouns,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: context.themeTextMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: context.themeIconMuted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Section 1: SAFETY & PRIVACY
                  Text(
                    'SAFETY & PRIVACY',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _buildOptionTile(
                    context: context,
                    iconWidget: SvgPicture.asset(
                      AppIcons.safety,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        AppColors.gradientCyan,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: 'Manage Account',
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacySettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildOptionTile(
                    context: context,
                    iconWidget: Icon(
                      Icons.block_rounded,
                      color: context.themeIconMuted,
                      size: 18,
                    ),
                    title: 'Blocked accounts',
                    trailingText: '7',
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const BlockedAccountsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildOptionTile(
                    context: context,
                    iconWidget: SvgPicture.asset(
                      AppIcons.mute,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        context.themeIconMuted,
                        BlendMode.srcIn,
                      ),
                    ),
                    title: 'Muted accounts',
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const MutedAccountsScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section 2: APP
                  Text(
                    'APP',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _buildOptionTile(
                    context: context,
                    iconWidget: Icon(
                      Icons.notifications_none_rounded,
                      color: context.themeIconMuted,
                      size: 18,
                    ),
                    title: 'Notifications',
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const NotificationsSettingsScreen(),
                        ),
                      );
                    },
                  ),
                  _buildOptionTile(
                    context: context,
                    iconWidget: Icon(
                      Icons.description_outlined,
                      color: context.themeIconMuted,
                      size: 18,
                    ),
                    title: 'Terms & Conditions',
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const TermsOfServiceScreen(),
                        ),
                      );
                    },
                  ),
                  _buildOptionTile(
                    context: context,
                    iconWidget: Icon(
                      Icons.description_outlined,
                      color: context.themeIconMuted,
                      size: 18,
                    ),
                    title: 'Privacy Policy',
                    onTap: () {
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Log Out Button (Themed Outlined Button with Exit Icon)
                  GestureDetector(
                    onTap: () {
                      LogoutConfirmationModalDialog.show(
                        context,
                        username: handle,
                        onConfirmLogout: () async {
                          context.read<HomeFeedProvider>().resetToHome();
                          await context.read<AuthProvider>().signOut();
                          if (context.mounted) {
                            AppSnackBar.showSuccess(
                              context,
                              title: 'Logged out',
                              subtitle:
                                  'You have been logged out of your account.',
                            );
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRoutes.login,
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: context.themeCardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: context.themeBorder,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.logout_rounded,
                            color: context.themeTextPrimary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Log out',
                            style: TextStyle(
                              color: context.themeTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Delete Account Text Button
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => const DeleteAccountScreen(),
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          'Delete account',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.themeTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

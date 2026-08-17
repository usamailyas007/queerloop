import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

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
          color: AppColors.background,
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
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (trailingText != null && trailingText.isNotEmpty) ...<Widget>[
              Text(
                trailingText,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white38,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
            ],
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      'Settings',
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
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          ClipOval(
                            child: Image.asset(
                              avatarAsset,
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
                                  name,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  handleWithPronouns,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
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
                      color: Colors.white54,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _buildOptionTile(
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
                    iconWidget: const Icon(
                      Icons.block_rounded,
                      color: Colors.white70,
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
                    iconWidget: SvgPicture.asset(
                      AppIcons.mute,
                      width: 18,
                      height: 18,
                      colorFilter: const ColorFilter.mode(
                        Colors.white70,
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
                      color: Colors.white54,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _buildOptionTile(
                    iconWidget: const Icon(
                      Icons.notifications_none_rounded,
                      color: Colors.white70,
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
                    iconWidget: const Icon(
                      Icons.description_outlined,
                      color: Colors.white70,
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
                    iconWidget: const Icon(
                      Icons.description_outlined,
                      color: Colors.white70,
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

                  // Log Out Button (Dark Outlined Button with Exit Icon)
                  GestureDetector(
                    onTap: () {
                      LogoutConfirmationModalDialog.show(
                        context,
                        username: '@ashinorbit',
                        onConfirmLogout: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            AppRoutes.login,
                            (Route<dynamic> route) => false,
                          );
                        },
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Log out',
                            style: TextStyle(
                              color: Colors.white,
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
                            color: AppColors.gradientCyan,
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

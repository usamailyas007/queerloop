import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../create_post/widgets/custom_gradient_switch.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _privateAccount = true;
  bool _appearInExplore = false;
  bool _hideLikes = true;

  bool _showActivityStatus = true;
  bool _sendReadReceipts = true;

  final String _whoCanMessage = 'People I follow';
  final String _whoCanComment = 'Everyone';
  final String _profileVisibility = 'People I follow';

  Widget _buildCardToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CustomGradientSwitch(
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCardSelector({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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
                      'Privacy',
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
                  // Section 1: ACCOUNT
                  Text(
                    'ACCOUNT',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white54,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _buildCardToggle(
                    title: 'Private account',
                    subtitle: 'Followers need approval',
                    value: _privateAccount,
                    onChanged: (bool val) =>
                        setState(() => _privateAccount = val),
                  ),
                  _buildCardToggle(
                    title: 'Appear in Explore',
                    subtitle: 'Search and suggestions',
                    value: _appearInExplore,
                    onChanged: (bool val) =>
                        setState(() => _appearInExplore = val),
                  ),
                  _buildCardToggle(
                    title: 'Hide my likes',
                    subtitle: 'Nobody sees what you liked',
                    value: _hideLikes,
                    onChanged: (bool val) => setState(() => _hideLikes = val),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section 2: INTERACTIONS
                  Text(
                    'INTERACTIONS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white54,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _buildCardSelector(
                    title: 'Who can message me',
                    subtitle: _whoCanMessage,
                    onTap: () {},
                  ),
                  _buildCardSelector(
                    title: 'Who can comment',
                    subtitle: _whoCanComment,
                    onTap: () {},
                  ),
                  _buildCardSelector(
                    title: 'Profile Visibility',
                    subtitle: _profileVisibility,
                    onTap: () {},
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section 3: STATUS
                  Text(
                    'STATUS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white54,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _buildCardToggle(
                    title: 'Show activity status',
                    subtitle: "Lets people you follow see when you're active",
                    value: _showActivityStatus,
                    onChanged: (bool val) =>
                        setState(() => _showActivityStatus = val),
                  ),
                  _buildCardToggle(
                    title: 'Send read receipts',
                    subtitle: 'Shows "Read" under messages you\'ve opened',
                    value: _sendReadReceipts,
                    onChanged: (bool val) =>
                        setState(() => _sendReadReceipts = val),
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

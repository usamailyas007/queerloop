import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../create_post/widgets/custom_gradient_switch.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _masterPush = true;
  bool _likes = false;
  bool _comments = false;
  bool _newFollowers = false;
  bool _followRequests = false;
  bool _messages = false;
  bool _communityPosts = false;

  bool _moderationUpdates = false;
  bool _announcements = false;

  Widget _buildToggleRow({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
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
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ],
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
                      'Notifications',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38), // Balance layout
                ],
              ),
            ),

            // ── Main Content Body ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  // Master Card: Push Notifications
                  Container(
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
                              'Push notifications',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Master switch for this device',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        CustomGradientSwitch(
                          value: _masterPush,
                          onChanged: (bool val) =>
                              setState(() => _masterPush = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Section 1: ACTIVITY
                  Text(
                    'ACTIVITY',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white54,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  _buildToggleRow(
                    title: 'Likes',
                    value: _likes,
                    onChanged: (bool val) => setState(() => _likes = val),
                  ),
                  _buildToggleRow(
                    title: 'Comments and replies',
                    value: _comments,
                    onChanged: (bool val) => setState(() => _comments = val),
                  ),
                  _buildToggleRow(
                    title: 'New followers',
                    value: _newFollowers,
                    onChanged: (bool val) =>
                        setState(() => _newFollowers = val),
                  ),
                  _buildToggleRow(
                    title: 'Follow requests',
                    value: _followRequests,
                    onChanged: (bool val) =>
                        setState(() => _followRequests = val),
                  ),
                  _buildToggleRow(
                    title: 'Messages',
                    value: _messages,
                    onChanged: (bool val) => setState(() => _messages = val),
                  ),
                  _buildToggleRow(
                    title: 'Community posts',
                    value: _communityPosts,
                    onChanged: (bool val) =>
                        setState(() => _communityPosts = val),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Section 2: FROM QUEERLOOP+
                  Text(
                    'FROM QUEERLOOP+',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white54,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  _buildToggleRow(
                    title: 'Moderation updates',
                    subtitle: 'Results of reports you filed',
                    value: _moderationUpdates,
                    onChanged: (bool val) =>
                        setState(() => _moderationUpdates = val),
                  ),
                  _buildToggleRow(
                    title: 'Announcements',
                    subtitle: 'Rare, and never marketing',
                    value: _announcements,
                    onChanged: (bool val) =>
                        setState(() => _announcements = val),
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

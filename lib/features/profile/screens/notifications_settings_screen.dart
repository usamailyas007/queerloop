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
                    color: context.themeTextPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.themeTextMuted,
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
                      'Notifications',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38), // Balance
                ],
              ),
            ),

            // ── Main Settings Body ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  const SizedBox(height: AppSpacing.sm),

                  // ── MASTER PUSH TOGGLE CARD ────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.themeBorder,
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
                                'Pause all notifications',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Temporarily mute push notifications on this device',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: context.themeTextSecondary,
                                  fontSize: 12,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
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

                  // ── ACTIVITY ON YOUR CONTENT SECTION ───────────────────────
                  Text(
                    'ACTIVITY ON YOUR CONTENT',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.themeBorder,
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        _buildToggleRow(
                          title: 'Likes',
                          subtitle: 'When someone likes your post or reel',
                          value: _likes,
                          onChanged: (bool val) => setState(() => _likes = val),
                        ),
                        Divider(color: context.themeDivider, height: 1),
                        _buildToggleRow(
                          title: 'Comments',
                          subtitle: 'When someone comments on your post',
                          value: _comments,
                          onChanged: (bool val) =>
                              setState(() => _comments = val),
                        ),
                        Divider(color: context.themeDivider, height: 1),
                        _buildToggleRow(
                          title: 'New followers',
                          subtitle: 'When someone follows your profile',
                          value: _newFollowers,
                          onChanged: (bool val) =>
                              setState(() => _newFollowers = val),
                        ),
                        Divider(color: context.themeDivider, height: 1),
                        _buildToggleRow(
                          title: 'Follow requests',
                          subtitle: 'When someone requests to follow you',
                          value: _followRequests,
                          onChanged: (bool val) =>
                              setState(() => _followRequests = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── MESSAGES & COMMUNITIES SECTION ─────────────────────────
                  Text(
                    'MESSAGES & COMMUNITIES',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.themeBorder,
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        _buildToggleRow(
                          title: 'Direct messages',
                          subtitle: 'When someone sends you a message',
                          value: _messages,
                          onChanged: (bool val) =>
                              setState(() => _messages = val),
                        ),
                        Divider(color: context.themeDivider, height: 1),
                        _buildToggleRow(
                          title: 'Community posts',
                          subtitle: 'Trending posts in communities you joined',
                          value: _communityPosts,
                          onChanged: (bool val) =>
                              setState(() => _communityPosts = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── FROM QUEERLOOP SECTION ─────────────────────────────────
                  Text(
                    'FROM QUEERLOOP',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: context.themeBorder,
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        _buildToggleRow(
                          title: 'Safety & moderation updates',
                          subtitle: 'Reports you filed and policy updates',
                          value: _moderationUpdates,
                          onChanged: (bool val) =>
                              setState(() => _moderationUpdates = val),
                        ),
                        Divider(color: context.themeDivider, height: 1),
                        _buildToggleRow(
                          title: 'Announcements & features',
                          subtitle: 'New features and community events',
                          value: _announcements,
                          onChanged: (bool val) =>
                              setState(() => _announcements = val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxxxxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

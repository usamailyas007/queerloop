import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/auth_provider.dart';
import '../../create_post/widgets/custom_gradient_switch.dart';
import '../provider/profile_provider.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() =>
      _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState
    extends State<NotificationsSettingsScreen> {
  bool _masterPush = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final String? uid = context.read<AuthProvider>().userId;
      if (uid != null && uid.isNotEmpty) {
        context.read<ProfileProvider>().fetchProfile(uid).catchError((_) {});
      }
    });
  }

  void _syncSetting({
    bool? notifyOnLike,
    bool? notifyOnComment,
    bool? notifyOnFollow,
    bool? notifyOnMessage,
    bool? notifyOnFollowRequests,
    bool? notifyOnCommunityPosts,
    bool? notifyOnAnnouncementsFeatures,
    bool? notifyOnSafetyModerationUpdates,
  }) {
    final String? userId = context.read<AuthProvider>().userId;
    if (userId == null || userId.isEmpty) return;
    context.read<ProfileProvider>().updateProfile(
          userId,
          notifyOnLike: notifyOnLike,
          notifyOnComment: notifyOnComment,
          notifyOnFollow: notifyOnFollow,
          notifyOnMessage: notifyOnMessage,
          notifyOnFollowRequests: notifyOnFollowRequests,
          notifyOnCommunityPosts: notifyOnCommunityPosts,
          notifyOnAnnouncementsFeatures: notifyOnAnnouncementsFeatures,
          notifyOnSafetyModerationUpdates: notifyOnSafetyModerationUpdates,
        );
  }

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
    final ProfileProvider provider = context.watch<ProfileProvider>();
    final bool likes = provider.notifyOnLike;
    final bool comments = provider.notifyOnComment;
    final bool newFollowers = provider.notifyOnFollow;
    final bool followRequests = provider.notifyOnFollowRequests;
    final bool messages = provider.notifyOnMessage;
    final bool communityPosts = provider.notifyOnCommunityPosts;
    final bool moderationUpdates = provider.notifyOnSafetyModerationUpdates;
    final bool announcements = provider.notifyOnAnnouncementsFeatures;

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
                          value: likes,
                          onChanged: (bool val) =>
                              _syncSetting(notifyOnLike: val),
                        ),
                        Divider(color: context.themeDivider, height: 1),
                        _buildToggleRow(
                          title: 'Comments',
                          subtitle: 'When someone comments on your post',
                          value: comments,
                          onChanged: (bool val) =>
                              _syncSetting(notifyOnComment: val),
                        ),
                        Divider(color: context.themeDivider, height: 1),
                        _buildToggleRow(
                          title: 'New followers',
                          subtitle: 'When someone follows your profile',
                          value: newFollowers,
                          onChanged: (bool val) =>
                              _syncSetting(notifyOnFollow: val),
                        ),
                        Divider(color: context.themeDivider, height: 1),
                        _buildToggleRow(
                          title: 'Follow requests',
                          subtitle: 'When someone requests to follow you',
                          value: followRequests,
                          onChanged: (bool val) =>
                              _syncSetting(notifyOnFollowRequests: val),
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
                          value: messages,
                          onChanged: (bool val) =>
                              _syncSetting(notifyOnMessage: val),
                        ),
                        Divider(color: context.themeDivider, height: 1),
                        _buildToggleRow(
                          title: 'Community posts',
                          subtitle: 'Trending posts in communities you joined',
                          value: communityPosts,
                          onChanged: (bool val) =>
                              _syncSetting(notifyOnCommunityPosts: val),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── FROM QUEERLOOP+ SECTION ────────────────────────────────
                  Text(
                    'FROM QUEERLOOP+',
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
                          value: moderationUpdates,
                          onChanged: (bool val) =>
                              _syncSetting(notifyOnSafetyModerationUpdates: val),
                        ),
                        Divider(color: context.themeDivider, height: 1),
                        _buildToggleRow(
                          title: 'Announcements & features',
                          subtitle: 'New features and community events',
                          value: announcements,
                          onChanged: (bool val) =>
                              _syncSetting(notifyOnAnnouncementsFeatures: val),
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

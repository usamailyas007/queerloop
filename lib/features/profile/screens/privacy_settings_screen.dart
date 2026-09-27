import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/auth_provider.dart';
import '../../create_post/widgets/custom_gradient_switch.dart';
import '../../profile_setup/screens/allow_messages_from_screen.dart';
import '../../profile_setup/screens/profile_visibility_screen.dart';
import '../../messages/provider/messages_provider.dart';
import '../../home/services/reel_video_preloader.dart';
import '../provider/profile_provider.dart';
import 'who_can_comment_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  @override
  void initState() {
    super.initState();
    ReelVideoPreloader.instance.setFeedVisible(false);
    ReelVideoPreloader.instance.pauseAll();
    ReelVideoPreloader.instance.muteAll();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ReelVideoPreloader.instance.pauseAll();
      final String? uid = context.read<AuthProvider>().userId;
      if (uid != null && uid.isNotEmpty) {
        context.read<ProfileProvider>().fetchProfile(uid).catchError((_) {});
      }
    });
  }

  void _syncSetting({
    bool? isPrivate,
    bool? showInDiscover,
    bool? hideMyLikes,
    String? allowMessagesFrom,
    String? profileVisibility,
    String? allowCommentsFrom,
    bool? showActivityStatus,
    bool? sendReadReceipts,
  }) {
    final String? userId = context.read<AuthProvider>().userId;
    if (userId == null || userId.isEmpty) return;
    context.read<ProfileProvider>().updateProfile(
          userId,
          isPrivate: isPrivate,
          showInDiscover: showInDiscover,
          hideMyLikes: hideMyLikes,
          allowMessagesFrom: allowMessagesFrom,
          profileVisibility: profileVisibility,
          allowCommentsFrom: allowCommentsFrom,
          showActivityStatus: showActivityStatus,
          sendReadReceipts: sendReadReceipts,
        );
    try {
      context.read<MessagesProvider>().updatePrivacySettings(
            showActivityStatus: showActivityStatus,
            sendReadReceipts: sendReadReceipts,
          );
    } catch (_) {}
  }

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
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(16),
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
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: context.themeTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.themeTextMuted,
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
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: context.themeBorder,
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
                    color: context.themeTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.themeTextMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
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
    final ProfileProvider provider = context.watch<ProfileProvider>();
    final bool privateAccount = provider.isPrivate;
    final bool appearInExplore = provider.showInDiscover;
    final bool hideLikes = provider.hideMyLikes;
    final String whoCanMessage = provider.allowMessagesFromLabel;
    final String whoCanComment = provider.allowCommentsFromLabel;
    final String profileVisibility = provider.profileVisibilityLabel;
    final bool showActivityStatus = provider.showActivityStatus;
    final bool sendReadReceipts = provider.sendReadReceipts;

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
                      'Privacy',
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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  // Section 1: ACCOUNT
                  Text(
                    'ACCOUNT',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _buildCardToggle(
                    title: 'Private account',
                    subtitle: 'Followers need approval',
                    value: privateAccount,
                    onChanged: (bool val) => _syncSetting(isPrivate: val),
                  ),
                  _buildCardToggle(
                    title: 'Appear in Explore',
                    subtitle: 'Search and suggestions',
                    value: appearInExplore,
                    onChanged: (bool val) => _syncSetting(showInDiscover: val),
                  ),
                  _buildCardToggle(
                    title: 'Hide my likes',
                    subtitle: 'Nobody sees what you liked',
                    value: hideLikes,
                    onChanged: (bool val) => _syncSetting(hideMyLikes: val),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section 2: INTERACTIONS
                  Text(
                    'INTERACTIONS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _buildCardSelector(
                    title: 'Who can message me',
                    subtitle: whoCanMessage,
                    onTap: () async {
                      final dynamic res = await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (_) => AllowMessagesFromScreen(
                            initialSelection: whoCanMessage,
                          ),
                        ),
                      );
                      if (res is String && mounted) {
                        _syncSetting(allowMessagesFrom: res);
                      }
                    },
                  ),
                  _buildCardSelector(
                    title: 'Who can comment',
                    subtitle: whoCanComment,
                    onTap: () async {
                      final String? res = await Navigator.push<String>(
                        context,
                        MaterialPageRoute<String>(
                          builder: (_) => WhoCanCommentScreen(
                            initialSelection: whoCanComment,
                          ),
                        ),
                      );
                      if (res != null && mounted) {
                        _syncSetting(allowCommentsFrom: res);
                      }
                    },
                  ),
                  _buildCardSelector(
                    title: 'Profile Visibility',
                    subtitle: profileVisibility,
                    onTap: () async {
                      final dynamic res = await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (_) => ProfileVisibilityScreen(
                            initialSelection: profileVisibility,
                          ),
                        ),
                      );
                      if (res is String && mounted) {
                        _syncSetting(profileVisibility: res);
                      }
                    },
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Section 3: STATUS
                  Text(
                    'STATUS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  _buildCardToggle(
                    title: 'Show activity status',
                    subtitle: "Lets people you follow see when you're active",
                    value: showActivityStatus,
                    onChanged: (bool val) =>
                        _syncSetting(showActivityStatus: val),
                  ),
                  _buildCardToggle(
                    title: 'Send read receipts',
                    subtitle: 'Shows "Read" under messages you\'ve opened',
                    value: sendReadReceipts,
                    onChanged: (bool val) =>
                        _syncSetting(sendReadReceipts: val),
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

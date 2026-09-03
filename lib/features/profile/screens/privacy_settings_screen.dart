import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/auth_provider.dart';
import '../../create_post/widgets/custom_gradient_switch.dart';
import '../../profile_setup/screens/allow_messages_from_screen.dart';
import '../../profile_setup/screens/profile_visibility_screen.dart';
import '../provider/profile_provider.dart';
import 'who_can_comment_screen.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  late bool _privateAccount;
  late bool _appearInExplore;
  late bool _hideLikes;

  bool _showActivityStatus = true;
  bool _sendReadReceipts = true;

  late String _whoCanMessage;
  late String _whoCanComment;
  late String _profileVisibility;

  @override
  void initState() {
    super.initState();
    final ProfileProvider provider = context.read<ProfileProvider>();
    _privateAccount = provider.isPrivate;
    _appearInExplore = provider.showInDiscover;
    _hideLikes = provider.hideMyLikes;
    _whoCanMessage = provider.allowMessagesFromLabel;
    _whoCanComment = provider.allowCommentsFromLabel;
    _profileVisibility = provider.profileVisibilityLabel;
    _showActivityStatus = provider.showActivityStatus;
    _sendReadReceipts = provider.sendReadReceipts;
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
                    value: _privateAccount,
                    onChanged: (bool val) {
                      setState(() => _privateAccount = val);
                      _syncSetting(isPrivate: val);
                    },
                  ),
                  _buildCardToggle(
                    title: 'Appear in Explore',
                    subtitle: 'Search and suggestions',
                    value: _appearInExplore,
                    onChanged: (bool val) {
                      setState(() => _appearInExplore = val);
                      _syncSetting(showInDiscover: val);
                    },
                  ),
                  _buildCardToggle(
                    title: 'Hide my likes',
                    subtitle: 'Nobody sees what you liked',
                    value: _hideLikes,
                    onChanged: (bool val) {
                      setState(() => _hideLikes = val);
                      _syncSetting(hideMyLikes: val);
                    },
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
                    subtitle: _whoCanMessage,
                    onTap: () async {
                      final dynamic res = await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (_) => AllowMessagesFromScreen(
                            initialSelection: _whoCanMessage,
                          ),
                        ),
                      );
                      if (res is String && mounted) {
                        setState(() => _whoCanMessage = res);
                        _syncSetting(allowMessagesFrom: res);
                      }
                    },
                  ),
                  _buildCardSelector(
                    title: 'Who can comment',
                    subtitle: _whoCanComment,
                    onTap: () async {
                      final String? res = await Navigator.push<String>(
                        context,
                        MaterialPageRoute<String>(
                          builder: (_) => WhoCanCommentScreen(
                            initialSelection: _whoCanComment,
                          ),
                        ),
                      );
                      if (res != null && mounted) {
                        setState(() => _whoCanComment = res);
                        _syncSetting(allowCommentsFrom: res);
                      }
                    },
                  ),
                  _buildCardSelector(
                    title: 'Profile Visibility',
                    subtitle: _profileVisibility,
                    onTap: () async {
                      final dynamic res = await Navigator.push<dynamic>(
                        context,
                        MaterialPageRoute<dynamic>(
                          builder: (_) => ProfileVisibilityScreen(
                            initialSelection: _profileVisibility,
                          ),
                        ),
                      );
                      if (res is String && mounted) {
                        setState(() => _profileVisibility = res);
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
                    value: _showActivityStatus,
                    onChanged: (bool val) {
                      setState(() => _showActivityStatus = val);
                      _syncSetting(showActivityStatus: val);
                    },
                  ),
                  _buildCardToggle(
                    title: 'Send read receipts',
                    subtitle: 'Shows "Read" under messages you\'ve opened',
                    value: _sendReadReceipts,
                    onChanged: (bool val) {
                      setState(() => _sendReadReceipts = val);
                      _syncSetting(sendReadReceipts: val);
                    },
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

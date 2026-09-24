import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../create_post/widgets/custom_gradient_switch.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile/services/user_relationship_service.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../provider/messages_provider.dart';
import 'block_user_modal_dialog.dart';
import 'mute_duration_bottom_sheet.dart';
import 'report_conversation_bottom_sheet.dart';
import 'restrict_user_modal_dialog.dart';

import '../../reports/models/report_models.dart';

class ChatOptionsBottomSheet extends StatelessWidget {
  const ChatOptionsBottomSheet({
    required this.username,
    this.conversationId,
    this.userId,
    super.key,
  });

  final String username;
  final String? conversationId;
  final String? userId;

  static Future<void> show(
    BuildContext context, {
    required String username,
    String? conversationId,
    String? userId,
  }) async {
    final MessagesProvider provider = context.read<MessagesProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<MessagesProvider>.value(
        value: provider,
        child: ChatOptionsBottomSheet(
          username: username,
          conversationId: conversationId,
          userId: userId,
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required Widget icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool isCyanHighlight = false,
    VoidCallback? onTap,
  }) {
    final bool isDark = context.isDarkMode;

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
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isCyanHighlight
                ? AppColors.gradientCyan
                : context.themeBorder,
            width: isCyanHighlight ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: <Widget>[
            // Icon in circular container matching requested style
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? (isCyanHighlight
                        ? AppColors.gradientCyan.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.08))
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? (isCyanHighlight
                          ? AppColors.gradientCyan.withValues(alpha: 0.3)
                          : Colors.white.withValues(alpha: 0.12))
                      : (isCyanHighlight
                          ? AppColors.gradientCyan.withValues(alpha: 0.4)
                          : context.themeBorder),
                  width: 1.1,
                ),
              ),
              child: Center(child: icon),
            ),

            const SizedBox(width: AppSpacing.md),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isCyanHighlight
                          ? AppColors.gradientCyan
                          : context.themeTextPrimary,
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

            if (trailing != null) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final MessagesProvider provider = context.watch<MessagesProvider>();
    final String cleanUsername =
        username.startsWith('@') ? username : '@$username';
    final bool isCurrentlyMuted = conversationId != null
        ? (provider.isMuted(conversationId!) ||
            provider.isMuted(userId) ||
            provider.isMuted(username))
        : (provider.isMuted(userId) || provider.isMuted(username));
    final bool isCurrentlyRestricted =
        provider.isRestricted(userId) || provider.isRestricted(username);
    final bool isCurrentlyBlocked =
        provider.isBlocked(userId) || provider.isBlocked(username);

    return Container(
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Drag handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.themeBorderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Title @username
              Text(
                cleanUsername,
                style: AppTextStyles.titleMedium.copyWith(
                  color: context.themeTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // 1. Mute / Unmute conversation
              _buildOptionTile(
                context: context,
                icon: SvgPicture.asset(
                  AppIcons.mute,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    isCurrentlyMuted
                        ? AppColors.gradientCyan
                        : context.themeTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                title: isCurrentlyMuted
                    ? 'Unmute conversation'
                    : 'Mute conversation',
                subtitle: isCurrentlyMuted
                    ? 'Notifications are currently off'
                    : 'Pick how long — you can undo anytime',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: context.themeIconMuted,
                  size: 20,
                ),
                onTap: () {
                  Navigator.pop(context);
                  if (isCurrentlyMuted) {
                    if (conversationId != null) {
                      provider.unmuteConversation(conversationId!);
                    } else {
                      provider.unmuteUser(userId ?? username, username: username);
                    }
                  } else {
                    MuteDurationBottomSheet.show(
                      context,
                      username: username,
                      onConfirmMute: (String duration) {
                        String apiDuration = '1_week';
                        int hours = 168;
                        if (duration.contains('24')) {
                          apiDuration = '24_hours';
                          hours = 24;
                        } else if (duration.contains('7')) {
                          apiDuration = '1_week';
                          hours = 168;
                        } else if (duration.contains('30')) {
                          apiDuration = '1_month';
                          hours = 720;
                        } else if (duration.toLowerCase().contains('undo')) {
                          apiDuration = 'indefinite';
                          hours = 87600;
                        }

                        if (conversationId != null) {
                          provider.muteConversation(
                            conversationId!,
                            duration: apiDuration,
                          );
                        } else {
                          provider.muteUser(
                            userId ?? username,
                            username: username,
                            durationHours: hours,
                          );
                        }
                      },
                    );
                  }
                },
              ),

              // 2. Restrict / Unrestrict @username
              _buildOptionTile(
                context: context,
                icon: SvgPicture.asset(
                  AppIcons.hide,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    isCurrentlyRestricted
                        ? AppColors.gradientCyan
                        : context.themeTextSecondary,
                    BlendMode.srcIn,
                  ),
                ),
                title: isCurrentlyRestricted
                    ? 'Unrestrict $cleanUsername'
                    : 'Restrict $cleanUsername',
                subtitle: isCurrentlyRestricted
                    ? 'Move their messages back to your main inbox'
                    : 'Their messages move to requests automatically',
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: context.themeIconMuted,
                  size: 20,
                ),
                onTap: () {
                  final ScaffoldMessengerState messenger =
                      ScaffoldMessenger.of(context);
                  final ApiClient client = context.read<ApiClient>();
                  final UserRelationshipService relService =
                      UserRelationshipService(client);
                  Navigator.pop(context);

                  if (isCurrentlyRestricted) {
                    () async {
                      String? targetId = userId;
                      if (targetId == null || targetId.isEmpty) {
                        targetId = await relService.resolveUserId(username);
                      }
                      final String effectiveId = (targetId != null && targetId.isNotEmpty)
                          ? targetId
                          : username;

                      await provider.unrestrictUser(effectiveId, username: username);
                      try {
                        if (context.mounted) {
                          context.read<ProfileProvider>().unrestrictUser(effectiveId);
                        }
                      } catch (_) {}
                      if (!context.mounted) return;
                      AppSnackBar.show(
                        context,
                        messenger: messenger,
                        title: '$cleanUsername unrestricted',
                        subtitle: 'Their messages returned to your main inbox',
                        actionLabel: 'Undo',
                        onAction: () async {
                          await provider.restrictUser(effectiveId, username: username);
                          try {
                            if (context.mounted) {
                              context.read<ProfileProvider>().restrictUser(effectiveId, username: username);
                            }
                          } catch (_) {}
                        },
                      );
                    }();
                  } else {
                    RestrictUserModalDialog.show(
                      context,
                      username: username,
                      onConfirmRestrict: () async {
                        String? targetId = userId;
                        if (targetId == null || targetId.isEmpty) {
                          targetId = await relService.resolveUserId(username);
                        }
                        final String effectiveId = (targetId != null && targetId.isNotEmpty)
                            ? targetId
                            : username;
                        await provider.restrictUser(effectiveId, username: username);
                        try {
                          if (context.mounted) {
                            context.read<ProfileProvider>().restrictUser(effectiveId, username: username);
                          }
                        } catch (_) {}
                      },
                    );
                  }
                },
              ),

              // 3. Block / Unblock @username
              _buildOptionTile(
                context: context,
                icon: Icon(
                  isCurrentlyBlocked ? Icons.lock_open_rounded : Icons.block_rounded,
                  color: AppColors.gradientCyan,
                  size: 18,
                ),
                title: isCurrentlyBlocked
                    ? 'Unblock $cleanUsername'
                    : 'Block $cleanUsername',
                subtitle: isCurrentlyBlocked
                    ? 'Allow them to message you and view your profile'
                    : 'Ends the conversation, removes all contact',
                isCyanHighlight: !isCurrentlyBlocked,
                onTap: () {
                  final ScaffoldMessengerState messenger =
                      ScaffoldMessenger.of(context);
                  final ApiClient client = context.read<ApiClient>();
                  final UserRelationshipService relService =
                      UserRelationshipService(client);
                  Navigator.pop(context);

                  if (isCurrentlyBlocked) {
                    () async {
                      String? targetId = userId;
                      if (targetId == null || targetId.isEmpty) {
                        targetId = await relService.resolveUserId(username);
                      }
                      final String effectiveId = (targetId != null && targetId.isNotEmpty)
                          ? targetId
                          : username;

                      await provider.unblockUser(effectiveId, username: username);
                      if (!context.mounted) return;
                      AppSnackBar.show(
                        context,
                        messenger: messenger,
                        title: '$cleanUsername unblocked',
                        subtitle: 'You can now message each other again',
                        actionLabel: 'Undo',
                        onAction: () => provider.blockUser(effectiveId, username: username),
                      );
                    }();
                  } else {
                    BlockUserModalDialog.show(
                      context,
                      username: username,
                      onConfirmBlock: () async {
                        String? targetId = userId;
                        if (targetId == null || targetId.isEmpty) {
                          targetId = await relService.resolveUserId(username);
                        }
                        final String effectiveId = (targetId != null && targetId.isNotEmpty)
                            ? targetId
                            : username;
                        await provider.blockUser(effectiveId, username: username);
                      },
                      onConfirmUnblock: () async {
                        String? targetId = userId;
                        if (targetId == null || targetId.isEmpty) {
                          targetId = await relService.resolveUserId(username);
                        }
                        final String effectiveId = (targetId != null && targetId.isNotEmpty)
                            ? targetId
                            : username;
                        await provider.unblockUser(effectiveId, username: username);
                      },
                    );
                  }
                },
              ),

              // 4. Report @username (Cyan highlight border!)
              _buildOptionTile(
                context: context,
                icon: const Icon(
                  Icons.flag_outlined,
                  color: AppColors.gradientCyan,
                  size: 18,
                ),
                title: 'Report $cleanUsername',
                subtitle: 'Send this conversation to a moderator',
                isCyanHighlight: true,
                onTap: () {
                  Navigator.pop(context);
                  ReportConversationBottomSheet.show(
                    context,
                    username: username,
                    targetType: ReportTargetType.conversation,
                    targetId: conversationId ?? username,
                    targetOwnerId: userId ?? username,
                    onReportSubmitted: () => provider.toggleBlock(username),
                  );
                },
              ),

              // 5. Typing Indicator toggle switch
              _buildOptionTile(
                context: context,
                icon: Icon(
                  Icons.keyboard_outlined,
                  color: context.themeTextSecondary,
                  size: 18,
                ),
                title: 'Typing Indicator',
                subtitle: "Let others see when you're typing a message.",
                trailing: CustomGradientSwitch(
                  value: provider.isTypingIndicatorEnabled(username) &&
                      (conversationId == null ||
                          provider.isTypingIndicatorEnabled(conversationId!)) &&
                      (userId == null ||
                          provider.isTypingIndicatorEnabled(userId!)),
                  onChanged: (bool val) {
                    provider.toggleTypingIndicator(username, val);
                    if (conversationId != null) {
                      provider.toggleTypingIndicator(conversationId!, val);
                    }
                    if (userId != null) {
                      provider.toggleTypingIndicator(userId!, val);
                    }
                  },
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Cancel button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.themeCardBackground,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: context.themeBorder,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

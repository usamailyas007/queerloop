import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../messages/widgets/block_user_modal_dialog.dart';
import '../../messages/widgets/mute_duration_bottom_sheet.dart';
import '../../messages/widgets/report_conversation_bottom_sheet.dart';
import '../../messages/widgets/restrict_user_modal_dialog.dart';

class UserProfileOptionsBottomSheet extends StatelessWidget {
  const UserProfileOptionsBottomSheet({
    required this.username,
    super.key,
  });

  final String username;

  static void show(BuildContext context, {required String username}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => UserProfileOptionsBottomSheet(username: username),
    );
  }

  Widget _buildOptionTile({
    required Widget iconWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color titleColor = Colors.white,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.card),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: ListTile(
            onTap: onTap,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 4,
            ),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: titleColor == AppColors.gradientCyan
                    ? AppColors.gradientCyan.withValues(alpha: 0.12)
                    : Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Center(child: iconWidget),
            ),
            title: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: titleColor,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white54,
                fontSize: 12,
              ),
            ),
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String cleanHandle =
        username.startsWith('@') ? username : '@$username';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Drag Handle Bar
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // User Handle Title + Subtitle
            Text(
              cleanHandle,
              style: AppTextStyles.titleLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Everything here is between you and this account — they're never notified which option you chose.",
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white54,
                fontSize: 12,
                height: 1.3,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // 1. Restrict Option
            _buildOptionTile(
              iconWidget: SvgPicture.asset(
                AppIcons.hide,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Colors.white70,
                  BlendMode.srcIn,
                ),
              ),
              title: 'Restrict $cleanHandle',
              subtitle: 'Their comments only show to them, DMs move to requests',
              onTap: () {
                final ScaffoldMessengerState messenger =
                    ScaffoldMessenger.of(context);
                Navigator.pop(context);
                RestrictUserModalDialog.show(
                  context,
                  username: username,
                  onConfirmRestrict: () {
                    AppSnackBar.show(
                      context,
                      messenger: messenger,
                      title: '$cleanHandle restrict',
                      subtitle:
                          'Their comments only shows to them, DMs sent to the requests',
                      icon: SvgPicture.asset(
                        AppIcons.hide,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          AppColors.gradientCyan,
                          BlendMode.srcIn,
                        ),
                      ),
                      actionLabel: 'Undo',
                    );
                  },
                );
              },
            ),

            // 2. Hide Content Option
            _buildOptionTile(
              iconWidget: SvgPicture.asset(
                AppIcons.hide,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Colors.white70,
                  BlendMode.srcIn,
                ),
              ),
              title: 'Hide content from this user',
              subtitle: 'Their posts stop appearing in your feeds',
              onTap: () {
                final ScaffoldMessengerState messenger =
                    ScaffoldMessenger.of(context);
                Navigator.pop(context);
                AppSnackBar.show(
                  context,
                  messenger: messenger,
                  title: 'Content hidden from $cleanHandle',
                  subtitle: 'Their posts will no longer show in your feed',
                  actionLabel: 'Undo',
                );
              },
            ),

            // 3. Mute Option
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
              title: 'Mute $cleanHandle',
              subtitle: 'Stay following, stop seeing posts',
              onTap: () {
                Navigator.pop(context);
                MuteDurationBottomSheet.show(
                  context,
                  username: username,
                  onConfirmMute: (String duration) {},
                );
              },
            ),

            // 4. Block Option
            _buildOptionTile(
              iconWidget: const Icon(
                Icons.block_rounded,
                color: AppColors.gradientCyan,
                size: 18,
              ),
              title: 'Block $cleanHandle',
              subtitle: 'They lose all contact with you',
              titleColor: AppColors.gradientCyan,
              onTap: () {
                Navigator.pop(context);
                BlockUserModalDialog.show(
                  context,
                  username: username,
                  onConfirmBlock: () {},
                );
              },
            ),

            // 5. Report Option
            _buildOptionTile(
              iconWidget: SvgPicture.asset(
                AppIcons.report,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  AppColors.gradientCyan,
                  BlendMode.srcIn,
                ),
              ),
              title: 'Report $cleanHandle',
              subtitle: 'A moderator reviews it within 24 hours',
              titleColor: AppColors.gradientCyan,
              onTap: () {
                Navigator.pop(context);
                ReportConversationBottomSheet.show(
                  context,
                  username: username,
                  onReportSubmitted: () {},
                );
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Cancel Button
            AppOutlineButton(
              text: 'Cancel',
              height: 48,
              onPressed: () => Navigator.pop(context),
            ),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

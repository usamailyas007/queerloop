import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snackbar.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({
    this.username = '@ashinorbit',
    super.key,
  });

  final String username;

  Widget _buildConsequenceCard(
    BuildContext context, {
    required Widget iconWidget,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 14,
      ),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.themeBorder,
          width: 1.1,
        ),
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 20,
            height: 20,
            child: Center(child: iconWidget),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: context.themeTextPrimary,
                fontSize: 13,
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String cleanUsername =
        username.startsWith('@') ? username : '@$username';
    final bool isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar (Back button + Delete account centered title) ──
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
                        color: context.themeIcon,
                        size: 24,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Delete account',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  const SizedBox(width: 38),
                ],
              ),
            ),

            // ── Main Content Body ───────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.lg),

                    // Top Cyan Trash Icon Badge Box matching reference design
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF003840).withValues(alpha: 0.45)
                            : const Color(0xFFE0F7FA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.gradientCyan.withValues(
                            alpha: isDark ? 0.3 : 0.35,
                          ),
                          width: 1.1,
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          AppIcons.delete,
                          width: 22,
                          height: 22,
                          colorFilter: const ColorFilter.mode(
                            AppColors.gradientCyan,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Title
                    Text(
                      "This can't be undone",
                      style: AppTextStyles.titleLarge.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Subtitle
                    Text(
                      "Here's exactly what happens when you confirm.",
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.themeTextSecondary,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // 1. All posts, comments erased within 30 days
                    _buildConsequenceCard(
                      context,
                      iconWidget: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                        size: 18,
                      ),
                      text:
                          'All posts, comments and messages are erased within 30 days',
                    ),

                    // 2. @username released and can be claimed by someone else
                    _buildConsequenceCard(
                      context,
                      iconWidget: Icon(
                        Icons.close_rounded,
                        color: isDark
                            ? Colors.white70
                            : const Color(0xFF334155),
                        size: 18,
                      ),
                      text:
                          '$cleanUsername is released and can be claimed by someone else',
                    ),

                    // 3. Reports stay with moderation without your name
                    _buildConsequenceCard(
                      context,
                      iconWidget: const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                      text:
                          'Reports you filed stay with moderation, without your name',
                    ),

                    const Spacer(),

                    // Bottom "Delete my account" outlined button
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        AppSnackBar.show(
                          context,
                          title: 'Account deletion initiated',
                          subtitle:
                              'You have 30 days to log back in and cancel.',
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: context.themeCardBackground,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: context.themeBorder,
                            width: 1.1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            'Delete my account',
                            style: TextStyle(
                              color: context.themeTextPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

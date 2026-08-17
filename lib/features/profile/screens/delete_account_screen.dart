import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snackbar.dart';

class DeleteAccountScreen extends StatelessWidget {
  const DeleteAccountScreen({
    this.username = '@ashinorbit',
    super.key,
  });

  final String username;

  Widget _buildConsequenceCard({
    required String text,
    required bool isPositive,
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
        children: <Widget>[
          Icon(
            isPositive ? Icons.check_rounded : Icons.close_rounded,
            color: AppColors.gradientCyan,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white70,
                fontSize: 13,
                height: 1.3,
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
                      'Delete account',
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
                  const SizedBox(height: AppSpacing.sm),

                  // Cyan Trash Badge Icon
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0D2A30),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.gradientCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.gradientCyan,
                        size: 26,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Main Title
                  Text(
                    "This can't be undone",
                    style: AppTextStyles.headingMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Subtitle
                  Text(
                    "Here's exactly what happens when you confirm.",
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // 3 Consequence List Cards
                  _buildConsequenceCard(
                    text: 'All posts, comments and messages are erased within 30 days',
                    isPositive: false,
                  ),
                  _buildConsequenceCard(
                    text: '$cleanUsername is released and can be claimed by someone else',
                    isPositive: false,
                  ),
                  _buildConsequenceCard(
                    text: 'Reports you filed stay with moderation, without your name',
                    isPositive: true,
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),

            // ── Bottom Action Button ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: GestureDetector(
                onTap: () {
                  final ScaffoldMessengerState messenger =
                      ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  AppSnackBar.show(
                    context,
                    messenger: messenger,
                    title: 'Account deletion requested',
                    subtitle: 'Your account will be erased within 30 days',
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: AppColors.gradientCyan,
                      size: 18,
                    ),
                    actionLabel: null,
                  );
                },
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D2A30),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(
                      color: AppColors.gradientCyan,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Delete my account',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.gradientCyan,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

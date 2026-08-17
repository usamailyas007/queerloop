import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';

class ReportConfirmationScreen extends StatelessWidget {
  const ReportConfirmationScreen({
    required this.username,
    required this.reason,
    required this.reportId,
    super.key,
  });

  final String username;
  final String reason;
  final String reportId;

  @override
  Widget build(BuildContext context) {
    final String cleanUsername =
        username.startsWith('@') ? username : '@$username';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Bar with Close X Button ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Main Content Body ───────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  // Center Checkmark Circle Badge
                  Center(
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F2F34),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.gradientCyan,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Header Title
                  Text(
                    'Report sent, and blocked',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.headingMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Subtitle Description
                  Text(
                    '$cleanUsername can no longer contact you. A moderator reviews the conversation within 24 hours.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white54,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Report Details Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      children: <Widget>[
                        // REPORT ID Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'REPORT ID',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white54,
                                letterSpacing: 1.2,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              reportId,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const Padding(
                          padding:
                              EdgeInsets.symmetric(vertical: AppSpacing.md),
                          child: Divider(
                            color: Color(0xFF2A2733),
                            height: 1,
                          ),
                        ),

                        // Reason Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Reason',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              reason,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // Status Row with Cyan Badge
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Status',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0F2F34),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                              ),
                              child: Text(
                                'In review',
                                style: AppTextStyles.caption.copyWith(
                                  color: AppColors.gradientCyan,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // WHAT HAPPENS NEXT Header
                  Text(
                    'WHAT HAPPENS NEXT',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white54,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // What happens next card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.check_rounded,
                          color: AppColors.gradientCyan,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            'You get a notification with the decision',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Bottom Fixed Action Button ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppGradientButton(
                text: 'Back to messages',
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

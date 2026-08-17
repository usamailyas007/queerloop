import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';

class ReportSentModalDialog extends StatelessWidget {
  const ReportSentModalDialog({
    required this.username,
    this.reportId = 'QL-84219',
    super.key,
  });

  final String username;
  final String reportId;

  static Future<void> show(
    BuildContext context, {
    required String username,
    String reportId = 'QL-84219',
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ReportSentModalDialog(
        username: username,
        reportId: reportId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String cleanUsername =
        username.startsWith('@') ? username : '@$username';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: const Color(0xFF191622),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Top Cyan Checkmark Circular Badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF0F2F34),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.gradientCyan.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.gradientCyan,
                size: 26,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Title: Report sent
            Text(
              'Report sent',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // Subtitle Description
            Text(
              "A moderator reviews it within 24 hours. You'll get a notification with the decision — $cleanUsername is never told who reported.",
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white54,
                fontSize: 12,
                height: 1.35,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Details Inset Box (Report ID & Status)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm + 4,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                ),
              ),
              child: Column(
                children: <Widget>[
                  // Row 1: Report ID
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Report ID',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white38,
                          fontSize: 12,
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
                  const SizedBox(height: 8),

                  // Row 2: Status with Cyan Pill Badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Status',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2F34),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.gradientCyan.withValues(alpha: 0.25),
                          ),
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

            // Done Button
            AppGradientButton(
              text: 'Done',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

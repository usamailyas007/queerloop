import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';

/// Center-screen dialog to confirm clearing all search history.
class ClearSearchHistoryDialog extends StatelessWidget {
  const ClearSearchHistoryDialog({super.key});

  /// Shows the dialog centered on screen.
  /// Returns [true] if user confirms, [false] otherwise.
  static Future<bool> show(BuildContext context) async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => const ClearSearchHistoryDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxxl,
        ),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: context.themeBorder),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: context.isDarkMode ? 0.5 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // ── Delete icon badge ────────────────────────────────────────
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: context.themeCyanBadgeBackground,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppIcons.delete,
                  width: 32,
                  height: 32,
                  colorFilter: const ColorFilter.mode(
                    AppColors.gradientCyan,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Title ────────────────────────────────────────────────────
            Text(
              'Clear search history?',
              style: AppTextStyles.headingMedium.copyWith(
                color: context.themeTextPrimary,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Subtitle ─────────────────────────────────────────────────
            Text(
              'This removes all recent searches from this account. Suggestions stay, and nothing you searched for was ever shown to anyone else.',
              style: AppTextStyles.authHeaderSub.copyWith(
                color: context.themeTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Buttons ──────────────────────────────────────────────────
            Row(
              children: <Widget>[
                Expanded(
                  child: AppOutlineButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context, false),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AppGradientButton(
                    text: 'Clear all',
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

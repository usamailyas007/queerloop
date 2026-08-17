import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../../messages/widgets/block_user_modal_dialog.dart';
import '../../messages/widgets/report_conversation_bottom_sheet.dart';

class SafetyBottomSheet extends StatelessWidget {
  const SafetyBottomSheet({
    this.username = '@rowankeeps',
    super.key,
  });

  final String username;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String cleanUsername =
        username.startsWith('@') ? username : '@$username';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12101A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Drag Handle Bar ──────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Title Header (Cyan Shield Icon + Safety Title) ────────────────
            Row(
              children: <Widget>[
                SvgPicture.asset(
                  AppIcons.safety,
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    AppColors.gradientCyan,
                    BlendMode.srcIn,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  l10n.safetyTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Subtitle ─────────────────────────────────────────────────────
            Text(
              l10n.safetySub,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 13,
                height: 1.35,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── 1. Report This Post Tile ─────────────────────────────────────
            _SafetyActionTile(
              iconChild: SvgPicture.asset(
                AppIcons.report,
                width: 18,
                height: 18,
                colorFilter: const ColorFilter.mode(
                  Colors.white70,
                  BlendMode.srcIn,
                ),
              ),
              title: l10n.safetyReportTitle,
              subtitle: l10n.safetyReportSub,
              onTap: () {
                Navigator.pop(context);
                ReportConversationBottomSheet.show(
                  context,
                  username: username,
                  targetTitle: 'Reporting $cleanUsername\'s post',
                  onReportSubmitted: () {},
                );
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // ── 2. Block User Tile ───────────────────────────────────────────
            _SafetyActionTile(
              iconChild: const Icon(
                Icons.block_rounded,
                color: Colors.white70,
                size: 20,
              ),
              title: l10n.safetyBlockTitle,
              subtitle: l10n.safetyBlockSub,
              onTap: () {
                Navigator.pop(context);
                BlockUserModalDialog.show(
                  context,
                  username: username,
                  onConfirmBlock: () {},
                );
              },
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Cancel Button ────────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1B26),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Center(
                  child: Text(
                    l10n.shareCancelBtn,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
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

class _SafetyActionTile extends StatelessWidget {
  const _SafetyActionTile({
    required this.iconChild,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget iconChild;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFF2C2738),
                shape: BoxShape.circle,
              ),
              child: Center(child: iconChild),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

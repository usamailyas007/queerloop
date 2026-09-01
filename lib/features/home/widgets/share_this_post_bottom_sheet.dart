import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';

class ShareThisPostBottomSheet extends StatelessWidget {
  const ShareThisPostBottomSheet({
    required this.onOpenMoreSendTo,
    required this.onOpenReportSafety,
    super.key,
  });

  final VoidCallback onOpenMoreSendTo;
  final VoidCallback onOpenReportSafety;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return Container(
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: context.themeBorderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Title ────────────────────────────────────────────────────────
            Text(
              l10n.sharePostTitle,
              style: TextStyle(
                color: context.themeTextPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── SEND TO Header ───────────────────────────────────────────────
            Text(
              l10n.shareSendToHeader,
              style: TextStyle(
                color: context.themeTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Top Connections Row (jules, rowan, moss, theo, + More) ──────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                _UserAvatarItem(
                  avatarAsset: AppImages.user1,
                  name: 'jules',
                  onTap: () {},
                ),
                _UserAvatarItem(
                  avatarAsset: AppImages.user2,
                  name: 'rowan',
                  onTap: () {},
                ),
                _UserAvatarItem(
                  avatarAsset: AppImages.user3,
                  name: 'moss',
                  onTap: () {},
                ),
                _UserAvatarItem(
                  avatarAsset: AppImages.user4,
                  name: 'theo',
                  onTap: () {},
                ),
                // More Circle Button (Opens SendToBottomSheet)
                GestureDetector(
                  onTap: onOpenMoreSendTo,
                  child: Column(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.themeCardBackground,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.themeBorder),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: context.themeIconMuted,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        l10n.shareMore,
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            Divider(color: context.themeBorder, height: 1),

            const SizedBox(height: AppSpacing.lg),

            // ── Action Circular Buttons Row (Copy Link, Save, Report) ────────
            Row(
              children: <Widget>[
                // 1. Copy Link
                _ActionButtonTile(
                  iconPath: AppIcons.copyLink,
                  label: l10n.shareCopyLink,
                  iconColor: context.themeIcon,
                  labelColor: context.themeTextSecondary,
                  onTap: () {
                    AppSnackBar.showSuccess(
                      context,
                      title: 'Link Copied',
                      subtitle: 'Link copied to clipboard!',
                    );
                  },
                ),

                const SizedBox(width: 24),

                // 2. Save
                _ActionButtonTile(
                  iconPath: AppIcons.save,
                  label: l10n.homeSave,
                  iconColor: context.themeIcon,
                  labelColor: context.themeTextSecondary,
                  onTap: () {},
                ),

                const SizedBox(width: 24),

                // 3. Report (Pink Icon + Pink Label, opens SafetyBottomSheet)
                _ActionButtonTile(
                  iconPath: AppIcons.report,
                  label: l10n.shareReport,
                  iconColor: const Color(0xFFFF4B8B),
                  labelColor: const Color(0xFFFF4B8B),
                  onTap: onOpenReportSafety,
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Location Privacy Banner ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.themeCardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.themeBorder,
                ),
              ),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.gradientCyan,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.shareNoticeText,
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // ── Cancel Button ────────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: context.themeCardBackground,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: context.themeBorder,
                  ),
                ),
                child: Center(
                  child: Text(
                    l10n.shareCancelBtn,
                    style: TextStyle(
                      color: context.themeTextPrimary,
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

class _UserAvatarItem extends StatelessWidget {
  const _UserAvatarItem({
    required this.avatarAsset,
    required this.name,
    required this.onTap,
  });

  final String avatarAsset;
  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          ClipOval(
            child: Image.asset(
              avatarAsset,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: TextStyle(
              color: context.themeTextSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtonTile extends StatelessWidget {
  const _ActionButtonTile({
    required this.iconPath,
    required this.label,
    required this.iconColor,
    required this.labelColor,
    required this.onTap,
  });

  final String iconPath;
  final String label;
  final Color iconColor;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.themeCardBackground,
              shape: BoxShape.circle,
              border: Border.all(color: context.themeBorder),
            ),
            child: Center(
              child: SvgPicture.asset(
                iconPath,
                width: 20,
                height: 20,
                colorFilter: ColorFilter.mode(
                  iconColor,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_provider.dart';
import '../../messages/widgets/block_user_modal_dialog.dart';
import '../../messages/widgets/report_conversation_bottom_sheet.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile/services/user_relationship_service.dart';
import '../../reports/models/report_models.dart';
import '../provider/home_feed_provider.dart';

class SafetyBottomSheet extends StatelessWidget {
  const SafetyBottomSheet({
    this.username = '@rowankeeps',
    this.postId,
    this.authorId,
    this.communityId,
    this.isReel = false,
    this.isCreator,
    super.key,
  });

  final String username;
  final String? postId;
  final String? authorId;
  final String? communityId;
  final bool isReel;
  final bool? isCreator;

  Future<void> _confirmDelete(BuildContext context) async {
    if (postId == null || postId!.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final String itemType = isReel ? 'reel' : 'post';
    final String itemTypeCap = isReel ? 'Reel' : 'Post';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: ctx.themeCardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: ctx.themeBorder),
        ),
        title: Text(
          'Delete $itemTypeCap',
          style: TextStyle(
            color: ctx.themeTextPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete this $itemType? This action cannot be undone.',
          style: TextStyle(color: ctx.themeTextSecondary),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: ctx.themeTextSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text(
              'Delete',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      Navigator.pop(context, true); // Dismiss safety bottom sheet with true
      final ProfileProvider profile = context.read<ProfileProvider>();
      final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
      final bool ok1 = await profile.deletePost(postId!);
      final bool ok2 = await homeFeed.deletePost(postId!);
      if (context.mounted) {
        if (ok1 || ok2) {
          AppSnackBar.showSuccess(
            context,
            title: '$itemTypeCap Deleted',
            subtitle: 'Your $itemType was successfully deleted.',
          );
        } else {
          AppSnackBar.show(
            context,
            title: 'Error',
            subtitle: 'Failed to delete $itemType. Please try again.',
            type: SnackBarType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String cleanUsername =
        username.startsWith('@') ? username : '@$username';

    final AuthProvider auth = context.read<AuthProvider>();
    final ProfileProvider profileProvider = context.read<ProfileProvider>();
    final String? currentUserId = auth.userId ?? profileProvider.profile?.id;
    final String myUsername = (auth.user?.displayName ?? profileProvider.username)
        .replaceAll('@', '')
        .trim()
        .toLowerCase();
    final String profileUsername = (profileProvider.profile?.username ?? '')
        .replaceAll('@', '')
        .trim()
        .toLowerCase();
    final String targetUsername =
        username.replaceAll('@', '').trim().toLowerCase();
    final String? cleanAuthorId =
        authorId?.replaceAll('@', '').trim().toLowerCase();
    final String? cleanCurrentUserId =
        currentUserId?.trim().toLowerCase();

    final bool isMatchingInUserLists = (postId != null && postId!.isNotEmpty) &&
        (profileProvider.userPosts.any((p) => p.id == postId) ||
            profileProvider.userReels.any((r) => r.id == postId));

    final bool calculatedIsCreator = isMatchingInUserLists ||
        (cleanAuthorId != null &&
            cleanCurrentUserId != null &&
            cleanAuthorId == cleanCurrentUserId) ||
        (cleanAuthorId != null &&
            ((myUsername.isNotEmpty && cleanAuthorId == myUsername) ||
                (profileUsername.isNotEmpty &&
                    cleanAuthorId == profileUsername))) ||
        (myUsername.isNotEmpty && targetUsername == myUsername) ||
        (profileUsername.isNotEmpty && targetUsername == profileUsername) ||
        targetUsername == 'you' ||
        cleanAuthorId == 'you';

    final bool creator = isCreator ?? calculatedIsCreator;
    final String itemType = isReel ? 'reel' : 'post';
    final String itemTypeCap = isReel ? 'Reel' : 'Post';

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
                  creator ? '$itemTypeCap Safety & Options' : l10n.safetyTitle,
                  style: TextStyle(
                    color: context.themeTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // ── Subtitle ─────────────────────────────────────────────────────
            Text(
              creator
                  ? 'Manage safety and deletion options for your $itemType.'
                  : l10n.safetySub,
              style: TextStyle(
                color: context.themeTextMuted,
                fontSize: 13,
                height: 1.35,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            if (creator) ...<Widget>[
              // ── Delete Post/Reel Option (Visible ONLY to creator) ───────────
              _SafetyActionTile(
                iconChild: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.redAccent,
                  size: 22,
                ),
                title: 'Delete $itemTypeCap',
                titleColor: Colors.redAccent,
                subtitle:
                    'Permanently remove this $itemType from your profile and feed',
                subtitleColor: Colors.redAccent.withValues(alpha: 0.8),
                borderColor: Colors.redAccent.withValues(alpha: 0.3),
                onTap: () => _confirmDelete(context),
              ),
            ] else ...<Widget>[
              // ── 1. Report This Post Tile ─────────────────────────────────────
              _SafetyActionTile(
                iconChild: SvgPicture.asset(
                  AppIcons.report,
                  width: 18,
                  height: 18,
                  colorFilter: ColorFilter.mode(
                    context.themeTextSecondary,
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
                    targetType: ReportTargetType.post,
                    targetId: postId,
                    targetOwnerId: authorId,
                    communityId: communityId,
                    onReportSubmitted: () {},
                  );
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // ── 2. Block User Tile ───────────────────────────────────────────
              _SafetyActionTile(
                iconChild: Icon(
                  Icons.block_rounded,
                  color: context.themeTextSecondary,
                  size: 20,
                ),
                title: l10n.safetyBlockTitle,
                subtitle: l10n.safetyBlockSub,
                onTap: () {
                  final ApiClient client = context.read<ApiClient>();
                  final UserRelationshipService relService =
                      UserRelationshipService(client);
                  Navigator.pop(context);
                  BlockUserModalDialog.show(
                    context,
                    username: username,
                    onConfirmBlock: () async {
                      String? targetId = authorId;
                      if (targetId == null || targetId.isEmpty) {
                        targetId = await relService.resolveUserId(username);
                      }
                      if (targetId != null && targetId.isNotEmpty) {
                        await relService.blockUser(targetId);
                      }
                    },
                    onConfirmUnblock: () async {
                      String? targetId = authorId;
                      if (targetId == null || targetId.isEmpty) {
                        targetId = await relService.resolveUserId(username);
                      }
                      if (targetId != null && targetId.isNotEmpty) {
                        await relService.unblockUser(targetId);
                      }
                    },
                  );
                },
              ),
            ],

            const SizedBox(height: AppSpacing.xl),

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

class _SafetyActionTile extends StatelessWidget {
  const _SafetyActionTile({
    required this.iconChild,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
    this.subtitleColor,
    this.borderColor,
  });

  final Widget iconChild;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? titleColor;
  final Color? subtitleColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: context.themeCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor ?? context.themeBorder,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? (titleColor != null
                        ? titleColor!.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.08))
                    : (titleColor != null
                        ? titleColor!.withValues(alpha: 0.08)
                        : Colors.transparent),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? (borderColor ?? Colors.white.withValues(alpha: 0.12))
                      : (borderColor ?? context.themeBorder),
                  width: 1.1,
                ),
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
                    style: TextStyle(
                      color: titleColor ?? context.themeTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: subtitleColor ?? context.themeTextMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: titleColor ?? context.themeTextMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

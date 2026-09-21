import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../messages/models/message_models.dart';
import '../../messages/provider/messages_provider.dart';
import '../../profile/models/user_relationship_models.dart';
import '../../profile/provider/profile_provider.dart';
import '../models/reel_item_model.dart';

class ShareContactItem {
  const ShareContactItem({
    required this.username,
    required this.displayName,
    this.conversationId,
    this.userId,
    this.avatarUrl,
  });

  final String username;
  final String displayName;
  final String? conversationId;
  final String? userId;
  final String? avatarUrl;
}

class ShareThisPostBottomSheet extends StatefulWidget {
  const ShareThisPostBottomSheet({
    required this.onOpenMoreSendTo,
    required this.onOpenReportSafety,
    this.reel,
    this.postId,
    this.postAuthor,
    this.postThumbnail,
    super.key,
  });

  final VoidCallback onOpenMoreSendTo;
  final VoidCallback onOpenReportSafety;
  final ReelItemModel? reel;
  final String? postId;
  final String? postAuthor;
  final String? postThumbnail;

  @override
  State<ShareThisPostBottomSheet> createState() =>
      _ShareThisPostBottomSheetState();
}

class _ShareThisPostBottomSheetState extends State<ShareThisPostBottomSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final MessagesProvider mp = context.read<MessagesProvider>();
        if (mp.conversations.isEmpty) {
          mp.loadConversations();
        }
        final ProfileProvider pp = context.read<ProfileProvider>();
        if (pp.followers.isEmpty) {
          pp.loadFollowers();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final MessagesProvider msgProvider = context.watch<MessagesProvider>();
    final ProfileProvider profileProvider = context.watch<ProfileProvider>();

    // ── Build Dynamic Contacts (Conversations + Followers) ───────────────────
    final List<ShareContactItem> contacts = <ShareContactItem>[];
    final Set<String> seenUsernames = <String>{};

    // 1. First add users with active conversations
    for (final ConversationModel c in msgProvider.conversations) {
      final String u = c.username.replaceAll('@', '').trim();
      final String effectiveUsername =
          u.isNotEmpty ? u : (c.displayName?.isNotEmpty == true ? c.displayName! : 'User');
      final String key = effectiveUsername.toLowerCase();
      if (!seenUsernames.contains(key)) {
        seenUsernames.add(key);
        contacts.add(ShareContactItem(
          conversationId: c.id,
          userId: c.participantId,
          username: effectiveUsername,
          displayName: c.displayName?.isNotEmpty == true ? c.displayName! : effectiveUsername,
          avatarUrl: (c.avatarUrl != null && c.avatarUrl!.isNotEmpty)
              ? c.avatarUrl
              : (c.avatarAsset.isNotEmpty ? c.avatarAsset : null),
        ));
      }
    }

    // 2. Add followers who aren't already in conversation list
    for (final UserRelationItem f in profileProvider.followers) {
      final String u = f.username.replaceAll('@', '').trim();
      final String key = u.toLowerCase();
      if (u.isNotEmpty && !seenUsernames.contains(key)) {
        seenUsernames.add(key);
        contacts.add(ShareContactItem(
          conversationId: null,
          userId: f.userId,
          username: u,
          displayName: f.displayName.isNotEmpty ? f.displayName : u,
          avatarUrl: f.avatarUrl,
        ));
      }
    }

    final String shareTargetId = widget.reel?.id ?? widget.postId ?? '';

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

            // ── Top Connections Row (Dynamic users + More button) ───────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  for (final ShareContactItem c in contacts.take(5)) ...<Widget>[
                    Padding(
                      padding: const EdgeInsets.only(right: 18),
                      child: _UserAvatarItem(
                        avatarAsset: (c.avatarUrl != null && c.avatarUrl!.isNotEmpty)
                            ? c.avatarUrl!
                            : AppImages.user1,
                        name: c.username,
                        onTap: () async {
                          Navigator.pop(context);
                          if (shareTargetId.isNotEmpty) {
                            if (c.conversationId != null &&
                                c.conversationId!.isNotEmpty) {
                              await msgProvider.sharePost(
                                sharedPostId: shareTargetId,
                                conversationIds: <String>[c.conversationId!],
                                contentType: 'reel_share',
                              );
                            } else if (c.userId != null &&
                                c.userId!.isNotEmpty) {
                              await msgProvider.sharePost(
                                sharedPostId: shareTargetId,
                                recipientUserIds: <String>[c.userId!],
                                contentType: 'reel_share',
                              );
                            }
                          }
                          if (!context.mounted) return;
                          AppSnackBar.showSuccess(
                            context,
                            title: 'Sent',
                            subtitle: 'Shared to @${c.username}!',
                          );
                        },
                      ),
                    ),
                  ],

                  // More Circle Button (Opens SendToBottomSheet)
                  GestureDetector(
                    onTap: widget.onOpenMoreSendTo,
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
                  onTap: widget.onOpenReportSafety,
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
            child: avatarAsset.startsWith('http')
                ? Image.network(
                    avatarAsset,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.person, size: 48),
                  )
                : Image.asset(
                    avatarAsset.isNotEmpty ? avatarAsset : AppImages.user1,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.person, size: 48),
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

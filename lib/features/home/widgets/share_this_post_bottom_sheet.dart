import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/services/media_download_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_provider.dart';
import '../../messages/models/message_models.dart';
import '../../messages/provider/messages_provider.dart';
import '../../profile/models/user_relationship_models.dart';
import '../../profile/provider/profile_provider.dart';
import '../models/post_item_model.dart';
import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../../messages/widgets/report_conversation_bottom_sheet.dart';
import '../../reports/models/report_models.dart';
import 'send_to_bottom_sheet.dart';

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
    this.onOpenMoreSendTo,
    this.onOpenReportSafety,
    this.reel,
    this.post,
    this.postId,
    this.postAuthor,
    this.postThumbnail,
    this.mediaUrl,
    this.allowDownloads = true,
    super.key,
  });

  final VoidCallback? onOpenMoreSendTo;
  final VoidCallback? onOpenReportSafety;
  final ReelItemModel? reel;
  final PostItemModel? post;
  final String? postId;
  final String? postAuthor;
  final String? postThumbnail;
  final String? mediaUrl;
  final bool allowDownloads;

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
      if (msgProvider.isBlocked(c.participantId) || msgProvider.isBlocked(c.username)) {
        continue;
      }
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
      if (msgProvider.isBlocked(f.userId) || msgProvider.isBlocked(f.username)) {
        continue;
      }
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
                        onTap: () {
                          final String contentTypeLabel =
                              widget.reel != null ? 'Reel' : 'Post';
                          AppSnackBar.showSuccess(
                            context,
                            title: '$contentTypeLabel shared',
                            subtitle: 'Shared to @${c.username}!',
                          );

                          Navigator.pop(context);

                          if (shareTargetId.isNotEmpty) {
                            if (c.conversationId != null &&
                                c.conversationId!.isNotEmpty) {
                              unawaited(
                                msgProvider.sharePost(
                                  sharedPostId: shareTargetId,
                                  conversationIds: <String>[c.conversationId!],
                                  contentType: widget.reel != null ? 'reel' : 'post',
                                  reel: widget.reel,
                                  post: widget.post,
                                ),
                              );
                            } else if (c.userId != null &&
                                c.userId!.isNotEmpty) {
                              unawaited(
                                msgProvider.sharePost(
                                  sharedPostId: shareTargetId,
                                  recipientUserIds: <String>[c.userId!],
                                  contentType: widget.reel != null ? 'reel' : 'post',
                                  reel: widget.reel,
                                  post: widget.post,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],

                  // More Circle Button (Opens SendToBottomSheet)
                  GestureDetector(
                    onTap: () {
                      if (widget.onOpenMoreSendTo != null) {
                        widget.onOpenMoreSendTo!();
                      } else {
                        Navigator.pop(context);
                        showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext ctx) => SendToBottomSheet(
                            reel: widget.reel,
                            postId: widget.reel?.id ?? widget.postId ?? widget.post?.id,
                            postAuthor: widget.reel?.username ?? widget.postAuthor ?? widget.post?.username,
                            postThumbnail: widget.reel?.thumbnailUrl ?? widget.postThumbnail ?? widget.post?.postImageUrl ?? widget.post?.postImageAsset,
                            postCaption: widget.reel?.caption ?? widget.post?.content,
                          ),
                        );
                      }
                    },
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

            // ── Action Circular Buttons Row (Copy Link, Download, Save, Report) ────────
            Builder(
              builder: (BuildContext ctx) {
                final String? resolvedMedia = widget.mediaUrl ??
                    widget.reel?.videoUrl ??
                    widget.reel?.videoFilePath ??
                    (widget.reel?.videoAsset.isNotEmpty == true ? widget.reel?.videoAsset : null) ??
                    widget.post?.videoUrl ??
                    widget.post?.postImageUrl ??
                    widget.post?.postImageAsset ??
                    widget.postThumbnail;
                final bool isVideo = widget.reel != null ||
                    (widget.post?.videoUrl != null) ||
                    (resolvedMedia != null &&
                        (resolvedMedia.endsWith('.mp4') ||
                            resolvedMedia.endsWith('.mov') ||
                            resolvedMedia.endsWith('.m3u8') ||
                            resolvedMedia.contains('video') ||
                            resolvedMedia.contains('/videos/')));
                final String? currentUserId = context.read<AuthProvider>().userId;
                final String? authorId = widget.reel?.authorId ?? widget.post?.authorId;
                final bool isCreator = (authorId != null &&
                        currentUserId != null &&
                        authorId.toLowerCase() == currentUserId.toLowerCase()) ||
                    (widget.postAuthor != null &&
                        context.read<ProfileProvider>().username.replaceAll('@', '').toLowerCase() ==
                            widget.postAuthor!.replaceAll('@', '').toLowerCase());
                final bool downloadsAllowed = widget.reel?.allowDownloads ??
                    widget.post?.allowDownloads ??
                    widget.allowDownloads;
                final bool canDownload = downloadsAllowed &&
                    (resolvedMedia != null && resolvedMedia.isNotEmpty);

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    // 1. Copy Link
                    _ActionButtonTile(
                      iconPath: AppIcons.copyLink,
                      label: l10n.shareCopyLink,
                      iconColor: context.themeIcon,
                      labelColor: context.themeTextSecondary,
                      onTap: () {
                        final String postUrl = resolvedMedia != null && resolvedMedia.isNotEmpty
                            ? resolvedMedia
                            : 'https://queerloop.com/post/$shareTargetId';
                        Clipboard.setData(ClipboardData(text: postUrl));
                        AppSnackBar.showSuccess(
                          context,
                          title: 'Link Copied',
                          subtitle: 'Link copied to clipboard!',
                        );
                        Navigator.pop(context);
                      },
                    ),

                    // 2. Download (Only if allowed by creator)
                    if (canDownload)
                      _ActionButtonTile(
                        icon: Icon(
                          Icons.download_rounded,
                          color: context.themeIcon,
                          size: 22,
                        ),
                        label: 'Download',
                        iconColor: context.themeIcon,
                        labelColor: context.themeTextSecondary,
                        onTap: () {
                          Navigator.pop(context);
                          MediaDownloadService.downloadMedia(
                            context: context,
                            mediaUrl: resolvedMedia,
                            title: widget.postAuthor ?? 'queerloop',
                            authorId: authorId,
                            isVideo: isVideo,
                            allowDownloads: canDownload,
                            isCreator: isCreator,
                          );
                        },
                      ),

                    // 3. Save
                    Builder(
                      builder: (BuildContext ctx) {
                        final HomeFeedProvider homeFeed = ctx.watch<HomeFeedProvider>();
                        final String? targetId = widget.reel?.id ?? widget.post?.id ?? widget.postId;
                        final bool isSaved = (targetId != null && homeFeed.isPostSaved(targetId)) ||
                            (widget.reel?.isSaved ?? widget.post?.isSaved ?? false);

                        return _ActionButtonTile(
                          icon: Icon(
                            isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                            color: isSaved ? AppColors.gradientCyan : context.themeIcon,
                            size: 22,
                          ),
                          label: isSaved ? 'Saved' : l10n.homeSave,
                          iconColor: isSaved ? AppColors.gradientCyan : context.themeIcon,
                          labelColor: isSaved ? AppColors.gradientCyan : context.themeTextSecondary,
                          onTap: () {
                            Navigator.pop(context);
                            if (targetId != null && targetId.isNotEmpty) {
                              final bool newSaved = !isSaved;
                              if (widget.reel != null || isVideo) {
                                homeFeed.toggleSaveReel(
                                  targetId,
                                  fallbackReel: widget.reel,
                                );
                                try {
                                  context.read<ProfileProvider>().updateSavedReel(
                                    targetId,
                                    isSaved: newSaved,
                                    fallbackReel: widget.reel?.copyWith(isSaved: newSaved),
                                  );
                                } catch (_) {}
                              } else {
                                homeFeed.toggleSavePost(
                                  targetId,
                                  fallbackPost: widget.post,
                                );
                                try {
                                  context.read<ProfileProvider>().updateSavedPost(
                                    targetId,
                                    isSaved: newSaved,
                                    fallbackPost: widget.post?.copyWith(isSaved: newSaved),
                                  );
                                } catch (_) {}
                              }
                              AppSnackBar.showSuccess(
                                context,
                                title: isSaved ? 'Removed' : 'Saved',
                                subtitle: isSaved
                                    ? 'Removed from your saved items.'
                                    : 'Saved to your profile!',
                              );
                            }
                          },
                        );
                      },
                    ),

                    // 4. Report (Only visible for other users' content)
                    if (!isCreator)
                      _ActionButtonTile(
                        iconPath: AppIcons.report,
                        label: l10n.shareReport,
                        iconColor: const Color(0xFFFF4B8B),
                        labelColor: const Color(0xFFFF4B8B),
                        onTap: () {
                          Navigator.pop(context);
                          final String author = widget.postAuthor ??
                              widget.reel?.username ??
                              widget.post?.username ??
                              'queerloop';
                          final String? targetId =
                              widget.reel?.id ?? widget.post?.id ?? widget.postId;
                          final String? authorId =
                              widget.reel?.authorId ?? widget.post?.authorId;
                          final String? communityId =
                              widget.reel?.communityId ?? widget.post?.communityId;
                          ReportConversationBottomSheet.show(
                            context,
                            username: author,
                            targetTitle:
                                'Reporting ${author.startsWith('@') ? author : '@$author'}\'s post',
                            targetType: ReportTargetType.post,
                            targetId: targetId,
                            targetOwnerId: authorId,
                            communityId: communityId,
                            onReportSubmitted: () {},
                          );
                        },
                      ),
                  ],
                );
              },
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
                    errorBuilder: (_, _, _) => Image.asset(
                        AppImages.defaultAvatar,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                  )
                : Image.asset(
                    avatarAsset.isNotEmpty ? avatarAsset : AppImages.defaultAvatar,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Image.asset(
                        AppImages.defaultAvatar,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
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
    this.iconPath,
    this.icon,
    required this.label,
    required this.iconColor,
    required this.labelColor,
    required this.onTap,
  });

  final String? iconPath;
  final Widget? icon;
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
              child: icon ??
                  (iconPath != null
                      ? SvgPicture.asset(
                          iconPath!,
                          width: 20,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            iconColor,
                            BlendMode.srcIn,
                          ),
                        )
                      : const SizedBox.shrink()),
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

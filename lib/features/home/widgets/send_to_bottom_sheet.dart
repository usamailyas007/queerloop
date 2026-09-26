import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../messages/models/message_models.dart';
import '../../messages/provider/messages_provider.dart';
import '../../profile/models/user_relationship_models.dart';
import '../../profile/provider/profile_provider.dart';
import '../models/reel_item_model.dart';
import 'share_this_post_bottom_sheet.dart';

class SendToBottomSheet extends StatefulWidget {
  const SendToBottomSheet({
    this.reel,
    this.postId,
    this.postAuthor,
    this.postAuthorId,
    this.postThumbnail,
    this.postCaption,
    super.key,
  });

  final ReelItemModel? reel;
  final String? postId;
  final String? postAuthor;
  final String? postAuthorId;
  final String? postThumbnail;
  final String? postCaption;

  @override
  State<SendToBottomSheet> createState() => _SendToBottomSheetState();
}

class _SendToBottomSheetState extends State<SendToBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  final Set<String> _selectedUserIds = <String>{};

  void _toggleUser(String id) {
    setState(() {
      if (_selectedUserIds.contains(id)) {
        _selectedUserIds.remove(id);
      } else {
        _selectedUserIds.add(id);
      }
    });
  }

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
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final MessagesProvider msgProvider = context.watch<MessagesProvider>();
    final ProfileProvider profileProvider = context.watch<ProfileProvider>();

    // ── Build Dynamic Contacts (Conversations + Followers) ───────────────────
    final List<ShareContactItem> allContacts = <ShareContactItem>[];
    final Set<String> seenUsernames = <String>{};

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
        allContacts.add(ShareContactItem(
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

    for (final UserRelationItem f in profileProvider.followers) {
      if (msgProvider.isBlocked(f.userId) || msgProvider.isBlocked(f.username)) {
        continue;
      }
      final String u = f.username.replaceAll('@', '').trim();
      final String key = u.toLowerCase();
      if (u.isNotEmpty && !seenUsernames.contains(key)) {
        seenUsernames.add(key);
        allContacts.add(ShareContactItem(
          conversationId: null,
          userId: f.userId,
          username: u,
          displayName: f.displayName.isNotEmpty ? f.displayName : u,
          avatarUrl: f.avatarUrl,
        ));
      }
    }

    final String query = _searchController.text.trim().toLowerCase();
    final List<ShareContactItem> filteredContacts = query.isEmpty
        ? allContacts
        : allContacts.where((ShareContactItem c) {
            return c.username.toLowerCase().contains(query) ||
                c.displayName.toLowerCase().contains(query);
          }).toList();

    final String shareTargetId = widget.reel?.id ?? widget.postId ?? '';
    final String postAuthorDisplay = widget.reel?.username ?? widget.postAuthor ?? 'Creator';
    final String postDescDisplay = widget.reel != null
        ? (widget.reel!.caption.isNotEmpty ? widget.reel!.caption : 'Reel')
        : (widget.postCaption ?? 'Post');
    String? postThumb = widget.reel?.thumbnailUrl ?? widget.postThumbnail;
    if (postThumb == null || postThumb.isEmpty) {
      if (widget.reel?.videoUrl != null && widget.reel!.videoUrl!.contains('/videos/processed/')) {
        postThumb = widget.reel!.videoUrl!.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg');
      }
    }
    if (postThumb != null) {
      if (postThumb.contains('/videos/processed/') && postThumb.endsWith('/thumbnail.jpg')) {
        postThumb = postThumb.replaceAll('/thumbnail.jpg', '/thumb.0000000.jpg');
      } else if (postThumb.contains('/videos/processed/') && postThumb.endsWith('/master.m3u8')) {
        postThumb = postThumb.replaceAll('/master.m3u8', '/thumb.0000000.jpg');
      }
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: SafeArea(
        top: false,
        child: Column(
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

            // ── Header (Back Arrow + "Send to" + "X selected") ───────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: context.themeIcon,
                      size: AppSizes.iconLg,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.sendToTitle,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _selectedUserIds.isEmpty
                        ? '0 selected'
                        : '${_selectedUserIds.length} selected',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.themeTextMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Scrollable Body ──────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  // ── Attached Post Preview Card ─────────────────────────────
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: (postThumb != null && postThumb.startsWith('http'))
                              ? Image.network(
                                  postThumb,
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Container(
                                    width: 44,
                                    height: 44,
                                    color: context.isDarkMode
                                        ? Colors.white12
                                        : Colors.black12,
                                    child: const Center(
                                      child: Icon(
                                        Icons.play_circle_outline_rounded,
                                        color: Colors.white38,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  width: 44,
                                  height: 44,
                                  color: context.isDarkMode
                                      ? Colors.white12
                                      : Colors.black12,
                                  child: const Center(
                                    child: Icon(
                                      Icons.play_circle_outline_rounded,
                                      color: Colors.white38,
                                      size: 24,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "@$postAuthorDisplay's ${widget.reel != null ? 'reel' : 'post'}",
                                style: TextStyle(
                                  color: context.themeTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                postDescDisplay,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: context.themeTextMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Search Field with Reusable AppTextField Component ──────
                  AppTextField(
                    controller: _searchController,
                    hintText: l10n.sendToSearchHint,
                    prefixIconPath: AppIcons.search,
                    onChanged: (_) => setState(() {}),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── TOP CONNECTIONS Subheader ──────────────────────────────
                  Text(
                    'CONNECTIONS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  if (filteredContacts.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          query.isEmpty
                              ? 'No active conversations yet'
                              : 'No matching people found',
                          style: TextStyle(
                            color: context.themeTextMuted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                  else
                    for (final ShareContactItem contact in filteredContacts) ...<Widget>[
                      _ContactListTile(
                        avatarAsset: (contact.avatarUrl != null &&
                                contact.avatarUrl!.isNotEmpty)
                            ? contact.avatarUrl!
                            : AppImages.user1,
                        handle: contact.username,
                        subText: contact.displayName,
                        isSelected: _selectedUserIds.contains(contact.username),
                        onTap: () => _toggleUser(contact.username),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),

            // ── Bottom Fixed Message Input & Send Button Row ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  // Reusable AppTextField Component for Message Input
                  Expanded(
                    child: AppTextField(
                      controller: _messageController,
                      hintText: l10n.sendToWriteMessageHint,
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () async {
                      if (_selectedUserIds.isEmpty) {
                        AppSnackBar.showError(
                          context,
                          title: 'Select recipient',
                          subtitle: 'Please select at least one person to send to.',
                        );
                        return;
                      }

                      final List<String> targetConvIds = <String>[];
                      final List<String> targetUserIds = <String>[];

                      for (final String u in _selectedUserIds) {
                        final ShareContactItem match = allContacts.firstWhere(
                          (c) => c.username == u,
                          orElse: () => ShareContactItem(username: u, displayName: u),
                        );
                        if (match.conversationId != null && match.conversationId!.isNotEmpty) {
                          targetConvIds.add(match.conversationId!);
                        } else if (match.userId != null && match.userId!.isNotEmpty) {
                          targetUserIds.add(match.userId!);
                        }
                      }

                      final int recipientCount = _selectedUserIds.length;
                      final String contentTypeLabel =
                          widget.reel != null ? 'Reel' : 'Post';
                      final String subtitleText = recipientCount == 1
                          ? 'Shared to @${_selectedUserIds.first}!'
                          : 'Shared with $recipientCount recipient(s)!';

                      AppSnackBar.showSuccess(
                        context,
                        title: '$contentTypeLabel shared',
                        subtitle: subtitleText,
                      );

                      Navigator.pop(context);

                      if (shareTargetId.isNotEmpty) {
                        unawaited(
                          msgProvider.sharePost(
                            sharedPostId: shareTargetId,
                            conversationIds: targetConvIds.isNotEmpty ? targetConvIds : null,
                            recipientUserIds: targetUserIds.isNotEmpty ? targetUserIds : null,
                            message: _messageController.text.trim().isNotEmpty
                                ? _messageController.text.trim()
                                : null,
                            contentType: widget.reel != null ? 'reel' : 'post',
                            reel: widget.reel,
                            postAuthorId: widget.reel?.authorId ?? widget.postAuthorId,
                          ),
                        );
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.secondaryGradientButton,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        l10n.sendToBtn,
                        style: AppTextStyles.buttonText.copyWith(
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactListTile extends StatelessWidget {
  const _ContactListTile({
    required this.avatarAsset,
    required this.handle,
    required this.subText,
    required this.isSelected,
    required this.onTap,
  });

  final String avatarAsset;
  final String handle;
  final String subText;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            ClipOval(
              child: avatarAsset.startsWith('http')
                  ? Image.network(
                      avatarAsset,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.asset(
                          AppImages.defaultAvatar,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                    )
                  : Image.asset(
                      avatarAsset.isNotEmpty ? avatarAsset : AppImages.defaultAvatar,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Image.asset(
                          AppImages.defaultAvatar,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                        ),
                    ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    handle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subText,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: context.themeTextMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.gradientPink : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.gradientPink
                      : (context.isDarkMode ? Colors.white38 : AppColors.lightBorderStrong),
                  width: 1.5,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

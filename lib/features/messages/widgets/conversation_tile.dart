import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/message_models.dart';
import '../provider/messages_provider.dart';

class ConversationTile extends StatelessWidget {
  const ConversationTile({
    required this.conversation,
    required this.onTap,
    super.key,
  });

  final ConversationModel conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final MessagesProvider? msgProvider = context.watch<MessagesProvider?>();
    final bool isOnline = (msgProvider != null)
        ? msgProvider.isUserOnline(conversation.participantId, conversation)
        : conversation.isOnline;
    final bool isTyping = (msgProvider != null)
        ? (conversation.isTyping ||
            msgProvider.isConversationTyping(conversation.id) ||
            (conversation.participantId != null &&
                msgProvider.isConversationTyping(conversation.participantId!)))
        : conversation.isTyping;

    final String titleText = (conversation.displayName != null &&
            conversation.displayName!.trim().isNotEmpty)
        ? conversation.displayName!.trim()
        : (conversation.username.startsWith('@')
            ? conversation.username
            : '@${conversation.username}');

    final String? handleText = (conversation.displayName != null &&
            conversation.displayName!.trim().isNotEmpty &&
            conversation.username.isNotEmpty &&
            conversation.username != 'User')
        ? (conversation.username.startsWith('@')
            ? conversation.username
            : '@${conversation.username}')
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        color: Colors.transparent,
        child: Row(
          children: <Widget>[
            // Avatar with optional Story Gradient Ring and Online Badge
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => UserProfileScreen(
                          userId: conversation.participantId,
                          username: conversation.username.replaceAll('@', ''),
                          name: (conversation.displayName != null &&
                                  conversation.displayName!.isNotEmpty)
                              ? conversation.displayName!
                              : conversation.username
                                  .replaceAll('@', '')
                                  .split('.')
                                  .first,
                          avatarAsset: conversation.avatarAsset,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(conversation.hasStoryRing ? 2.5 : 0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: conversation.hasStoryRing
                          ? AppColors.primaryGradientButton
                          : null,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.themeBackground,
                      ),
                      padding:
                          EdgeInsets.all(conversation.hasStoryRing ? 2.0 : 0),
                      child: ClipOval(
                        child: conversation.avatarAsset.startsWith('http')
                            ? Image.network(
                                conversation.avatarAsset,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.person, size: 44),
                              )
                            : Image.asset(
                                conversation.avatarAsset.isNotEmpty
                                    ? conversation.avatarAsset
                                    : AppImages.user1,
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const Icon(Icons.person, size: 44),
                              ),
                      ),
                    ),
                  ),
                ),
                if (isOnline)
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.themeBackground,
                          width: 2.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: AppSpacing.md),

            // Username + Last Message / Muted status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          titleText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: context.themeTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (handleText != null) ...<Widget>[
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            handleText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.caption.copyWith(
                              color: context.themeTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (conversation.isMuted) ...<Widget>[
                        const SizedBox(width: 6),
                        SvgPicture.asset(
                          AppIcons.mute,
                          width: 14,
                          height: 14,
                          colorFilter: ColorFilter.mode(
                            context.themeIconMuted,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isTyping ? 'Typing...' : conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isTyping
                          ? AppColors.gradientCyan
                          : (conversation.unreadCount > 0
                              ? context.themeTextPrimary
                              : context.themeTextMuted),
                      fontStyle:
                          isTyping ? FontStyle.italic : FontStyle.normal,
                      fontWeight: (isTyping || conversation.unreadCount > 0)
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Time + Unread Badge
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  conversation.timeAgo,
                  style: AppTextStyles.caption.copyWith(
                    color: conversation.unreadCount > 0
                        ? AppColors.gradientPink
                        : context.themeTextMuted,
                    fontWeight: conversation.unreadCount > 0
                        ? FontWeight.w600
                        : FontWeight.w400,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                if (conversation.unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gradientPink,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        conversation.unreadCount > 99
                            ? '99+'
                            : '${conversation.unreadCount}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          height: 1.1,
                        ),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/message_models.dart';

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        color: Colors.transparent,
        child: Row(
          children: <Widget>[
            // Avatar with optional Story Gradient Ring
            Container(
              padding: EdgeInsets.all(conversation.hasStoryRing ? 2.5 : 0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: conversation.hasStoryRing
                    ? AppColors.primaryGradientButton
                    : null,
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.background,
                ),
                padding: EdgeInsets.all(conversation.hasStoryRing ? 2.0 : 0),
                child: ClipOval(
                  child: Image.asset(
                    conversation.avatarAsset,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Username + Last Message / Muted status
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        conversation.username,
                        style: AppTextStyles.titleSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (conversation.isMuted) ...<Widget>[
                        const SizedBox(width: 6),
                        SvgPicture.asset(
                          AppIcons.mute,
                          width: 14,
                          height: 14,
                          colorFilter: const ColorFilter.mode(
                            Colors.white38,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    conversation.lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: conversation.isTyping
                          ? AppColors.gradientCyan
                          : Colors.white54,
                      fontWeight: conversation.unreadCount > 0
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Time + Unread Badge / Checkmark Icon
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  conversation.timeAgo,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                if (conversation.unreadCount > 0)
                  Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.gradientPink,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${conversation.unreadCount}',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  )
                else if (conversation.username == 'rowankeeps')
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.gradientCyan,
                    size: 16,
                  )
                else
                  const SizedBox(height: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

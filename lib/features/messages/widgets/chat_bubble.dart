import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/message_models.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    required this.message,
    super.key,
  });

  final ChatMessageModel message;

  Widget _buildReactionPill(String emoji, int count) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            emoji,
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: <Widget>[
          // ── Gradient Sent Text Bubble (Right) ─────────────────────────────
          if (message.type == MessageType.gradientText)
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradientButton,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                    ),
                    child: Text(
                      message.text ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (message.reactionEmoji != null)
                    _buildReactionPill(
                      message.reactionEmoji!,
                      message.reactionCount ?? 1,
                    ),
                ],
              ),
            ),

          // ── Cyan Outlined Received Bubble (Left) ──────────────────────────
          if (message.type == MessageType.cyanOutlinedText)
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: AppColors.gradientCyan,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      message.text ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (message.reactionEmoji != null)
                    _buildReactionPill(
                      message.reactionEmoji!,
                      message.reactionCount ?? 1,
                    ),
                ],
              ),
            ),

          // ── Standard Text Bubble (Left / Right) ───────────────────────────
          if (message.type == MessageType.text)
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Text(
                      message.text ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (message.reactionEmoji != null)
                    _buildReactionPill(
                      message.reactionEmoji!,
                      message.reactionCount ?? 1,
                    ),
                ],
              ),
            ),

          // ── Image Bubble with Reaction Badge ─────────────────────────────
          if (message.type == MessageType.image && message.imageAsset != null)
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      message.imageAsset!,
                      width: 190,
                      height: 190,
                      fit: BoxFit.cover,
                    ),
                  ),
                  if (message.reactionEmoji != null)
                    _buildReactionPill(
                      message.reactionEmoji!,
                      message.reactionCount ?? 1,
                    ),
                ],
              ),
            ),

          // ── Shared Post Card Bubble (Right) ────────────────────────────────
          if (message.type == MessageType.postShare)
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Container(
                    width: 210,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        children: <Widget>[
                          // Post Thumbnail Preview
                          SizedBox(
                            height: 200,
                            width: double.infinity,
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                Image.asset(
                                  message.postThumbnailAsset ??
                                      AppImages.forYouImg,
                                  fit: BoxFit.cover,
                                ),
                                // View Count Badge
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        message.postViews ?? '12.4K',
                                        style: AppTextStyles.caption.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // User Post Handle Banner
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            color: AppColors.cardBackground,
                            child: Row(
                              children: <Widget>[
                                ClipOval(
                                  child: Image.asset(
                                    AppImages.user1,
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    message.postAuthor ?? "@ashinorbit's post",
                                    style: AppTextStyles.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (message.reactionEmoji != null)
                    _buildReactionPill(
                      message.reactionEmoji!,
                      message.reactionCount ?? 1,
                    ),
                ],
              ),
            ),

          if (isMe && message.type == MessageType.gradientText) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              'Read 9:14',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

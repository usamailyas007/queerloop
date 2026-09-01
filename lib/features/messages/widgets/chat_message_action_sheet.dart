import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_snackbar.dart';

class ChatMessageActionSheet extends StatefulWidget {
  const ChatMessageActionSheet({
    required this.messageText,
    this.isMe = false,
    this.onEmojiReaction,
    this.onReply,
    this.onCopy,
    this.onDeleteForMe,
    this.onUnsend,
    super.key,
  });

  final String messageText;
  final bool isMe;
  final ValueChanged<String>? onEmojiReaction;
  final VoidCallback? onReply;
  final VoidCallback? onCopy;
  final VoidCallback? onDeleteForMe;
  final VoidCallback? onUnsend;

  static Future<void> show(
    BuildContext context, {
    required String messageText,
    bool isMe = false,
    ValueChanged<String>? onEmojiReaction,
    VoidCallback? onReply,
    VoidCallback? onCopy,
    VoidCallback? onDeleteForMe,
    VoidCallback? onUnsend,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChatMessageActionSheet(
        messageText: messageText,
        isMe: isMe,
        onEmojiReaction: onEmojiReaction,
        onReply: onReply,
        onCopy: onCopy,
        onDeleteForMe: onDeleteForMe,
        onUnsend: onUnsend,
      ),
    );
  }

  @override
  State<ChatMessageActionSheet> createState() => _ChatMessageActionSheetState();
}

class _ChatMessageActionSheetState extends State<ChatMessageActionSheet> {
  bool _showAllEmojis = false;

  Widget _buildActionItem(
    BuildContext context, {
    required Widget iconWidget,
    required String label,
    bool isCyanHighlight = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 20,
              height: 20,
              child: Center(child: iconWidget),
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isCyanHighlight
                    ? AppColors.gradientCyan
                    : context.themeTextPrimary,
                fontWeight: isCyanHighlight ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<String> baseEmojis = <String>['❤️', '😂', '🔥', '🙌', '🏳️‍🌈'];
    final List<String> extraEmojis = <String>['👍', '💙', '✨', '🎉', '💯', '🥰'];
    final List<String> displayEmojis =
        _showAllEmojis ? <String>[...baseEmojis, ...extraEmojis] : baseEmojis;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // ── Floating Emoji Reaction Pill ──────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: context.themeCardBackground,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: context.themeBorder,
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ...displayEmojis.map((String e) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          if (widget.onEmojiReaction != null) {
                            widget.onEmojiReaction!(e);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 4,
                          ),
                          child: Text(
                            e,
                            style: const TextStyle(fontSize: 20),
                          ),
                        ),
                      );
                    }),

                    // Add Plus Icon button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showAllEmojis = !_showAllEmojis;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.isDarkMode
                                ? Colors.white.withValues(alpha: 0.12)
                                : context.themeBorder,
                            width: 1.1,
                          ),
                        ),
                        child: Icon(
                          _showAllEmojis
                              ? Icons.remove_rounded
                              : Icons.add_rounded,
                          color: context.themeIconMuted,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Action Sheet Card ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: context.themeCardBackground,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.themeBorder,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  // 1. Reply
                  _buildActionItem(
                    context,
                    iconWidget: Icon(
                      Icons.reply_rounded,
                      color: context.themeTextSecondary,
                      size: 20,
                    ),
                    label: 'Reply',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onReply != null) widget.onReply!();
                    },
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // 2. Copy (using AppIcons.copyLink)
                  _buildActionItem(
                    context,
                    iconWidget: SvgPicture.asset(
                      AppIcons.copyLink,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        context.themeTextSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: 'Copy',
                    onTap: () {
                      Navigator.pop(context);
                      Clipboard.setData(
                        ClipboardData(text: widget.messageText),
                      );
                      AppSnackBar.showSuccess(
                        context,
                        title: 'Copied',
                        subtitle: 'Message copied to clipboard',
                      );
                      if (widget.onCopy != null) widget.onCopy!();
                    },
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // 3. Delete for me (available on both received & sent msgs, using AppIcons.hide)
                  _buildActionItem(
                    context,
                    iconWidget: SvgPicture.asset(
                      AppIcons.hide,
                      width: 18,
                      height: 18,
                      colorFilter: ColorFilter.mode(
                        context.themeTextSecondary,
                        BlendMode.srcIn,
                      ),
                    ),
                    label: 'Delete for me',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onDeleteForMe != null) {
                        widget.onDeleteForMe!();
                      }
                    },
                  ),

                  // 4. Unsend (available ONLY on sent messages, using AppIcons.delete with Cyan Highlight)
                  if (widget.isMe) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    _buildActionItem(
                      context,
                      iconWidget: SvgPicture.asset(
                        AppIcons.delete,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          AppColors.gradientCyan,
                          BlendMode.srcIn,
                        ),
                      ),
                      label: 'Unsend',
                      isCyanHighlight: true,
                      onTap: () {
                        Navigator.pop(context);
                        if (widget.onUnsend != null) widget.onUnsend!();
                      },
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }
}

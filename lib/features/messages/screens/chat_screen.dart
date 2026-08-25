import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/message_models.dart';
import '../provider/messages_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_message_action_sheet.dart';
import '../widgets/chat_options_bottom_sheet.dart';
import '../../profile/screens/user_profile_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({
    required this.conversation,
    super.key,
  });

  final ConversationModel conversation;

  @override
  Widget build(BuildContext context) {
    final MessagesProvider? existingProvider =
        context.read<MessagesProvider?>();

    if (existingProvider != null) {
      return _ChatScreenContent(conversation: conversation);
    }

    return ChangeNotifierProvider<MessagesProvider>(
      create: (_) => MessagesProvider(),
      child: _ChatScreenContent(conversation: conversation),
    );
  }
}

class _ChatScreenContent extends StatefulWidget {
  const _ChatScreenContent({required this.conversation});

  final ConversationModel conversation;

  @override
  State<_ChatScreenContent> createState() => _ChatScreenContentState();
}

class _ChatScreenContentState extends State<_ChatScreenContent> {
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MessagesProvider provider = context.watch<MessagesProvider>();
    final ConversationModel activeConv = provider.conversations.firstWhere(
      (ConversationModel c) => c.id == widget.conversation.id,
      orElse: () => widget.conversation,
    );

    final bool isMuted = provider.isMuted(activeConv.username);
    final bool isRestricted = provider.isRestricted(activeConv.username);
    final bool isBlocked = provider.isBlocked(activeConv.username);
    final String cleanUsername = activeConv.username.startsWith('@')
        ? activeConv.username
        : '@${activeConv.username}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),

                  // Avatar & Username (Tap -> Open UserProfileScreen)
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push<void>(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => UserProfileScreen(
                              username: activeConv.username,
                              name: activeConv.username.split('.').first,
                              avatarAsset: activeConv.avatarAsset,
                            ),
                          ),
                        );
                      },
                      child: Row(
                        children: <Widget>[
                          if (isBlocked)
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_outline_rounded,
                                color: Colors.white54,
                                size: 20,
                              ),
                            )
                          else
                            ClipOval(
                              child: Image.asset(
                                activeConv.avatarAsset,
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Text(
                                      activeConv.username,
                                      style: AppTextStyles.titleMedium.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (isRestricted && !isBlocked) ...<Widget>[
                                      const SizedBox(width: 4),
                                      SvgPicture.asset(
                                        AppIcons.hide,
                                        width: 14,
                                        height: 14,
                                        colorFilter: const ColorFilter.mode(
                                          Colors.white54,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ] else if (isMuted && !isBlocked) ...<Widget>[
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
                                Text(
                                  isBlocked
                                      ? 'Blocked'
                                      : (isRestricted
                                          ? 'Restricted'
                                          : (isMuted
                                              ? 'Muted until 12 Aug'
                                              : 'Active now')),
                                  style: AppTextStyles.caption.copyWith(
                                    color: (isBlocked || isRestricted)
                                        ? AppColors.gradientCyan
                                        : (isMuted
                                            ? Colors.white54
                                            : AppColors.gradientCyan),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Safety Badge SVG Icon
                  if (!isBlocked)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: SvgPicture.asset(
                        AppIcons.safety,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          AppColors.gradientCyan,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),

                  // Options 3-dots Menu -> Opens ChatOptionsBottomSheet
                  GestureDetector(
                    onTap: () {
                      ChatOptionsBottomSheet.show(
                        context,
                        username: activeConv.username,
                      );
                    },
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white54,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(color: Color(0xFF2A2733), height: 1),

            // ── Restricted Banner Card ─────────────────────────────────────────
            if (isRestricted && !isBlocked)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F242A),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.gradientCyan,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SvgPicture.asset(
                        AppIcons.hide,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          AppColors.gradientCyan,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'You restricted this account',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "New messages arrive in your requests tray. They can't see your activity status.",
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white54,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => provider.toggleRestrict(activeConv.username),
                        child: Text(
                          'Undo',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gradientCyan,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Muted Banner Card ──────────────────────────────────────────────
            if (isMuted && !isBlocked && !isRestricted)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F242A),
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.gradientCyan,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      SvgPicture.asset(
                        AppIcons.mute,
                        width: 18,
                        height: 18,
                        colorFilter: const ColorFilter.mode(
                          AppColors.gradientCyan,
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Notifications are off for this chat',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Messages still arrive — you just won't be alerted. Jules isn't told.",
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white54,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => provider.toggleMute(activeConv.username),
                        child: Text(
                          'Unmute',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.gradientCyan,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Messages Feed ListView ────────────────────────────────────────
            Expanded(
              child: Opacity(
                opacity: isBlocked ? 0.35 : 1.0,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  children: <Widget>[
                    const SizedBox(height: AppSpacing.md),

                    // Date Separator Pill Header
                    Center(
                      child: Text(
                        'Today 9:12',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // List of Chat Messages (with long press -> ChatMessageActionSheet)
                    ...activeConv.messages.map(
                      (ChatMessageModel msg) => GestureDetector(
                        onLongPress: isBlocked
                            ? null
                            : () {
                                ChatMessageActionSheet.show(
                                  context,
                                  messageText: msg.text ?? '',
                                  isMe: msg.isMe,
                                  onEmojiReaction: (String emoji) {
                                    provider.addReaction(
                                        activeConv.id, msg.id, emoji);
                                  },
                                  onDeleteForMe: () {
                                    provider.deleteMessage(
                                        activeConv.id, msg.id);
                                  },
                                  onUnsend: () {
                                    provider.deleteMessage(
                                        activeConv.id, msg.id);
                                  },
                                );
                              },
                        child: ChatBubble(message: msg),
                      ),
                    ),

                    // Restricted Info Subtitle Text
                    if (isRestricted && !isBlocked) ...<Widget>[
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Anything Jules sends from now on will appear in Message requests until you unrestrict them.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white38,
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Typing indicator (if active & not blocked/restricted)
                    if (activeConv.isTyping &&
                        !isBlocked &&
                        !isMuted &&
                        !isRestricted) ...<Widget>[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${activeConv.username} is typing...',
                        style: AppTextStyles.caption.copyWith(
                          color: Colors.white38,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.cardBackground,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: SvgPicture.asset(
                            AppIcons.typing,
                            height: 14,
                            colorFilter: const ColorFilter.mode(
                              Colors.white70,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ],
                ),
              ),
            ),

            // ── Bottom Section: Input Bar OR Blocked Footer Notice ───────────
            if (isBlocked)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Color(0xFF2A2733), width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Blocked Icon Circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gradientCyan.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        color: AppColors.gradientCyan,
                        size: 22,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // You blocked @username
                    Text(
                      'You blocked $cleanUsername',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xs),

                    // Description text
                    Text(
                      "You can't message each other. Nothing new arrives here. They were not told, and your old messages stay visible to you only.",
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white54,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Reusable AppOutlineButton for Unblock
                    AppOutlineButton(
                      text: 'Unblock',
                      onPressed: () => provider.toggleBlock(activeConv.username),
                    ),
                  ],
                ),
              )
            else
              // Standard Input Bar
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  children: <Widget>[
                    // Gallery Icon
                    GestureDetector(
                      onTap: () async {
                        try {
                          final ImagePicker picker = ImagePicker();
                          final XFile? file = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          if (file != null) {
                            provider.sendImageMessage(
                              activeConv.id,
                              imageFilePath: file.path,
                            );
                          }
                        } catch (e) {
                          debugPrint('Error picking chat image from gallery: $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.image_outlined,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Camera Icon
                    GestureDetector(
                      onTap: () async {
                        try {
                          final ImagePicker picker = ImagePicker();
                          final XFile? file = await picker.pickImage(
                            source: ImageSource.camera,
                          );
                          if (file != null) {
                            provider.sendImageMessage(
                              activeConv.id,
                              imageFilePath: file.path,
                            );
                          }
                        } catch (e) {
                          debugPrint('Error capturing chat image: $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          color: Colors.white70,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),

                    // Message Input Field
                    Expanded(
                      child: AppTextField(
                        controller: _messageController,
                        hintText: 'Message...',
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),

                    // Send Button
                    GestureDetector(
                      onTap: () {
                        final String text = _messageController.text.trim();
                        if (text.isNotEmpty) {
                          provider.sendMessage(activeConv.id, text);
                          _messageController.clear();
                        }
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          gradient: AppColors.secondaryGradientButton,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 18,
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

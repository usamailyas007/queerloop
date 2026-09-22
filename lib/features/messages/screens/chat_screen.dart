import 'dart:async' show Timer;
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/message_models.dart';
import '../provider/messages_provider.dart';
import '../services/chat_socket_service.dart';
import '../services/conversations_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_message_action_sheet.dart';
import '../widgets/chat_options_bottom_sheet.dart';
import '../../auth/auth_provider.dart';
import '../../profile/screens/user_profile_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({required this.conversation, super.key});

  final ConversationModel conversation;

  @override
  Widget build(BuildContext context) {
    MessagesProvider? existingProvider;
    try {
      existingProvider = context.read<MessagesProvider>();
    } catch (_) {}

    if (existingProvider != null) {
      return _ChatScreenContent(conversation: conversation);
    }

    return ChangeNotifierProvider<MessagesProvider>(
      create: (BuildContext ctx) => MessagesProvider(
        service: ctx.read<ConversationsService>(),
        socketService: ctx.read<ChatSocketService>(),
        currentUserId: ctx.read<AuthProvider>().userId,
        token: ctx.read<ApiClient>().authToken,
      ),
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
  late final ScrollController _scrollController;
  Timer? _typingTimer;
  bool _isTypingSent = false;
  int _lastMessageCount = 0;
  bool _lastWasTyping = false;

  void _scrollToBottom({bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      try {
        final double maxScroll = _scrollController.position.maxScrollExtent;
        if (animated) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(maxScroll);
        }
      } catch (_) {}
    });
  }

  void _handleTypingChange() {
    final String text = _messageController.text;
    if (!mounted) return;
    final MessagesProvider p = context.read<MessagesProvider>();
    final String convId = p.activeChatConvId ?? widget.conversation.id;
    if (convId.isEmpty) return;

    if (text.isEmpty) {
      if (_isTypingSent) {
        _isTypingSent = false;
        _typingTimer?.cancel();
        p.sendTyping(convId, false);
      }
      return;
    }

    if (!_isTypingSent) {
      _isTypingSent = true;
      p.sendTyping(convId, true);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(milliseconds: 1800), () {
      if (_isTypingSent && mounted) {
        _isTypingSent = false;
        p.sendTyping(convId, false);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _messageController.addListener(_handleTypingChange);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final MessagesProvider p = context.read<MessagesProvider>();
        p.loadBlockedUsers();
        String convId = widget.conversation.id;

        // If conversation ID is missing or equal to participantId, start/resolve conversation
        if (convId.isEmpty || convId == widget.conversation.participantId) {
          final String? pId = widget.conversation.participantId;
          if (pId != null && pId.trim().isNotEmpty) {
            try {
              final ConversationModel? started = await p.startConversation(
                pId.trim(),
              );
              if (started != null && started.id.isNotEmpty) {
                convId = started.id;
              }
            } catch (_) {}
          }
        }

        // Set active chat so new socket messages stream live
        p.setActiveChat(convId.isNotEmpty ? convId : widget.conversation.id);

        // If we have an active conversation ID, load messages from backend
        if (convId.isNotEmpty && convId != widget.conversation.participantId) {
          await p.loadMessages(convId);
        }

        if (mounted && convId.isNotEmpty) {
          await p.markAllMessagesAsRead(convId);
        }

        // Scroll directly to the bottom (latest message) on opening chat
        if (mounted) {
          _scrollToBottom(animated: false);
          Future<void>.delayed(const Duration(milliseconds: 120), () {
            if (mounted) _scrollToBottom(animated: false);
          });
        }
      }
    });
  }

  @override
  void deactivate() {
    try {
      final MessagesProvider p = context.read<MessagesProvider>();
      p.markAllMessagesAsRead(widget.conversation.id);
      p.setActiveChat(null);
    } catch (_) {}
    super.deactivate();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    if (_isTypingSent) {
      try {
        final MessagesProvider p = context.read<MessagesProvider>();
        final String convId = p.activeChatConvId ?? widget.conversation.id;
        p.sendTyping(convId, false);
      } catch (_) {}
    }
    _messageController.removeListener(_handleTypingChange);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final MessagesProvider provider = context.watch<MessagesProvider>();
    final ConversationModel activeConv = provider.conversations.firstWhere(
      (ConversationModel c) =>
          c.id == widget.conversation.id ||
          (widget.conversation.participantId != null &&
              widget.conversation.participantId!.isNotEmpty &&
              c.participantId == widget.conversation.participantId),
      orElse: () => widget.conversation,
    );

    final bool isMuted =
        provider.isMuted(activeConv.username) ||
        provider.isMuted(activeConv.id) ||
        (activeConv.participantId != null &&
            provider.isMuted(activeConv.participantId!)) ||
        (activeConv.isMuted &&
            !provider.isExplicitlyUnmuted(activeConv.id) &&
            !provider.isExplicitlyUnmuted(activeConv.username) &&
            (activeConv.participantId == null ||
                !provider.isExplicitlyUnmuted(activeConv.participantId!)));
    final bool isRestricted = provider.isRestricted(activeConv.username) ||
        (activeConv.participantId != null &&
            provider.isRestricted(activeConv.participantId!)) ||
        provider.isRestricted(activeConv.id);
    final bool isBlocked =
        provider.isBlocked(activeConv.username) ||
        (activeConv.participantId != null &&
            provider.isBlocked(activeConv.participantId!)) ||
        provider.isBlocked(activeConv.id);
    final String cleanUsername = activeConv.username.startsWith('@')
        ? activeConv.username
        : '@${activeConv.username}';

    final String titleText =
        (activeConv.displayName != null &&
            activeConv.displayName!.trim().isNotEmpty)
        ? activeConv.displayName!.trim()
        : cleanUsername;

    final String? handleText =
        (activeConv.displayName != null &&
            activeConv.displayName!.trim().isNotEmpty &&
            activeConv.username.isNotEmpty &&
            activeConv.username != 'User')
        ? (activeConv.username.startsWith('@')
              ? activeConv.username
              : '@${activeConv.username}')
        : null;

    return Scaffold(
      backgroundColor: context.themeBackground,
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
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: context.themeIcon,
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
                              userId: activeConv.participantId,
                              username: activeConv.username,
                              name:
                                  (activeConv.displayName != null &&
                                      activeConv.displayName!.isNotEmpty)
                                  ? activeConv.displayName!
                                  : activeConv.username.split('.').first,
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
                                color: context.themeChipBackground,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                color: context.themeIconMuted,
                                size: 20,
                              ),
                            )
                          else
                            Stack(
                              clipBehavior: Clip.none,
                              children: <Widget>[
                                ClipOval(
                                  child:
                                      activeConv.avatarAsset.startsWith('http')
                                      ? Image.network(
                                          activeConv.avatarAsset,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              Image.asset(
                                                AppImages.user1,
                                                width: 36,
                                                height: 36,
                                                fit: BoxFit.cover,
                                              ),
                                        )
                                      : Image.asset(
                                          activeConv.avatarAsset.isNotEmpty
                                              ? activeConv.avatarAsset
                                              : AppImages.user1,
                                          width: 36,
                                          height: 36,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, _, _) =>
                                              Image.asset(
                                                AppImages.user1,
                                                width: 36,
                                                height: 36,
                                                fit: BoxFit.cover,
                                              ),
                                        ),
                                ),
                                if (provider.isUserOnline(
                                  activeConv.participantId,
                                  activeConv,
                                ))
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: context.themeBackground,
                                          width: 1.8,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          const SizedBox(width: AppSpacing.sm),
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
                                        style: AppTextStyles.titleMedium
                                            .copyWith(
                                              color: context.themeTextPrimary,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 15,
                                            ),
                                      ),
                                    ),
                                    if (isRestricted && !isBlocked) ...<Widget>[
                                      const SizedBox(width: 4),
                                      SvgPicture.asset(
                                        AppIcons.hide,
                                        width: 14,
                                        height: 14,
                                        colorFilter: ColorFilter.mode(
                                          context.themeIconMuted,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ] else if (isMuted &&
                                        !isBlocked) ...<Widget>[
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
                                Builder(
                                  builder: (BuildContext _) {
                                    final bool isTypingAllowed =
                                        provider.isTypingIndicatorEnabled(
                                          activeConv.username,
                                        ) &&
                                        provider.isTypingIndicatorEnabled(
                                          activeConv.id,
                                        ) &&
                                        (activeConv.participantId == null ||
                                            provider.isTypingIndicatorEnabled(
                                              activeConv.participantId!,
                                            ));
                                    final bool isOtherTyping =
                                        isTypingAllowed &&
                                        (activeConv.isTyping ||
                                            provider.isConversationTyping(
                                              activeConv.id,
                                            ) ||
                                            (activeConv.participantId != null &&
                                                provider.isConversationTyping(
                                                  activeConv.participantId!,
                                                )) ||
                                            provider.isConversationTyping(
                                              activeConv.username,
                                            ));
                                    final bool isOnline = provider.isUserOnline(
                                      activeConv.participantId,
                                      activeConv,
                                    );
                                    final String? lastActiveStr = provider
                                        .getUserLastActiveText(
                                          activeConv.participantId,
                                          activeConv,
                                        );

                                    String statusText;
                                    Color statusColor;

                                    if (isBlocked) {
                                      statusText = 'Blocked';
                                      statusColor = AppColors.gradientCyan;
                                    } else if (isRestricted) {
                                      statusText = 'Restricted';
                                      statusColor = AppColors.gradientCyan;
                                    } else if (isMuted) {
                                      statusText = 'Muted';
                                      statusColor = context.themeTextMuted;
                                    } else if (isOtherTyping) {
                                      statusText = 'typing...';
                                      statusColor = AppColors.gradientCyan;
                                    } else if (isOnline) {
                                      statusText = 'Active now';
                                      statusColor = const Color(0xFF10B981);
                                    } else if (lastActiveStr != null &&
                                        lastActiveStr.isNotEmpty) {
                                      statusText = lastActiveStr;
                                      statusColor = context.themeTextMuted;
                                    } else {
                                      statusText = handleText ?? '';
                                      statusColor = AppColors.gradientCyan;
                                    }

                                    return Text(
                                      statusText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption.copyWith(
                                        color: statusColor,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Options 3-dots Menu -> Opens ChatOptionsBottomSheet
                  GestureDetector(
                    onTap: () {
                      ChatOptionsBottomSheet.show(
                        context,
                        username: activeConv.username,
                        conversationId: activeConv.id,
                        userId: activeConv.participantId,
                      );
                    },
                    child: Icon(
                      Icons.more_vert_rounded,
                      color: context.themeIconMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            Divider(color: context.themeDivider, height: 1),

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
                    color: context.themeCyanBadgeBackground,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.gradientCyan),
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
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "New messages arrive in your requests tray. They can't see your activity status.",
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.themeTextSecondary,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () => provider.toggleRestrict(
                          activeConv.username,
                          userId: activeConv.participantId,
                        ),
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
                    color: context.themeCyanBadgeBackground,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(color: AppColors.gradientCyan),
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
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "Messages still arrive — you just won't be alerted. Jules isn't told.",
                              style: AppTextStyles.bodySmall.copyWith(
                                color: context.themeTextSecondary,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: () {
                          final String targetId = activeConv.id.isNotEmpty
                              ? activeConv.id
                              : widget.conversation.id;
                          provider.unmuteConversation(targetId);
                        },
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

            // ── Messages List (Scrollable) ───────────────────────────────────
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  children: <Widget>[
                    // Date Separator Pill (TODAY)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.themeChipBackground,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          'TODAY',
                          style: AppTextStyles.caption.copyWith(
                            color: context.themeTextMuted,
                            fontSize: 10,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Render Chat Bubbles & Live Typing Indicator
                    Builder(
                      builder: (BuildContext _) {
                        final List<ChatMessageModel> chatMessages = provider
                            .getMessagesFor(activeConv.id);
                        final List<ChatMessageModel> fallbackMessages =
                            activeConv.id != widget.conversation.id
                            ? provider.getMessagesFor(widget.conversation.id)
                            : const <ChatMessageModel>[];
                        final List<ChatMessageModel> effectiveMessages =
                            chatMessages.isNotEmpty
                            ? chatMessages
                            : (fallbackMessages.isNotEmpty
                                  ? fallbackMessages
                                  : activeConv.messages);

                        final bool isTypingAllowed =
                            provider.isTypingIndicatorEnabled(
                              activeConv.username,
                            ) &&
                            provider.isTypingIndicatorEnabled(activeConv.id) &&
                            (activeConv.participantId == null ||
                                provider.isTypingIndicatorEnabled(
                                  activeConv.participantId!,
                                ));
                        final bool isOtherTyping =
                            isTypingAllowed &&
                            !isBlocked &&
                            !isMuted &&
                            !isRestricted &&
                            (activeConv.isTyping ||
                                provider.isConversationTyping(activeConv.id) ||
                                (activeConv.participantId != null &&
                                    provider.isConversationTyping(
                                      activeConv.participantId!,
                                    )) ||
                                provider.isConversationTyping(
                                  activeConv.username,
                                ));

                        if (effectiveMessages.length != _lastMessageCount ||
                            isOtherTyping != _lastWasTyping) {
                          final bool isInitial = _lastMessageCount == 0;
                          _lastMessageCount = effectiveMessages.length;
                          _lastWasTyping = isOtherTyping;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToBottom(animated: !isInitial);
                          });
                        }

                        return Column(
                          children: <Widget>[
                            for (final ChatMessageModel msg
                                in effectiveMessages)
                              GestureDetector(
                                onLongPress: () {
                                  if (msg.isUnsent) return;
                                  ChatMessageActionSheet.show(
                                    context,
                                    messageText: msg.text ?? '',
                                    isMe: msg.isMe,
                                    onEmojiReaction: (String emoji) {
                                      provider.toggleReaction(
                                        activeConv.id,
                                        msg.id,
                                        emoji,
                                      );
                                    },
                                    onUnsend: () {
                                      provider.unsendMessage(
                                        activeConv.id,
                                        msg.id,
                                      );
                                    },
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: ChatBubble(message: msg),
                                ),
                              ),

                            // ── Live SpinKit Typing Indicator Bubble (Exact incoming message position) ──
                            if (isOtherTyping)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 64,
                                      minHeight: 40,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.lg,
                                      vertical: AppSpacing.md,
                                    ),
                                    decoration: BoxDecoration(
                                      color: context.themeCardBackground,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(
                                          AppRadius.card,
                                        ),
                                        topRight: Radius.circular(
                                          AppRadius.card,
                                        ),
                                        bottomRight: Radius.circular(
                                          AppRadius.card,
                                        ),
                                        bottomLeft: Radius.circular(4),
                                      ),
                                      border: Border.all(
                                        color: context.themeBorder,
                                      ),
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.04,
                                          ),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const SizedBox(
                                      width: 36,
                                      height: 18,
                                      child: Center(
                                        child: SpinKitThreeBounce(
                                          color: AppColors.gradientCyan,
                                          size: 16.0,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ── Bottom Section: Input Bar OR Blocked Footer Notice ───────────
            if (isBlocked)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: context.themeDivider, width: 1),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // Blocked Icon Circle matching Image 1
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? context.themeChipBackground
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gradientCyan.withValues(
                            alpha: context.isDarkMode ? 0.3 : 0.35,
                          ),
                          width: 1.2,
                        ),
                      ),
                      child: const Icon(
                        Icons.block_rounded,
                        color: AppColors.gradientCyan,
                        size: 20,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // You blocked @username
                    Text(
                      'You blocked $cleanUsername',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
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
                        color: context.themeTextSecondary,
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Reusable AppOutlineButton for Unblock
                    AppOutlineButton(
                      text: 'Unblock',
                      onPressed: () async {
                        final String targetId =
                            (activeConv.participantId != null &&
                                activeConv.participantId!.isNotEmpty)
                            ? activeConv.participantId!
                            : activeConv.username;
                        await provider.unblockUser(
                          targetId,
                          username: activeConv.username,
                        );
                      },
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
                          debugPrint(
                            'Error picking chat image from gallery: $e',
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.image_outlined,
                          color: context.themeIconMuted,
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
                        child: Icon(
                          Icons.camera_alt_outlined,
                          color: context.themeIconMuted,
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
                          _typingTimer?.cancel();
                          if (_isTypingSent) {
                            _isTypingSent = false;
                            provider.sendTyping(activeConv.id, false);
                          }
                          provider.sendMessage(activeConv.id, text);
                          _messageController.clear();
                          _scrollToBottom(animated: true);
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

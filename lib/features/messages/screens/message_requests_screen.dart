import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/message_models.dart';
import '../provider/messages_provider.dart';

import 'chat_screen.dart';

class MessageRequestsScreen extends StatefulWidget {
  const MessageRequestsScreen({super.key});

  @override
  State<MessageRequestsScreen> createState() => _MessageRequestsScreenState();
}

class _MessageRequestsScreenState extends State<MessageRequestsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<MessagesProvider>().loadMessageRequests(force: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final MessagesProvider provider = context.watch<MessagesProvider>();
    final bool isLoading = provider.isLoadingRequests;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // ── Top Header Bar (Back button + Title "Message requests") ───────
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
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
                        Icons.chevron_left_rounded,
                        color: context.themeIcon,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Message requests',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.sm),

            // ── Subtitle Info Text ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                "Messages from people who don't follow you or whom you've restricted. Accepting moves them to your main inbox — they won't know you read their message until you accept.",
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.themeTextSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── List of Message Request Cards OR Empty State ─────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.gradientPink,
                onRefresh: () =>
                    context.read<MessagesProvider>().loadMessageRequests(force: true),
                child: isLoading && provider.messageRequests.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.gradientPink,
                        ),
                      )
                    : provider.messageRequests.isEmpty
                        ? LayoutBuilder(
                            builder: (BuildContext ctx,
                                BoxConstraints constraints) {
                              return SingleChildScrollView(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: <Widget>[
                                        Icon(
                                          Icons.mark_email_read_outlined,
                                          size: 56,
                                          color: context.themeIconMuted,
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Text(
                                          'No message requests',
                                          style: AppTextStyles.titleMedium
                                              .copyWith(
                                            color: context.themeTextPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'You have answered all incoming requests.',
                                          style: AppTextStyles.bodySmall
                                              .copyWith(
                                            color: context.themeTextSecondary,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg),
                            itemCount: provider.messageRequests.length,
                            itemBuilder: (BuildContext context, int index) {
                              final MessageRequestModel req =
                                  provider.messageRequests[index];
                              final String displayName = (req.displayName != null &&
                                      req.displayName!.trim().isNotEmpty)
                                  ? req.displayName!.trim()
                                  : (req.username.startsWith('@')
                                      ? req.username
                                      : '@${req.username}');
                              final String? handleText = (req.displayName != null &&
                                      req.displayName!.trim().isNotEmpty &&
                                      req.username.isNotEmpty &&
                                      req.username != 'User')
                                  ? (req.username.startsWith('@')
                                      ? req.username
                                      : '@${req.username}')
                                  : null;
                              final String avatar = (req.avatarUrl != null && req.avatarUrl!.isNotEmpty)
                                  ? req.avatarUrl!
                                  : req.avatarAsset;

                              return Container(
                                margin: const EdgeInsets.only(bottom: AppSpacing.lg),
                                child: Column(
                                  children: <Widget>[
                                    // Request Info Card (Tap opens ChatScreen to view)
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push<void>(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                ChangeNotifierProvider<MessagesProvider>.value(
                                              value: provider,
                                              child: ChatScreen(
                                                conversation: ConversationModel(
                                                  id: req.id,
                                                  participantId: req.participantId,
                                                  username: req.username,
                                                  displayName: req.displayName,
                                                  avatarUrl: req.avatarUrl,
                                                  avatarAsset: avatar,
                                                  lastMessage: req.previewMessage,
                                                  timeAgo: 'Just now',
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(AppSpacing.md),
                                        decoration: BoxDecoration(
                                          color: context.themeCardBackground,
                                          borderRadius:
                                              BorderRadius.circular(AppRadius.card),
                                          border: Border.all(
                                            color: context.themeBorder,
                                          ),
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.push<void>(
                                                  context,
                                                  MaterialPageRoute<void>(
                                                    builder: (_) => UserProfileScreen(
                                                      userId: req.participantId,
                                                      username: req.username
                                                          .replaceAll('@', ''),
                                                      name: displayName,
                                                      avatarAsset: avatar,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: ClipOval(
                                                child: avatar.startsWith('http')
                                                    ? Image.network(
                                                        avatar,
                                                        width: 40,
                                                        height: 40,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, _, _) =>
                                                            Image.asset(
                                                              AppImages.defaultAvatar,
                                                              width: 40,
                                                              height: 40,
                                                              fit: BoxFit.cover,
                                                            ),
                                                      )
                                                    : Image.asset(
                                                        avatar.isNotEmpty
                                                            ? avatar
                                                            : AppImages.defaultAvatar,
                                                        width: 40,
                                                        height: 40,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (_, _, _) =>
                                                            Image.asset(
                                                              AppImages.defaultAvatar,
                                                              width: 40,
                                                              height: 40,
                                                              fit: BoxFit.cover,
                                                            ),
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(width: AppSpacing.md),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Row(
                                                    children: <Widget>[
                                                      Flexible(
                                                        child: Text(
                                                          displayName,
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
                                                          style: AppTextStyles.titleSmall
                                                              .copyWith(
                                                            color: context.themeTextPrimary,
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 14,
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
                                                            style: AppTextStyles.caption
                                                                .copyWith(
                                                              color: context.themeTextMuted,
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ],
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Text(
                                                    req.previewMessage,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: AppTextStyles.bodySmall
                                                        .copyWith(
                                                      color: context.themeTextSecondary,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Icon(
                                              Icons.chevron_right_rounded,
                                              color: context.themeIconMuted,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                      const SizedBox(height: AppSpacing.sm),

                                      // Action Buttons Row (Accept, Delete, Block)
                                      Row(
                                        children: <Widget>[
                                  // Accept (AppGradientButton)
                                  Expanded(
                                    flex: 3,
                                    child: AppGradientButton(
                                      text: 'Accept',
                                      onPressed: () async {
                                        final bool ok = await provider
                                            .acceptRequest(req.id);
                                        if (context.mounted && ok) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Request accepted! Chat moved to your main inbox.',
                                              ),
                                              duration: Duration(seconds: 2),
                                              backgroundColor:
                                                  AppColors.gradientCyan,
                                            ),
                                          );
                                        }
                                      },
                                      height: 38,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),

                                  // Delete (AppOutlineButton)
                                  Expanded(
                                    flex: 3,
                                    child: AppOutlineButton(
                                      text: 'Delete',
                                      onPressed: () async {
                                        final bool ok = await provider
                                            .rejectRequest(req.id);
                                        if (context.mounted && ok) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Message request deleted.',
                                              ),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      },
                                      height: 38,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),

                                  // Block (AppOutlineButton with Cyan Border & Text)
                                  Expanded(
                                    flex: 2,
                                    child: AppOutlineButton(
                                      text: 'Block',
                                      onPressed: () {
                                        provider.toggleBlock(req.username);
                                        provider.rejectRequest(req.id);
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                           SnackBar(
                                             content: Text(
                                               'Blocked $displayName',
                                             ),
                                             duration:
                                                 const Duration(seconds: 2),
                                           ),
                                        );
                                      },
                                      height: 38,
                                      borderColor: AppColors.gradientCyan,
                                      textColor: AppColors.gradientCyan,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

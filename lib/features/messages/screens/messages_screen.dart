import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../models/message_models.dart';
import '../provider/messages_provider.dart';
import '../widgets/conversation_tile.dart';
import '../widgets/delete_chat_modal_dialog.dart';
import 'chat_screen.dart';
import 'discover_people_screen.dart';
import 'message_requests_screen.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MessagesProvider>(
      create: (_) => MessagesProvider(),
      child: Consumer<MessagesProvider>(
        builder:
            (BuildContext context, MessagesProvider provider, Widget? child) {
          final int requestCount = provider.messageRequests.length;
          final bool isEmpty = provider.conversations.isEmpty;
          final ConversationModel? deletedConv = provider.lastDeletedConv;

          return Scaffold(
            backgroundColor: context.themeBackground,
            body: SafeArea(
              child: Column(
                children: <Widget>[
                  // ── Top Bar (Title "Messages" + Circular (+) Gradient Button) ──
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          'Messages',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: context.themeTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 22,
                          ),
                        ),
                        // Circular (+) Gradient Button -> Opens DiscoverPeopleScreen
                        GestureDetector(
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    ChangeNotifierProvider<MessagesProvider>.value(
                                  value: provider,
                                  child: const DiscoverPeopleScreen(),
                                ),
                              ),
                            );
                          },
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradientButton,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Search Bar Input Field ─────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: AppTextField(
                      controller: _searchController,
                      hintText: 'Search messages',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: context.themeIconMuted,
                        size: 20,
                      ),
                      onChanged: provider.setSearchQuery,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // ── Deleted Toast Banner Card (Image 1) ───────────────────
                  if (deletedConv != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: context.themeCyanBadgeBackground,
                          borderRadius: BorderRadius.circular(AppRadius.card),
                          border: Border.all(
                            color: AppColors.gradientCyan,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            const Icon(
                              Icons.check_rounded,
                              color: AppColors.gradientCyan,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                'Chat with ${deletedConv.username.startsWith('@') ? deletedConv.username : '@${deletedConv.username}'} deleted',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            GestureDetector(
                              onTap: () => provider.undoDeleteConversation(),
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

                  const SizedBox(height: AppSpacing.sm),

                  // ── Body: Conversations List OR Empty State (Image 1) ─────
                  if (isEmpty)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          // Dark Teal Rounded Icon Container
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: context.themeCyanBadgeBackground,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: SvgPicture.asset(
                                AppIcons.msg,
                                width: 28,
                                height: 28,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.gradientCyan,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Start a conversation 💬
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Text(
                                'Start a conversation',
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: context.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                '💬',
                                style: TextStyle(fontSize: 18),
                              ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.sm),

                          // Subtitle text
                          Text(
                            'Connect with people from the community\nand start meaningful conversations.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.themeTextSecondary,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),

                          // Discover People Button -> Opens DiscoverPeopleScreen
                          AppGradientButton(
                            text: 'Discover People',
                            width: 180,
                            height: 42,
                            onPressed: () {
                              Navigator.push<void>(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ChangeNotifierProvider<MessagesProvider>.value(
                                    value: provider,
                                    child: const DiscoverPeopleScreen(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg),
                        children: <Widget>[
                          // ── Message Requests Banner Card ────────────────────
                          if (requestCount > 0)
                            GestureDetector(
                              onTap: () {
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) =>
                                        ChangeNotifierProvider<MessagesProvider>.value(
                                      value: provider,
                                      child: const MessageRequestsScreen(),
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.lg,
                                  vertical: AppSpacing.md,
                                ),
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
                                    // Circle with cyan envelope icon
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: context.themeChipBackground,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.mail_outline_rounded,
                                        color: AppColors.gradientCyan,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.md),

                                    // Text: Message requests / 3 people you don't follow
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            'Message requests',
                                            style: AppTextStyles.titleMedium
                                                .copyWith(
                                              color: AppColors.gradientCyan,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "$requestCount people you don't follow",
                                            style: AppTextStyles.bodySmall
                                                .copyWith(
                                              color: context.themeTextMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Cyan Circle Badge (Count)
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: const BoxDecoration(
                                        color: AppColors.gradientCyan,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$requestCount',
                                          style: AppTextStyles.caption.copyWith(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: AppSpacing.md),

                          // ── Conversations List with Dismissible Swipe Action (Image 2) ──
                          ...provider.conversations.map(
                            (ConversationModel conv) => Dismissible(
                              key: ValueKey<String>(conv.id),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) async {
                                bool confirmDelete = false;
                                await DeleteChatModalDialog.show(
                                  context,
                                  username: conv.username,
                                  onConfirmDelete: () {
                                    confirmDelete = true;
                                  },
                                );
                                if (confirmDelete) {
                                  provider.deleteConversation(conv.id);
                                }
                                return false; // Prevent automatic raw dismissal, managed by provider
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(
                                    right: AppSpacing.md),
                                color: Colors.transparent,
                                child: Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: context.themeCyanBadgeBackground,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.gradientCyan
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  child: Center(
                                    child: SvgPicture.asset(
                                      AppIcons.delete,
                                      width: 20,
                                      height: 20,
                                      colorFilter: const ColorFilter.mode(
                                        AppColors.gradientCyan,
                                        BlendMode.srcIn,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              child: ConversationTile(
                                conversation: conv,
                                onTap: () {
                                  Navigator.push<void>(
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (_) =>
                                          ChangeNotifierProvider<MessagesProvider>.value(
                                        value: provider,
                                        child: ChatScreen(conversation: conv),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.xl),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

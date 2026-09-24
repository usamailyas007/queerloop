import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../home/provider/home_feed_provider.dart';
import '../../messages/models/message_models.dart';
import '../../messages/provider/messages_provider.dart';
import '../../messages/screens/chat_screen.dart';
import '../../notifications/models/notification_item_model.dart';
import '../../notifications/provider/notifications_provider.dart';
import '../provider/profile_provider.dart';
import 'followers_following_screen.dart';
import 'user_profile_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotificationsProvider>().loadNotifications(refresh: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final NotificationsProvider provider = context.watch<NotificationsProvider>();
    final List<NotificationItemModel> items = provider.filteredNotifications;

    return Scaffold(
      backgroundColor: context.themeBackground,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // ── Top Header Bar (Back button + "Notifications" + "Mark all read") ──
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: <Widget>[
                  // Back button chevron
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
                  Row(
                    children: <Widget>[
                      Text(
                        'Notifications',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: context.themeTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      if (provider.unreadCount > 0) ...<Widget>[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradientButton,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${provider.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () async {
                      if (provider.unreadCount == 0 && items.every((NotificationItemModel n) => n.isRead)) {
                        AppSnackBar.show(
                          context,
                          title: 'Notifications',
                          subtitle: 'All notifications are already marked as read.',
                        );
                        return;
                      }
                      await provider.markAllAsRead();
                      if (context.mounted) {
                        AppSnackBar.showSuccess(
                          context,
                          title: 'Notifications',
                          subtitle: 'All notifications marked as read.',
                        );
                      }
                    },
                    child: Text(
                      'Mark all read',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: provider.unreadCount > 0
                            ? AppColors.gradientCyan
                            : context.themeTextMuted,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Horizontal Scrollable Filter Pills ───────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: List<Widget>.generate(NotificationsProvider.filters.length, (int index) {
                  final bool isSelected = provider.selectedFilterIndex == index;

                  return GestureDetector(
                    onTap: () => provider.setFilterIndex(index),
                    child: Container(
                      margin: const EdgeInsets.only(right: AppSpacing.sm),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppColors.primaryGradientButton
                            : null,
                        color: isSelected ? null : context.themeCardBackground,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: isSelected
                            ? null
                            : Border.all(
                                color: context.themeBorder,
                              ),
                      ),
                      child: Text(
                        NotificationsProvider.filters[index],
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : context.themeTextSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Main Notifications Feed ──────────────────────────────────────
            Expanded(
              child: RefreshIndicator(
                color: AppColors.gradientCyan,
                onRefresh: () => provider.loadNotifications(refresh: true),
                child: provider.isLoading && items.isEmpty
                    ? const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.gradientCyan,
                          ),
                        ),
                      )
                    : items.isEmpty
                        ? _buildEmptyState(context, provider)
                        : _buildNotificationsList(context, provider, items),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, NotificationsProvider provider) {
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: context.themeCyanBadgeBackground,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.gradientCyan.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Center(
                        child: SvgPicture.asset(
                          AppIcons.bell,
                          width: 32,
                          height: 32,
                          colorFilter: const ColorFilter.mode(
                            AppColors.gradientCyan,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No notifications yet',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      provider.selectedFilterIndex == 0
                          ? "You're all caught up! Check back later."
                          : 'No ${NotificationsProvider.filters[provider.selectedFilterIndex].toLowerCase()} notifications found.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.themeTextMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationsList(
    BuildContext context,
    NotificationsProvider provider,
    List<NotificationItemModel> items,
  ) {
    // Separate safety banner from the rest of the notifications if present
    final NotificationItemModel? safetyItem = items.cast<NotificationItemModel?>().firstWhere(
          (NotificationItemModel? n) => n != null && n.isSafety,
          orElse: () => null,
        );

    final List<NotificationItemModel> feedItems =
        items.where((NotificationItemModel n) => !n.isSafety).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      physics: const AlwaysScrollableScrollPhysics(),
      children: <Widget>[
        // Safety Banner Card
        if (safetyItem != null) ...<Widget>[
          GestureDetector(
            onTap: () => provider.markAsRead(safetyItem.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.themeCyanBadgeBackground,
                borderRadius: BorderRadius.circular(AppRadius.card),
                border: Border.all(
                  color: AppColors.gradientCyan,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
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
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          (safetyItem.title != null && safetyItem.title!.isNotEmpty)
                              ? safetyItem.title!
                              : 'Safety Update',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.themeTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                        if (safetyItem.body != null && safetyItem.body!.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 2),
                          Text(
                            safetyItem.body!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.themeTextMuted,
                              fontSize: 11,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!safetyItem.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(left: 6, top: 4),
                      decoration: const BoxDecoration(
                        color: AppColors.gradientCyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],

        // Feed items
        ...feedItems.asMap().entries.map((MapEntry<int, NotificationItemModel> entry) {
          final int index = entry.key;
          final NotificationItemModel item = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _buildNotificationTile(context, provider, item, index),
          );
        }),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationsProvider provider,
    NotificationItemModel item,
    int index,
  ) {
    final ProfileProvider profile = context.watch<ProfileProvider>();
    final String followStatus = provider.getFollowStatus(
      item.id,
      actorId: item.actorId,
      username: item.displayName,
      fallbackStatus: item.followStatus,
    );

    return InkWell(
      onTap: () {
        if (!item.isRead) {
          provider.markAsRead(item.id);
        }
        _onNotificationTileTapped(context, item, followStatus);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: !item.isRead
              ? (context.isDarkMode
                  ? Colors.white.withValues(alpha: 0.03)
                  : AppColors.gradientCyan.withValues(alpha: 0.04))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 1. Actor Avatar
                GestureDetector(
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => UserProfileScreen(
                          userId: item.actorId,
                          username: item.displayName,
                          name: item.displayName,
                          avatarAsset: item.safeAvatar,
                        ),
                      ),
                    );
                  },
                  child: ClipOval(
                    child: _buildAvatar(item.safeAvatar),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // 2. Notification text & timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      RichText(
                        text: TextSpan(
                          style: AppTextStyles.bodySmall.copyWith(
                            color: context.themeTextSecondary,
                            fontSize: 13,
                            height: 1.3,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: '${item.displayUsername} ',
                              style: TextStyle(
                                color: context.themeTextPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(
                              text: (item.body != null && item.body!.isNotEmpty)
                                  ? '${item.body!}\n'
                                  : (item.isLike
                                      ? 'liked your post\n'
                                      : (item.isComment
                                          ? 'commented on your post\n'
                                          : (item.isFollowRequest
                                              ? 'requested to follow you\n'
                                              : (item.isFollow
                                                  ? 'started following you\n'
                                                  : 'interacted with your profile\n')))),
                            ),
                            TextSpan(
                              text: item.timeAgo,
                              style: TextStyle(
                                color: context.themeTextMuted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Follow Request Action Buttons
                      if (item.isFollowRequest) ...<Widget>[
                        const SizedBox(height: 8),
                        if (followStatus == 'accepted')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.themeCyanBadgeBackground,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: AppColors.gradientCyan,
                              ),
                            ),
                            child: const Text(
                              'Accepted',
                              style: TextStyle(
                                color: AppColors.gradientCyan,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else if (followStatus == 'declined')
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.themeCardBackground,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border: Border.all(
                                color: context.themeBorder,
                              ),
                            ),
                            child: Text(
                              'Declined',
                              style: TextStyle(
                                color: context.themeTextMuted,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          Row(
                            children: <Widget>[
                              AppGradientButton(
                                text: 'Accept',
                                height: 32,
                                width: 76,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                onPressed: () async {
                                  final bool ok = await provider.acceptFollowRequest(
                                    notificationId: item.id,
                                    userId: item.actorId ?? item.displayName,
                                    username: item.displayName,
                                    followRequestId: item.followRequestId,
                                  );
                                  if (context.mounted) {
                                    if (ok) {
                                      AppSnackBar.showSuccess(
                                        context,
                                        title: 'Request accepted',
                                        subtitle:
                                            '${item.displayUsername} is now following you',
                                      );
                                    } else {
                                      AppSnackBar.showError(
                                        context,
                                        title: 'Failed',
                                        subtitle: 'Could not accept follow request',
                                      );
                                    }
                                  }
                                },
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              AppOutlineButton(
                                text: 'Decline',
                                height: 32,
                                width: 76,
                                onPressed: () async {
                                  final bool ok = await provider.declineFollowRequest(
                                    notificationId: item.id,
                                    userId: item.actorId ?? item.displayName,
                                    username: item.displayName,
                                    followRequestId: item.followRequestId,
                                  );
                                  if (context.mounted) {
                                    if (ok) {
                                      AppSnackBar.show(
                                        context,
                                        title: 'Request declined',
                                        subtitle:
                                            'Follow request from ${item.displayUsername} declined',
                                      );
                                    } else {
                                      AppSnackBar.showError(
                                        context,
                                        title: 'Failed',
                                        subtitle: 'Could not decline follow request',
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.sm),

                // 3. Right Action or Media Thumbnail
                if (item.postThumbnail != null && item.postThumbnail!.isNotEmpty) ...<Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildPostThumbnail(item.postThumbnail!),
                  ),
                ] else if (item.isFollow && !item.isFollowRequest) ...<Widget>[
                  _buildFollowBackButton(context, profile, item),
                ],

                // Unread dot indicator
                if (!item.isRead) ...<Widget>[
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    margin: const EdgeInsets.only(top: 6),
                    decoration: const BoxDecoration(
                      color: AppColors.gradientCyan,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String avatar) {
    if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
      return Image.network(
        avatar,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          AppImages.defaultAvatar,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
        ),
      );
    }
    final String cleanAsset = avatar.startsWith('assets/') ? avatar : AppImages.defaultAvatar;
    return Image.asset(
      cleanAsset,
      width: 40,
      height: 40,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(
        AppImages.defaultAvatar,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildPostThumbnail(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 40,
          height: 40,
          color: Colors.white12,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white38,
              size: 20,
            ),
          ),
        ),
      );
    }
    if (url.startsWith('assets/')) {
      return Image.asset(
        url,
        width: 40,
        height: 40,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          width: 40,
          height: 40,
          color: Colors.white12,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white38,
              size: 20,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 40,
      height: 40,
      color: Colors.white12,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.white38,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildFollowBackButton(
    BuildContext context,
    ProfileProvider profile,
    NotificationItemModel item,
  ) {
    final String cleanUsername = item.displayName.replaceAll('@', '');
    final bool isFollowing = profile.isFollowingUser(
      userId: item.actorId,
      username: cleanUsername,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 88,
        maxWidth: 104,
      ),
      child: isFollowing
          ? AppOutlineButton(
              text: 'Following',
              height: 30,
              fontSize: 11,
              onPressed: () async {
                if (item.actorId != null && item.actorId!.isNotEmpty) {
                  await profile.unfollowUser(
                    item.actorId!,
                    username: cleanUsername,
                  );
                }
              },
            )
          : AppGradientButton(
              text: 'Follow back',
              height: 30,
              width: 96,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onPressed: () async {
                if (item.actorId != null && item.actorId!.isNotEmpty) {
                  await profile.followUser(
                    item.actorId!,
                    username: cleanUsername,
                  );
                }
              },
            ),
    );
  }

  void _onNotificationTileTapped(
    BuildContext context,
    NotificationItemModel item,
    String followStatus,
  ) {
    // 1. Chat / Message Notification -> Navigate to conversation
    if (item.isMessage) {
      _openChat(context, item);
      return;
    }

    // 2. Follow / Follow Request Notification
    // If request was accepted: go straight to user profile. If not accepted: go to Requests page.
    final bool isFollowRelated = item.isFollow ||
        item.isFollowRequest ||
        item.type.toUpperCase().contains('FOLLOW');

    if (isFollowRelated) {
      final bool isAccepted = followStatus == 'accepted' ||
          followStatus == 'following' ||
          item.followStatus == 'accepted' ||
          item.type.toUpperCase().contains('ACCEPT') ||
          item.type.toUpperCase().contains('APPROVED') ||
          (item.isFollow && !item.isFollowRequest);

      if (isAccepted && item.actorId != null && item.actorId!.isNotEmpty) {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => UserProfileScreen(
              userId: item.actorId,
              username: item.displayName,
              name: item.displayName,
              avatarAsset: item.safeAvatar,
            ),
          ),
        );
      } else {
        // Not accepted yet -> go to Requests tab (index 2)
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (_) => const FollowersFollowingScreen(
              initialTabIndex: 2,
            ),
          ),
        );
      }
      return;
    }

    // 3. Fallback: If actor is known, view profile
    if (item.actorId != null && item.actorId!.isNotEmpty) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => UserProfileScreen(
            userId: item.actorId,
            username: item.displayName,
            name: item.displayName,
            avatarAsset: item.safeAvatar,
          ),
        ),
      );
    }
  }

  void _openChat(BuildContext context, NotificationItemModel item) {
    final String convId = (item.conversationId ??
            item.extraData?['conversationId'] ??
            item.extraData?['conversation_id'] ??
            item.extraData?['convId'] ??
            '')
        .toString()
        .trim();

    final String senderId = (item.actorId ??
            item.extraData?['senderId'] ??
            item.extraData?['sender_id'] ??
            item.extraData?['userId'] ??
            '')
        .toString()
        .trim();

    final String username = item.displayUsername.replaceAll('@', '');
    final String displayName = item.displayName;
    final String avatarUrl = item.safeAvatar;

    try {
      final MessagesProvider messagesProvider =
          Provider.of<MessagesProvider>(context, listen: false);
      ConversationModel? found;

      if (convId.isNotEmpty) {
        found = messagesProvider.conversations.firstWhere(
          (ConversationModel c) => c.id == convId || c.participantId == convId,
          orElse: () => const ConversationModel(
            id: '',
            username: '',
            avatarAsset: '',
            lastMessage: '',
            timeAgo: '',
          ),
        );
        if (found.id.isEmpty) found = null;
      }
      if (found == null && senderId.isNotEmpty) {
        found = messagesProvider.conversations.firstWhere(
          (ConversationModel c) =>
              c.participantId == senderId ||
              c.id == senderId ||
              c.username.replaceAll('@', '') == username,
          orElse: () => const ConversationModel(
            id: '',
            username: '',
            avatarAsset: '',
            lastMessage: '',
            timeAgo: '',
          ),
        );
        if (found.id.isEmpty) found = null;
      }

      final ConversationModel conv = found ??
          ConversationModel(
            id: convId.isNotEmpty ? convId : senderId,
            participantId: senderId.isNotEmpty ? senderId : null,
            username: username.isNotEmpty ? username : 'user',
            displayName: displayName.isNotEmpty ? displayName : null,
            avatarUrl: avatarUrl.isNotEmpty ? avatarUrl : null,
            avatarAsset: '',
            lastMessage: '',
            timeAgo: '',
          );

      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => ChatScreen(conversation: conv),
        ),
      );
    } catch (e) {
      debugPrint('⚠️ [NotificationsScreen] Error navigating to chat: $e');
      try {
        Provider.of<HomeFeedProvider>(context, listen: false).setBottomNavIndex(3);
        Navigator.pop(context);
      } catch (_) {}
    }
  }
}

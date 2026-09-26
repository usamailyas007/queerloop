import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/config/app_config.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../create_post/models/create_post_models.dart';
import '../../create_post/services/post_content_service.dart';
import '../../home/models/reel_item_model.dart';
import '../../home/screens/reels_feed_view.dart';
import '../../home/screens/single_post_view_screen.dart';
import '../models/message_models.dart';
import '../provider/messages_provider.dart';
import '../services/shared_post_cache.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({required this.message, super.key});

  final ChatMessageModel message;

  Widget _buildReactionPill(BuildContext context, String emoji, int count) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: AppTextStyles.caption.copyWith(
              color: context.themeTextPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactions(BuildContext context) {
    if (message.reactions.isNotEmpty) {
      final Map<String, int> counts = <String, int>{};
      for (final MessageReactionModel r in message.reactions) {
        if (r.emoji.isNotEmpty) {
          counts[r.emoji] = (counts[r.emoji] ?? 0) + 1;
        }
      }
      if (counts.isNotEmpty) {
        return Wrap(
          spacing: 4,
          runSpacing: 4,
          children: counts.entries.map((MapEntry<String, int> entry) {
            return _buildReactionPill(context, entry.key, entry.value);
          }).toList(),
        );
      }
    }
    if (message.reactionEmoji != null && message.reactionEmoji!.isNotEmpty) {
      return _buildReactionPill(
        context,
        message.reactionEmoji!,
        message.reactionCount ?? 1,
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildSharedPostThumbnail(BuildContext context) {
    final SharedPostData? cached = SharedPostCache.get(message.sharedPostId);
    String? thumb = (cached != null &&
            cached.thumbnailUrl != null &&
            cached.thumbnailUrl!.isNotEmpty)
        ? cached.thumbnailUrl
        : ((message.postThumbnailAsset != null &&
                message.postThumbnailAsset!.trim().isNotEmpty)
            ? message.postThumbnailAsset!.trim()
            : message.mediaUrl?.trim());

    if (thumb != null) {
      if (thumb.contains('/videos/processed/') && thumb.endsWith('/thumbnail.jpg')) {
        thumb = thumb.replaceAll('/thumbnail.jpg', '/thumb.0000000.jpg');
      } else if (thumb.contains('/videos/processed/') && thumb.endsWith('/master.m3u8')) {
        thumb = thumb.replaceAll('/master.m3u8', '/thumb.0000000.jpg');
      } else if (thumb.contains('/images/original/') && message.postType == 'reel') {
        final RegExp reg = RegExp(r'/([0-9a-fA-F-]{36})\.jpg$');
        final Match? m = reg.firstMatch(thumb);
        if (m != null) {
          final String mediaId = m.group(1)!;
          thumb = '${AppConfig.cdnUrl}/videos/processed/$mediaId/thumb.0000000.jpg';
        }
      }
    }

    if (thumb != null && thumb.startsWith('http')) {
      return Image.network(
        thumb,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: context.themeCardBackground,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gradientCyan,
                ),
              ),
            ),
          );
        },
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFF1E1B26),
          child: Center(
            child: Icon(
              message.postType == 'reel'
                  ? Icons.play_circle_outline_rounded
                  : Icons.image_rounded,
              color: Colors.white38,
              size: 36,
            ),
          ),
        ),
      );
    }
    if (thumb != null && thumb.startsWith('assets/')) {
      return Image.asset(
        thumb,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Container(
          color: const Color(0xFF1E1B26),
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: Colors.white24,
              size: 28,
            ),
          ),
        ),
      );
    }

    // If thumbnail or views not resolved yet and not in cache, trigger background resolution
    if (message.sharedPostId != null && message.sharedPostId!.isNotEmpty) {
      final bool needsThumb = cached == null || cached.thumbnailUrl == null;
      final bool needsViews = message.postType == 'reel' &&
          (message.postViews == null || message.postViews == '0' || cached == null || cached.views == 0);
      if (needsThumb || needsViews) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          try {
            context.read<MessagesProvider>().resolveSharedPost(
              message.sharedPostId!,
            );
          } catch (_) {}
        });
      }
    }

    return Container(
      color: const Color(0xFF1E1B26),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              message.postType == 'reel'
                  ? Icons.play_circle_outline_rounded
                  : Icons.image_rounded,
              color: AppColors.gradientCyan.withValues(alpha: 0.8),
              size: 38,
            ),
            const SizedBox(height: 6),
            Text(
              message.postType == 'reel'
                  ? 'Loading reel...'
                  : 'Loading post...',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white60,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSharedPostOrReel(BuildContext context) async {
    final String? postId = message.sharedPostId;
    if (postId == null || postId.trim().isEmpty) return;

    if (message.postType == 'reel') {
      final SharedPostData? cached = SharedPostCache.get(postId);
      String? resolvedVideo = (cached?.videoUrl != null && cached!.videoUrl!.isNotEmpty)
          ? cached.videoUrl
          : ((message.mediaUrl != null &&
                  (message.mediaUrl!.contains('/videos/') ||
                      message.mediaUrl!.endsWith('.m3u8') ||
                      message.mediaUrl!.endsWith('.mp4')))
              ? message.mediaUrl
              : null);
      String? resolvedThumb = cached?.thumbnailUrl ?? message.postThumbnailAsset;
      String authorName = cached?.author ?? message.postAuthor ?? '@creator';
      String authorAvatar = cached?.authorAvatarUrl ??
          ((message.postAuthorAvatarUrl != null && message.postAuthorAvatarUrl!.isNotEmpty)
              ? message.postAuthorAvatarUrl!
              : AppImages.user1);
      String caption = cached?.caption ?? message.postCaption ?? '';
      int likes = cached?.likes ?? message.postLikes ?? 0;
      int comments = cached?.comments ?? message.postComments ?? 0;
      String? authorId = (message.postAuthorId != null && message.postAuthorId!.isNotEmpty)
          ? message.postAuthorId
          : (cached?.authorId != null && cached!.authorId!.isNotEmpty
              ? cached.authorId
              : null);

      // If videoUrl is not resolved yet, fetch the post from backend
      if (resolvedVideo == null || resolvedVideo.isEmpty) {
        try {
          final PostContentService postService =
              PostContentService(context.read<ApiClient>());
          final PostResponseModel raw = await postService.getPost(postId);
          authorId ??= raw.authorId;
          if (raw.authorName != null && raw.authorName!.isNotEmpty) {
            authorName = raw.authorName!.startsWith('@') ? raw.authorName! : '@${raw.authorName!}';
          }
          if (raw.authorAvatar != null && raw.authorAvatar!.isNotEmpty) {
            authorAvatar = raw.authorAvatar!;
          }
          if (raw.caption.isNotEmpty) caption = raw.caption;
          if (raw.likesCount > 0) likes = raw.likesCount;
          if (raw.commentsCount > 0) comments = raw.commentsCount;

          if (raw.mediaRefs.isNotEmpty) {
            final String firstRef = raw.mediaRefs.first.trim();
            if (firstRef.startsWith('http://') || firstRef.startsWith('https://')) {
              resolvedVideo = firstRef;
              if (raw.thumbnailUrl != null && raw.thumbnailUrl!.isNotEmpty) {
                resolvedThumb ??= raw.thumbnailUrl;
              } else if (firstRef.contains('/videos/processed/')) {
                resolvedThumb ??= firstRef.replaceAll(RegExp(r'/master\.m3u8.*$'), '/thumb.0000000.jpg');
              }
            } else {
              final String cleanRef = firstRef
                  .replaceAll(RegExp(r'^/+'), '')
                  .replaceAll(RegExp(r'^media/'), '');
              resolvedVideo = '${AppConfig.cdnUrl}/videos/processed/$cleanRef/master.m3u8';
              resolvedThumb ??= raw.thumbnailUrl ?? '${AppConfig.cdnUrl}/videos/processed/$cleanRef/thumb.0000000.jpg';
            }
          }
        } catch (e) {
          debugPrint('⚠️ [ChatBubble] Error fetching shared reel $postId: $e');
        }
      }

      if (!context.mounted) return;

      final ReelItemModel reel = ReelItemModel(
        id: postId,
        authorId: authorId,
        username: authorName,
        pronounsTime: message.timestamp.isNotEmpty
            ? message.timestamp
            : 'just now',
        avatarAsset: authorAvatar,
        videoAsset: '',
        videoUrl: resolvedVideo,
        thumbnailUrl: resolvedThumb,
        caption: caption,
        likesCount: likes,
        commentsCount: comments,
      );

      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext routeContext) => Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: <Widget>[
                ReelsFeedView(
                  initialPage: 0,
                  customReels: <ReelItemModel>[reel],
                  hasBottomBar: false,
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => Navigator.of(routeContext).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Icon(
                          Icons.chevron_left_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) =>
              SinglePostViewScreen(postId: postId, chatMessage: message),
        ),
      );
    }
  }

  Widget _buildPostAuthorAvatar() {
    final String? av = message.postAuthorAvatarUrl;
    if (av != null && av.trim().startsWith('http')) {
      return Image.network(
        av.trim(),
        width: 22,
        height: 22,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          AppImages.user1,
          width: 22,
          height: 22,
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      AppImages.user1,
      width: 22,
      height: 22,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: <Widget>[
          // ── Unsent Message Bubble (WhatsApp style) ─────────────────────────
          if (message.isUnsent)
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm + 2,
                ),
                decoration: BoxDecoration(
                  color: context.themeCardBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: context.themeBorder.withValues(alpha: 0.7),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(
                      Icons.block_rounded,
                      size: 15,
                      color: context.themeTextMuted,
                    ),
                    const SizedBox(width: AppSpacing.xs + 2),
                    Flexible(
                      child: Text(
                        message.text ??
                            (isMe
                                ? 'You unsent this message'
                                : 'This message was unsent'),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: context.themeTextMuted,
                          fontStyle: FontStyle.italic,
                          fontSize: 12.5,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── Gradient Sent Text Bubble (Right) ─────────────────────────────
          if (!message.isUnsent && message.type == MessageType.gradientText)
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
                  if (message.reactionEmoji != null || message.reactions.isNotEmpty)
                    _buildReactions(context),
                ],
              ),
            ),

          // ── Cyan Outlined Received Bubble (Left) ──────────────────────────
          if (!message.isUnsent && message.type == MessageType.cyanOutlinedText)
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
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: AppColors.gradientCyan,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      message.text ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (message.reactionEmoji != null || message.reactions.isNotEmpty)
                    _buildReactions(context),
                ],
              ),
            ),

          // ── Standard Text Bubble (Left / Right) ───────────────────────────
          if (!message.isUnsent && message.type == MessageType.text)
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
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
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(color: context.themeBorder),
                    ),
                    child: Text(
                      message.text ?? '',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                  if (message.reactionEmoji != null || message.reactions.isNotEmpty)
                    _buildReactions(context),
                ],
              ),
            ),

          // ── Image Bubble with Reaction Badge ─────────────────────────────
          if (!message.isUnsent &&
              message.type == MessageType.image &&
              (message.imageFilePath != null ||
                  message.imageAsset != null ||
                  message.mediaUrl != null))
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  Builder(
                    builder: (BuildContext context) {
                      final bool hasLocalFile = message.imageFilePath != null &&
                          message.imageFilePath!.isNotEmpty &&
                          File(message.imageFilePath!).existsSync();
                      final String? resolvedUrl = (message.mediaUrl != null &&
                              message.mediaUrl!.isNotEmpty)
                          ? (message.mediaUrl!.startsWith('http')
                              ? message.mediaUrl!
                              : '${AppConfig.baseUrl.replaceAll(RegExp(r"/+$"), "")}/media/${message.mediaUrl!.replaceAll(RegExp(r"^/media/"), "").replaceAll(RegExp(r"^/+"), "")}')
                          : ((message.imageAsset != null &&
                                  message.imageAsset!.startsWith('http'))
                              ? message.imageAsset!
                              : null);

                      return GestureDetector(
                        onTap: () {
                          showDialog<void>(
                            context: context,
                            builder: (BuildContext ctx) {
                              return Dialog(
                                backgroundColor: const Color(0xEB000000),
                                insetPadding: EdgeInsets.zero,
                                child: Stack(
                                  children: <Widget>[
                                    Center(
                                      child: InteractiveViewer(
                                        child: hasLocalFile
                                            ? Image.file(
                                                File(message.imageFilePath!),
                                                fit: BoxFit.contain,
                                              )
                                            : (resolvedUrl != null
                                                ? Image.network(
                                                    resolvedUrl,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, _, _) =>
                                                        Image.asset(
                                                      AppImages.user1,
                                                      fit: BoxFit.contain,
                                                    ),
                                                  )
                                                : Image.asset(
                                                    message.imageAsset ??
                                                        AppImages.user1,
                                                    fit: BoxFit.contain,
                                                  )),
                                      ),
                                    ),
                                    Positioned(
                                      top: 40,
                                      right: 20,
                                      child: IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white, size: 28),
                                        onPressed: () =>
                                            Navigator.of(ctx).pop(),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: hasLocalFile
                              ? Image.file(
                                  File(message.imageFilePath!),
                                  width: 190,
                                  height: 190,
                                  fit: BoxFit.cover,
                                )
                              : (resolvedUrl != null
                                  ? Image.network(
                                      resolvedUrl,
                                      width: 190,
                                      height: 190,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Image.asset(
                                        AppImages.user1,
                                        width: 190,
                                        height: 190,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Image.asset(
                                      message.imageAsset ?? AppImages.user1,
                                      width: 190,
                                      height: 190,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Image.asset(
                                        AppImages.user1,
                                        width: 190,
                                        height: 190,
                                        fit: BoxFit.cover,
                                      ),
                                    )),
                        ),
                      );
                    },
                  ),
                  if (message.reactionEmoji != null || message.reactions.isNotEmpty)
                    _buildReactions(context),
                ],
              ),
            ),

          // ── Shared Post Card Bubble (Responsive Left/Right) ────────────────
          if (!message.isUnsent && message.type == MessageType.postShare)
            Align(
              alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: isMe
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: <Widget>[
                  // 1. Accompanying message text bubble (if any message was sent with the share)
                  if (message.text != null &&
                      message.text!.trim().isNotEmpty &&
                      message.text!.trim().toLowerCase() != 'null') ...<Widget>[
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.72,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        gradient: isMe ? AppColors.primaryGradientButton : null,
                        color: isMe ? null : context.themeCardBackground,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(20),
                          topRight: const Radius.circular(20),
                          bottomLeft: Radius.circular(isMe ? 20 : 4),
                          bottomRight: Radius.circular(isMe ? 4 : 20),
                        ),
                        border: isMe
                            ? null
                            : Border.all(
                                color: context.themeBorder.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                      ),
                      child: Text(
                        message.text!.trim(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isMe ? Colors.white : context.themeTextPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],

                  // 2. Shared Post Template Card (Tap to open Post / Reel)
                  Builder(
                    builder: (BuildContext context) {
                      final SharedPostData? cachedPost =
                          SharedPostCache.get(message.sharedPostId);
                      return GestureDetector(
                        onTap: () => _openSharedPostOrReel(context),
                        child: Container(
                          width: 220,
                          decoration: BoxDecoration(
                            color: context.themeCardBackground,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: context.themeBorder.withValues(alpha: 0.6),
                            ),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // Post Thumbnail Preview
                            SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: Stack(
                                fit: StackFit.expand,
                                children: <Widget>[
                                  _buildSharedPostThumbnail(context),
                                  // Center play icon if it is a reel
                                  if (message.postType == 'reel')
                                    Center(
                                      child: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.45,
                                          ),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.play_arrow_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                    ),
                                  // Bottom badge: Views or Likes
                                  Positioned(
                                    bottom: 8,
                                    left: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.6,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Icon(
                                            message.postType == 'reel'
                                                ? Icons.play_arrow_rounded
                                                : Icons.favorite_rounded,
                                            color: Colors.white,
                                            size: 13,
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            (message.postViews != null && message.postViews != '0')
                                                ? message.postViews!
                                                : (cachedPost != null && cachedPost.views > 0
                                                    ? '${cachedPost.views}'
                                                    : (message.postViews ??
                                                        (message.postLikes != null
                                                            ? '${message.postLikes}'
                                                            : '0'))),
                                            style: AppTextStyles.caption
                                                .copyWith(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 11,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Post Caption / Body if present in shared content
                            if (message.postCaption != null &&
                                message.postCaption!.trim().isNotEmpty &&
                                message.postCaption!.trim().toLowerCase() !=
                                    'null')
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.md,
                                  right: AppSpacing.md,
                                  top: AppSpacing.sm,
                                ),
                                child: Text(
                                  message.postCaption!.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: context.themeTextPrimary,
                                    fontSize: 12,
                                    height: 1.2,
                                  ),
                                ),
                              ),

                            // User Post Handle Banner
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              color: context.themeCardBackground,
                              child: Row(
                                children: <Widget>[
                                  ClipOval(child: _buildPostAuthorAvatar()),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      message.postAuthor != null &&
                                              message.postAuthor!.isNotEmpty
                                          ? (message.postAuthor!.endsWith(
                                                      "'s post",
                                                    ) ||
                                                    message.postAuthor!
                                                        .endsWith("'s reel")
                                                ? message.postAuthor!
                                                : "${message.postAuthor}'s ${message.postType == 'reel' ? 'reel' : 'post'}")
                                          : "@creator's post",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.caption.copyWith(
                                        color: context.themeTextPrimary,
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
                  );
                },
              ),
                  if (message.reactionEmoji != null || message.reactions.isNotEmpty)
                    _buildReactions(context),
                ],
              ),
            ),

          if (isMe && !message.isUnsent) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              message.isRead ? 'Seen' : 'Sent',
              style: AppTextStyles.caption.copyWith(
                color: context.themeTextMuted,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

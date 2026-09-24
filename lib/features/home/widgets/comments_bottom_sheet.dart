import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/auth_provider.dart';
import '../../create_post/services/post_content_service.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../screens/profile_tab_screen.dart';
import 'report_comment_bottom_sheet.dart';

/// Global in-memory tracker for comment likes across all screens.
/// Guarantees that if a user likes a comment on screen A, opening comments on
/// screen B (e.g. profile, feed, hashtag, discover) will preserve the liked state.
class CommentLikesTracker {
  CommentLikesTracker._();

  static final Set<String> _likedCommentIds = <String>{};
  static final Set<String> _unlikedCommentIds = <String>{};

  static bool isCommentLiked(String id, {bool serverStatus = false}) {
    if (id.isEmpty) return serverStatus;
    if (_likedCommentIds.contains(id)) return true;
    if (_unlikedCommentIds.contains(id)) return false;
    return serverStatus;
  }

  static void setLiked(String id, bool liked) {
    if (id.isEmpty) return;
    if (liked) {
      _likedCommentIds.add(id);
      _unlikedCommentIds.remove(id);
    } else {
      _unlikedCommentIds.add(id);
      _likedCommentIds.remove(id);
    }
  }
}

class CommentItemModel {
  CommentItemModel({
    required this.id,
    this.authorId,
    required this.avatarAsset,
    required this.username,
    required this.timeAgo,
    required this.content,
    this.likesCount = 0,
    this.isLiked = false,
    this.parentId,
    List<CommentItemModel>? replies,
    this.isAuthorReply = false,
    this.authorReplyText,
    this.authorReplyUser,
    this.authorReplyAvatar,
    this.moderationReason,
  }) : replies = replies ?? <CommentItemModel>[];

  String id;
  final String? authorId;
  final String avatarAsset;
  final String username;
  final String timeAgo;
  final String content;
  int likesCount;
  bool isLiked;
  final String? parentId;
  final List<CommentItemModel> replies;
  final bool isAuthorReply;
  final String? authorReplyText;
  final String? authorReplyUser;
  final String? authorReplyAvatar;
  final String? moderationReason;
}

class CommentsBottomSheet extends StatefulWidget {
  const CommentsBottomSheet({
    required this.totalComments,
    this.postId,
    this.postAuthorId,
    this.communityId,
    this.isAnswers = false,
    this.allowComments = true,
    this.onCommentAdded,
    super.key,
  });

  final int totalComments;
  final String? postId;
  final String? postAuthorId;
  final String? communityId;
  final bool isAnswers;
  final bool allowComments;
  final VoidCallback? onCommentAdded;

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentInputController =
      TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();

  bool _isLoadingComments = false;
  bool _isSubmittingComment = false;
  List<CommentItemModel> _comments = <CommentItemModel>[];
  final List<CommentItemModel> _hiddenComments = <CommentItemModel>[];
  CommentItemModel? _replyingToComment;

  @override
  void initState() {
    super.initState();
    final bool isRealPostId = widget.postId != null &&
        widget.postId!.isNotEmpty &&
        !widget.postId!.startsWith('mock_');
    if (isRealPostId) {
      _isLoadingComments = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchLiveComments();
      });
    } else {
      _comments = <CommentItemModel>[
        CommentItemModel(
          id: 'c1',
          avatarAsset: AppImages.user1,
          username: 'jules.does',
          timeAgo: '2h',
          content:
              'Six months looks so good on you. The scar care tips in your last video actually saved me.',
          likesCount: 214,
          isAuthorReply: true,
          authorReplyText: "that's the whole reason I post them 🤍",
          authorReplyUser: 'rowankeeps',
          authorReplyAvatar: AppImages.user2,
        ),
        CommentItemModel(
          id: 'c2',
          avatarAsset: AppImages.user2,
          username: 'moss.and.oat',
          timeAgo: '1h',
          content:
              "Sending this to my sister, she's four weeks post-op today.",
          likesCount: 214,
        ),
      ];
    }
  }

  Future<void> _fetchLiveComments() async {
    if (widget.postId == null) return;
    try {
      final PostContentService service =
          PostContentService(context.read<ApiClient>());
      final String? myUserId = context.read<AuthProvider>().userId;
      final List<dynamic> raw = await service.getComments(widget.postId!);
      final Map<String, CommentItemModel> allMap = <String, CommentItemModel>{};
      final List<CommentItemModel> topLevel = <CommentItemModel>[];
      final List<CommentItemModel> pendingReplies = <CommentItemModel>[];

      for (final dynamic item in raw) {
        if (item is Map<String, dynamic>) {
          final dynamic author = item['author'];
          final String? authorId = (item['authorId'] ??
                  item['userId'] ??
                  (author is Map ? (author['userId'] ?? author['id']) : null))
              ?.toString();
          final String username = author is Map
              ? (author['username'] ?? author['name'] ?? '@user').toString()
              : (item['username'] ?? '@user').toString();
          final String avatar = author is Map
              ? (author['avatarUrl'] ?? author['avatar'] ?? AppImages.user4).toString()
              : (item['avatarUrl'] ?? item['avatar'] ?? AppImages.user4).toString();
          final String text =
              (item['body'] ?? item['content'] ?? item['text'] ?? '').toString();
          final String? parentId = item['parentId']?.toString();
          final String timeAgo = _formatCommentTime(item['createdAt']?.toString());
          final int likesCount = (item['likeCount'] ?? item['likesCount'] ?? item['likes'] ?? 0) as int? ?? 0;
          final String commentId = (item['id'] ?? item['_id'] ?? '').toString();

          bool isLiked = (item['isLiked'] ??
                  item['liked'] ??
                  item['hasLiked'] ??
                  item['likedByMe'] ??
                  item['isLikedByMe'] ??
                  item['userLiked'] ??
                  false) as bool? ??
              false;

          final dynamic rawLikes = item['likes'] ?? item['commentLikes'] ?? item['userLikes'];
          if (rawLikes is List && myUserId != null && myUserId.isNotEmpty) {
            for (final dynamic l in rawLikes) {
              if (l is String && l == myUserId) {
                isLiked = true;
                break;
              } else if (l is Map) {
                final String? uid = (l['userId'] ?? l['user_id'] ?? l['id'] ?? l['authorId'])?.toString();
                if (uid == myUserId) {
                  isLiked = true;
                  break;
                }
              }
            }
          }

          isLiked = CommentLikesTracker.isCommentLiked(commentId, serverStatus: isLiked);

          final CommentItemModel model = CommentItemModel(
            id: commentId,
            authorId: authorId,
            avatarAsset: avatar,
            username: username,
            timeAgo: timeAgo,
            content: text,
            parentId: parentId,
            likesCount: likesCount,
            isLiked: isLiked,
          );

          allMap[model.id] = model;
          if (parentId != null && parentId.isNotEmpty) {
            pendingReplies.add(model);
          } else {
            topLevel.add(model);
          }
        }
      }

      for (final CommentItemModel reply in pendingReplies) {
        final CommentItemModel? parent = allMap[reply.parentId];
        if (parent != null) {
          parent.replies.add(reply);
        } else {
          topLevel.add(reply);
        }
      }

      if (mounted) {
        setState(() {
          _comments = topLevel;
          _isLoadingComments = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching comments for ${widget.postId}: $e');
      if (mounted) {
        setState(() => _isLoadingComments = false);
      }
    }
  }

  String _formatCommentTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return 'Just now';
    try {
      final DateTime dt = DateTime.parse(createdAt);
      final Duration diff = DateTime.now().difference(dt);
      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}m';
      return 'Just now';
    } catch (_) {
      return 'Recently';
    }
  }

  @override
  void dispose() {
    _commentInputController.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _startReply(CommentItemModel comment) {
    setState(() {
      _replyingToComment = comment;
    });
    _commentFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
    });
  }

  void _toggleLikeComment(CommentItemModel comment) {
    final bool wasLiked = comment.isLiked;
    final bool newLiked = !wasLiked;
    CommentLikesTracker.setLiked(comment.id, newLiked);

    setState(() {
      comment.isLiked = newLiked;
      if (newLiked) {
        comment.likesCount += 1;
      } else {
        comment.likesCount = (comment.likesCount - 1).clamp(0, 999999);
      }
    });

    final bool isRealCommentId = comment.id.isNotEmpty &&
        !comment.id.startsWith('mock_');
    if (isRealCommentId) {
      final PostContentService service =
          PostContentService(context.read<ApiClient>());
      if (!wasLiked) {
        service
            .likeComment(comment.id, postId: widget.postId)
            .catchError((Object e) {
          debugPrint('⚠️ [CommentsBottomSheet] Failed to like comment ${comment.id}: $e');
        });
      } else {
        service
            .unlikeComment(comment.id, postId: widget.postId)
            .catchError((Object e) {
          debugPrint('⚠️ [CommentsBottomSheet] Failed to unlike comment ${comment.id}: $e');
        });
      }
    }
  }

  void _hideComment(CommentItemModel comment) {
    final String typeName = widget.isAnswers ? 'Answer' : 'Comment';
    setState(() {
      _comments.removeWhere((CommentItemModel c) => c.id == comment.id);
      _hiddenComments.add(comment);
    });

    AppSnackBar.showSuccess(
      context,
      title: 'Hidden',
      subtitle: '$typeName from @${comment.username} hidden',
    );
  }

  void _unhideComment(CommentItemModel comment) {
    setState(() {
      _hiddenComments.removeWhere((CommentItemModel c) => c.id == comment.id);
      _comments.add(comment);
    });
  }

  Future<void> _deleteComment(CommentItemModel comment,
      {CommentItemModel? parentComment}) async {
    final String typeName = widget.isAnswers ? 'Answer' : 'Comment';
    setState(() {
      if (parentComment != null) {
        parentComment.replies
            .removeWhere((CommentItemModel c) => c.id == comment.id);
      } else {
        _comments.removeWhere((CommentItemModel c) => c.id == comment.id);
      }
    });

    AppSnackBar.showSuccess(
      context,
      title: 'Deleted',
      subtitle:
          comment.parentId != null ? 'Reply deleted' : '$typeName deleted',
    );

    final bool isRealCommentId = comment.id.isNotEmpty &&
        !comment.id.startsWith('c1') &&
        !comment.id.startsWith('c2') &&
        !comment.id.startsWith('mock_');
    if (isRealCommentId) {
      try {
        final PostContentService service =
            PostContentService(context.read<ApiClient>());
        await service.deleteComment(comment.id);
      } catch (e) {
        debugPrint('Error deleting comment ${comment.id}: $e');
      }
    }
  }

  void _showCommentOptionsModal(CommentItemModel comment,
      {CommentItemModel? parentComment}) {
    final String typeName = widget.isAnswers ? 'Answer' : 'Comment';
    final String typeNameLower = widget.isAnswers ? 'answer' : 'comment';
    final String typeNamePluralLower =
        widget.isAnswers ? 'answers' : 'comments';

    final AuthProvider auth = context.read<AuthProvider>();
    final String? currentUserId = auth.userId;
    final String? currentUsername = auth.user?.displayName;
    final bool isOwnComment = (currentUserId != null &&
            comment.authorId != null &&
            (currentUserId.trim().toLowerCase() ==
                comment.authorId!.trim().toLowerCase())) ||
        (currentUsername != null &&
            currentUsername.trim().isNotEmpty &&
            comment.username.isNotEmpty &&
            (currentUsername.replaceAll('@', '').trim().toLowerCase() ==
                comment.username.replaceAll('@', '').trim().toLowerCase()));
    final bool isPostAuthor = currentUserId != null &&
        widget.postAuthorId != null &&
        (currentUserId.trim().toLowerCase() ==
            widget.postAuthorId!.trim().toLowerCase());
    final bool canDelete = isOwnComment || isPostAuthor;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
          decoration: BoxDecoration(
            color: ctx.themeBottomSheetBackground,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xl,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: ctx.themeBorderStrong,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Comment preview quote
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ctx.isDarkMode
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '"${comment.content}"',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: ctx.themeTextSecondary,
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Option: Delete Comment / Reply (User's own comment or Post author cleanup)
                if (canDelete)
                  ListTile(
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                    title: Text(
                      isOwnComment
                          ? (comment.parentId != null
                              ? 'Delete reply'
                              : 'Delete $typeNameLower')
                          : 'Delete $typeNameLower (as author)',
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      isOwnComment
                          ? 'Permanently delete your ${comment.parentId != null ? 'reply' : typeNameLower}'
                          : 'Remove this $typeNameLower from your post',
                      style: TextStyle(
                        color: ctx.themeTextMuted,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _deleteComment(comment, parentComment: parentComment);
                    },
                  ),

                // Option 1: Hide Comment / Answer
                ListTile(
                  leading: Icon(
                    Icons.visibility_off_outlined,
                    color: ctx.themeIcon,
                    size: 22,
                  ),
                  title: Text(
                    'Hide $typeNameLower',
                    style: TextStyle(
                      color: ctx.themeTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'This $typeNameLower will be moved to hidden $typeNamePluralLower',
                    style: TextStyle(color: ctx.themeTextMuted, fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _hideComment(comment);
                  },
                ),

                // Option 2: Report Comment / Answer
                ListTile(
                  leading: Icon(
                    Icons.flag_outlined,
                    color: ctx.themeIcon,
                    size: 22,
                  ),
                  title: Text(
                    'Report $typeNameLower',
                    style: TextStyle(
                      color: ctx.themeTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ReportCommentBottomSheet.show(
                      context,
                      commentId: comment.id,
                      username: comment.username,
                      commentText: comment.content,
                      avatarAsset: comment.avatarAsset,
                      authorId: comment.authorId ?? comment.username,
                      communityId: widget.communityId,
                    );
                  },
                ),

                // Option 3: Copy Text
                ListTile(
                  leading: Icon(
                    Icons.copy_rounded,
                    color: ctx.themeIcon,
                    size: 22,
                  ),
                  title: Text(
                    'Copy $typeNameLower',
                    style: TextStyle(
                      color: ctx.themeTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: comment.content));
                    Navigator.pop(ctx);
                    AppSnackBar.showSuccess(
                      context,
                      title: 'Copied',
                      subtitle: '$typeName copied to clipboard',
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openHiddenCommentsSheet() {
    final String typeNamePluralLower =
        widget.isAnswers ? 'answers' : 'comments';
    final String typeNameLower =
        widget.isAnswers ? 'answer' : 'comment';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.72,
              decoration: BoxDecoration(
                color: context.themeBottomSheetBackground,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: SafeArea(
                top: false,
                child: Column(
                  children: <Widget>[
                    // Drag Handle Bar
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.themeBorderStrong,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                Icons.visibility_off_outlined,
                                color: context.themeIcon,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${_hiddenComments.length} Hidden $typeNamePluralLower',
                                style: TextStyle(
                                  color: context.themeTextPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(
                              Icons.close_rounded,
                              color: context.themeIconMuted,
                              size: 22,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Info Header Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: context.isDarkMode
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.themeBorder,
                          ),
                        ),
                        child: Text(
                          'These $typeNamePluralLower were hidden by you or flagged by automatic community moderation.',
                          style: TextStyle(
                            color: context.themeTextSecondary,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Hidden Comments List
                    Expanded(
                      child: _hiddenComments.isEmpty
                          ? Center(
                              child: Text(
                                'No hidden $typeNamePluralLower',
                                style: TextStyle(
                                  color: context.themeTextMuted,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
                              ),
                              itemCount: _hiddenComments.length,
                              separatorBuilder:
                                  (BuildContext context, int index) =>
                                      const SizedBox(height: AppSpacing.lg),
                              itemBuilder: (BuildContext context, int index) {
                                final CommentItemModel item =
                                    _hiddenComments[index];
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    ClipOval(
                                      child: item.avatarAsset.startsWith('http')
                                          ? Image.network(
                                              item.avatarAsset,
                                              width: 36,
                                              height: 36,
                                              fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                                  Image.asset(
                                                    AppImages.defaultAvatar,
                                                    width: 36,
                                                    height: 36,
                                                    fit: BoxFit.cover,
                                                  ),
                                            )
                                          : Image.asset(
                                              item.avatarAsset.isNotEmpty
                                                  ? item.avatarAsset
                                                  : AppImages.defaultAvatar,
                                              width: 36,
                                              height: 36,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  Image.asset(
                                                    AppImages.defaultAvatar,
                                                    width: 36,
                                                    height: 36,
                                                    fit: BoxFit.cover,
                                                  ),
                                            ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Row(
                                            children: <Widget>[
                                              Text(
                                                item.username,
                                                style: TextStyle(
                                                  color: context.themeTextPrimary,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                item.timeAgo,
                                                style: TextStyle(
                                                  color: context.themeTextMuted,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            item.content,
                                            style: TextStyle(
                                              color: context.themeTextPrimary,
                                              fontSize: 13,
                                              height: 1.35,
                                            ),
                                          ),
                                          if (item.moderationReason !=
                                              null) ...<Widget>[
                                            const SizedBox(height: 4),
                                            Text(
                                              'Note: ${item.moderationReason}',
                                              style: const TextStyle(
                                                color: Colors.redAccent,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: () {
                                              setModalState(() {
                                                _unhideComment(item);
                                              });
                                              setState(() {});
                                            },
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: context.themeChipBackground,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: context.themeBorder,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: <Widget>[
                                                  Icon(
                                                    Icons.visibility_outlined,
                                                    color: context.themeIcon,
                                                    size: 14,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'Unhide $typeNameLower',
                                                    style: TextStyle(
                                                      color: context.themeTextPrimary,
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _addNewComment() async {
    final String text = _commentInputController.text.trim();
    if (text.isEmpty || _isSubmittingComment) return;

    final CommentItemModel? targetReply = _replyingToComment;
    final String? parentId = targetReply != null
        ? (targetReply.parentId ?? targetReply.id)
        : null;

    final String tempId = 'c_${DateTime.now().millisecondsSinceEpoch}';
    final AuthProvider auth = context.read<AuthProvider>();
    final String myUserId = auth.userId ?? '';
    final String myUsername = auth.user?.displayName ?? 'you';
    final String myAvatar = auth.user?.avatarUrl ?? AppImages.user4;

    final CommentItemModel optimistic = CommentItemModel(
      id: tempId,
      authorId: myUserId,
      avatarAsset: myAvatar,
      username: myUsername,
      timeAgo: 'Just now',
      content: text,
      parentId: parentId,
      likesCount: 0,
    );

    setState(() {
      if (parentId != null) {
        final int parentIndex =
            _comments.indexWhere((CommentItemModel c) => c.id == parentId);
        if (parentIndex != -1) {
          _comments[parentIndex].replies.add(optimistic);
        } else {
          _comments.insert(0, optimistic);
        }
      } else {
        _comments.insert(0, optimistic);
      }
      _commentInputController.clear();
      _replyingToComment = null;
      _isSubmittingComment = true;
    });

    widget.onCommentAdded?.call();

    final bool isRealPostId = widget.postId != null &&
        widget.postId!.isNotEmpty &&
        !widget.postId!.startsWith('mock_');
    if (isRealPostId) {
      try {
        final PostContentService service =
            PostContentService(context.read<ApiClient>());
        final dynamic res = await service.createComment(
          postId: widget.postId!,
          content: text,
          parentId: parentId,
        );
        if (res is Map) {
          final dynamic data = res['data'] ?? res;
          final String? realId =
              (data is Map ? (data['id'] ?? data['_id']) : null)?.toString();
          if (realId != null && realId.isNotEmpty) {
            optimistic.id = realId;
          }
        }
      } catch (e) {
        debugPrint('Error posting comment: $e');
      } finally {
        if (mounted) {
          setState(() => _isSubmittingComment = false);
        }
      }
    } else {
      setState(() => _isSubmittingComment = false);
    }
  }

  int get _totalCommentsCount {
    int count = 0;
    for (final CommentItemModel c in _comments) {
      count += 1;
      count += c.replies.length;
      if (c.isAuthorReply &&
          c.authorReplyText != null &&
          c.authorReplyText!.isNotEmpty) {
        count += 1;
      }
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final int displayCount = _isLoadingComments
        ? widget.totalComments
        : _totalCommentsCount;
    final String titleText = widget.isAnswers
        ? '$displayCount ${displayCount == 1 ? 'answer' : 'answers'}'
        : '$displayCount ${displayCount == 1 ? 'comment' : l10n.commentsTitle.toLowerCase()}';

    final String placeholderText = widget.isAnswers
        ? 'Add a your answer...'
        : (_replyingToComment != null
            ? 'Replying to @${_replyingToComment!.username}...'
            : l10n.commentPlaceholder);

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            // ── Drag Handle Bar ──────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: context.themeBorderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Header (Title + Close X Button) ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    titleText,
                    style: TextStyle(
                      color: context.themeTextPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      color: context.themeIconMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // ── Scrollable Comments / Answers List ──────────────────────────
            Expanded(
              child: _isLoadingComments
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gradientPink,
                      ),
                    )
                  : _comments.isEmpty
                      ? Center(
                          child: Text(
                            widget.isAnswers
                                ? 'No answers yet. Be the first to answer!'
                                : 'No comments yet. Be the first to comment!',
                            style: TextStyle(
                              color: context.themeTextMuted,
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          children: <Widget>[
                            for (final CommentItemModel item in _comments) ...<Widget>[
                              _CommentItemTile(
                                comment: item,
                                onLikeToggle: () => _toggleLikeComment(item),
                                onLongPress: () =>
                                    _showCommentOptionsModal(item),
                                onReplyTap: () => _startReply(item),
                                replyLabel: l10n.commentReply,
                                reportLabel: l10n.commentReport,
                                authorLabel: l10n.commentAuthor,
                                communityId: widget.communityId,
                              ),
                              if (item.replies.isNotEmpty) ...<Widget>[
                                Padding(
                                  padding: const EdgeInsets.only(left: 42, top: 10),
                                  child: Column(
                                    children: <Widget>[
                                      for (final CommentItemModel reply
                                          in item.replies) ...<Widget>[
                                        _CommentItemTile(
                                          comment: reply,
                                          onLikeToggle: () =>
                                              _toggleLikeComment(reply),
                                          onLongPress: () =>
                                              _showCommentOptionsModal(reply,
                                                  parentComment: item),
                                          onReplyTap: () =>
                                              _startReply(item),
                                          replyLabel: l10n.commentReply,
                                          reportLabel: l10n.commentReport,
                                          authorLabel: l10n.commentAuthor,
                                          communityId: widget.communityId,
                                          isReply: true,
                                        ),
                                        const SizedBox(height: 10),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.lg),
                            ],

                            if (_hiddenComments.isNotEmpty) ...<Widget>[
                              // Hidden Comment / Answer Warning Card -> Clickable to open Hidden Sheet
                              GestureDetector(
                                onTap: _openHiddenCommentsSheet,
                                child: Container(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  decoration: BoxDecoration(
                                    color: context.isDarkMode
                                        ? const Color(0xFF1E1B26)
                                        : const Color(0xFFE8FAF9),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: context.isDarkMode
                                          ? Colors.white.withValues(alpha: 0.12)
                                          : AppColors.gradientCyan
                                              .withValues(alpha: 0.45),
                                      width: context.isDarkMode ? 1.0 : 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Icon(
                                        Icons.visibility_off_outlined,
                                        color: context.isDarkMode
                                            ? Colors.white54
                                            : AppColors.gradientCyan,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            Text(
                                              widget.isAnswers
                                                  ? '${_hiddenComments.length} ${_hiddenComments.length > 1 ? 'Answers' : 'Answer'} hidden'
                                                  : '${_hiddenComments.length} ${_hiddenComments.length > 1 ? 'comments' : 'comment'} hidden',
                                              style: TextStyle(
                                                color: context.isDarkMode
                                                    ? Colors.white
                                                    : const Color(0xFFE5A8BA),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              widget.isAnswers
                                                  ? 'This answer was flagged for moderation.'
                                                  : l10n.commentHiddenSub,
                                              style: TextStyle(
                                                color: context.isDarkMode
                                                    ? Colors.white54
                                                    : const Color(0xFF7E7989),
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (context.isDarkMode)
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.white54,
                                          size: 20,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                          ],
                        ),
            ),

            // ── Replying Banner if active ───────────────────────────
            if (_replyingToComment != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gradientCyan.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.reply_rounded,
                      size: 16,
                      color: AppColors.gradientCyan,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Replying to @${_replyingToComment!.username}',
                        style: TextStyle(
                          color: context.themeTextPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _cancelReply,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: context.themeIconMuted,
                      ),
                    ),
                  ],
                ),
              ),

            // ── Bottom Fixed Input Bar ────────────────────────────────
            if (widget.allowComments)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: <Widget>[
                    // Current User Avatar
                    Builder(
                      builder: (BuildContext context) {
                        final String? currentAvatarUrl =
                            context.read<AuthProvider>().user?.avatarUrl;
                        return ClipOval(
                          child: currentAvatarUrl != null &&
                                  currentAvatarUrl.startsWith('http')
                              ? Image.network(
                                  currentAvatarUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Image.asset(
                                    AppImages.user4,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(
                                  AppImages.user4,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),

                    // Reusable AppTextField Widget
                    Expanded(
                      child: AppTextField(
                        controller: _commentInputController,
                        focusNode: _commentFocusNode,
                        hintText: placeholderText,
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Send Button with Secondary Gradient (Cyan to Pink)
                    GestureDetector(
                      onTap: _addNewComment,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.secondaryGradientButton,
                        ),
                        child: Center(
                          child: _isSubmittingComment
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : SvgPicture.asset(
                                  AppIcons.send,
                                  width: 18,
                                  height: 18,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: 8,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: context.isDarkMode
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.comments_disabled_outlined,
                      size: 18,
                      color: context.themeTextMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Comments are disabled for this post.',
                      style: TextStyle(
                        color: context.themeTextMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
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

class _CommentItemTile extends StatelessWidget {
  const _CommentItemTile({
    required this.comment,
    required this.onLikeToggle,
    required this.onLongPress,
    this.onReplyTap,
    required this.replyLabel,
    required this.reportLabel,
    required this.authorLabel,
    this.communityId,
    this.isReply = false,
  });

  final CommentItemModel comment;
  final VoidCallback onLikeToggle;
  final VoidCallback onLongPress;
  final VoidCallback? onReplyTap;
  final String replyLabel;
  final String reportLabel;
  final String authorLabel;
  final String? communityId;
  final bool isReply;

  void _openProfile(BuildContext context) {
    final AuthProvider auth = context.read<AuthProvider>();
    final String? currentUserId = auth.userId;
    final String? authorId = comment.authorId;

    final bool isCurrentUser = authorId != null &&
        currentUserId != null &&
        authorId.trim().toLowerCase() == currentUserId.trim().toLowerCase();

    if (isCurrentUser) {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => const ProfileTabScreen(),
        ),
      );
    } else {
      Navigator.push<void>(
        context,
        MaterialPageRoute<void>(
          builder: (_) => UserProfileScreen(
            userId: authorId,
            username: comment.username.replaceAll('@', ''),
            name: comment.username.replaceAll('@', '').split('.').first,
            avatarAsset: comment.avatarAsset,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSize = isReply ? 28 : 36;

    return GestureDetector(
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: () => _openProfile(context),
                child: ClipOval(
                  child: comment.avatarAsset.startsWith('http')
                      ? Image.network(
                          comment.avatarAsset,
                          width: avatarSize,
                          height: avatarSize,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Image.asset(
                              AppImages.defaultAvatar,
                              width: avatarSize,
                              height: avatarSize,
                              fit: BoxFit.cover,
                            ),
                        )
                      : Image.asset(
                          comment.avatarAsset.isNotEmpty
                              ? comment.avatarAsset
                              : AppImages.defaultAvatar,
                          width: avatarSize,
                          height: avatarSize,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Image.asset(
                            AppImages.defaultAvatar,
                            width: avatarSize,
                            height: avatarSize,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => _openProfile(context),
                          child: Text(
                            comment.username,
                            style: TextStyle(
                              color: context.themeTextPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          comment.timeAgo,
                          style: TextStyle(
                            color: context.themeTextMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      comment.content,
                      style: TextStyle(
                        color: context.themeTextPrimary,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: <Widget>[
                        GestureDetector(
                          onTap: onReplyTap,
                          child: Text(
                            replyLabel,
                            style: TextStyle(
                              color: context.themeTextMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () {
                            ReportCommentBottomSheet.show(
                              context,
                              commentId: comment.id,
                              username: comment.username,
                              commentText: comment.content,
                              avatarAsset: comment.avatarAsset,
                              authorId: comment.authorId ?? comment.username,
                              communityId: communityId,
                            );
                          },
                          child: Text(
                            reportLabel,
                            style: TextStyle(
                              color: context.themeTextMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Interactive Like Button with Animated Icon & Count
              GestureDetector(
                onTap: onLikeToggle,
                behavior: HitTestBehavior.opaque,
                child: Column(
                  children: <Widget>[
                    Image.asset(
                      comment.isLiked
                          ? AppIcons.likedLogo
                          : AppIcons.unlikeLogo,
                      width: 22,
                      height: 22,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${comment.likesCount}',
                      style: TextStyle(
                        color: comment.isLiked
                            ? AppColors.gradientPink
                            : context.themeTextMuted,
                        fontSize: 11,
                        fontWeight: comment.isLiked
                            ? FontWeight.w700
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Author Reply if present
          if (comment.isAuthorReply && comment.authorReplyText != null) ...<Widget>[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  GestureDetector(
                    onTap: () {
                      final String authorName =
                          comment.authorReplyUser ?? 'rowankeeps';
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => UserProfileScreen(
                            username: authorName.replaceAll('@', ''),
                            name: authorName
                                .replaceAll('@', '')
                                .split('.')
                                .first,
                            avatarAsset:
                                comment.authorReplyAvatar ?? AppImages.user2,
                          ),
                        ),
                      );
                    },
                    child: ClipOval(
                      child: Image.asset(
                        comment.authorReplyAvatar ?? AppImages.user2,
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            GestureDetector(
                              onTap: () {
                                final String authorName =
                                    comment.authorReplyUser ?? 'rowankeeps';
                                Navigator.push<void>(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (_) => UserProfileScreen(
                                      username:
                                          authorName.replaceAll('@', ''),
                                      name: authorName
                                          .replaceAll('@', '')
                                          .split('.')
                                          .first,
                                      avatarAsset:
                                          comment.authorReplyAvatar ??
                                              AppImages.user2,
                                    ),
                                  ),
                                );
                              },
                              child: Text(
                                comment.authorReplyUser ?? 'rowankeeps',
                                style: TextStyle(
                                  color: context.themeTextPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppColors.secondaryGradientButton,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                authorLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          comment.authorReplyText!,
                          style: TextStyle(
                            color: context.themeTextPrimary,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

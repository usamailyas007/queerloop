import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/cache/cache_manager.dart';
import '../../../core/cache/user_relationship_cache.dart';
import '../../auth/auth_provider.dart';
import '../../create_post/services/post_content_service.dart';
import '../../profile/provider/profile_provider.dart';
import '../../profile/screens/user_profile_screen.dart';
import '../models/post_item_model.dart';
import '../models/reel_item_model.dart';
import '../provider/home_feed_provider.dart';
import '../screens/profile_tab_screen.dart';
import 'report_comment_bottom_sheet.dart';

/// Global persistent tracker for comment likes across all screens and app restarts.
/// Guarantees that if a user likes a comment, the state survives app restarts and tab switches.
class CommentLikesTracker {
  CommentLikesTracker._();

  static final Set<String> _likedCommentIds = <String>{};
  static final Set<String> _unlikedCommentIds = <String>{};
  static bool _initialized = false;
  static String? _loadedUserId;

  static Future<void> ensureInitialized({String? userId}) async {
    if (_initialized && _loadedUserId == userId) return;
    _loadedUserId = userId;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = userId != null && userId.isNotEmpty
          ? 'user_liked_comments_$userId'
          : 'user_liked_comments_global';
      final List<String>? saved = prefs.getStringList(key);
      if (saved != null) {
        _likedCommentIds.addAll(saved);
      }
      _initialized = true;
    } catch (e) {
      debugPrint('⚠️ [CommentLikesTracker] Failed to load persisted likes: $e');
    }
  }

  static void _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String key = _loadedUserId != null && _loadedUserId!.isNotEmpty
          ? 'user_liked_comments_$_loadedUserId'
          : 'user_liked_comments_global';
      await prefs.setStringList(key, _likedCommentIds.toList());
    } catch (e) {
      debugPrint('⚠️ [CommentLikesTracker] Failed to save persisted likes: $e');
    }
  }

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
    _persist();
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
    this.allowCommentsFrom = 'everyone',
    this.authorUsername,
    this.onCommentAdded,
    this.onCommentDeleted,
    this.onCommentCountChanged,
    super.key,
  });

  final int totalComments;
  final String? postId;
  final String? postAuthorId;
  final String? communityId;
  final bool isAnswers;
  final bool allowComments;
  final String allowCommentsFrom;
  final String? authorUsername;
  final VoidCallback? onCommentAdded;
  final void Function(int deletedCount, int remainingCount)? onCommentDeleted;
  final void Function(int totalCount)? onCommentCountChanged;

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

  void _syncGlobalCommentCount(int count) {
    if (widget.postId != null && widget.postId!.isNotEmpty) {
      try {
        context.read<HomeFeedProvider>().setCommentCount(widget.postId!, count);
      } catch (_) {}
      try {
        context.read<ProfileProvider>().updatePostCommentCount(widget.postId!, count);
      } catch (_) {}
    }
  }

  String? _resolveCurrentUserAvatar({BuildContext? watchContext}) {
    try {
      final ProfileProvider profile = watchContext != null
          ? watchContext.watch<ProfileProvider>()
          : context.read<ProfileProvider>();
      if (profile.avatarUrl.isNotEmpty &&
          profile.avatarUrl != 'https://picsum.photos/seed/ash/400') {
        return profile.avatarUrl;
      }
    } catch (_) {}

    try {
      final AuthProvider auth = watchContext != null
          ? watchContext.watch<AuthProvider>()
          : context.read<AuthProvider>();
      if (auth.user?.avatarUrl != null &&
          auth.user!.avatarUrl!.trim().isNotEmpty &&
          auth.user!.avatarUrl != 'https://picsum.photos/seed/ash/400') {
        return auth.user!.avatarUrl!.trim();
      }
      final String? uid = auth.userId;
      if (uid != null && uid.isNotEmpty) {
        final dynamic cached = CacheManager.instance.get('profile_details_$uid');
        if (cached is Map<String, dynamic>) {
          final String? cachedAvatar = (cached['avatarUrl'] ??
                  cached['avatar'] ??
                  cached['profilePic'])
              ?.toString();
          if (cachedAvatar != null &&
              cachedAvatar.isNotEmpty &&
              cachedAvatar != 'https://picsum.photos/seed/ash/400') {
            return cachedAvatar;
          }
        }
      }
    } catch (_) {}

    return null;
  }

  String _resolveCurrentUserName({BuildContext? watchContext}) {
    try {
      final ProfileProvider profile = watchContext != null
          ? watchContext.watch<ProfileProvider>()
          : context.read<ProfileProvider>();
      if (profile.username.isNotEmpty && profile.username != 'ashinorbit') {
        return profile.username;
      }
      if (profile.displayName.isNotEmpty && profile.displayName != 'Ash Mercado') {
        return profile.displayName;
      }
    } catch (_) {}

    try {
      final AuthProvider auth = watchContext != null
          ? watchContext.watch<AuthProvider>()
          : context.read<AuthProvider>();
      if (auth.user?.displayName != null &&
          auth.user!.displayName!.trim().isNotEmpty &&
          auth.user!.displayName != 'Ash Mercado') {
        return auth.user!.displayName!.trim();
      }
      final String? uid = auth.userId;
      if (uid != null && uid.isNotEmpty) {
        final dynamic cached = CacheManager.instance.get('profile_details_$uid');
        if (cached is Map<String, dynamic>) {
          final String? name = (cached['username'] ??
                  cached['displayName'] ??
                  cached['name'])
              ?.toString();
          if (name != null &&
              name.isNotEmpty &&
              name != 'ashinorbit' &&
              name != 'Ash Mercado') {
            return name;
          }
        }
      }
      if (auth.user?.email.isNotEmpty == true) {
        return auth.user!.email.split('@').first;
      }
    } catch (_) {}

    return 'you';
  }

  @override
  void initState() {
    super.initState();
    final String mode = widget.allowCommentsFrom.toLowerCase().trim();
    if (mode == 'following' || mode == 'mutual') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final ProfileProvider profile = context.read<ProfileProvider>();
        if (profile.followers.isEmpty) {
          profile.loadFollowers().then((_) {
            if (mounted) setState(() {});
          });
        }
      });
    }
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
      await CommentLikesTracker.ensureInitialized(userId: myUserId);
      final List<dynamic> raw = await service.getComments(widget.postId!);
      final Map<String, CommentItemModel> allMap = <String, CommentItemModel>{};
      final List<CommentItemModel> topLevel = <CommentItemModel>[];
      final List<CommentItemModel> pendingReplies = <CommentItemModel>[];

      for (final dynamic item in raw) {
        if (item is Map<String, dynamic>) {
          final dynamic author = item['author'] ?? item['user'];
          final String? authorId = (item['authorId'] ??
                  item['author_id'] ??
                  item['userId'] ??
                  item['user_id'] ??
                  item['creatorId'] ??
                  item['creator_id'] ??
                  (author is String
                      ? author
                      : (author is Map
                          ? (author['id'] ??
                              author['_id'] ??
                              author['userId'] ??
                              author['user_id'])
                          : null)))
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

          final dynamic rawIsLiked = item['isLiked'] ??
              item['is_liked'] ??
              item['liked'] ??
              item['hasLiked'] ??
              item['has_liked'] ??
              item['likedByMe'] ??
              item['liked_by_me'] ??
              item['isLikedByMe'] ??
              item['is_liked_by_me'] ??
              item['userLiked'] ??
              item['user_liked'] ??
              (item['viewer'] is Map ? (item['viewer']['isLiked'] ?? item['viewer']['liked']) : null) ??
              (item['metadata'] is Map ? (item['metadata']['isLiked'] ?? item['metadata']['is_liked']) : null);

          bool isLiked = rawIsLiked == true || rawIsLiked == 1 || rawIsLiked == 'true';

          final dynamic rawLikes = item['likes'] ??
              item['commentLikes'] ??
              item['comment_likes'] ??
              item['userLikes'] ??
              item['user_likes'] ??
              item['likedBy'] ??
              item['liked_by'] ??
              item['likesList'] ??
              item['likes_users'];
          if (rawLikes is List && myUserId != null && myUserId.isNotEmpty) {
            for (final dynamic l in rawLikes) {
              if (l is String && l.trim().toLowerCase() == myUserId.trim().toLowerCase()) {
                isLiked = true;
                break;
              } else if (l is Map) {
                final String? uid = (l['userId'] ?? l['user_id'] ?? l['id'] ?? l['authorId'])?.toString();
                if (uid != null && uid.trim().toLowerCase() == myUserId.trim().toLowerCase()) {
                  isLiked = true;
                  break;
                }
              }
            }
          }

          isLiked = CommentLikesTracker.isCommentLiked(commentId, serverStatus: isLiked);
          if (isLiked) {
            CommentLikesTracker.setLiked(commentId, true);
          }

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
          // Parent comment was deleted, so this reply is an orphaned reply.
          // Do not display it, and clean it up from backend in background.
          final bool isReal = reply.id.isNotEmpty &&
              reply.id != 'c1' &&
              reply.id != 'c2' &&
              !reply.id.startsWith('c_') &&
              !reply.id.startsWith('mock_');
          if (isReal) {
            service.deleteComment(reply.id, postId: widget.postId).catchError((Object _) {});
          }
        }
      }

      if (mounted) {
        setState(() {
          _comments = topLevel;
          _isLoadingComments = false;
        });
        widget.onCommentCountChanged?.call(_totalCommentsCount);
        _syncGlobalCommentCount(_totalCommentsCount);
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

  bool _isUserOwnComment(CommentItemModel comment) {
    if (comment.id.startsWith('c_')) return true;
    try {
      final AuthProvider auth = context.read<AuthProvider>();
      final ProfileProvider profile = context.read<ProfileProvider>();
      final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
      final String? authUid = auth.userId;
      final String? profileId = profile.profile?.id;
      final String? authUserObjId = auth.user?.id;
      final String? feedUserId = homeFeed.currentUserId;
      final String myUsername = _resolveCurrentUserName();

      final Set<String> myIds = <String>{
        if (authUid != null && authUid.trim().isNotEmpty) authUid.trim().toLowerCase(),
        if (profileId != null && profileId.trim().isNotEmpty) profileId.trim().toLowerCase(),
        if (authUserObjId != null && authUserObjId.trim().isNotEmpty) authUserObjId.trim().toLowerCase(),
        if (feedUserId != null && feedUserId.trim().isNotEmpty) feedUserId.trim().toLowerCase(),
      };

      final String? authorId = comment.authorId;
      if (authorId != null && authorId.isNotEmpty) {
        if (myIds.contains(authorId.trim().toLowerCase())) {
          return true;
        }
      }

      final String cleanCommentUser =
          comment.username.replaceAll('@', '').trim().toLowerCase();
      if (cleanCommentUser.isEmpty) return false;

      final Set<String> myNames = <String>{
        myUsername.replaceAll('@', '').trim().toLowerCase(),
        profile.username.replaceAll('@', '').trim().toLowerCase(),
        profile.displayName.replaceAll('@', '').trim().toLowerCase(),
        if (auth.user?.displayName != null)
          auth.user!.displayName!.replaceAll('@', '').trim().toLowerCase(),
        if (auth.user != null && auth.user!.email.isNotEmpty)
          auth.user!.email.split('@').first.trim().toLowerCase(),
      }..removeWhere((String s) =>
          s.isEmpty || s == 'ashinorbit' || s == 'ash mercado');

      if (myNames.contains(cleanCommentUser)) {
        return true;
      }
      for (final String n in myNames) {
        if (n == cleanCommentUser ||
            cleanCommentUser.contains(n) ||
            n.contains(cleanCommentUser)) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  bool _isPostAuthor() {
    try {
      final AuthProvider auth = context.read<AuthProvider>();
      final ProfileProvider profile = context.read<ProfileProvider>();
      final HomeFeedProvider homeFeed = context.read<HomeFeedProvider>();
      final String? authUid = auth.userId;
      final String? profileId = profile.profile?.id;
      final String? authUserObjId = auth.user?.id;
      final String? feedUserId = homeFeed.currentUserId;
      final String myUsername = _resolveCurrentUserName();

      final Set<String> myIds = <String>{
        if (authUid != null && authUid.trim().isNotEmpty) authUid.trim().toLowerCase(),
        if (profileId != null && profileId.trim().isNotEmpty) profileId.trim().toLowerCase(),
        if (authUserObjId != null && authUserObjId.trim().isNotEmpty) authUserObjId.trim().toLowerCase(),
        if (feedUserId != null && feedUserId.trim().isNotEmpty) feedUserId.trim().toLowerCase(),
      };

      if (widget.postAuthorId != null && widget.postAuthorId!.isNotEmpty) {
        final String targetId = widget.postAuthorId!.trim().toLowerCase();
        if (myIds.contains(targetId)) return true;
      }

      if (widget.authorUsername != null && widget.authorUsername!.isNotEmpty) {
        final String targetUser = widget.authorUsername!.replaceAll('@', '').trim().toLowerCase();
        final Set<String> myNames = <String>{
          myUsername.replaceAll('@', '').trim().toLowerCase(),
          profile.username.replaceAll('@', '').trim().toLowerCase(),
          profile.displayName.replaceAll('@', '').trim().toLowerCase(),
          if (auth.user?.displayName != null)
            auth.user!.displayName!.replaceAll('@', '').trim().toLowerCase(),
        }..removeWhere((String s) => s.isEmpty);
        if (myNames.contains(targetUser)) return true;
        for (final String n in myNames) {
          if (n == targetUser || targetUser.contains(n) || n.contains(targetUser)) {
            return true;
          }
        }
      }

      // Check if widget.postId belongs to the current user's profile posts, reels, or home feed posts
      if (widget.postId != null && widget.postId!.isNotEmpty) {
        if (profile.userPosts.any((PostItemModel p) => p.id == widget.postId)) {
          return true;
        }
        if (profile.userReels.any((ReelItemModel r) => r.id == widget.postId)) {
          return true;
        }
        if (homeFeed.posts.any((PostItemModel p) =>
            p.id == widget.postId &&
            (myIds.contains(p.authorId?.trim().toLowerCase()) ||
             p.username.replaceAll('@', '').trim().toLowerCase() == myUsername.replaceAll('@', '').trim().toLowerCase()))) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  bool _canDeleteComment(CommentItemModel comment) =>
      _isUserOwnComment(comment) || _isPostAuthor();

  void _confirmDeleteComment(CommentItemModel comment,
      {CommentItemModel? parentComment}) {
    final String typeName = widget.isAnswers ? 'answer' : 'comment';
    final String itemType = comment.parentId != null ? 'reply' : typeName;
    final int repliesCount = parentComment == null ? comment.replies.length : 0;
    final bool hasReplies = repliesCount > 0;

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          backgroundColor: ctx.themeCardBackground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(
            hasReplies
                ? 'Delete $typeName & replies?'
                : 'Delete ${itemType[0].toUpperCase()}${itemType.substring(1)}?',
            style: TextStyle(
              color: ctx.themeTextPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            hasReplies
                ? 'Are you sure you want to delete this $typeName? All $repliesCount replies will also be permanently deleted. This action cannot be undone.'
                : 'Are you sure you want to delete this $itemType? This action cannot be undone.',
            style: TextStyle(
              color: ctx.themeTextSecondary,
              fontSize: 14,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: ctx.themeTextMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _deleteComment(comment, parentComment: parentComment);
              },
              child: Text(
                hasReplies ? 'Delete All (${repliesCount + 1})' : 'Delete',
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteComment(CommentItemModel comment,
      {CommentItemModel? parentComment}) async {
    final String typeName = widget.isAnswers ? 'Answer' : 'Comment';

    // Collect all child reply IDs that must also be deleted on the backend
    final List<String> replyIdsToDelete = <String>[];
    if (parentComment == null) {
      for (final CommentItemModel r in comment.replies) {
        final bool isRealReply = r.id.isNotEmpty &&
            r.id != 'c1' &&
            r.id != 'c2' &&
            !r.id.startsWith('c_') &&
            !r.id.startsWith('mock_');
        if (isRealReply && !replyIdsToDelete.contains(r.id)) {
          replyIdsToDelete.add(r.id);
        }
      }
      for (final CommentItemModel c in _comments) {
        if (c.parentId == comment.id) {
          final bool isRealReply = c.id.isNotEmpty &&
              c.id != 'c1' &&
              c.id != 'c2' &&
              !c.id.startsWith('c_') &&
              !c.id.startsWith('mock_');
          if (isRealReply && !replyIdsToDelete.contains(c.id)) {
            replyIdsToDelete.add(c.id);
          }
        }
      }
    }

    final int deletedCount =
        1 + (parentComment == null ? comment.replies.length : 0);

    setState(() {
      if (parentComment != null) {
        parentComment.replies
            .removeWhere((CommentItemModel c) => c.id == comment.id);
      } else {
        _comments.removeWhere((CommentItemModel c) =>
            c.id == comment.id || c.parentId == comment.id);
      }
    });

    final int remainingCount = _totalCommentsCount;
    widget.onCommentDeleted?.call(deletedCount, remainingCount);
    widget.onCommentCountChanged?.call(remainingCount);
    _syncGlobalCommentCount(remainingCount);

    AppSnackBar.showSuccess(
      context,
      title: 'Deleted',
      subtitle: comment.parentId != null
          ? 'Reply deleted'
          : (comment.replies.isNotEmpty
              ? '$typeName and ${comment.replies.length} replies deleted'
              : '$typeName deleted'),
    );

    final bool isRealCommentId = comment.id.isNotEmpty &&
        comment.id != 'c1' &&
        comment.id != 'c2' &&
        !comment.id.startsWith('c_') &&
        !comment.id.startsWith('mock_');
    if (isRealCommentId) {
      try {
        final PostContentService service =
            PostContentService(context.read<ApiClient>());
        // Delete parent comment with postId support
        await service.deleteComment(comment.id, postId: widget.postId);

        // Cascade delete child replies on server so they don't remain in DB
        for (final String replyId in replyIdsToDelete) {
          try {
            await service.deleteComment(replyId, postId: widget.postId);
          } catch (err) {
            debugPrint('Error cascade deleting reply $replyId: $err');
          }
        }
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

    final bool isOwnComment = _isUserOwnComment(comment);
    final bool canDelete = _canDeleteComment(comment);

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
                      comment.replies.isNotEmpty
                          ? 'Delete this $typeNameLower and its ${comment.replies.length} replies'
                          : (isOwnComment
                              ? 'Permanently delete your ${comment.parentId != null ? 'reply' : typeNameLower}'
                              : 'Remove this $typeNameLower from your post'),
                      style: TextStyle(
                        color: ctx.themeTextMuted,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _confirmDeleteComment(comment, parentComment: parentComment);
                    },
                  ),

                // Option: Copy Text
                ListTile(
                  leading: Icon(
                    Icons.copy_rounded,
                    color: ctx.themeIcon,
                    size: 22,
                  ),
                  title: Text(
                    'Copy text',
                    style: TextStyle(
                      color: ctx.themeTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: comment.content));
                    AppSnackBar.showSuccess(context, title: 'Copied to clipboard');
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

  bool _canCurrentUserComment() {
    final AuthProvider auth = context.read<AuthProvider>();
    final ProfileProvider profile = context.read<ProfileProvider>();
    final String? currentUserId = auth.userId;
    final String? currentUsername =
        profile.profile?.username ?? auth.username;
    final bool isGuest =
        auth.isGuest || currentUserId == null || currentUserId.trim().isEmpty;
    if (isGuest) {
      return false;
    }

    // 1. Author can ALWAYS comment on their own post
    final bool isAuthor = (widget.postAuthorId != null &&
            widget.postAuthorId!.trim().isNotEmpty &&
            currentUserId.trim().toLowerCase() ==
                widget.postAuthorId!.trim().toLowerCase()) ||
        (widget.authorUsername != null &&
            widget.authorUsername!.trim().isNotEmpty &&
            currentUsername != null &&
            currentUsername.trim().isNotEmpty &&
            widget.authorUsername!.replaceAll('@', '').trim().toLowerCase() ==
                currentUsername.replaceAll('@', '').trim().toLowerCase());

    if (isAuthor) {
      return true;
    }

    // 2. If allowComments is false, no one else can comment
    if (!widget.allowComments) {
      return false;
    }

    final String mode = widget.allowCommentsFrom.toLowerCase().trim();

    // 3. Mode: "nobody" -> only author can comment
    if (mode == 'nobody') {
      return false;
    }

    // 4. Mode: "everyone" -> all authenticated users can comment
    if (mode.isEmpty || mode == 'everyone') {
      return true;
    }

    final bool isViewerFollowingAuthor = profile.isFollowingUser(
            userId: widget.postAuthorId, username: widget.authorUsername) ||
        UserRelationshipCache.isFollowing(
            userId: widget.postAuthorId, username: widget.authorUsername);

    final bool isAuthorFollowingViewer = profile.isFollower(
            userId: widget.postAuthorId, username: widget.authorUsername) ||
        UserRelationshipCache.isFollowedBy(
            userId: widget.postAuthorId, username: widget.authorUsername);

    // 5. Mode: "following" -> users followed by author can comment
    if (mode == 'following') {
      return isAuthorFollowingViewer;
    }

    // 6. Mode: "mutual" -> mutual followers can comment
    if (mode == 'mutual') {
      return isAuthorFollowingViewer && isViewerFollowingAuthor;
    }

    return true;
  }

  String _getCommentsRestrictionMessage() {
    final AuthProvider auth = context.read<AuthProvider>();
    if (auth.isGuest || auth.userId == null || auth.userId!.trim().isEmpty) {
      return 'Sign in to join the conversation.';
    }
    if (!widget.allowComments) {
      return 'Comments are disabled for this post.';
    }
    final String mode = widget.allowCommentsFrom.toLowerCase().trim();
    if (mode == 'nobody') {
      return 'Comments are turned off for this post.';
    }
    if (mode == 'following') {
      return 'Only users followed by the author can comment.';
    }
    if (mode == 'mutual') {
      return 'Only mutual followers can comment on this post.';
    }
    return 'Comments are restricted for this post.';
  }

  Future<void> _addNewComment() async {
    if (!_canCurrentUserComment()) return;
    final String text = _commentInputController.text.trim();
    if (text.isEmpty || _isSubmittingComment) return;

    final CommentItemModel? targetReply = _replyingToComment;
    final String? parentId = targetReply != null
        ? (targetReply.parentId ?? targetReply.id)
        : null;

    final String tempId = 'c_${DateTime.now().millisecondsSinceEpoch}';
    final AuthProvider auth = context.read<AuthProvider>();
    final String myUserId = auth.userId ?? '';
    final String myUsername = _resolveCurrentUserName();
    final String myAvatar = _resolveCurrentUserAvatar() ?? '';

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
    widget.onCommentCountChanged?.call(_totalCommentsCount);
    _syncGlobalCommentCount(_totalCommentsCount);

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
                                onReplyTap: _canCurrentUserComment()
                                    ? () => _startReply(item)
                                    : null,
                                canDelete: _canDeleteComment(item),
                                onDeleteTap: () => _confirmDeleteComment(item),
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
                                          onReplyTap: _canCurrentUserComment()
                                              ? () => _startReply(item)
                                              : null,
                                          canDelete: _canDeleteComment(reply),
                                          onDeleteTap: () => _confirmDeleteComment(reply,
                                              parentComment: item),
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
            if (_canCurrentUserComment())
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Row(
                  children: <Widget>[
                    // Current User Avatar
                    Builder(
                      builder: (BuildContext ctx) {
                        final String? avatar =
                            _resolveCurrentUserAvatar(watchContext: ctx);
                        if (avatar == null || avatar.trim().isEmpty) {
                          return const SizedBox.shrink();
                        }
                        final String cleanAvatar = avatar.trim();
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: ClipOval(
                            child: cleanAvatar.startsWith('http')
                                ? Image.network(
                                    cleanAvatar,
                                    width: 36,
                                    height: 36,
                                    cacheWidth: 108,
                                    cacheHeight: 108,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) =>
                                        const SizedBox.shrink(),
                                  )
                                : (cleanAvatar.startsWith('assets/')
                                    ? Image.asset(
                                        cleanAvatar,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, _, _) =>
                                            const SizedBox.shrink(),
                                      )
                                    : const SizedBox.shrink()),
                          ),
                        );
                      },
                    ),

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
                    Flexible(
                      child: Text(
                        _getCommentsRestrictionMessage(),
                        style: TextStyle(
                          color: context.themeTextMuted,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
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
    this.canDelete = false,
    this.onDeleteTap,
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
  final bool canDelete;
  final VoidCallback? onDeleteTap;
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
      onLongPress: () {
        HapticFeedback.mediumImpact();
        onLongPress();
      },
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
                        if (onReplyTap != null) ...<Widget>[
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
                        ],

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

                        if (canDelete && onDeleteTap != null) ...<Widget>[
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: onDeleteTap,
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.redAccent.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
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
                    if (comment.likesCount > 0) ...<Widget>[
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

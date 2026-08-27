import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/screens/user_profile_screen.dart';
import 'report_comment_bottom_sheet.dart';

class CommentItemModel {
  CommentItemModel({
    required this.id,
    required this.avatarAsset,
    required this.username,
    required this.timeAgo,
    required this.content,
    this.likesCount = 0,
    this.isLiked = false,
    this.isAuthorReply = false,
    this.authorReplyText,
    this.authorReplyUser,
    this.authorReplyAvatar,
    this.moderationReason,
  });

  final String id;
  final String avatarAsset;
  final String username;
  final String timeAgo;
  final String content;
  int likesCount;
  bool isLiked;
  final bool isAuthorReply;
  final String? authorReplyText;
  final String? authorReplyUser;
  final String? authorReplyAvatar;
  final String? moderationReason;
}

class CommentsBottomSheet extends StatefulWidget {
  const CommentsBottomSheet({
    required this.totalComments,
    this.isAnswers = false,
    super.key,
  });

  final int totalComments;
  final bool isAnswers;

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentInputController =
      TextEditingController();

  late final List<CommentItemModel> _comments;
  final List<CommentItemModel> _hiddenComments = <CommentItemModel>[];

  @override
  void initState() {
    super.initState();
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
      CommentItemModel(
        id: 'c3',
        avatarAsset: AppImages.user3,
        username: 'moss.and.oat',
        timeAgo: '1h',
        content:
            "Sending this to my sister, she's four weeks post-op today.",
        likesCount: 214,
      ),
      CommentItemModel(
        id: 'c4',
        avatarAsset: AppImages.user4,
        username: 'moss.and.oat',
        timeAgo: '1h',
        content:
            "Sending this to my sister, she's four weeks post-op today.",
        likesCount: 214,
      ),
    ];

    _hiddenComments.add(
      CommentItemModel(
        id: 'hidden_1',
        avatarAsset: AppImages.user1,
        username: 'anonymous_user',
        timeAgo: '3h',
        content:
            'This comment contains sensitive language and was automatically filtered.',
        likesCount: 3,
        moderationReason: 'Flagged by community guidelines filter',
      ),
    );
  }

  @override
  void dispose() {
    _commentInputController.dispose();
    super.dispose();
  }

  void _toggleLikeComment(CommentItemModel comment) {
    setState(() {
      comment.isLiked = !comment.isLiked;
      if (comment.isLiked) {
        comment.likesCount += 1;
      } else {
        comment.likesCount = (comment.likesCount - 1).clamp(0, 999999);
      }
    });
  }

  void _hideComment(CommentItemModel comment) {
    final String typeName = widget.isAnswers ? 'Answer' : 'Comment';
    setState(() {
      _comments.removeWhere((CommentItemModel c) => c.id == comment.id);
      _hiddenComments.add(comment);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$typeName from @${comment.username} hidden'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF2C2836),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _unhideComment(CommentItemModel comment) {
    setState(() {
      _hiddenComments.removeWhere((CommentItemModel c) => c.id == comment.id);
      _comments.add(comment);
    });
  }

  void _showCommentOptionsModal(CommentItemModel comment) {
    final String typeName = widget.isAnswers ? 'Answer' : 'Comment';
    final String typeNameLower = widget.isAnswers ? 'answer' : 'comment';
    final String typeNamePluralLower =
        widget.isAnswers ? 'answers' : 'comments';

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
                      username: comment.username,
                      commentText: comment.content,
                      avatarAsset: comment.avatarAsset,
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$typeName copied to clipboard'),
                        duration: const Duration(seconds: 2),
                        backgroundColor: const Color(0xFF2C2836),
                        behavior: SnackBarBehavior.floating,
                      ),
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
                                      child: Image.asset(
                                        item.avatarAsset,
                                        width: 36,
                                        height: 36,
                                        fit: BoxFit.cover,
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

  void _addNewComment() {
    final String text = _commentInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _comments.insert(
          0,
          CommentItemModel(
            id: 'c_${DateTime.now().millisecondsSinceEpoch}',
            avatarAsset: AppImages.user4,
            username: 'you',
            timeAgo: 'Just now',
            content: text,
            likesCount: 0,
          ),
        );
        _commentInputController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final String titleText = widget.isAnswers
        ? '${_comments.length} answers'
        : '${_comments.length} ${l10n.commentsTitle.toLowerCase()}';

    final String placeholderText = widget.isAnswers
        ? 'Add a your answer...'
        : l10n.commentPlaceholder;

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
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                children: <Widget>[
                  for (final CommentItemModel item in _comments) ...<Widget>[
                    _CommentItemTile(
                      comment: item,
                      onLikeToggle: () => _toggleLikeComment(item),
                      onLongPress: () => _showCommentOptionsModal(item),
                      replyLabel: l10n.commentReply,
                      reportLabel: l10n.commentReport,
                      authorLabel: l10n.commentAuthor,
                    ),
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
                                : AppColors.gradientCyan.withValues(alpha: 0.45),
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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

            // ── Bottom Fixed Input Bar ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  // Current User Avatar
                  ClipOval(
                    child: Image.asset(
                      AppImages.user4,
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Reusable AppTextField Widget
                  Expanded(
                    child: AppTextField(
                      controller: _commentInputController,
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
                        child: SvgPicture.asset(
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
    required this.replyLabel,
    required this.reportLabel,
    required this.authorLabel,
  });

  final CommentItemModel comment;
  final VoidCallback onLikeToggle;
  final VoidCallback onLongPress;
  final String replyLabel;
  final String reportLabel;
  final String authorLabel;

  @override
  Widget build(BuildContext context) {
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
                onTap: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => UserProfileScreen(
                        username: comment.username.replaceAll('@', ''),
                        name: comment.username
                            .replaceAll('@', '')
                            .split('.')
                            .first,
                        avatarAsset: comment.avatarAsset,
                      ),
                    ),
                  );
                },
                child: ClipOval(
                  child: Image.asset(
                    comment.avatarAsset,
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
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
                          onTap: () {
                            Navigator.push<void>(
                              context,
                              MaterialPageRoute<void>(
                                builder: (_) => UserProfileScreen(
                                  username:
                                      comment.username.replaceAll('@', ''),
                                  name: comment.username
                                      .replaceAll('@', '')
                                      .split('.')
                                      .first,
                                  avatarAsset: comment.avatarAsset,
                                ),
                              ),
                            );
                          },
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
                          onTap: () {},
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
                              username: comment.username,
                              commentText: comment.content,
                              avatarAsset: comment.avatarAsset,
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
                      comment.isLiked ? AppIcons.likedLogo : AppIcons.unlikeLogo,
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

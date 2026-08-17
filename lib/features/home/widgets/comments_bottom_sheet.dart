import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../l10n/app_localizations.dart';
import 'report_comment_bottom_sheet.dart';

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

  @override
  void dispose() {
    _commentInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    final String titleText = widget.isAnswers
        ? '${widget.totalComments} answers'
        : '${widget.totalComments} ${l10n.commentsTitle.toLowerCase()}';

    final String placeholderText = widget.isAnswers
        ? 'Add a your answer...'
        : l10n.commentPlaceholder;

    return Container(
      height: MediaQuery.of(context).size.height * 0.72,
      decoration: const BoxDecoration(
        color: AppColors.bottomSheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                  color: Colors.white24,
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white54,
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
                  // Item 1: jules.does
                  _CommentItemTile(
                    avatarAsset: AppImages.user1,
                    username: 'jules.does',
                    timeAgo: '2h',
                    content:
                        'Six months looks so good on you. The scar care tips in your last video actually saved me.',
                    likesCount: 214,
                    replyLabel: l10n.commentReply,
                    reportLabel: l10n.commentReport,
                  ),

                  if (!widget.isAnswers) ...<Widget>[
                    const SizedBox(height: 12),
                    // Author Reply (Comments Mode Only)
                    Padding(
                      padding: const EdgeInsets.only(left: 44),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          ClipOval(
                            child: Image.asset(
                              AppImages.user2,
                              width: 28,
                              height: 28,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    const Text(
                                      'rowankeeps',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient:
                                            AppColors.secondaryGradientButton,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        l10n.commentAuthor,
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
                                const Text(
                                  "that's the whole reason I post them 🤍",
                                  style: TextStyle(
                                    color: Colors.white,
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

                  const SizedBox(height: AppSpacing.lg),

                  // Item 2: moss.and.oat
                  _CommentItemTile(
                    avatarAsset: AppImages.user2,
                    username: 'moss.and.oat',
                    timeAgo: '1h',
                    content:
                        "Sending this to my sister, she's four weeks post-op today.",
                    likesCount: 214,
                    replyLabel: l10n.commentReply,
                    reportLabel: l10n.commentReport,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Item 3: moss.and.oat
                  _CommentItemTile(
                    avatarAsset: AppImages.user3,
                    username: 'moss.and.oat',
                    timeAgo: '1h',
                    content:
                        "Sending this to my sister, she's four weeks post-op today.",
                    likesCount: 214,
                    replyLabel: l10n.commentReply,
                    reportLabel: l10n.commentReport,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // Item 4: moss.and.oat
                  _CommentItemTile(
                    avatarAsset: AppImages.user4,
                    username: 'moss.and.oat',
                    timeAgo: '1h',
                    content:
                        "Sending this to my sister, she's four weeks post-op today.",
                    likesCount: 214,
                    replyLabel: l10n.commentReply,
                    reportLabel: l10n.commentReport,
                  ),

                  if (!widget.isAnswers) ...<Widget>[
                    const SizedBox(height: AppSpacing.lg),
                    // Hidden Comment Warning Card (Comments Mode Only)
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          const Icon(
                            Icons.visibility_off_outlined,
                            color: Colors.white54,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  l10n.commentHiddenTitle,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.commentHiddenSub,
                                  style: const TextStyle(
                                    color: Colors.white54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.lg),
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
                    onTap: () {
                      if (_commentInputController.text.trim().isNotEmpty) {
                        _commentInputController.clear();
                      }
                    },
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
    required this.avatarAsset,
    required this.username,
    required this.timeAgo,
    required this.content,
    required this.likesCount,
    required this.replyLabel,
    required this.reportLabel,
  });

  final String avatarAsset;
  final String username;
  final String timeAgo;
  final String content;
  final int likesCount;
  final String replyLabel;
  final String reportLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ClipOval(
          child: Image.asset(
            avatarAsset,
            width: 36,
            height: 36,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    timeAgo,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                content,
                style: const TextStyle(
                  color: Colors.white,
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
                      style: const TextStyle(
                        color: Colors.white54,
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
                        username: username,
                        commentText: content,
                        avatarAsset: avatarAsset,
                      );
                    },
                    child: Text(
                      reportLabel,
                      style: const TextStyle(
                        color: Colors.white54,
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
        Column(
          children: <Widget>[
            Image.asset(
              AppIcons.unlikeLogo,
              width: 22,
              height: 22,
            ),
            const SizedBox(height: 2),
            Text(
              '$likesCount',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

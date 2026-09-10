import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../create_post/widgets/custom_gradient_switch.dart';
import '../../messages/widgets/report_sent_modal_dialog.dart';
import '../../reports/models/report_models.dart';
import '../../reports/provider/report_provider.dart';

class ReportCommentBottomSheet extends StatefulWidget {
  const ReportCommentBottomSheet({
    required this.username,
    required this.commentText,
    this.commentId,
    this.authorId,
    this.communityId,
    this.avatarAsset = AppImages.user1,
    super.key,
  });

  final String username;
  final String commentText;
  final String? commentId;
  final String? authorId;
  final String? communityId;
  final String avatarAsset;

  static Future<void> show(
    BuildContext context, {
    required String username,
    required String commentText,
    String? commentId,
    String? authorId,
    String? communityId,
    String avatarAsset = AppImages.user1,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportCommentBottomSheet(
        username: username,
        commentText: commentText,
        commentId: commentId,
        authorId: authorId,
        communityId: communityId,
        avatarAsset: avatarAsset,
      ),
    );
  }

  @override
  State<ReportCommentBottomSheet> createState() =>
      _ReportCommentBottomSheetState();
}

class _ReportCommentBottomSheetState extends State<ReportCommentBottomSheet> {
  int _selectedReasonIndex = 2; // Default: Harassment or bullying
  bool _alsoBlock = false;

  // All 8 server-supported reasons.
  static const List<ReportReason> _reasons = <ReportReason>[
    ReportReason.threats,
    ReportReason.selfHarm,
    ReportReason.harassment,
    ReportReason.hateSpeech,
    ReportReason.spam,
    ReportReason.outing,
    ReportReason.sexualContent,
    ReportReason.other,
  ];

  @override
  Widget build(BuildContext context) {
    final String cleanUsername =
        widget.username.startsWith('@') ? widget.username : '@${widget.username}';

    return Container(
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Drag handle
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

              const SizedBox(height: AppSpacing.lg),

              // Header Row (Back Chevron < + Title)
              Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: context.themeIcon,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Why are you reporting this comment?',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Reported Comment Preview Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: context.themeCardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: context.themeBorder,
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    ClipOval(
                      child: widget.avatarAsset.startsWith('http')
                          ? Image.network(
                              widget.avatarAsset,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.person, size: 32),
                            )
                          : Image.asset(
                              widget.avatarAsset.isNotEmpty
                                  ? widget.avatarAsset
                                  : AppImages.user1,
                              width: 32,
                              height: 32,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  const Icon(Icons.person, size: 32),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            '$cleanUsername commented',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.themeTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '"${widget.commentText}"',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: context.themeTextMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Reason Option Tiles List
              ...List<Widget>.generate(_reasons.length, (int index) {
                final ReportReason reason = _reasons[index];
                final bool isSelected = _selectedReasonIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedReasonIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: context.themeCardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gradientCyan
                            : context.themeBorder,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          reason.label,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.themeTextPrimary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                        Icon(
                          isSelected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          color: isSelected
                              ? AppColors.gradientCyan
                              : context.themeBorderStrong,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.md),

              // Also block @username toggle card
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: context.themeCardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: context.themeBorder,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Also block $cleanUsername',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: context.themeTextSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    CustomGradientSwitch(
                      value: _alsoBlock,
                      onChanged: (bool val) => setState(() => _alsoBlock = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Send report button
              Consumer<ReportProvider>(
                builder: (BuildContext ctx, ReportProvider reportProvider, _) {
                  return AppGradientButton(
                    text: reportProvider.isSubmitting ? 'Sending...' : 'Send report',
                    isLoading: reportProvider.isSubmitting,
                    isEnabled: !reportProvider.isSubmitting,
                    onPressed: () async {
                            final ScaffoldMessengerState messenger =
                                ScaffoldMessenger.of(context);

                            final String effectiveTargetId =
                                widget.commentId ?? widget.username;
                            final String effectiveOwnerId =
                                widget.authorId ?? widget.username;

                            final String? displayId =
                                await reportProvider.submitReport(
                              CreateReportRequest(
                                targetType: ReportTargetType.comment,
                                targetId: effectiveTargetId,
                                targetOwnerId: effectiveOwnerId,
                                reason: _reasons[_selectedReasonIndex],
                                communityId: widget.communityId,
                              ),
                            );

                            if (!context.mounted) return;
                            Navigator.pop(context);

                            ReportSentModalDialog.show(
                              context,
                              username: widget.username,
                              reportId: displayId ?? 'QL-00000',
                            );

                            if (_alsoBlock) {
                              AppSnackBar.show(
                                context,
                                messenger: messenger,
                                title: '${widget.username} blocked',
                                subtitle:
                                    'Their posts and comments are gone from your app',
                                actionLabel: 'Undo',
                              );
                            }
                          },
                  );
                },
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

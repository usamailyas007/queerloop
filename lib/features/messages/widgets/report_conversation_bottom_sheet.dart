import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../create_post/widgets/custom_gradient_switch.dart';
import '../../reports/models/report_models.dart';
import '../../reports/provider/report_provider.dart';
import 'report_sent_modal_dialog.dart';

class ReportConversationBottomSheet extends StatefulWidget {
  const ReportConversationBottomSheet({
    required this.username,
    required this.onReportSubmitted,
    this.targetTitle,
    this.targetType = ReportTargetType.post,
    this.targetId,
    this.targetOwnerId,
    this.communityId,
    this.thumbnailAsset = '',
    super.key,
  });

  final String username;
  final VoidCallback onReportSubmitted;
  final String? targetTitle;
  final ReportTargetType targetType;
  final String? targetId;
  final String? targetOwnerId;
  final String? communityId;
  final String thumbnailAsset;

  static Future<void> show(
    BuildContext context, {
    required String username,
    required VoidCallback onReportSubmitted,
    String? targetTitle,
    ReportTargetType targetType = ReportTargetType.post,
    String? targetId,
    String? targetOwnerId,
    String? communityId,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportConversationBottomSheet(
        username: username,
        onReportSubmitted: onReportSubmitted,
        targetTitle: targetTitle,
        targetType: targetType,
        targetId: targetId,
        targetOwnerId: targetOwnerId,
        communityId: communityId,
      ),
    );
  }

  @override
  State<ReportConversationBottomSheet> createState() =>
      _ReportConversationBottomSheetState();
}

class _ReportConversationBottomSheetState
    extends State<ReportConversationBottomSheet> {
  int _selectedIndex = 2; // Default: Harassment or bullying
  bool _alsoBlock = false;

  // Ordered list of reasons exposed in this sheet (all 8 server reasons).
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
    final String displayTargetTitle =
        widget.targetTitle ?? "Reporting $cleanUsername's post";

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
              // Drag handle bar
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

              // Header Row (Back Chevron < + Title "Why are you reporting this?")
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
                      'Why are you reporting this?',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: context.themeTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Target Info Card Header (Thumbnail + Title + Subtitle)
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
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: widget.thumbnailAsset.startsWith('http')
                          ? Image.network(
                              widget.thumbnailAsset,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => Container(
                                width: 36,
                                height: 36,
                                color: const Color(0xFF0F2F34),
                                child: const Icon(
                                  Icons.report_problem_rounded,
                                  color: AppColors.gradientCyan,
                                  size: 20,
                                ),
                              ),
                            )
                          : Image.asset(
                              widget.thumbnailAsset,
                              width: 36,
                              height: 36,
                              fit: BoxFit.cover,
                              errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) => Container(
                                width: 36,
                                height: 36,
                                color: const Color(0xFF0F2F34),
                                child: const Icon(
                                  Icons.report_problem_rounded,
                                  color: AppColors.gradientCyan,
                                  size: 20,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            displayTargetTitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: context.themeTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'A moderator reads every report',
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

              // Radio Option Cards List
              ...List<Widget>.generate(_reasons.length, (int index) {
                final ReportReason reason = _reasons[index];
                final bool isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md - 2,
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
                  vertical: AppSpacing.xs + 2,
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
                                widget.targetId ?? widget.username;
                            final String effectiveOwnerId =
                                widget.targetOwnerId ?? widget.username;

                            final String? displayId =
                                await reportProvider.submitReport(
                              CreateReportRequest(
                                targetType: widget.targetType,
                                targetId: effectiveTargetId,
                                targetOwnerId: effectiveOwnerId,
                                reason: _reasons[_selectedIndex],
                                communityId: widget.communityId,
                              ),
                            );

                            if (!context.mounted) return;
                            Navigator.pop(context);
                            widget.onReportSubmitted();

                            ReportSentModalDialog.show(
                              context,
                              username: widget.username,
                              reportId: displayId ?? 'QL-00000',
                            );

                            if (_alsoBlock) {
                              AppSnackBar.show(
                                context,
                                messenger: messenger,
                                title: '$cleanUsername blocked',
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

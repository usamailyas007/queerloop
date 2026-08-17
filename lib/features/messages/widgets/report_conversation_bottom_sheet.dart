import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../create_post/widgets/custom_gradient_switch.dart';
import 'report_sent_modal_dialog.dart';

class ReportConversationBottomSheet extends StatefulWidget {
  const ReportConversationBottomSheet({
    required this.username,
    required this.onReportSubmitted,
    this.targetTitle,
    this.thumbnailAsset = AppImages.forYouImg,
    super.key,
  });

  final String username;
  final VoidCallback onReportSubmitted;
  final String? targetTitle;
  final String thumbnailAsset;

  static Future<void> show(
    BuildContext context, {
    required String username,
    required VoidCallback onReportSubmitted,
    String? targetTitle,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportConversationBottomSheet(
        username: username,
        onReportSubmitted: onReportSubmitted,
        targetTitle: targetTitle,
      ),
    );
  }

  @override
  State<ReportConversationBottomSheet> createState() =>
      _ReportConversationBottomSheetState();
}

class _ReportConversationBottomSheetState
    extends State<ReportConversationBottomSheet> {
  int _selectedIndex = 1; // Default: Harassment or bullying
  bool _alsoBlock = false;

  static const List<String> _reasons = <String>[
    'Hate speech or slurs',
    'Harassment or bullying',
    'Outing someone without consent',
    'Sexual content or nudity',
    'Violence or threats',
    'Spam or a fake account',
  ];

  @override
  Widget build(BuildContext context) {
    final String cleanUsername =
        widget.username.startsWith('@') ? widget.username : '@${widget.username}';
    final String displayTargetTitle =
        widget.targetTitle ?? "Reporting $cleanUsername's post";

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomSheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: Colors.white24,
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
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'Why are you reporting this?',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
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
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
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
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'A moderator reads every report',
                            style: AppTextStyles.bodySmall.copyWith(
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

              const SizedBox(height: AppSpacing.lg),

              // Radio Option Cards List
              ...List<Widget>.generate(_reasons.length, (int index) {
                final String reason = _reasons[index];
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
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.gradientCyan
                            : Colors.white.withValues(alpha: 0.08),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          reason,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
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
                              : Colors.white24,
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
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      'Also block $cleanUsername',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white70,
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
              AppGradientButton(
                text: 'Send report',
                onPressed: () {
                  final ScaffoldMessengerState messenger =
                      ScaffoldMessenger.of(context);
                  Navigator.pop(context);
                  widget.onReportSubmitted();

                  // Open ReportSentModalDialog matching Image 2
                  ReportSentModalDialog.show(
                    context,
                    username: widget.username,
                    reportId: 'QL-84219',
                  );

                  if (_alsoBlock) {
                    AppSnackBar.show(
                      context,
                      messenger: messenger,
                      title: '$cleanUsername blocked',
                      subtitle: 'Their posts and comments are gone from your app',
                      actionLabel: 'Undo',
                    );
                  }
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

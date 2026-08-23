import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../admin_icons.dart';
import 'admin_conversation_history_screen.dart';

String _formatCompactCount(int n) {
  if (n >= 1000) {
    return '${(n / 1000).toStringAsFixed(1)}K';
  }
  return '$n';
}

class AdminConversationOverviewScreen extends StatefulWidget {
  const AdminConversationOverviewScreen({
    required this.questions,
    required this.onOpenHistory,
    required this.onPublish,
    super.key,
  });

  final List<ConversationQuestion> questions;
  final VoidCallback onOpenHistory;
  final ValueChanged<String> onPublish;

  @override
  State<AdminConversationOverviewScreen> createState() =>
      _AdminConversationOverviewScreenState();
}

class _AdminConversationOverviewScreenState
    extends State<AdminConversationOverviewScreen> {
  late final TextEditingController _questionController = TextEditingController(
    text: _liveQuestion.question,
  );

  ConversationQuestion get _liveQuestion => widget.questions.firstWhere(
    (ConversationQuestion q) => q.isLive,
    orElse: () => widget.questions.first,
  );

  List<ConversationQuestion> get _pastQuestions => widget.questions
      .where((ConversationQuestion q) => !q.isLive)
      .take(3)
      .toList();

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Conversation of the day',
                      style: TextStyle(
                        color: AppColors.adminTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: AppTextField(
                      hintText: 'Search past questions',
                      prefixIconPath: AdminIcons.search,
                      fillColor: AppColors.adminSurface,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 90,
                    child: AppOutlineButton(
                      text: 'History',
                      height: 44,
                      backgroundColor: AppColors.adminSurfaceAlt,
                      onPressed: widget.onOpenHistory,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 160,
                    height: 44,
                    child: AppGradientButton(
                      text: 'Publish new question',
                      textStyle: const TextStyle(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 11,
                    child: Container(
                      padding: const EdgeInsets.all(23),
                      decoration: BoxDecoration(
                        color: AppColors.adminSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.adminBorder,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            "Today's question",
                            style: TextStyle(
                              color: AppColors.adminTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          const Text(
                            'Question',
                            style: TextStyle(
                              color: AppColors.adminTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          AppTextField(
                            controller: _questionController,
                            fillColor: AppColors.adminSurfaceAlt,
                          ),
                          const SizedBox(height: 53),
                          Align(
                            alignment: Alignment.centerRight,
                            child: SizedBox(
                              width: 259,
                              height: 44,
                              child: AppGradientButton(
                                text: 'Publish to everyone',
                                textStyle: const TextStyle(
                                  color: AppColors.textInverse,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                                onPressed: () =>
                                    widget.onPublish(_questionController.text),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    flex: 10,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.adminSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.adminBorder,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text(
                                      'Live now',
                                      style: TextStyle(
                                        color: AppColors.adminTextPrimary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${NumberFormat.decimalPattern().format(_liveQuestion.answers)} answers so far',
                                      style: const TextStyle(
                                        color: AppColors.adminTextMuted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF3FE0AE,
                                  ).withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF3FE0AE,
                                    ).withValues(alpha: 0.1),
                                  ),
                                ),
                                child: const Text(
                                  'Live',
                                  style: TextStyle(
                                    color: AppColors.adminTeal,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(19),
                            decoration: BoxDecoration(
                              color: AppColors.adminSurfaceAlt,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.adminHighlightBorder.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  "TODAY'S QUESTION",
                                  style: TextStyle(
                                    color: AppColors.adminTextMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _liveQuestion.question,
                                  style: const TextStyle(
                                    color: AppColors.adminTextPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          const Text(
                            'Past questions',
                            style: TextStyle(
                              color: AppColors.adminTextPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 10),
                          for (final ConversationQuestion q in _pastQuestions)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      q.question,
                                      style: const TextStyle(
                                        color: AppColors.adminTextPrimary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${_formatCompactCount(q.answers)} answers',
                                    style: const TextStyle(
                                      color: AppColors.adminTextMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

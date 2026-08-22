import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_gradient_button.dart';
import '../../core/widgets/app_outline_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../admin_icons.dart';
import 'admin_conversation_history_screen.dart';

class _PastQuestion {
  const _PastQuestion({required this.question, required this.answers});

  final String question;
  final String answers;
}

class AdminConversationOverviewScreen extends StatefulWidget {
  const AdminConversationOverviewScreen({
    required this.liveQuestion,
    required this.onOpenHistory,
    super.key,
  });

  final ConversationQuestion liveQuestion;
  final VoidCallback onOpenHistory;

  @override
  State<AdminConversationOverviewScreen> createState() =>
      _AdminConversationOverviewScreenState();
}

class _AdminConversationOverviewScreenState
    extends State<AdminConversationOverviewScreen> {
  late final TextEditingController _questionController =
      TextEditingController(text: widget.liveQuestion.question);

  static const List<_PastQuestion> _pastQuestions = <_PastQuestion>[
    _PastQuestion(
      question: "What's a small act of pride you did today?",
      answers: '1.8K answers',
    ),
    _PastQuestion(
      question: 'Who was your first queer friend?',
      answers: '2.6K answers',
    ),
    _PastQuestion(
      question: 'What song makes you feel most yourself?',
      answers: '3.1K answers',
    ),
  ];

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
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
                        color: Color(0xFFF3EFF7),
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
                      fillColor: const Color(0xFF141119),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 90,
                    child: AppOutlineButton(
                      text: 'History',
                      height: 44,
                      backgroundColor: const Color(0xFF1C1824),
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
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 11,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141119),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.09),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              "Today's question",
                              style: TextStyle(
                                color: Color(0xFFF3EFF7),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            const Text(
                              'Question',
                              style: TextStyle(
                                color: Color(0xFF948CA3),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            AppTextField(
                              controller: _questionController,
                              fillColor: const Color(0xFF1C1824),
                            ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: SizedBox(
                                width: 190,
                                height: 44,
                                child: AppGradientButton(
                                  text: 'Publish to everyone',
                                  textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                  ),
                                  onPressed: () {},
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
                          color: const Color(0xFF141119),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.09),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text(
                                        'Live now',
                                        style: TextStyle(
                                          color: Color(0xFFF3EFF7),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${NumberFormat.decimalPattern().format(widget.liveQuestion.answers)} answers so far',
                                        style: const TextStyle(
                                          color: Color(0xFF635C72),
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
                                      ).withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Text(
                                    'Live',
                                    style: TextStyle(
                                      color: Color(0xFF3FE0AE),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: AppSpacing.md),

                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(AppSpacing.md),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1C1824),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    "TODAY'S QUESTION",
                                    style: TextStyle(
                                      color: Color(0xFF635C72),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.liveQuestion.question,
                                    style: const TextStyle(
                                      color: Color(0xFFF3EFF7),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: AppSpacing.lg),

                            const Text(
                              'Past questions',
                              style: TextStyle(
                                color: Color(0xFFF3EFF7),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            for (final _PastQuestion q in _pastQuestions)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Expanded(
                                      child: Text(
                                        q.question,
                                        style: const TextStyle(
                                          color: Color(0xFF948CA3),
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      q.answers,
                                      style: const TextStyle(
                                        color: Color(0xFF635C72),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
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
          ),
        ),
      ),
    );
  }
}

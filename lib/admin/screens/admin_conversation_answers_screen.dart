import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_images.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_gradient_button.dart';
import '../../core/widgets/app_outline_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../admin_icons.dart';
import 'admin_conversation_history_screen.dart';

class _Answer {
  const _Answer({
    required this.handle,
    required this.avatar,
    required this.answer,
    required this.likes,
    required this.postedAgo,
    this.isFlagged = false,
  });

  final String handle;
  final String avatar;
  final String answer;
  final int likes;
  final String postedAgo;
  final bool isFlagged;
}

class AdminConversationAnswersScreen extends StatelessWidget {
  const AdminConversationAnswersScreen({
    required this.question,
    required this.onBack,
    required this.onPublishNew,
    super.key,
  });

  final ConversationQuestion question;
  final VoidCallback onBack;
  final VoidCallback onPublishNew;

  static const List<_Answer> _answers = <_Answer>[
    _Answer(
      handle: '@ashinorbit',
      avatar: AppImages.user1,
      answer: 'The people who show up on the bad days, not just the good ones.',
      likes: 412,
      postedAgo: '2h',
    ),
    _Answer(
      handle: '@rowankeeps',
      avatar: AppImages.user2,
      answer: "My roommates threw me a party the week I came out. That's family.",
      likes: 388,
      postedAgo: '3h',
    ),
    _Answer(
      handle: '@jules.does',
      avatar: AppImages.user1,
      answer: 'Not needing to explain myself twice.',
      likes: 301,
      postedAgo: '4h',
    ),
    _Answer(
      handle: '@dg_returns',
      avatar: AppImages.user3,
      answer: 'go be miserable somewhere else lol',
      likes: 2,
      postedAgo: '5h',
      isFlagged: true,
    ),
  ];

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
              const Text(
                'Conversation of the day /',
                style: TextStyle(color: Color(0xFF635C72), fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Answers',
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
                      onPressed: onBack,
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
                      onPressed: onPublishNew,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                "Answers: '${question.question}'",
                                style: const TextStyle(
                                  color: Color(0xFFF3EFF7),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Shown to users as comments under the question',
                                style: TextStyle(
                                  color: Color(0xFF635C72),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'View all ${NumberFormat.decimalPattern().format(question.answers)}',
                          style: const TextStyle(
                            color: Color(0xFF4CC9FF),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      child: const Row(
                        children: <Widget>[
                          Expanded(flex: 2, child: _Header('PERSON')),
                          Expanded(flex: 4, child: _Header('ANSWER')),
                          Expanded(flex: 1, child: _Header('LIKES')),
                          Expanded(flex: 1, child: _Header('POSTED')),
                          SizedBox(width: 70),
                        ],
                      ),
                    ),
                    for (final _Answer a in _answers)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: <Widget>[
                                  ClipOval(
                                    child: Image.asset(
                                      a.avatar,
                                      width: 26,
                                      height: 26,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      a.handle,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFFF3EFF7),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                a.answer,
                                style: const TextStyle(
                                  color: Color(0xFF948CA3),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${a.likes}',
                                style: const TextStyle(
                                  color: Color(0xFF948CA3),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                a.postedAgo,
                                style: const TextStyle(
                                  color: Color(0xFF948CA3),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 70,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: a.isFlagged
                                      ? const Color(
                                          0xFFFF3B77,
                                        ).withValues(alpha: 0.14)
                                      : const Color(0xFF1C1824),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: a.isFlagged
                                        ? const Color(
                                            0xFFFF3B77,
                                          ).withValues(alpha: 0.4)
                                        : Colors.white.withValues(
                                            alpha: 0.09,
                                          ),
                                  ),
                                ),
                                child: Text(
                                  a.isFlagged ? 'Hide' : 'Feature',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: a.isFlagged
                                        ? const Color(0xFFFF3B77)
                                        : const Color(0xFFF3EFF7),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF635C72),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

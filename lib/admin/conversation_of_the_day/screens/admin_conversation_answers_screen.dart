import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/widgets/app_user_avatar.dart';
import '../../../core/theme/app_colors.dart';

import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../admin_icons.dart';
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
      answer:
          "My roommates threw me a party the week I came out. That's family.",
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
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Conversation of the day /',
                style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Answers',
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
                        color: AppColors.textInverse,
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
                              Text(
                                "Answers: '${question.question}'",
                                style: const TextStyle(
                                  color: AppColors.adminTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Shown to users as comments under the question',
                                style: TextStyle(
                                  color: AppColors.adminTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'View all ${NumberFormat.decimalPattern().format(question.answers)}',
                          style: const TextStyle(
                            color: AppColors.adminBlue,
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
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: AppColors.adminDivider,
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
                                  AppUserAvatar(
                                    imageAsset: a.avatar,
                                    size: 26,
                                    hasGradientBorder: false,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      a.handle,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.adminTextPrimary,
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
                                  color: AppColors.adminTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                '${a.likes}',
                                style: const TextStyle(
                                  color: AppColors.adminTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                a.postedAgo,
                                style: const TextStyle(
                                  color: AppColors.adminTextSecondary,
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
                                  color: AppColors.adminSurfaceAlt,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: a.isFlagged
                                        ? const Color(
                                            0xFFFF8080,
                                          ).withValues(alpha: 0.4)
                                        : AppColors.adminBorder,
                                  ),
                                ),
                                child: Text(
                                  a.isFlagged ? 'Hide' : 'Feature',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: a.isFlagged
                                        ? AppColors.adminPinkLight
                                        : AppColors.adminTextPrimary,
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
        color: AppColors.adminTextMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

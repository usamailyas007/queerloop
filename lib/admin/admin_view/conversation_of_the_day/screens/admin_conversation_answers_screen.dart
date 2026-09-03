import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../models/cotd_models.dart';
import '../provider/cotd_provider.dart';

class AdminConversationAnswersScreen extends StatefulWidget {
  const AdminConversationAnswersScreen({
    required this.onBack,
    required this.onPublishNew,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onPublishNew;

  @override
  State<AdminConversationAnswersScreen> createState() =>
      _AdminConversationAnswersScreenState();
}

class _AdminConversationAnswersScreenState
    extends State<AdminConversationAnswersScreen> {
  void _onError(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
      context.read<CotdProvider>().clearAnswersError();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Consumer<CotdProvider>(
            builder: (_, CotdProvider provider, _) {
              final CotdQuestion? question = provider.selectedQuestion;
              if (provider.answersError != null &&
                  provider.answers.isNotEmpty) {
                _onError(provider.answersError!);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Conversation of the day /',
                    style: TextStyle(
                      color: AppColors.adminTextMuted,
                      fontSize: 12,
                    ),
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
                        width: 100,
                        child: AppOutlineButton(
                          text: 'History',
                          height: 44,
                          backgroundColor: AppColors.adminSurfaceAlt,
                          onPressed: widget.onBack,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SizedBox(
                        width: 170,
                        height: 44,
                        child: AppGradientButton(
                          text: 'Publish new question',
                          textStyle: const TextStyle(
                            color: AppColors.textInverse,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          onPressed: widget.onPublishNew,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.adminSurface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.adminBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            question == null
                                ? 'Answers'
                                : "Answers · '${question.question}'",
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
                          const SizedBox(height: AppSpacing.lg),
                          const _AnswersHeaderRow(),
                          Expanded(child: _AnswersBody(provider: provider)),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _AnswersBody extends StatelessWidget {
  const _AnswersBody({required this.provider});

  final CotdProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingAnswers && provider.answers.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.adminPink,
          ),
        ),
      );
    }
    if (provider.answersError != null && provider.answers.isEmpty) {
      return _Centered(
        message: provider.answersError!,
        onRetry: provider.refreshAnswers,
      );
    }
    if (provider.isAnswersEmpty) {
      return const _Centered(message: 'No answers yet.');
    }

    return RefreshIndicator(
      color: AppColors.adminPink,
      backgroundColor: AppColors.adminSurface,
      onRefresh: provider.refreshAnswers,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.answers.length,
        separatorBuilder: (_, _) =>
            Divider(height: 1, color: AppColors.adminRowDivider),
        itemBuilder: (_, int index) {
          final CotdAnswer a = provider.answers[index];
          return _AnswerRow(
            answer: a,
            busy: provider.isAnswerMutating(a.id),
            onFeature: () => provider.featureAnswer(a.id),
            onHide: () => provider.hideAnswer(a.id),
          );
        },
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.answer,
    required this.busy,
    required this.onFeature,
    required this.onHide,
  });

  final CotdAnswer answer;
  final bool busy;
  final VoidCallback onFeature;
  final VoidCallback onHide;

  static final DateFormat _date = DateFormat('d MMM · h:mm a');

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: answer.hidden ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Row(
                children: <Widget>[
                  _InitialsAvatar(seed: answer.handle),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      answer.handle,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    answer.body,
                    style: const TextStyle(
                      color: AppColors.adminTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                  if (answer.featured || answer.hidden) ...<Widget>[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: <Widget>[
                        if (answer.featured)
                          const _Tag(text: 'Featured', color: AppColors.adminTeal),
                        if (answer.hidden)
                          const _Tag(
                            text: 'Hidden',
                            color: AppColors.adminPinkLight,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                _date.format(answer.createdAt.toLocal()),
                style: const TextStyle(
                  color: AppColors.adminTextMuted,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(
              width: 150,
              child: Align(
                alignment: Alignment.centerRight,
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.adminPink,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _MiniButton(
                            label: 'Feature',
                            color: AppColors.adminTeal,
                            enabled: !answer.featured,
                            onTap: onFeature,
                          ),
                          const SizedBox(width: 6),
                          _MiniButton(
                            label: 'Hide',
                            color: AppColors.adminPinkLight,
                            enabled: !answer.hidden,
                            onTap: onHide,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.adminSurfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _AnswersHeaderRow extends StatelessWidget {
  const _AnswersHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.adminDivider)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 2, child: _Header('PERSON')),
          Expanded(flex: 4, child: _Header('ANSWER')),
          Expanded(flex: 1, child: _Header('POSTED')),
          SizedBox(width: 150),
        ],
      ),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.seed});

  final String seed;

  @override
  Widget build(BuildContext context) {
    final String clean = seed.replaceAll('@', '');
    final String initial =
        clean.isEmpty ? '?' : clean.characters.first.toUpperCase();
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.adminPurple.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.adminPurple.withValues(alpha: 0.5)),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.adminPurple,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.message, this.onRetry});

  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 13,
            ),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 120,
              child: AppOutlineButton(
                text: 'Retry',
                height: 38,
                onPressed: onRetry!,
              ),
            ),
          ],
        ],
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

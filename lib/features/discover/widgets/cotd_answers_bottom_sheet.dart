import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../auth/auth_provider.dart';
import '../models/cotd_models.dart';
import '../provider/cotd_provider.dart';

/// Bottom sheet that shows the Conversation of the Day answers and lets the
/// current user submit their own answer.
class CotdAnswersBottomSheet extends StatefulWidget {
  const CotdAnswersBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider<CotdProvider>.value(
        value: context.read<CotdProvider>(),
        child: const CotdAnswersBottomSheet(),
      ),
    );
  }

  @override
  State<CotdAnswersBottomSheet> createState() => _CotdAnswersBottomSheetState();
}

class _CotdAnswersBottomSheetState extends State<CotdAnswersBottomSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _showInput = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final AuthProvider auth = context.read<AuthProvider>();
        context.read<CotdProvider>().updateUserId(auth.userId);
        context.read<CotdProvider>().fetchAnswers();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final String text = _controller.text.trim();
    if (text.isEmpty) return;
    final bool ok = await context.read<CotdProvider>().submitAnswer(text);
    if (ok && mounted) {
      _controller.clear();
      setState(() => _showInput = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final CotdProvider provider = context.watch<CotdProvider>();
    final CotdQuestion? question = provider.currentQuestion;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color sheetColor =
        isDark ? const Color(0xFF1A1030) : Colors.white;
    final double screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: BoxDecoration(
        color: sheetColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            // ── Drag handle ──────────────────────────────────────────────────
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ── Header ───────────────────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  Text(
                    "TODAY'S ANSWERS",
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.gradientCyan,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  if (question != null)
                    Text(
                      question.formattedAnswerCount,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.5)
                            : Colors.black.withValues(alpha: 0.4),
                      ),
                    ),
                ],
              ),
            ),

            if (question != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  question.body,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],

            const SizedBox(height: AppSpacing.md),
            Divider(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.06),
              height: 1,
            ),

            // ── Answers list ─────────────────────────────────────────────────
            Expanded(
              child: provider.answers.isEmpty && !provider.isLoading
                  ? Center(
                      child: Text(
                        'No answers yet. Be the first!',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.black.withValues(alpha: 0.35),
                        ),
                      ),
                    )
                  : provider.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gradientCyan,
                            strokeWidth: 2,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.sm,
                            horizontal: AppSpacing.lg,
                          ),
                          itemCount: provider.answers.length,
                          separatorBuilder: (BuildContext c, int i) => Divider(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.06)
                                : Colors.black.withValues(alpha: 0.05),
                            height: 1,
                          ),
                          itemBuilder: (BuildContext context, int index) {
                            final CotdAnswer answer = provider.answers[index];
                            return _AnswerTile(
                              answer: answer,
                              isDark: isDark,
                            );
                          },
                        ),
            ),

            // ── Submit section ───────────────────────────────────────────────
            if (question != null)
              _AnswerInputSection(
                controller: _controller,
                showInput: _showInput,
                hasAnswered: provider.hasAnswered,
                isSubmitting: provider.isSubmitting,
                isDark: isDark,
                onToggle: () => setState(() => _showInput = !_showInput),
                onSubmit: _submit,
              ),

            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }
}

class _AnswerTile extends StatelessWidget {
  const _AnswerTile({required this.answer, required this.isDark});

  final CotdAnswer answer;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.gradientPurple.withValues(alpha: 0.3),
            backgroundImage: answer.authorAvatarUrl != null
                ? NetworkImage(answer.authorAvatarUrl!)
                : null,
            child: answer.authorAvatarUrl == null
                ? Text(
                    (answer.displayName.isNotEmpty
                            ? answer.displayName[0]
                            : '?')
                        .toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  answer.displayName,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.9)
                        : Colors.black.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  answer.body,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.6),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AnswerInputSection extends StatelessWidget {
  const _AnswerInputSection({
    required this.controller,
    required this.showInput,
    required this.hasAnswered,
    required this.isSubmitting,
    required this.isDark,
    required this.onToggle,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final bool showInput;
  final bool hasAnswered;
  final bool isSubmitting;
  final bool isDark;
  final VoidCallback onToggle;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final Color borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.06);

    return Column(
      children: <Widget>[
        Divider(color: borderColor, height: 1),
        if (showInput && !hasAnswered)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
            child: TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              minLines: 2,
              style: TextStyle(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.85),
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Share your answer…',
                hintStyle: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.35)
                      : Colors.black.withValues(alpha: 0.3),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.1),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.gradientCyan,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.all(AppSpacing.md),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.md),
          child: hasAnswered
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.gradientCyan.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.gradientCyan.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '\u2713 You have already answered today\'s question',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.gradientCyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : showInput
                  ? AppGradientButton(
                      text: isSubmitting ? 'Submitting…' : 'Submit Answer',
                      onPressed: isSubmitting ? () {} : onSubmit,
                      height: 44,
                      borderRadius: BorderRadius.circular(14),
                    )
                  : AppGradientButton(
                      text: 'Answer',
                      onPressed: onToggle,
                      height: 44,
                      borderRadius: BorderRadius.circular(14),
                    ),
        ),
      ],
    );
  }
}

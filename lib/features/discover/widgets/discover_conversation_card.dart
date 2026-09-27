import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../models/cotd_models.dart';
import '../provider/cotd_provider.dart';
import 'cotd_answers_bottom_sheet.dart';

/// "Conversation of the Day" card — live data from CotdProvider.
class DiscoverConversationCard extends StatelessWidget {
  const DiscoverConversationCard({super.key});

  void _showAnswers(BuildContext context) {
    CotdAnswersBottomSheet.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<CotdProvider>(
      builder: (BuildContext ctx, CotdProvider provider, _) {
        final CotdQuestion? question = provider.currentQuestion;

        // ── Loading skeleton ───────────────────────────────────────────────
        if (provider.isLoading && question == null) {
          return _buildSkeleton(isDark);
        }

        // ── Fallback static card (no data / error) ─────────────────────────
        final String questionText = question?.body.isNotEmpty == true
            ? question!.body
            : 'What does chosen family mean to you?';

        final String subtitle = question?.subtitle ??
            '2,140 people have answered — add your voice, or just read what others said.';

        final String answerCount =
            question?.formattedAnswerCount ?? '2.1K answered';

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: isDark ? null : Colors.white,
            gradient: LinearGradient(
              colors: isDark
                  ? const <Color>[Color(0xFF2A1040), Color(0xFF1A1030)]
                  : const <Color>[
                      Color(0x24FF3B77),
                      Color(0x248B5CFF),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? AppColors.gradientPurple.withValues(alpha: 0.4)
                  : const Color(0xFF8B5CFF).withValues(alpha: 0.25),
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                "TODAY'S QUESTION",
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark
                      ? AppColors.gradientCyan
                      : const Color(0xFF9D7BFF),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                questionText,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.95)
                      : Colors.black.withValues(alpha: 0.85),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.55)
                      : Colors.black.withValues(alpha: 0.5),
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  // Stacked placeholder circles for avatar preview
                  _StackedCircles(isDark: isDark),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    answerCount,
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.55)
                          : Colors.black.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  AppGradientButton(
                    text: provider.hasAnswered ? 'Read' : 'Answer',
                    onPressed: () => _showAnswers(ctx),
                    height: 36,
                    width: 88,
                    borderRadius:
                        BorderRadius.circular(AppRadius.pill),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(bool isDark) {
    return AppShimmer(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1030) : const Color(0xFFF4F4F8),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark
                ? AppColors.gradientPurple.withValues(alpha: 0.2)
                : const Color(0xFF8B5CFF).withValues(alpha: 0.12),
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ShimmerBox(width: 120, height: 10, borderRadius: 4),
            SizedBox(height: AppSpacing.sm),
            ShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
            SizedBox(height: 6),
            ShimmerBox(width: 220, height: 12, borderRadius: 4),
            SizedBox(height: AppSpacing.lg),
            ShimmerBox(width: double.infinity, height: 36, borderRadius: 18),
          ],
        ),
      ),
    );
  }
}

class _StackedCircles extends StatelessWidget {
  const _StackedCircles({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = <Color>[
      AppColors.gradientPink.withValues(alpha: 0.6),
      AppColors.gradientPurple.withValues(alpha: 0.6),
    ];

    return SizedBox(
      width: 48,
      height: 28,
      child: Stack(
        children: List<Widget>.generate(2, (int i) {
          return Positioned(
            left: i * 20.0,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors[i],
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A1040)
                      : Colors.white,
                  width: 2,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

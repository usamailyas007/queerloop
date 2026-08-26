import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../auth/widgets/auth_back_button.dart';

class StepProgressHeader extends StatelessWidget {
  const StepProgressHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    this.onSkip,
    super.key,
  });

  final int currentStep; // 1-indexed (1..5)
  final int totalSteps; // 5
  final VoidCallback onBack;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            AuthBackButton(onTap: onBack),
            Text(
              'STEP $currentStep OF $totalSteps',
              style: TextStyle(
                color: context.themeTextMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            onSkip != null
                ? GestureDetector(
                    onTap: onSkip,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: List<Widget>.generate(totalSteps, (int index) {
            final bool isFilled = index < currentStep;
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(
                  right: index < totalSteps - 1 ? 6.0 : 0.0,
                ),
                decoration: BoxDecoration(
                  color: isFilled
                      ? AppColors.gradientPink
                      : context.themeBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

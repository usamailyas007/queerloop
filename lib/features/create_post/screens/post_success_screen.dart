import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../../core/widgets/app_outline_button.dart';
import '../../../core/widgets/success_animation_circle.dart';

class PostSuccessScreen extends StatelessWidget {
  const PostSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              // Compact Success Animation (Tight container to eliminate empty Lottie canvas margin)
              Center(child: SuccessAnimationCircle(size: 300)),

              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                'Posted',
                style: AppTextStyles.headingMedium.copyWith(fontSize: 22),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Subtitle
              Text(
                "Your post is live. It's visible to\nthe audience you picked on the\nlast screen.",
                textAlign: TextAlign.center,
                style: AppTextStyles.authHeaderSub.copyWith(
                  color: Colors.white54,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: AppSpacing.xl),
              // View post button
              AppGradientButton(
                text: 'View post',
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
                },
              ),

              const SizedBox(height: AppSpacing.md),

              // Back to feed button
              AppOutlineButton(
                text: 'Back to feed',
                onPressed: () {
                  Navigator.popUntil(context, (route) => route.isFirst);
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

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_gradient_button.dart';
import '../../home/widgets/comments_bottom_sheet.dart';

/// "Conversation of the Day" card with question, avatars, and Answer button.
class DiscoverConversationCard extends StatelessWidget {
  const DiscoverConversationCard({super.key});

  void _showAnswersBottomSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return const CommentsBottomSheet(totalComments: 842, isAnswers: true);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2A1040), Color(0xFF1A1030)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(
          color: AppColors.gradientPurple.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            "TODAY'S QUESTION",
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.gradientCyan,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'What does chosen family mean to you?',
            style: AppTextStyles.titleSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '5.1K people from over mid — add your voice, or see what others said',
            style: AppTextStyles.bodySmall.copyWith(
              color: Colors.white54,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              // Stacked avatars
              SizedBox(
                width: 72,
                height: 26,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      child: _StackedAvatar(imageAsset: AppImages.user1),
                    ),
                    Positioned(
                      left: 18,
                      child: _StackedAvatar(imageAsset: AppImages.user2),
                    ),
                    Positioned(
                      left: 36,
                      child: _StackedAvatar(imageAsset: AppImages.user3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '2.1K answered',
                style:
                    AppTextStyles.bodySmall.copyWith(color: Colors.white54),
              ),
              const Spacer(),
              AppGradientButton(
                text: 'Answer',
                onPressed: () => _showAnswersBottomSheet(context),
                height: 34,
                width: 80,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StackedAvatar extends StatelessWidget {
  const _StackedAvatar({required this.imageAsset});

  final String imageAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF2A1040), width: 2),
      ),
      child: ClipOval(
        child: Image.asset(
          imageAsset,
          width: 24,
          height: 24,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

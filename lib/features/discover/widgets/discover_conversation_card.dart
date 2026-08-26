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
    final bool isDark = context.isDarkMode;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? null : Colors.white,
        gradient: LinearGradient(
          colors: isDark
              ? const <Color>[Color(0xFF2A1040), Color(0xFF1A1030)]
              : const <Color>[
                  Color(0x24FF3B77), // #FF3B77 with 14% opacity
                  Color(0x248B5CFF), // #8B5CFF with 14% opacity
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
            'What does chosen family mean to you?',
            style: TextStyle(
              color: context.themeTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '2,140 people have answered — add your voice, or just read what others said.',
            style: TextStyle(
              color: context.themeTextSecondary,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              // Stacked overlapping avatars
              SizedBox(
                width: 48,
                height: 28,
                child: Stack(
                  children: <Widget>[
                    Positioned(
                      left: 0,
                      child: _StackedAvatar(
                        imageAsset: AppImages.user1,
                        borderColor: isDark
                            ? const Color(0xFF2A1040)
                            : const Color(0xFF1E1B26),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      child: _StackedAvatar(
                        imageAsset: AppImages.user2,
                        borderColor: isDark
                            ? const Color(0xFF2A1040)
                            : const Color(0xFF1E1B26),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '2.1K answered',
                style: TextStyle(
                  color: context.themeTextSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              AppGradientButton(
                text: 'Answer',
                onPressed: () => _showAnswersBottomSheet(context),
                height: 36,
                width: 88,
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
  const _StackedAvatar({
    required this.imageAsset,
    required this.borderColor,
  });

  final String imageAsset;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
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

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Read-only search bar — tapping navigates to SearchScreen.
class DiscoverStaticSearchBar extends StatelessWidget {
  const DiscoverStaticSearchBar({required this.hint, super.key});

  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSizes.fieldHeight,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: AppSpacing.md),
          SvgPicture.asset(
            AppIcons.search,
            width: AppSizes.iconMd,
            height: AppSizes.iconMd,
            colorFilter: const ColorFilter.mode(
              Colors.white38,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(hint, style: AppTextStyles.inputHintText),
        ],
      ),
    );
  }
}

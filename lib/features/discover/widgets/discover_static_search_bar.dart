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
        color: context.themeCardBackground,
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(width: AppSpacing.md),
          SvgPicture.asset(
            AppIcons.search,
            width: AppSizes.iconMd,
            height: AppSizes.iconMd,
            colorFilter: ColorFilter.mode(
              context.themeIconMuted,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            hint,
            style: AppTextStyles.inputHintText.copyWith(
              color: context.themeTextMuted,
            ),
          ),
        ],
      ),
    );
  }
}

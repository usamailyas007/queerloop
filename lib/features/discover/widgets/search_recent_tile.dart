import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// A single recent search query row with clock icon and delete button.
class SearchRecentTile extends StatelessWidget {
  const SearchRecentTile({
    required this.query,
    required this.onDelete,
    super.key,
  });

  final String query;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          SvgPicture.asset(
            AppIcons.clock,
            width: AppSizes.iconMd,
            height: AppSizes.iconMd,
            colorFilter: ColorFilter.mode(
              context.themeIconMuted,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              query,
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.themeTextPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: SvgPicture.asset(
              AppIcons.cross,
              width: AppSizes.iconMd,
              height: AppSizes.iconMd,
              colorFilter: ColorFilter.mode(
                context.themeIconMuted,
                BlendMode.srcIn,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

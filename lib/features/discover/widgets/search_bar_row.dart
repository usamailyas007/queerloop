import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';

/// Animated search input row with Cancel button.
/// Uses the app-wide [AppTextField] for consistency.
class SearchBarRow extends StatelessWidget {
  const SearchBarRow({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onCancel,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: AppTextField(
              controller: controller,
              focusNode: focusNode,
              hintText: 'Search here',
              prefixIconPath: AppIcons.search,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          GestureDetector(
            onTap: onCancel,
            child: Text(
              'Cancel',
              style: AppTextStyles.bodyMedium.copyWith(
                color: context.isDarkMode
                    ? AppColors.gradientCyan
                    : context.themeTextPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

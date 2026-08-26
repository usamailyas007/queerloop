import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class AuthDivider extends StatelessWidget {
  const AuthDivider({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Container(
            height: AppSizes.dividerThickness,
            color: context.themeBorder,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            text,
            style: AppTextStyles.authDividerText.copyWith(
              color: context.themeTextMuted,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: AppSizes.dividerThickness,
            color: context.themeBorder,
          ),
        ),
      ],
    );
  }
}

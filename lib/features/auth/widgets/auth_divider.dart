import 'package:flutter/material.dart';
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
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            text,
            style: AppTextStyles.authDividerText,
          ),
        ),
        Expanded(
          child: Container(
            height: AppSizes.dividerThickness,
            color: Colors.white.withValues(alpha: 0.12),
          ),
        ),
      ],
    );
  }
}

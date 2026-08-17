import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppOutlineButton extends StatelessWidget {
  const AppOutlineButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.backgroundColor = AppColors.cardBackground,
    this.borderColor,
    this.textColor = Colors.white,
    this.height = AppSizes.buttonHeight,
    this.width = double.infinity,
  });

  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final Color? borderColor;
  final Color textColor;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: borderColor ?? Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Center(
            child: Text(
              text,
              style: AppTextStyles.buttonText.copyWith(color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

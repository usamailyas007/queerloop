import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppOutlineButton extends StatelessWidget {
  const AppOutlineButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.backgroundColor,
    this.borderColor,
    this.textColor,
    this.height = AppSizes.buttonHeight,
    this.width = double.infinity,
    this.fontSize = 13,
  });

  final String text;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? borderColor;
  final Color? textColor;
  final double height;
  final double width;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final Color effectiveBg = backgroundColor ?? context.themeCardBackground;
    final Color effectiveBorder = borderColor ?? context.themeBorder;
    final Color effectiveText = textColor ?? context.themeTextPrimary;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(
          color: effectiveBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  text,
                  maxLines: 1,
                  style: AppTextStyles.buttonText.copyWith(
                    color: effectiveText,
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class AppTagChip extends StatelessWidget {
  const AppTagChip({
    required this.label,
    super.key,
    this.onTap,
    this.isSelected = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    this.textStyle,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 20.0,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isSelected;
  final EdgeInsetsGeometry padding;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final TextStyle defaultTextStyle = AppTextStyles.bodySmall.copyWith(
      color: Colors.white,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: 0.1,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          gradient: isSelected && backgroundColor == null
              ? AppColors.secondaryGradientButton
              : null,
          color: backgroundColor ??
              (isSelected ? null : const Color(0xFF1E1B26)),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(
            color: borderColor ??
                (isSelected
                    ? Colors.transparent
                    : Colors.white.withValues(alpha: 0.12)),
          ),
        ),
        child: Text(
          label,
          style: textStyle ?? defaultTextStyle,
        ),
      ),
    );
  }
}

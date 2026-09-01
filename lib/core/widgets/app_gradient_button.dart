import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';
import 'shimmer_text.dart';

class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.gradient = AppColors.primaryGradientButton,
    this.height = AppSizes.buttonHeight,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(AppRadius.button)),
    this.textStyle,
    this.fontSize,
    this.isLoading = false,
    this.isEnabled = true,
    this.shimmerLabelWhileLoading = false,
  });

  final String text;
  final VoidCallback onPressed;
  final Gradient gradient;
  final double height;
  final double width;
  final BorderRadiusGeometry borderRadius;
  final TextStyle? textStyle;
  final double? fontSize;
  final bool isLoading;
  final bool isEnabled;

  /// When loading, sweep a shimmer across the label instead of showing a spinner.
  final bool shimmerLabelWhileLoading;

  @override
  Widget build(BuildContext context) {
    final TextStyle resolvedTextStyle = textStyle ??
        (fontSize != null
            ? AppTextStyles.buttonText.copyWith(fontSize: fontSize)
            : AppTextStyles.buttonText);

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.5,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: borderRadius,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppColors.gradientPink.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isEnabled && !isLoading) ? onPressed : null,
            borderRadius: borderRadius is BorderRadius
                ? borderRadius as BorderRadius
                : BorderRadius.circular(AppRadius.button),
            child: Center(
              child: (isLoading && !shimmerLabelWhileLoading)
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: (isLoading && shimmerLabelWhileLoading)
                            ? ShimmerText(
                                text,
                                style: resolvedTextStyle,
                                baseColor:
                                    resolvedTextStyle.color ?? Colors.white,
                              )
                            : Text(
                                text,
                                maxLines: 1,
                                style: resolvedTextStyle,
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

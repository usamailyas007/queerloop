import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({
    required this.normalText,
    required this.highlightedText,
    required this.onTap,
    super.key,
    this.highlightColor = AppColors.gradientPink,
    this.highlightGradient,
  });

  final String normalText;
  final String highlightedText;
  final VoidCallback onTap;
  final Color highlightColor;
  final Gradient? highlightGradient;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(normalText, style: AppTextStyles.authFooterText),
            if (highlightGradient != null)
              ShaderMask(
                shaderCallback: (Rect bounds) =>
                    highlightGradient!.createShader(bounds),
                child: Text(
                  highlightedText,
                  style: AppTextStyles.authFooterLink(color: Colors.white),
                ),
              )
            else
              Text(
                highlightedText,
                style: AppTextStyles.authFooterLink(color: highlightColor),
              ),
          ],
        ),
      ),
    );
  }
}

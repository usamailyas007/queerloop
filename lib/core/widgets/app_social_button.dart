import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

class AppSocialButton extends StatelessWidget {
  const AppSocialButton({
    required this.text,
    required this.onPressed,
    super.key,
    this.iconPath,
    this.icon,
    this.height = AppSizes.buttonHeight,
    this.width = double.infinity,
  });

  final String text;
  final VoidCallback onPressed;
  final String? iconPath;
  final Widget? icon;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    Widget? leadingIcon;
    if (iconPath != null) {
      final bool isSvg = iconPath!.endsWith('.svg');
      if (isSvg) {
        leadingIcon = SvgPicture.asset(
          iconPath!,
          width: AppSizes.iconMd,
          height: AppSizes.iconMd,
        );
      } else {
        leadingIcon = Image.asset(
          iconPath!,
          width: AppSizes.iconMd,
          height: AppSizes.iconMd,
          errorBuilder: (context, error, stackTrace) =>
              icon ?? const SizedBox.shrink(),
        );
      }
    } else {
      leadingIcon = icon;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B26),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: AppSizes.borderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.input),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (leadingIcon != null) ...<Widget>[
                  leadingIcon,
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  text,
                  style: AppTextStyles.socialButtonText,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

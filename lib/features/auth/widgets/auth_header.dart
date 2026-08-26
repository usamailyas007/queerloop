import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppImages.logo.endsWith('.svg')
            ? SvgPicture.asset(
                AppImages.logo,
                height: AppSizes.logoHeight,
                fit: BoxFit.contain,
              )
            : Image.asset(
                AppImages.logo,
                height: AppSizes.logoHeight,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.all_inclusive,
                  color: Color(0xFF00E5FF),
                  size: AppSizes.logoHeight,
                ),
              ),
        const SizedBox(height: AppSpacing.xl),
        Text(
          title,
          style: AppTextStyles.authHeaderTitle.copyWith(
            color: context.themeTextPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          subtitle,
          style: AppTextStyles.authHeaderSub.copyWith(
            color: context.themeTextSecondary,
          ),
        ),
      ],
    );
  }
}

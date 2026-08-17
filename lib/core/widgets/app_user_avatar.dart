import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppUserAvatar extends StatelessWidget {
  const AppUserAvatar({
    required this.imageAsset,
    super.key,
    this.size = 38.0,
    this.hasGradientBorder = true,
  });

  final String imageAsset;
  final double size;
  final bool hasGradientBorder;

  @override
  Widget build(BuildContext context) {
    if (!hasGradientBorder) {
      return ClipOval(
        child: Image.asset(
          imageAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: <Color>[
            AppColors.gradientPink,
            AppColors.gradientCyan,
          ],
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: ClipOval(
        child: Image.asset(
          imageAsset,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

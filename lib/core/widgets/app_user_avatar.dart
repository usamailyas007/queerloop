import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_images.dart';

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

  Widget _buildAvatarImage({double? width, double? height}) {
    final bool isNetwork =
        imageAsset.startsWith('http://') || imageAsset.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        imageAsset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => Image.asset(
          AppImages.user1,
          width: width,
          height: height,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      imageAsset.isNotEmpty ? imageAsset : AppImages.user1,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Image.asset(
        AppImages.user1,
        width: width,
        height: height,
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!hasGradientBorder) {
      return ClipOval(
        child: _buildAvatarImage(
          width: size,
          height: size,
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
        child: _buildAvatarImage(),
      ),
    );
  }
}

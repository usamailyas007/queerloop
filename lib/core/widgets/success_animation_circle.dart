import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../theme/app_images.dart';

class SuccessAnimationCircle extends StatelessWidget {
  const SuccessAnimationCircle({super.key, this.size = 100});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      AppImages.successLottie,
      height: size,
      width: size,
      fit: BoxFit.cover,
      // repeat: false,
    );
  }
}

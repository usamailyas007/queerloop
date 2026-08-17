import 'package:flutter/material.dart';
import '../../../core/theme/app_spacing.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ??
          () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
      child: Container(
        width: AppSizes.backButtonSize,
        height: AppSizes.backButtonSize,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B26),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: AppSizes.borderWidth,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}

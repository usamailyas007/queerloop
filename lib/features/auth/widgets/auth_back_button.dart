import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

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
          color: isDark
              ? const Color(0xFF1E1B26)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : context.themeBorder,
            width: 1.1,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.chevron_left_rounded,
            color: context.themeTextPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Full-width pill button used across the case review screen and its dialogs.
class WideButton extends StatelessWidget {
  const WideButton({required this.label, this.onTap, this.gradient = false, super.key});

  final String label;
  final VoidCallback? onTap;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 46,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: gradient
                  ? const LinearGradient(
                      colors: <Color>[AppColors.moderatorPink, AppColors.moderatorPurpleAccent, AppColors.gradientCyan],
                    )
                  : null,
              color: gradient ? null : AppColors.moderatorSurfaceAlt2,
              borderRadius: BorderRadius.circular(23),
              border: gradient ? null : Border.all(color: AppColors.moderatorTextPrimary.withValues(alpha: 0.1)),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}

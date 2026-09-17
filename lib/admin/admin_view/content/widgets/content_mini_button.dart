import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Small "View" / "Hide" / "Restore" action button on a content card.
class ContentMiniButton extends StatelessWidget {
  const ContentMiniButton({required this.label, required this.onTap, this.danger = false, super.key});

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: danger ? AppColors.adminPink.withValues(alpha: 0.14) : AppColors.adminSurfaceAlt,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: danger ? AppColors.adminPink.withValues(alpha: 0.4) : AppColors.adminButtonBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: danger ? AppColors.adminPink : AppColors.adminTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ),
    );
  }
}

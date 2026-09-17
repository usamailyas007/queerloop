import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Small trash-icon button for destructive "delete" row actions — reused
/// across every admin list (users, communities, announcements, CotD,
/// spotlights, posts).
class AdminDeleteIconButton extends StatelessWidget {
  const AdminDeleteIconButton({required this.onTap, this.tooltip = 'Delete', super.key});

  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.adminSurfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.adminPink.withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.delete_outline, size: 16, color: AppColors.adminPink),
          ),
        ),
      ),
    );
  }
}

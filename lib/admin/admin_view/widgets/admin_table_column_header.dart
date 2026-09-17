import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Muted, uppercase-style column header used in every admin data table.
class AdminTableColumnHeader extends StatelessWidget {
  const AdminTableColumnHeader(
    this.label, {
    this.fontSize = 11,
    this.color = AppColors.adminTextMuted,
    super.key,
  });

  final String label;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

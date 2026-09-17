import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Bordered, scrollable panel shell for the two case-review columns.
class CasePanel extends StatelessWidget {
  const CasePanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.moderatorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.moderatorBorder),
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}

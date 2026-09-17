import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Bordered card shell shared by the dashboard's side-by-side panels.
class DashboardCard extends StatelessWidget {
  const DashboardCard({required this.child, super.key});

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
      child: child,
    );
  }
}

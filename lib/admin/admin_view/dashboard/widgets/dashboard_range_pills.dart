import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Today / 7 days / 30 days selector for the Platform overview page.
class DashboardRangePills extends StatelessWidget {
  const DashboardRangePills({required this.selectedIndex, required this.onChanged, super.key});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const List<String> labels = <String>['Today', '7 days', '30 days'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < labels.length; i++)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: selectedIndex == i ? AppColors.adminSurfaceAlt : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: selectedIndex == i ? AppColors.adminTextPrimary : AppColors.adminTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

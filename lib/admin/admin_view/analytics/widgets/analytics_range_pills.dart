import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AnalyticsRangePills extends StatelessWidget {
  const AnalyticsRangePills({required this.range, required this.onChanged, super.key});

  final String range;
  final ValueChanged<String> onChanged;

  static const List<(String, String)> ranges = <(String, String)>[
    ('Today', 'today'),
    ('7 days', '7d'),
    ('30 days', '30d'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Row(
        children: <Widget>[
          for (final (String label, String value) in ranges)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => onChanged(value),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: range == value ? AppColors.moderatorChipSelected : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: range == value ? AppColors.adminTextPrimary : AppColors.adminTextSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
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

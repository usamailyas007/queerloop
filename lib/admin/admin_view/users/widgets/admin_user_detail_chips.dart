import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Wrap of small outlined chips — used for pronouns / interests in the
/// user-detail dialog.
class AdminUserDetailChips extends StatelessWidget {
  const AdminUserDetailChips({required this.values, super.key});

  final List<String> values;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: 6,
        runSpacing: 6,
        children: <Widget>[
          for (final String v in values)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.adminSurfaceAlt,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.adminBorder),
              ),
              child: Text(
                v,
                style: const TextStyle(
                  color: AppColors.adminTextSecondary,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
}

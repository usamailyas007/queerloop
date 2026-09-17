import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A "label: value" row — a muted key on the left, the value on the right.
/// Used across the admin/moderator detail panels (user detail, report
/// detail, account history).
class AdminKvRow extends StatelessWidget {
  const AdminKvRow(
    this.label,
    this.value, {
    this.mono = false,
    this.labelWidth = 120,
    this.labelColor = AppColors.adminTextMuted,
    this.valueColor = AppColors.adminTextPrimary,
    super.key,
  });

  final String label;
  final String value;
  final bool mono;
  final double labelWidth;
  final Color labelColor;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: labelWidth,
              child: Text(
                label,
                style: TextStyle(color: labelColor, fontSize: 12),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: mono ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

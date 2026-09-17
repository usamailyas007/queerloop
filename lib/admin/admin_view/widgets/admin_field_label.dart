import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

/// Small muted label above a form field, used across every admin create/edit
/// form (communities, moderators, announcements, spotlights).
class AdminFieldLabel extends StatelessWidget {
  const AdminFieldLabel(this.text, {this.bottomSpacing = AppSpacing.xs, super.key});

  final String text;
  final double bottomSpacing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.adminTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

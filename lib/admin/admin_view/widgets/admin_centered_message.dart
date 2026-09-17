import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_outline_button.dart';

/// Centered icon + message, with an optional "Retry" button — the shared
/// empty-state / error-state layout used across every admin list/table.
class AdminCenteredMessage extends StatelessWidget {
  const AdminCenteredMessage({
    this.icon,
    required this.message,
    this.onRetry,
    super.key,
  });

  final IconData? icon;
  final String message;
  final Future<void> Function()? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, color: AppColors.adminTextMuted, size: 32),
            const SizedBox(height: AppSpacing.sm),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
          ),
          if (onRetry != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 120,
              child: AppOutlineButton(text: 'Retry', height: 38, onPressed: onRetry!),
            ),
          ],
        ],
      ),
    );
  }
}

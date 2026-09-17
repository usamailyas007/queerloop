import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'case_top_bar.dart';

/// Shown when the selected report failed to load or is missing.
class CaseCenteredError extends StatelessWidget {
  const CaseCenteredError({required this.message, required this.onBack, super.key});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(message, style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 13)),
          const SizedBox(height: AppSpacing.md),
          TopBarButton(label: 'Back to queue', onTap: onBack),
        ],
      ),
    );
  }
}

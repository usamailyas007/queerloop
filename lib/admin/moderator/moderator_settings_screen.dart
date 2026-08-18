// Admin settings screen.

import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';

class ModeratorSettingsScreen extends StatelessWidget {
  const ModeratorSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(AppSpacing.xl),
      child: Align(
        alignment: Alignment.topLeft,
        child: Text('Settings', style: AppTextStyles.titleMedium),
      ),
    );
  }
}

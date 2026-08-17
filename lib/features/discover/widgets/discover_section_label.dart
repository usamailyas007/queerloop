import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// Small ALL-CAPS section label used throughout Discover screens.
class DiscoverSectionLabel extends StatelessWidget {
  const DiscoverSectionLabel({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.labelSmall.copyWith(
        color: Colors.white54,
        letterSpacing: 1.2,
      ),
    );
  }
}

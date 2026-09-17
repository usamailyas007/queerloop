import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Small uppercase section label used inside the user-detail dialog.
class AdminUserDetailLabel extends StatelessWidget {
  const AdminUserDetailLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: AppColors.adminTextMuted,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      );
}

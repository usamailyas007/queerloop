import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Destructive-action confirmation dialog — the "Ban permanently?" style
/// shared across every admin delete action. Returns true if confirmed.
Future<bool> showAdminConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (BuildContext ctx) => AlertDialog(
      backgroundColor: AppColors.adminSurfaceAlt,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: AppColors.adminCardBorderStrong),
      ),
      title: Text(
        title,
        style: const TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w800, fontSize: 17),
      ),
      content: Text(
        message,
        style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13, height: 1.45),
      ),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(cancelLabel)),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel, style: const TextStyle(color: AppColors.adminPink, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
  return result ?? false;
}

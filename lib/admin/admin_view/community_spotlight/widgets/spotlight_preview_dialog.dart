import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../models/spotlight.dart';
import '../screens/spotlight_image.dart';

/// Full preview of one spotlight, with Edit / Re-run / Close actions.
Future<void> showSpotlightPreviewDialog(
  BuildContext context,
  Spotlight spotlight, {
  required ValueChanged<Spotlight> onEdit,
  required ValueChanged<Spotlight> onRerun,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: AppColors.adminSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.adminBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SpotlightImage(url: spotlight.imageUrl, height: 200, borderRadius: 0),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    spotlight.title,
                    style: const TextStyle(
                      color: AppColors.adminTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    spotlight.body,
                    style: const TextStyle(
                      color: AppColors.adminTextSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${DateFormat('d MMM yyyy').format(spotlight.createdAt)} · '
                    '${NumberFormat.decimalPattern().format(spotlight.views)} views · '
                    '${NumberFormat.decimalPattern().format(spotlight.taps)} taps',
                    style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 11),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      AppOutlineButton(
                        text: 'Edit',
                        width: 90,
                        height: 36,
                        onPressed: () {
                          Navigator.pop(context);
                          onEdit(spotlight);
                        },
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      if (!spotlight.live) ...<Widget>[
                        AppOutlineButton(
                          text: 'Re-run',
                          width: 90,
                          height: 36,
                          onPressed: () {
                            Navigator.pop(context);
                            onRerun(spotlight);
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

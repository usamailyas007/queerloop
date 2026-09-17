import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// The cover-image dropzone on the spotlight editor, with change/remove
/// actions once an image (picked or existing) is present.
class SpotlightCoverPicker extends StatelessWidget {
  const SpotlightCoverPicker({
    required this.pickedBytes,
    required this.currentImageUrl,
    required this.saving,
    required this.onPick,
    required this.onRemove,
    super.key,
  });

  final Uint8List? pickedBytes;
  final String? currentImageUrl;
  final bool saving;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  bool get _hasImage =>
      pickedBytes != null ||
      (currentImageUrl != null && currentImageUrl!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: saving ? null : onPick,
            child: Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: AppColors.adminSurfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.adminDropzoneBorder),
              ),
              clipBehavior: Clip.antiAlias,
              alignment: Alignment.center,
              child: _preview(),
            ),
          ),
        ),
        if (_hasImage) ...<Widget>[
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              TextButton(
                onPressed: saving ? null : onPick,
                child: const Text('Change image', style: TextStyle(fontSize: 12)),
              ),
              TextButton(
                onPressed: saving ? null : onRemove,
                child: const Text(
                  'Remove',
                  style: TextStyle(fontSize: 12, color: AppColors.adminOrange),
                ),
              ),
            ],
          ),
        ] else
          const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _preview() {
    if (pickedBytes != null) {
      return Image.memory(
        pickedBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (currentImageUrl != null && currentImageUrl!.trim().isNotEmpty) {
      return Image.network(
        currentImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Media CDN has no CORS headers — render via <img> on web.
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, _, _) => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.broken_image_outlined, color: AppColors.adminTextMuted, size: 28),
            SizedBox(height: 8),
            Text(
              "Can't load current image",
              style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(Icons.file_upload_outlined, color: AppColors.adminTextSecondary, size: 28),
        SizedBox(height: 8),
        Text(
          'Upload cover image (optional)',
          style: TextStyle(
            color: AppColors.adminTextSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'PNG or JPG · Tap to choose from system',
          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 11),
        ),
      ],
    );
  }
}

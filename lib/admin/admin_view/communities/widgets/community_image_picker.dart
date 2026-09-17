import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The "Community image" upload dropzone on the create-community form.
class CommunityImagePicker extends StatelessWidget {
  const CommunityImagePicker({
    required this.pickedBytes,
    required this.enabled,
    required this.onTap,
    super.key,
  });

  final Uint8List? pickedBytes;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.adminSurfaceAlt,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.adminDropzoneBorder),
          ),
          clipBehavior: Clip.antiAlias,
          child: pickedBytes == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.file_upload_outlined,
                      color: AppColors.adminTextSecondary,
                      size: 22,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Upload image (optional)',
                      style: TextStyle(
                        color: AppColors.adminTextSecondary,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'PNG or JPG · Max 2 MB',
                      style: TextStyle(
                        color: AppColors.adminTextMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                )
              : Image.memory(pickedBytes!, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

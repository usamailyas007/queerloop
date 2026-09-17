import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../widgets/admin_field_label.dart';
import 'community_image_picker.dart';

/// The card holding every input for creating a community.
class AddCommunityForm extends StatelessWidget {
  const AddCommunityForm({
    required this.nameController,
    required this.slugController,
    required this.descriptionController,
    required this.onSlugEdited,
    required this.pickedImageBytes,
    required this.onPickImage,
    required this.isPublic,
    required this.onVisibilityChanged,
    required this.creating,
    required this.onCancel,
    required this.onSubmit,
    super.key,
  });

  final TextEditingController nameController;
  final TextEditingController slugController;
  final TextEditingController descriptionController;
  final VoidCallback onSlugEdited;
  final Uint8List? pickedImageBytes;
  final VoidCallback onPickImage;
  final bool isPublic;
  final ValueChanged<bool> onVisibilityChanged;
  final bool creating;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 440,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const AdminFieldLabel('Community name'),
          AppTextField(
            controller: nameController,
            enabled: !creating,
            hintText: 'e.g. Asexual',
            fillColor: AppColors.adminSurfaceAlt,
          ),
          const SizedBox(height: AppSpacing.lg),
          const AdminFieldLabel('Slug'),
          AppTextField(
            controller: slugController,
            enabled: !creating,
            hintText: 'e.g. asexual',
            fillColor: AppColors.adminSurfaceAlt,
            onChanged: (_) => onSlugEdited(),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AdminFieldLabel('Short description'),
          AppTextField(
            controller: descriptionController,
            enabled: !creating,
            hintText: "Shown on the community's about page",
            fillColor: AppColors.adminSurfaceAlt,
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.lg),
          const AdminFieldLabel('Community image'),
          CommunityImagePicker(
            pickedBytes: pickedImageBytes,
            enabled: !creating,
            onTap: onPickImage,
          ),
          const SizedBox(height: AppSpacing.lg),
          const AdminFieldLabel('Visibility'),
          Row(
            children: <Widget>[
              AppTagChip(
                label: 'Public',
                isSelected: isPublic,
                onTap: () => onVisibilityChanged(true),
              ),
              const SizedBox(width: 8),
              AppTagChip(
                label: 'Members only',
                isSelected: !isPublic,
                onTap: () => onVisibilityChanged(false),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          Row(
            children: <Widget>[
              Expanded(
                child: AppOutlineButton(
                  text: 'Cancel',
                  onPressed: creating ? () {} : onCancel,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppGradientButton(
                  text: 'Create community',
                  isLoading: creating,
                  onPressed: creating ? () {} : onSubmit,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

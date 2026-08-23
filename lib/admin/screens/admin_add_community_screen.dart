import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_gradient_button.dart';
import '../../core/widgets/app_outline_button.dart';
import '../../core/widgets/app_tag_chip.dart';
import '../../core/widgets/app_text_field.dart';

class AdminAddCommunityScreen extends StatefulWidget {
  const AdminAddCommunityScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<AdminAddCommunityScreen> createState() =>
      _AdminAddCommunityScreenState();
}

class _AdminAddCommunityScreenState extends State<AdminAddCommunityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedImageBytes;
  bool _isPublic = true;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() => _pickedImageBytes = bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Communities /',
                          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add community',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Creates a new group tab in the app's Communities section",
                          style: TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: AppOutlineButton(
                      text: 'Cancel',
                      height: 40,
                      onPressed: widget.onBack,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
                width: 440,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.adminSurface,
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: AppColors.adminBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Community name',
                      style: TextStyle(
                          color: AppColors.adminTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _nameController,
                      hintText: 'e.g. Asexual',
                      fillColor: AppColors.adminSurfaceAlt,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Short description',
                      style: TextStyle(
                          color: AppColors.adminTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _descriptionController,
                      hintText: "Shown on the community's about page",
                      fillColor: AppColors.adminSurfaceAlt,
                      maxLines: 3,
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Community image',
                      style: TextStyle(
                          color: AppColors.adminTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.adminSurfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.adminDropzoneBorder,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _pickedImageBytes == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(Icons.file_upload_outlined,
                                      color: AppColors.adminTextSecondary, size: 22),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload image',
                                    style: TextStyle(
                                        color: AppColors.adminTextSecondary, fontSize: 13),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'PNG, JPG or SVG · Max 2 MB',
                                    style: TextStyle(
                                        color: AppColors.adminTextMuted, fontSize: 11),
                                  ),
                                ],
                              )
                            : Image.memory(_pickedImageBytes!,
                                fit: BoxFit.cover),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Visibility',
                      style: TextStyle(
                          color: AppColors.adminTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: <Widget>[
                        AppTagChip(
                          label: 'Public',
                          isSelected: _isPublic,
                          onTap: () => setState(() => _isPublic = true),
                        ),
                        const SizedBox(width: 8),
                        AppTagChip(
                          label: 'Members only',
                          isSelected: !_isPublic,
                          onTap: () => setState(() => _isPublic = false),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppOutlineButton(
                            text: 'Cancel',
                            onPressed: widget.onBack,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppGradientButton(
                            text: 'Create community',
                            onPressed: widget.onBack,
                          ),
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
}

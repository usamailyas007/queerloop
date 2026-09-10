import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../models/spotlight.dart';
import '../provider/spotlights_provider.dart';

/// Create (target == null) or edit an existing spotlight.
class AdminSpotlightEditorScreen extends StatefulWidget {
  const AdminSpotlightEditorScreen({
    required this.target,
    required this.onDone,
    required this.onCancel,
    super.key,
  });

  final Spotlight? target;
  final VoidCallback onDone;
  final VoidCallback onCancel;

  @override
  State<AdminSpotlightEditorScreen> createState() =>
      _AdminSpotlightEditorScreenState();
}

class _AdminSpotlightEditorScreenState
    extends State<AdminSpotlightEditorScreen> {
  late final TextEditingController _titleController =
      TextEditingController(text: widget.target?.title ?? '');
  late final TextEditingController _bodyController =
      TextEditingController(text: widget.target?.body ?? '');

  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedBytes;
  String? _currentImageUrl;

  bool get _isEdit => widget.target != null;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.target?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() {
        _pickedBytes = bytes;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _pickedBytes = null;
      _currentImageUrl = null;
    });
  }

  Future<void> _save() async {
    final SpotlightsProvider provider = context.read<SpotlightsProvider>();
    String? finalImageUrl;

    if (_pickedBytes != null) {
      finalImageUrl = 'data:image/jpeg;base64,${base64Encode(_pickedBytes!)}';
    } else {
      finalImageUrl = _currentImageUrl;
    }

    final Spotlight? saved = await provider.saveSpotlight(
      targetId: widget.target?.id,
      title: _titleController.text,
      body: _bodyController.text,
      imageUrl: finalImageUrl,
    );

    if (!mounted) {
      return;
    }
    if (saved != null) {
      _snack(_isEdit ? 'Spotlight updated.' : 'Spotlight published.');
      widget.onDone();
    } else {
      _snack(provider.error ?? 'Could not save the spotlight.');
      provider.clearError();
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _hasImage =>
      _pickedBytes != null ||
      (_currentImageUrl != null && _currentImageUrl!.trim().isNotEmpty);

  @override
  Widget build(BuildContext context) {
    final bool saving = context.select<SpotlightsProvider, bool>(
      (SpotlightsProvider p) => p.isSaving,
    );

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Community spotlight /',
                style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Text(
                      _isEdit ? 'Edit spotlight' : 'New spotlight',
                      style: const TextStyle(
                        color: AppColors.adminTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: AppOutlineButton(
                      text: 'Cancel',
                      height: 40,
                      onPressed: saving ? () {} : widget.onCancel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              Container(
                width: 480,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.adminSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.adminBorder),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _Label('Cover image'),
                    GestureDetector(
                      onTap: saving ? null : _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: AppColors.adminSurfaceAlt,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.adminDropzoneBorder,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        alignment: Alignment.center,
                        child: _buildImagePreview(),
                      ),
                    ),
                    if (_hasImage) ...<Widget>[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: <Widget>[
                          TextButton(
                            onPressed: saving ? null : _pickImage,
                            child: const Text(
                              'Change image',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                          TextButton(
                            onPressed: saving ? null : _removeImage,
                            child: const Text(
                              'Remove',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.adminOrange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else
                      const SizedBox(height: AppSpacing.lg),
                    const _Label('Headline'),
                    AppTextField(
                      controller: _titleController,
                      enabled: !saving,
                      hintText: 'Community of the Week',
                      fillColor: AppColors.adminSurfaceAlt,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _Label('Description'),
                    AppTextField(
                      controller: _bodyController,
                      enabled: !saving,
                      hintText: 'Why this community is featured this week',
                      fillColor: AppColors.adminSurfaceAlt,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 200,
                        height: 44,
                        child: AppGradientButton(
                          text: _isEdit ? 'Save changes' : 'Publish spotlight',
                          isLoading: saving,
                          textStyle: const TextStyle(
                            color: AppColors.textInverse,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          onPressed: saving ? () {} : _save,
                        ),
                      ),
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

  Widget _buildImagePreview() {
    if (_pickedBytes != null) {
      return Image.memory(
        _pickedBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    if (_currentImageUrl != null && _currentImageUrl!.trim().isNotEmpty) {
      return Image.network(
        _currentImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.broken_image_outlined,
              color: AppColors.adminTextMuted,
              size: 28,
            ),
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
        Icon(
          Icons.file_upload_outlined,
          color: AppColors.adminTextSecondary,
          size: 28,
        ),
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

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.adminTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

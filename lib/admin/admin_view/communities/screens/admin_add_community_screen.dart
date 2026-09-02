import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_gradient_button.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../models/community.dart';
import '../provider/communities_provider.dart';

class AdminAddCommunityScreen extends StatefulWidget {
  const AdminAddCommunityScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<AdminAddCommunityScreen> createState() =>
      _AdminAddCommunityScreenState();
}

class _AdminAddCommunityScreenState extends State<AdminAddCommunityScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _slugController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _pickedImageBytes;
  bool _isPublic = true;
  bool _slugEdited = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_syncSlug);
  }

  @override
  void dispose() {
    _nameController.removeListener(_syncSlug);
    _nameController.dispose();
    _slugController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Keep the slug mirrored to the name until the user edits it by hand.
  void _syncSlug() {
    if (_slugEdited) {
      return;
    }
    _slugController.value = _slugController.value.copyWith(
      text: _slugify(_nameController.text),
      selection: TextSelection.collapsed(
        offset: _slugify(_nameController.text).length,
      ),
    );
  }

  static String _slugify(String raw) => raw
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final Uint8List bytes = await image.readAsBytes();
      setState(() => _pickedImageBytes = bytes);
    }
  }

  Future<void> _submit() async {
    final String name = _nameController.text.trim();
    final String slug = _slugController.text.trim();
    final String description = _descriptionController.text.trim();

    if (name.isEmpty || slug.isEmpty) {
      _snack('Name and slug are required.');
      return;
    }

    final Community? created =
        await context.read<CommunitiesProvider>().createCommunity(
              name: name,
              slug: slug,
              description: description,
              visibility: _isPublic
                  ? CommunityVisibility.public
                  : CommunityVisibility.private,
              imageBase64: _pickedImageBytes == null
                  ? null
                  : base64Encode(_pickedImageBytes!),
            );

    if (!mounted) {
      return;
    }
    if (created != null) {
      _snack('“${created.name}” created.');
      widget.onBack();
    } else {
      _snack(context.read<CommunitiesProvider>().error ??
          'Could not create the community.');
      context.read<CommunitiesProvider>().clearError();
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool creating = context.select<CommunitiesProvider, bool>(
      (CommunitiesProvider p) => p.isCreating,
    );

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: SingleChildScrollView(
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
                          style: TextStyle(
                            color: AppColors.adminTextMuted,
                            fontSize: 12,
                          ),
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
                          style: TextStyle(
                            color: AppColors.adminTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 100,
                    child: AppOutlineButton(
                      text: 'Cancel',
                      height: 40,
                      onPressed: creating ? () {} : widget.onBack,
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
                  border: Border.all(color: AppColors.adminBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _FieldLabel('Community name'),
                    AppTextField(
                      controller: _nameController,
                      enabled: !creating,
                      hintText: 'e.g. Asexual',
                      fillColor: AppColors.adminSurfaceAlt,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _FieldLabel('Slug'),
                    AppTextField(
                      controller: _slugController,
                      enabled: !creating,
                      hintText: 'e.g. asexual',
                      fillColor: AppColors.adminSurfaceAlt,
                      onChanged: (_) => _slugEdited = true,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _FieldLabel('Short description'),
                    AppTextField(
                      controller: _descriptionController,
                      enabled: !creating,
                      hintText: "Shown on the community's about page",
                      fillColor: AppColors.adminSurfaceAlt,
                      maxLines: 3,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _FieldLabel('Community image'),
                    GestureDetector(
                      onTap: creating ? null : _pickImage,
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
                                      color: AppColors.adminTextSecondary,
                                      size: 22),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload image (optional)',
                                    style: TextStyle(
                                        color: AppColors.adminTextSecondary,
                                        fontSize: 13),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'PNG or JPG · Max 2 MB',
                                    style: TextStyle(
                                        color: AppColors.adminTextMuted,
                                        fontSize: 11),
                                  ),
                                ],
                              )
                            : Image.memory(_pickedImageBytes!,
                                fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _FieldLabel('Visibility'),
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
                            onPressed: creating ? () {} : widget.onBack,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppGradientButton(
                            text: 'Create community',
                            isLoading: creating,
                            onPressed: creating ? () {} : _submit,
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

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

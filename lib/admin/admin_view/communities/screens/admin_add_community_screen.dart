import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../models/community.dart';
import '../provider/communities_provider.dart';
import '../widgets/add_community_form.dart';

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
    final String slug = _slugify(_nameController.text);
    _slugController.value = _slugController.value.copyWith(
      text: slug,
      selection: TextSelection.collapsed(offset: slug.length),
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

    final CommunitiesProvider provider = context.read<CommunitiesProvider>();
    final Community? created = await provider.createCommunity(
      name: name,
      slug: slug,
      description: description,
      visibility:
          _isPublic ? CommunityVisibility.public : CommunityVisibility.private,
      imageBase64:
          _pickedImageBytes == null ? null : base64Encode(_pickedImageBytes!),
    );

    if (!mounted) {
      return;
    }
    if (created != null) {
      _snack('“${created.name}” created.');
      widget.onBack();
    } else {
      _snack(provider.error ?? 'Could not create the community.');
      provider.clearError();
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
              AddCommunityForm(
                nameController: _nameController,
                slugController: _slugController,
                descriptionController: _descriptionController,
                onSlugEdited: () => _slugEdited = true,
                pickedImageBytes: _pickedImageBytes,
                onPickImage: _pickImage,
                isPublic: _isPublic,
                onVisibilityChanged: (bool v) => setState(() => _isPublic = v),
                creating: creating,
                onCancel: widget.onBack,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_gradient_button.dart';
import '../../core/widgets/app_outline_button.dart';
import '../../core/widgets/app_tag_chip.dart';
import '../../core/widgets/app_text_field.dart';

class AdminSpotlightFormScreen extends StatefulWidget {
  const AdminSpotlightFormScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<AdminSpotlightFormScreen> createState() =>
      _AdminSpotlightFormScreenState();
}

class _AdminSpotlightFormScreenState extends State<AdminSpotlightFormScreen> {
  final TextEditingController _handleController = TextEditingController();
  final TextEditingController _storyController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedImageBytes;
  String _selectedCommunity = 'Lesbian';

  static const List<String> _communities = <String>[
    'Lesbian',
    'Gay',
    'Bisexual',
    'Transgender',
    'Non-binary',
    'Queer',
    'General',
  ];

  @override
  void dispose() {
    _handleController.dispose();
    _storyController.dispose();
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
      backgroundColor: const Color(0xFF18181B),
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
                          'Community spotlight /',
                          style: TextStyle(
                            color: Color(0xFF635C72),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'New spotlight',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: const Color(0xFFF3EFF7),
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
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
                      backgroundColor: const Color(0xFF1C1824),
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
                  color: const Color(0xFF141119),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Member photo',
                      style: TextStyle(
                        color: Color(0xFF948CA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1824),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _pickedImageBytes == null
                            ? const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Icon(
                                    Icons.file_upload_outlined,
                                    color: Color(0xFF948CA3),
                                    size: 22,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Upload photo',
                                    style: TextStyle(
                                      color: Color(0xFF948CA3),
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'PNG or JPG · Max 2 MB',
                                    style: TextStyle(
                                      color: Color(0xFF635C72),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              )
                            : Image.memory(
                                _pickedImageBytes!,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Member handle',
                      style: TextStyle(
                        color: Color(0xFF948CA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _handleController,
                      hintText: '@rowankeeps',
                      fillColor: const Color(0xFF1C1824),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Community',
                      style: TextStyle(
                        color: Color(0xFF948CA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (final String name in _communities)
                          AppTagChip(
                            label: name,
                            isSelected: _selectedCommunity == name,
                            onTap: () =>
                                setState(() => _selectedCommunity = name),
                          ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Their story',
                      style: TextStyle(
                        color: Color(0xFF948CA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _storyController,
                      hintText: 'Shown alongside their photo on Discover',
                      fillColor: const Color(0xFF1C1824),
                      maxLines: 3,
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppOutlineButton(
                            text: 'Cancel',
                            backgroundColor: const Color(0xFF1C1824),
                            onPressed: widget.onBack,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: AppGradientButton(
                            text: 'Publish spotlight',
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

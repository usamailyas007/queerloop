import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_gradient_button.dart';
import '../../core/widgets/app_outline_button.dart';
import '../../core/widgets/app_text_field.dart';
import '../admin_icons.dart';
import 'admin_spotlight_screen.dart';

class AdminSpotlightOverviewScreen extends StatefulWidget {
  const AdminSpotlightOverviewScreen({
    required this.picks,
    required this.onOpenPast,
    required this.onPublish,
    super.key,
  });

  final List<SpotlightPick> picks;
  final VoidCallback onOpenPast;
  final void Function({
    required String headline,
    required String description,
    ImageProvider? coverImage,
  })
  onPublish;

  @override
  State<AdminSpotlightOverviewScreen> createState() =>
      _AdminSpotlightOverviewScreenState();
}

class _AdminSpotlightOverviewScreenState
    extends State<AdminSpotlightOverviewScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _pickedImageBytes;

  SpotlightPick get _livePick => widget.picks.firstWhere(
    (SpotlightPick p) => p.isLive,
    orElse: () => widget.picks.first,
  );

  late final TextEditingController _headlineController =
      TextEditingController(text: _livePick.headline);
  late final TextEditingController _descriptionController =
      TextEditingController(text: _livePick.description);

  @override
  void dispose() {
    _headlineController.dispose();
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

  void _publish() {
    widget.onPublish(
      headline: _headlineController.text,
      description: _descriptionController.text,
      coverImage: _pickedImageBytes != null
          ? MemoryImage(_pickedImageBytes!)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF18181B),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Community spotlight',
                          style: TextStyle(
                            color: Color(0xFFF3EFF7),
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Admin-curated feature shown once a week in Discover',
                          style: TextStyle(
                            color: Color(0xFF948CA3),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    child: AppTextField(
                      hintText: 'Search past spotlights',
                      prefixIconPath: AdminIcons.search,
                      fillColor: const Color(0xFF141119),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 120,
                    child: AppOutlineButton(
                      text: 'Past Spotlight',
                      height: 44,
                      backgroundColor: const Color(0xFF1C1824),
                      onPressed: widget.onOpenPast,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 130,
                    height: 44,
                    child: AppGradientButton(
                      text: 'New spotlight',
                      textStyle: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              Container(
                width: 480,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: const Color(0xFF141119),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.09),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      "This week's pick",
                      style: TextStyle(
                        color: Color(0xFFF3EFF7),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Cover image',
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
                        height: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.09),
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image(
                          image: _pickedImageBytes != null
                              ? MemoryImage(_pickedImageBytes!)
                              : _livePick.coverImage,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Headline',
                      style: TextStyle(
                        color: Color(0xFF948CA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _headlineController,
                      fillColor: const Color(0xFF1C1824),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    const Text(
                      'Description',
                      style: TextStyle(
                        color: Color(0xFF948CA3),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    AppTextField(
                      controller: _descriptionController,
                      fillColor: const Color(0xFF1C1824),
                      maxLines: 3,
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    Align(
                      alignment: Alignment.centerRight,
                      child: SizedBox(
                        width: 190,
                        height: 44,
                        child: AppGradientButton(
                          text: 'Publish spotlight',
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          onPressed: _publish,
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
}

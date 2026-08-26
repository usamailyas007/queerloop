import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';

class InterestsBottomSheet extends StatefulWidget {
  const InterestsBottomSheet({
    required this.selectedInterests,
    required this.onSave,
    super.key,
  });

  final List<String> selectedInterests;
  final ValueChanged<List<String>> onSave;

  static Future<void> show(
    BuildContext context, {
    required List<String> selectedInterests,
    required ValueChanged<List<String>> onSave,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => InterestsBottomSheet(
        selectedInterests: selectedInterests,
        onSave: onSave,
      ),
    );
  }

  @override
  State<InterestsBottomSheet> createState() => _InterestsBottomSheetState();
}

class _InterestsBottomSheetState extends State<InterestsBottomSheet> {
  late List<String> _selected;
  String _searchQuery = '';

  static const List<String> _creative = <String>[
    'Photography',
    'Writing',
    'Drag',
    'Dance',
    'Crafts',
  ];

  static const List<String> _wellbeing = <String>[
    'Skincare',
    'Recovery',
    'Mental health',
    'Cooking',
    'Hiking',
    'Plants',
  ];

  static const List<String> _community = <String>[
    'Activism',
    'Pride events',
    'Books',
    'Faith',
    'Parenting',
  ];

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedInterests);
    if (_selected.isEmpty) {
      _selected = <String>[
        'Music',
        'Gaming',
        'Fashion',
        'Fitness',
        'Travel',
        'Photography',
        'Cooking',
      ];
    }
  }

  void _toggle(String item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        if (_selected.length < 10) {
          _selected.add(item);
        }
      }
    });
  }

  Widget _buildSectionCategory({
    required String title,
    required List<String> options,
  }) {
    final List<String> filtered = options.where((String item) {
      return _searchQuery.isEmpty ||
          item.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            color: context.themeTextMuted,
            letterSpacing: 1.2,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: List<Widget>.generate(filtered.length, (int index) {
            final String item = filtered[index];
            final bool isSelected = _selected.contains(item);

            return GestureDetector(
              onTap: () => _toggle(item),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  gradient:
                      isSelected ? AppColors.primaryGradientButton : null,
                  color: isSelected ? null : context.themeCardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : context.themeBorder,
                  ),
                ),
                child: Text(
                  item,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : context.themeTextSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: AppSpacing.md,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Drag handle bar
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.themeBorderStrong,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Header Row (Cancel + Title "Interests" + Save Gradient Button)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.themeTextMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'Interests',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: context.themeTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      widget.onSave(_selected);
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradientButton,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Save',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Subtitle
              Text(
                'Pick up to 10. These show on your profile and shape what Explore recommends. You can leave this empty.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: context.themeTextSecondary,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Search Bar Field using AppTextField
              AppTextField(
                hintText: 'Search interests',
                prefixIconPath: AppIcons.searchSvg,
                onChanged: (String val) =>
                    setState(() => _searchQuery = val),
              ),

              const SizedBox(height: AppSpacing.lg),

              // SELECTED Section Header with Counter (7 / 10)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    'SELECTED',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: context.themeTextMuted,
                      letterSpacing: 1.2,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${_selected.length} / 10',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.gradientCyan,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.sm),

              // Selected Removable Chips Wrap
              if (_selected.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: List<Widget>.generate(_selected.length, (int index) {
                    final String item = _selected[index];

                    return Container(
                      padding: const EdgeInsets.only(
                        left: 14,
                        right: 8,
                        top: 7,
                        bottom: 7,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradientButton,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            item,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _toggle(item),
                            child: const Padding(
                              padding: EdgeInsets.all(2),
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),

              const SizedBox(height: AppSpacing.xl),

              // Categories
              _buildSectionCategory(
                title: 'CREATIVE',
                options: _creative,
              ),
              _buildSectionCategory(
                title: 'LIFE & WELLBEING',
                options: _wellbeing,
              ),
              _buildSectionCategory(
                title: 'COMMUNITY',
                options: _community,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

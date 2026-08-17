import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';

class IdentityBottomSheet extends StatefulWidget {
  const IdentityBottomSheet({
    required this.selectedIdentities,
    required this.onSave,
    super.key,
  });

  final List<String> selectedIdentities;
  final ValueChanged<List<String>> onSave;

  static Future<void> show(
    BuildContext context, {
    required List<String> selectedIdentities,
    required ValueChanged<List<String>> onSave,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => IdentityBottomSheet(
        selectedIdentities: selectedIdentities,
        onSave: onSave,
      ),
    );
  }

  @override
  State<IdentityBottomSheet> createState() => _IdentityBottomSheetState();
}

class _IdentityBottomSheetState extends State<IdentityBottomSheet> {
  late List<String> _selected;
  final TextEditingController _customController = TextEditingController();

  static const List<String> _allOptions = <String>[
    'Lesbian',
    'Bisexual',
    'Non-binary',
    'Gay',
    'Transgender',
    'Queer',
    'Pansexual',
    'Asexual',
    'Intersex',
    'Genderfluid',
    'Agender',
    'Two-Spirit',
    'Questioning',
    'Ally',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedIdentities);
    if (_selected.isEmpty) {
      _selected = <String>['Lesbian', 'Bisexual', 'Non-binary'];
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _toggle(String item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
  }

  void _addCustom() {
    final String text = _customController.text.trim();
    if (text.isNotEmpty && !_selected.contains(text)) {
      setState(() {
        _selected.add(text);
        _customController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<String> addMoreList = _allOptions
        .where((String item) => !_selected.contains(item))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomSheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Header Row (Cancel + Title "Identity" + Save Gradient Button)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white54,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    'Identity',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: Colors.white,
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

              // Description
              Text(
                'Add as many or as few as you want. Nothing here is required, and you can remove them at any time.',
                style: AppTextStyles.bodySmall.copyWith(
                  color: Colors.white54,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Selected Removable Gradient Chips
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

              // ADD MORE Section
              if (addMoreList.isNotEmpty) ...<Widget>[
                Text(
                  'ADD MORE',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white54,
                    letterSpacing: 1.2,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: List<Widget>.generate(addMoreList.length,
                      (int index) {
                    final String item = addMoreList[index];

                    return GestureDetector(
                      onTap: () => _toggle(item),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Text(
                          item,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // NOT LISTED? WRITE YOUR OWN Section
              Text(
                'NOT LISTED? WRITE YOUR OWN',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white54,
                  letterSpacing: 1.2,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              AppTextField(
                controller: _customController,
                hintText: 'Add a label in your words',
                onSubmitted: (_) => _addCustom(),
                suffixIcon: UnconstrainedBox(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: _addCustom,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradientButton,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Add',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}

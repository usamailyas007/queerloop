import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class PronounsBottomSheet extends StatefulWidget {
  const PronounsBottomSheet({
    required this.selectedPronouns,
    required this.onSave,
    super.key,
  });

  final List<String> selectedPronouns;
  final ValueChanged<List<String>> onSave;

  static Future<void> show(
    BuildContext context, {
    required List<String> selectedPronouns,
    required ValueChanged<List<String>> onSave,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PronounsBottomSheet(
        selectedPronouns: selectedPronouns,
        onSave: onSave,
      ),
    );
  }

  @override
  State<PronounsBottomSheet> createState() => _PronounsBottomSheetState();
}

class _PronounsBottomSheetState extends State<PronounsBottomSheet> {
  late List<String> _selected;

  static const List<String> _options = <String>[
    'she / her',
    'he / him',
    'they / them',
    'ze / zir',
    'xe / xem',
    'ey / em',
    'fae / faer',
    'any pronouns',
    'ask me',
  ];

  @override
  void initState() {
    super.initState();
    _selected = List<String>.from(widget.selectedPronouns);
    if (_selected.isEmpty) {
      _selected = <String>['she / her', 'they / them'];
    }
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomSheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: SafeArea(
        top: false,
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

            // Header Row (Cancel + Title "Pronouns" + Save Gradient Button)
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
                  'Pronouns',
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
              'Pick as many as fit. They sit next to your name everywhere in the app.',
              style: AppTextStyles.bodySmall.copyWith(
                color: Colors.white54,
                fontSize: 13,
                height: 1.35,
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Pronoun Chips Wrap
            Wrap(
              spacing: 8,
              runSpacing: 10,
              children: List<Widget>.generate(_options.length, (int index) {
                final String item = _options[index];
                final bool isSelected = _selected.contains(item);

                return GestureDetector(
                  onTap: () => _toggle(item),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppColors.primaryGradientButton
                          : null,
                      color: isSelected ? null : AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

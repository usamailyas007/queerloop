import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';

class AddTagBottomSheet extends StatefulWidget {
  const AddTagBottomSheet({
    required this.selectedTags,
    required this.onTagsChanged,
    super.key,
  });

  final List<String> selectedTags;
  final ValueChanged<List<String>> onTagsChanged;

  static Future<void> show(
    BuildContext context, {
    required List<String> initialTags,
    required ValueChanged<List<String>> onTagsChanged,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTagBottomSheet(
        selectedTags: initialTags,
        onTagsChanged: onTagsChanged,
      ),
    );
  }

  @override
  State<AddTagBottomSheet> createState() => _AddTagBottomSheetState();
}

class _AddTagBottomSheetState extends State<AddTagBottomSheet> {
  late List<String> _tags;
  late final TextEditingController _searchController;

  static const List<String> _allMatchingTags = <String>[
    '#chosenfamily',
    '#chosenfam2026',
    '#choseninfj',
    '#transjoy',
    '#support',
    '#queerbooktok',
  ];

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.selectedTags);
    _searchController = TextEditingController(text: 'chosen');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_tags.contains(tag)) {
        _tags.remove(tag);
      } else {
        if (_tags.length < 5) {
          _tags.add(tag);
        }
      }
    });
    widget.onTagsChanged(_tags);
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<String> matching = _allMatchingTags
        .where((String t) => query.isEmpty || t.toLowerCase().contains(query))
        .toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bottomSheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 12,
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
            // Drag handle
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

            const SizedBox(height: AppSpacing.lg),

            // Header (Title + Close X)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Add a tag',
                  style: AppTextStyles.headingMedium.copyWith(fontSize: 20),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.lg),

            // Search Bar Row using AppTextField component
            Row(
              children: <Widget>[
                Expanded(
                  child: AppTextField(
                    controller: _searchController,
                    hintText: 'Search tags...',
                    prefixIconPath: AppIcons.search,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(
                    'Done',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.gradientPink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // SELECTED header
            Text(
              'SELECTED  ·  ${_tags.length}',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white54,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Selected tags chips (Gradient pill chips with x)
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: _tags
                  .map(
                    (String tag) => GestureDetector(
                      onTap: () => _toggleTag(tag),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradientButton,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(
                              tag,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: AppSpacing.xl),

            // MATCHING TAGS header
            Text(
              'MATCHING TAGS',
              style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white54,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Matching tags list
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: matching
                  .map(
                    (String tag) => GestureDetector(
                      onTap: () => _toggleTag(tag),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: Text(
                          tag,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Up to 5 tags note
            Text(
              'Up to 5 tags per post.',
              style: AppTextStyles.caption.copyWith(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

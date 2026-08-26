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
    '#prideprep2026',
    '#binderfitcheck',
    '#lgbtq',
    '#transgender',
  ];

  @override
  void initState() {
    super.initState();
    _tags = List<String>.from(widget.selectedTags);
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _addCustomTag(String raw) {
    final String clean = raw.trim();
    if (clean.isEmpty) return;
    final String tag = clean.startsWith('#') ? clean : '#$clean';

    if (!_tags.contains(tag)) {
      if (_tags.length < 5) {
        setState(() {
          _tags.add(tag);
          _searchController.clear();
        });
        widget.onTagsChanged(_tags);
      }
    } else {
      _searchController.clear();
    }
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

  void _handleDone() {
    final String query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _addCustomTag(query);
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final String cleanTagQuery = query.startsWith('#') ? query : '#$query';

    final List<String> matching = _allMatchingTags
        .where((String t) => query.isEmpty || t.toLowerCase().contains(query))
        .toList();

    final bool isExactMatch = matching.any((String t) => t.toLowerCase() == cleanTagQuery.toLowerCase());
    final bool showCustomCreate = query.isNotEmpty && !isExactMatch;

    return Container(
      decoration: BoxDecoration(
        color: context.themeBottomSheetBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: context.themeBorderStrong,
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
                    style: AppTextStyles.headingMedium.copyWith(
                      color: context.themeTextPrimary,
                      fontSize: 20,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: context.isDarkMode
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.04),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: context.themeIconMuted,
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
                      hintText: 'Search or type new tag...',
                      prefixIconPath: AppIcons.search,
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (String val) {
                        _addCustomTag(val);
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  GestureDetector(
                    onTap: _handleDone,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Text(
                        'Done',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.gradientPink,
                          fontWeight: FontWeight.w700,
                        ),
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
                  color: context.themeTextMuted,
                  letterSpacing: 1.2,
                  fontSize: 11,
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Selected tags chips (Gradient pill chips with x)
              if (_tags.isNotEmpty)
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
                )
              else
                Text(
                  'No tags selected yet.',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.themeTextMuted,
                  ),
                ),

              const SizedBox(height: AppSpacing.xl),

              // Create Custom Tag Chip if typed something new
              if (showCustomCreate) ...<Widget>[
                GestureDetector(
                  onTap: () => _addCustomTag(query),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gradientCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      border: Border.all(
                        color: AppColors.gradientCyan.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          Icons.add_rounded,
                          color: AppColors.gradientCyan,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Add "$cleanTagQuery"',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.gradientCyan,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // MATCHING TAGS header
              Text(
                'MATCHING TAGS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: context.themeTextMuted,
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
                          child: Row(
                            children: <Widget>[
                              Text(
                                tag,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: _tags.contains(tag)
                                      ? AppColors.gradientPink
                                      : context.themeTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (_tags.contains(tag)) ...<Widget>[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_rounded,
                                  color: AppColors.gradientPink,
                                  size: 16,
                                ),
                              ],
                            ],
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
                  color: context.themeTextMuted,
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

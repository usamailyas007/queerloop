import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_images.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_text_field.dart';

class SelectCommunityBottomSheet extends StatefulWidget {
  const SelectCommunityBottomSheet({
    required this.selectedCommunity,
    required this.onSelect,
    super.key,
  });

  final String selectedCommunity;
  final ValueChanged<String> onSelect;

  static Future<String?> show(
    BuildContext context, {
    required String currentCommunity,
  }) async {
    String? selected;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SelectCommunityBottomSheet(
        selectedCommunity: currentCommunity,
        onSelect: (String c) => selected = c,
      ),
    );
    return selected;
  }

  @override
  State<SelectCommunityBottomSheet> createState() =>
      _SelectCommunityBottomSheetState();
}

class _SelectCommunityBottomSheetState
    extends State<SelectCommunityBottomSheet> {
  late String _tempSelected;
  late final TextEditingController _searchController;

  static const List<Map<String, String>> _communities = <Map<String, String>>[
    {
      'name': 'Transgender',
      'members': '12.4K members',
      'image': AppImages.transgender,
    },
    {
      'name': 'Non-Binary',
      'members': '8.1K members',
      'image': AppImages.queer,
    },
    {
      'name': 'LGBTQ+ Support',
      'members': '24.9K members',
      'image': AppImages.communityImg,
    },
    {
      'name': 'Pride Showcase',
      'members': '15.2K members',
      'image': AppImages.searchResult1,
    },
    {
      'name': 'Chosen Family',
      'members': '9.8K members',
      'image': AppImages.searchResult2,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tempSelected = widget.selectedCommunity;
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String query = _searchController.text.trim().toLowerCase();
    final List<Map<String, String>> filtered = _communities
        .where((Map<String, String> c) =>
            query.isEmpty || c['name']!.toLowerCase().contains(query))
        .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
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
        child: Column(
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
                  'Select Community',
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

            const SizedBox(height: AppSpacing.md),

            // Search Bar using AppTextField
            AppTextField(
              controller: _searchController,
              hintText: 'Search communities...',
              prefixIconPath: AppIcons.search,
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Scrollable List of Communities
            Expanded(
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, String> item = filtered[index];
                  final String name = item['name']!;
                  final bool isSelected = _tempSelected == name;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _tempSelected = name);
                      widget.onSelect(name);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: context.themeCardBackground,
                        borderRadius: BorderRadius.circular(AppRadius.card),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.gradientCyan
                              : context.themeBorder,
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: <Widget>[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              item['image']!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  name,
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: context.themeTextPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  item['members']!,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: context.themeTextMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_rounded,
                              color: AppColors.gradientCyan,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

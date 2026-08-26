import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

/// Left-aligned horizontal tab bar for All / Posts / Reels / People / Tags / Communities tabs.
class SearchTabBar extends StatelessWidget {
  const SearchTabBar({
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    super.key,
  });

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: List<Widget>.generate(
            tabs.length,
            (int i) => Padding(
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              child: GestureDetector(
                onTap: () => onTabSelected(i),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        tabs[i],
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: selectedIndex == i
                              ? context.themeTextPrimary
                              : context.themeTextMuted,
                          fontWeight: selectedIndex == i
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 2.5,
                      width: selectedIndex == i ? 28 : 0,
                      decoration: BoxDecoration(
                        color: AppColors.gradientPink,
                        borderRadius: BorderRadius.circular(1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

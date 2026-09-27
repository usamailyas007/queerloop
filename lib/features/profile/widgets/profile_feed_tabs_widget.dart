import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';

class ProfileFeedTabsWidget extends StatelessWidget {
  const ProfileFeedTabsWidget({
    required this.selectedIndex,
    required this.onTabSelected,
    this.isOwnProfile = true,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final bool isOwnProfile;

  @override
  Widget build(BuildContext context) {
    final List<String> tabs = isOwnProfile
        ? const <String>['Posts', 'Reels', 'Saved', 'Liked']
        : const <String>['Posts', 'Reels'];

    return Column(
      children: <Widget>[
        Row(
          children: List<Widget>.generate(tabs.length, (int index) {
            final bool isSelected = selectedIndex == index;
            final bool hasLock = index >= 2 && isOwnProfile;

            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTabSelected(index),
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            tabs[index],
                            style: AppTextStyles.titleSmall.copyWith(
                              color: isSelected
                                  ? context.themeTextPrimary
                                  : context.themeTextMuted,
                              fontWeight:
                                  isSelected ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 13,
                            ),
                          ),
                          if (hasLock) ...<Widget>[
                            const SizedBox(width: 4),
                            SvgPicture.asset(
                              AppIcons.password,
                              width: 12,
                              height: 12,
                              colorFilter: ColorFilter.mode(
                                isSelected
                                    ? context.themeTextPrimary
                                    : context.themeTextMuted,
                                BlendMode.srcIn,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 2.5,
                        color: isSelected
                            ? AppColors.gradientPink
                            : Colors.transparent,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        Divider(color: context.themeDivider, height: 1),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

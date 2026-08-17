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
    final List<String> tabs = <String>['Posts', 'Reels', 'Saved', 'Liked'];

    return Column(
      children: <Widget>[
        Row(
          children: List<Widget>.generate(tabs.length, (int index) {
            final bool isSelected = selectedIndex == index;
            final bool hasLock = index >= 2 && isOwnProfile;

            return Expanded(
              child: GestureDetector(
                onTap: () => onTabSelected(index),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          tabs[index],
                          style: AppTextStyles.titleSmall.copyWith(
                            color: isSelected ? Colors.white : Colors.white54,
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
                              isSelected ? Colors.white : Colors.white54,
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
            );
          }),
        ),
        const Divider(color: Color(0xFF2A2733), height: 1),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

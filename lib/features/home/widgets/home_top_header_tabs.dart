import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../app/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';
import '../provider/home_feed_provider.dart';

class HomeTopHeaderTabs extends StatelessWidget {
  const HomeTopHeaderTabs({
    required this.activeTab,
    required this.activeSubMode,
    required this.onTabSelected,
    required this.onSubModeSelected,
    this.isGuest = false,
    super.key,
  });

  final TopTab activeTab;
  final SubMode activeSubMode;
  final ValueChanged<TopTab> onTabSelected;
  final ValueChanged<SubMode> onSubModeSelected;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final bool isDark = context.isDarkMode;
    final bool isReels = activeSubMode == SubMode.reels;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // ── Top Navigation Bar Stack (Centered Tabs + Top Right Sign up button)
        SizedBox(
          height: 38,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Perfectly Centered Tabs Row (Following | For You | Communities)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // Following Tab
                  _HeaderTabItem(
                    title: l10n.homeTabFollowing,
                    isSelected: activeTab == TopTab.following,
                    isReels: isReels,
                    onTap: () => onTabSelected(TopTab.following),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // For You Tab
                  _HeaderTabItem(
                    title: l10n.homeTabForYou,
                    isSelected: activeTab == TopTab.forYou,
                    isReels: isReels,
                    onTap: () => onTabSelected(TopTab.forYou),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Communities Tab
                  _HeaderTabItem(
                    title: l10n.homeTabCommunities,
                    isSelected: activeTab == TopTab.communities,
                    isReels: isReels,
                    onTap: () => onTabSelected(TopTab.communities),
                  ),
                ],
              ),

              // Top Right "Sign up" Button in Guest Mode (Positioned on far right)
              if (isGuest)
                Positioned(
                  right: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, Routes.register);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.secondaryGradientButton,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: AppColors.gradientCyan.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        l10n.guestSignUpBtn,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // ── Sub-Mode Toggle Container (Reels vs Posts) ──
        Container(
          height: 38,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isReels
                ? Colors.black.withValues(alpha: 0.4)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFF0EFF4)),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isReels
                  ? Colors.white.withValues(alpha: 0.18)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : context.themeBorder),
            ),
            boxShadow: !isReels && !isDark
                ? <BoxShadow>[
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Reels Toggle Item
              _SubModeToggleItem(
                title: l10n.homeSubReels,
                iconPath: AppIcons.play,
                isSelected: isReels,
                isReelsMode: isReels,
                onTap: () => onSubModeSelected(SubMode.reels),
              ),

              const SizedBox(width: 3),

              // Posts Toggle Item
              _SubModeToggleItem(
                title: l10n.homeSubPosts,
                iconPath: AppIcons.posts,
                isSelected: !isReels,
                isReelsMode: isReels,
                onTap: () => onSubModeSelected(SubMode.posts),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderTabItem extends StatelessWidget {
  const _HeaderTabItem({
    required this.title,
    required this.isSelected,
    required this.isReels,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final bool isReels;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    // When on full-screen video Reels, ALWAYS use bright white so it's readable over any video
    final Color activeColor =
        (isReels || isDark) ? Colors.white : context.themeTextPrimary;
    final Color inactiveColor =
        (isReels || isDark) ? Colors.white.withValues(alpha: 0.75) : context.themeTextSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              shadows: isReels
                  ? const <Shadow>[
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2.5,
            width: isSelected ? 24 : 0,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(1.5),
              boxShadow: isReels && isSelected
                  ? const <BoxShadow>[
                      BoxShadow(
                        color: Colors.black54,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubModeToggleItem extends StatelessWidget {
  const _SubModeToggleItem({
    required this.title,
    required this.iconPath,
    required this.isSelected,
    required this.isReelsMode,
    required this.onTap,
  });

  final String title;
  final String iconPath;
  final bool isSelected;
  final bool isReelsMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    // Unselected text & icon colors
    final Color unselectedColor =
        (isReelsMode || isDark) ? Colors.white : context.themeTextPrimary;

    // Selected text & icon colors
    final Color selectedColor = Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isReelsMode ? 0.3 : 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgPicture.asset(
              iconPath,
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(
                isSelected ? selectedColor : unselectedColor,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? selectedColor : unselectedColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

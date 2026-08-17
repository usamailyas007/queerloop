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
                    onTap: () => onTabSelected(TopTab.following),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // For You Tab
                  _HeaderTabItem(
                    title: l10n.homeTabForYou,
                    isSelected: activeTab == TopTab.forYou,
                    onTap: () => onTabSelected(TopTab.forYou),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Communities Tab
                  _HeaderTabItem(
                    title: l10n.homeTabCommunities,
                    isSelected: activeTab == TopTab.communities,
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

        // ── Sub-Mode Toggle Container (Reels vs Posts - Matching Image 3) ──
        Container(
          height: 38,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Reels Toggle Item (Solid White Active Pill with Dark Black Text/Icon)
              _SubModeToggleItem(
                title: l10n.homeSubReels,
                iconPath: AppIcons.play,
                isSelected: activeSubMode == SubMode.reels,
                onTap: () => onSubModeSelected(SubMode.reels),
              ),

              const SizedBox(width: 4),

              // Posts Toggle Item
              _SubModeToggleItem(
                title: l10n.homeSubPosts,
                iconPath: AppIcons.posts,
                isSelected: activeSubMode == SubMode.posts,
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
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white54,
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 2,
            width: isSelected ? 24 : 0,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(1),
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
    required this.onTap,
  });

  final String title;
  final String iconPath;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SvgPicture.asset(
              iconPath,
              width: 14,
              height: 14,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.black : Colors.black,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: Colors.black,
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

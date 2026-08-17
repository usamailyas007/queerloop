import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_icons.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

class HomeBottomNavBar extends StatelessWidget {
  const HomeBottomNavBar({
    required this.currentIndex,
    required this.onTap,
    this.isGuest = false,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isGuest;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    // System navigation bar ka bottom inset check karo
    // Agar system nav bar hai (buttons wala) to zyada padding, warna sirf 8px
    final double systemNavBarHeight =
        MediaQuery.of(context).viewPadding.bottom;
    final double bottomPadding =
        systemNavBarHeight > 0 ? systemNavBarHeight + 4 : 8;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        height: 72,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.bottomBarBackground.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            // 1. Home
            _NavItem(
              iconPath: AppIcons.home,
              label: l10n.homeNavHome,
              isSelected: currentIndex == 0,
              onTap: () => onTap(0),
            ),

            // 2. Discover
            _NavItem(
              iconPath: AppIcons.discover,
              label: l10n.homeNavDiscover,
              isSelected: currentIndex == 1,
              onTap: () => onTap(1),
            ),

            // 3. Center (+) Button in Regular Mode / Lock Icon in Guest Mode
            GestureDetector(
              onTap: () => onTap(2),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isGuest ? null : AppColors.secondaryGradientButton,
                  color: isGuest ? Colors.white.withValues(alpha: 0.12) : null,
                  boxShadow: isGuest
                      ? null
                      : <BoxShadow>[
                          BoxShadow(
                            color: AppColors.gradientPink.withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 5),
                          ),
                        ],
                ),
                child: Icon(
                  isGuest ? Icons.lock_outline_rounded : Icons.add_rounded,
                  color: isGuest ? Colors.white54 : Colors.white,
                  size: isGuest ? AppSizes.iconMd : 28,
                ),
              ),
            ),

            // 4. Messages
            _NavItem(
              iconPath: AppIcons.msg,
              label: l10n.homeNavMessages,
              isSelected: currentIndex == 3,
              onTap: () => onTap(3),
            ),

            // 5. Profile
            _NavItem(
              iconPath: AppIcons.user,
              label: l10n.homeNavProfile,
              isSelected: currentIndex == 4,
              onTap: () => onTap(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.iconPath,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String iconPath;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = AppColors.gradientPink;
    final Color inactiveColor = Colors.white54;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SvgPicture.asset(
            iconPath,
            width: AppSizes.iconMd,
            height: AppSizes.iconMd,
            colorFilter: ColorFilter.mode(
              isSelected ? activeColor : inactiveColor,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: isSelected ? activeColor : inactiveColor,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

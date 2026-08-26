import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../l10n/app_localizations.dart';

class PrivacyOptionCard extends StatelessWidget {
  const PrivacyOptionCard({
    required this.optionTitle,
    required this.isSelected,
    required this.onTap,
    super.key,
    this.isRecommended = false,
  });

  final String optionTitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isRecommended;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.themeCyanBadgeBackground
              : context.themeCardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.gradientCyan
                : context.themeBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    optionTitle,
                    style: TextStyle(
                      color: context.themeTextPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (isSelected && isRecommended) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      l10n.profileRecommendedDefault,
                      style: TextStyle(
                        color: context.themeTextMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.gradientCyan : context.themeIconMuted,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

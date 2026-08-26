import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class AppFollowButton extends StatelessWidget {
  const AppFollowButton({
    required this.isFollowing,
    required this.onTap,
    this.isRequested = false,
    this.isOverMedia = false,
    super.key,
  });

  final bool isFollowing;
  final bool isRequested;
  final bool isOverMedia;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String label = isRequested
        ? 'Request'
        : (isFollowing ? l10n.homeFollowing : l10n.homeFollow);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isRequested
            ? _RequestPill(key: const ValueKey<String>('request'), label: label)
            : (isFollowing
                ? _FollowingPill(
                    key: const ValueKey<String>('following'),
                    label: label,
                    isOverMedia: isOverMedia,
                  )
                : _FollowPill(
                    key: const ValueKey<String>('follow'),
                    label: label,
                  )),
      ),
    );
  }
}

/// "Follow" — secondary pink-to-cyan gradient pill matching design
class _FollowPill extends StatelessWidget {
  const _FollowPill({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.secondaryGradientButton,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// "Following" — outline pill matching Light and Dark designs
class _FollowingPill extends StatelessWidget {
  const _FollowingPill({
    required this.label,
    this.isOverMedia = false,
    super.key,
  });

  final String label;
  final bool isOverMedia;

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkMode;

    if (isOverMedia) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w700,
            shadows: <Shadow>[
              Shadow(
                color: Colors.black54,
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.22)
              : context.themeBorder,
          width: 1.2,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isDark ? Colors.white54 : context.themeTextPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// "Request" — grey pill for pending requests
class _RequestPill extends StatelessWidget {
  const _RequestPill({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF757575),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class AppFollowButton extends StatelessWidget {
  const AppFollowButton({
    required this.isFollowing,
    required this.onTap,
    super.key,
  });

  final bool isFollowing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final String label =
        isFollowing ? l10n.homeFollowing : l10n.homeFollow;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: isFollowing
            ? _FollowingPill(key: const ValueKey<String>('following'), label: label)
            : _FollowPill(key: const ValueKey<String>('follow'), label: label),
      ),
    );
  }
}

/// "Follow" — gradient pill
class _FollowPill extends StatelessWidget {
  const _FollowPill({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradientButton,
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

/// "Following" — outline pill
class _FollowingPill extends StatelessWidget {
  const _FollowingPill({required this.label, super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

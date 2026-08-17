import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../models/community_model.dart';

class CommunityCardTile extends StatelessWidget {
  const CommunityCardTile({
    required this.community,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final CommunityModel community;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1B26),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.gradientCyan
                : Colors.white.withValues(alpha: 0.12),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Image.asset(
                  community.avatarAsset,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackAvatar(),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                community.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_rounded : Icons.add_rounded,
              color: isSelected ? AppColors.gradientCyan : Colors.white54,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: 40,
      height: 40,
      color: const Color(0xFF2C1929),
      child: const Icon(
        Icons.groups_rounded,
        color: AppColors.gradientPink,
        size: 20,
      ),
    );
  }
}

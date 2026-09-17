import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../models/analytics_overview.dart';

class ContentMixCard extends StatelessWidget {
  const ContentMixCard({required this.overview, super.key});

  final AnalyticsOverview? overview;

  static Color _color(String type) {
    switch (type.toUpperCase()) {
      case 'VIDEO':
        return AppColors.moderatorPink;
      case 'PHOTO':
        return AppColors.gradientCyan;
      case 'TEXT':
      default:
        return AppColors.adminPurple;
    }
  }

  static String _label(String type) {
    switch (type.toUpperCase()) {
      case 'VIDEO':
        return 'Short video';
      case 'PHOTO':
        return 'Image posts';
      case 'TEXT':
        return 'Text posts';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final AnalyticsOverview? o = overview;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'What people post',
              style: TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (o != null && o.contentMix.isNotEmpty) ...<Widget>[
              for (final ContentMixItem item in o.contentMix)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            _label(item.type),
                            style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
                          ),
                          Text(
                            '${item.count} (${o.totalContentCount > 0 ? (item.count / o.totalContentCount * 100).toStringAsFixed(0) : 0}%)',
                            style: const TextStyle(
                              color: AppColors.adminTextPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: o.totalContentCount > 0 ? item.count / o.totalContentCount : 0.0,
                          minHeight: 6,
                          backgroundColor: const Color(0xFF1C1824),
                          valueColor: AlwaysStoppedAnimation<Color>(_color(item.type)),
                        ),
                      ),
                    ],
                  ),
                ),
            ] else
              const Text('No content mix data', style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12)),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Top hashtags',
              style: TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (o != null && o.topHashtags.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final TopHashtagItem item in o.topHashtags)
                    AppTagChip(
                      label: '${item.tag} (${item.count})',
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 12),
                    ),
                ],
              )
            else
              const Text('No top hashtags yet', style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

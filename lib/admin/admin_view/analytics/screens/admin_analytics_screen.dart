import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../admin_icons.dart';
import '../../widgets/admin_stat_card.dart';
import '../models/analytics_overview.dart';
import '../provider/analytics_provider.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  static const List<(String, String)> _ranges = <(String, String)>[
    ('Today', '1d'),
    ('7 days', '7d'),
    ('30 days', '30d'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnalyticsProvider>().loadInitial();
      }
    });
  }

  Color _contentMixColor(String type) {
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

  String _contentMixLabel(String type) {
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
    final AnalyticsProvider provider = context.watch<AnalyticsProvider>();
    final AnalyticsOverview? overview = provider.overview;
    final bool loading = provider.isLoadingOverview && overview == null;

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ── Header Row ──────────────────────────────────────────────
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Analytics',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Overview metrics for range: ${provider.range}',
                          style: const TextStyle(
                            color: AppColors.adminTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.adminSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.adminBorder),
                    ),
                    child: Row(
                      children: <Widget>[
                        for (int i = 0; i < _ranges.length; i++)
                          GestureDetector(
                            onTap: () => provider.setRange(_ranges[i].$2),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: provider.range == _ranges[i].$2
                                    ? AppColors.moderatorChipSelected
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                _ranges[i].$1,
                                style: TextStyle(
                                  color: provider.range == _ranges[i].$2
                                      ? AppColors.adminTextPrimary
                                      : AppColors.adminTextSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Content State ──────────────────────────────────────────
              if (loading)
                const Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.adminPink,
                      ),
                    ),
                  ),
                )
              else if (provider.overviewError != null && overview == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          provider.overviewError!,
                          style: const TextStyle(
                            color: AppColors.adminTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: 120,
                          child: AppOutlineButton(
                            text: 'Retry',
                            height: 38,
                            onPressed: provider.fetchOverview,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: Column(
                    children: <Widget>[
                      // ── Stat Cards ───────────────────────────────────────
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: AdminStatCard(
                              label: 'Retention',
                              value: overview?.retention != null
                                  ? '${overview!.retention!.toStringAsFixed(0)}%'
                                  : 'N/A',
                              delta: provider.range,
                              deltaColor: AppColors.adminTextMuted,
                              iconPath: AdminIcons.chart,
                              iconColor: AppColors.adminGreen,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AdminStatCard(
                              label: 'Avg session',
                              value: overview?.avgSessionDuration != null
                                  ? '${overview!.avgSessionDuration!.toStringAsFixed(0)}s'
                                  : 'N/A',
                              delta: provider.range,
                              deltaColor: AppColors.adminTextMuted,
                              iconPath: AdminIcons.globe,
                              iconColor: AppColors.gradientCyan,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AdminStatCard(
                              label: 'Posts per person',
                              value: (overview?.postsPerPerson ?? 0.0)
                                  .toStringAsFixed(1),
                              delta: 'Average',
                              deltaColor: AppColors.adminTextMuted,
                              iconPath: AdminIcons.image,
                              iconColor: AppColors.adminPurpleSoft,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AdminStatCard(
                              label: 'Reports per 1k posts',
                              value: (overview?.reportsPer1kPosts ?? 0.0)
                                  .toStringAsFixed(0),
                              delta: provider.range,
                              deltaColor: AppColors.adminOrange,
                              iconPath: AdminIcons.shield,
                              iconColor: AppColors.adminOrange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.md),

                      // ── Breakdown Cards ──────────────────────────────────
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            // What people post & Top hashtags
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.adminSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.adminBorder,
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text(
                                        'What people post',
                                        style: TextStyle(
                                          color: AppColors.adminTextPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      if (overview != null &&
                                          overview.contentMix.isNotEmpty) ...<Widget>[
                                        for (final ContentMixItem item
                                            in overview.contentMix)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: AppSpacing.md,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: <Widget>[
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.spaceBetween,
                                                  children: <Widget>[
                                                    Text(
                                                      _contentMixLabel(item.type),
                                                      style: const TextStyle(
                                                        color: AppColors.adminTextSecondary,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                    Text(
                                                      '${item.count} (${overview.totalContentCount > 0 ? (item.count / overview.totalContentCount * 100).toStringAsFixed(0) : 0}%)',
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
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  child: LinearProgressIndicator(
                                                    value: overview.totalContentCount > 0
                                                        ? item.count / overview.totalContentCount
                                                        : 0.0,
                                                    minHeight: 6,
                                                    backgroundColor: const Color(
                                                      0xFF1C1824,
                                                    ),
                                                    valueColor:
                                                        AlwaysStoppedAnimation<Color>(
                                                      _contentMixColor(item.type),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ] else
                                        const Text(
                                          'No content mix data',
                                          style: TextStyle(
                                            color: AppColors.adminTextMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      const SizedBox(height: AppSpacing.sm),
                                      const Text(
                                        'Top hashtags',
                                        style: TextStyle(
                                          color: AppColors.adminTextPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      if (overview != null &&
                                          overview.topHashtags.isNotEmpty)
                                        Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: <Widget>[
                                            for (final TopHashtagItem item
                                                in overview.topHashtags)
                                              AppTagChip(
                                                label: '${item.tag} (${item.count})',
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 12,
                                                  vertical: 6,
                                                ),
                                                textStyle: const TextStyle(
                                                  color: AppColors.adminTextSecondary,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        )
                                      else
                                        const Text(
                                          'No top hashtags yet',
                                          style: TextStyle(
                                            color: AppColors.adminTextMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            // Safety outcomes
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color: AppColors.adminSurface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.adminBorder,
                                  ),
                                ),
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Safety outcomes · ${provider.range}',
                                        style: const TextStyle(
                                          color: AppColors.adminTextPrimary,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.lg),
                                      if (overview != null) ...<Widget>[
                                        _SafetyRow(
                                          label: 'Reports received',
                                          value: '${overview.safetyOutcomes.received}',
                                        ),
                                        _SafetyRow(
                                          label: 'Content hidden',
                                          value: '${overview.safetyOutcomes.hidden}',
                                        ),
                                        _SafetyRow(
                                          label: 'Accounts warned',
                                          value: '${overview.safetyOutcomes.warned}',
                                        ),
                                        _SafetyRow(
                                          label: 'Accounts suspended',
                                          value: '${overview.safetyOutcomes.suspended}',
                                        ),
                                        _SafetyRow(
                                          label: 'Accounts banned',
                                          value: '${overview.safetyOutcomes.banned}',
                                        ),
                                        _SafetyRow(
                                          label: 'In queue',
                                          value: '${overview.safetyOutcomes.inQueue}',
                                        ),
                                        _SafetyRow(
                                          label: 'Avg response time',
                                          value: '${overview.safetyOutcomes.avgResponseHours.toStringAsFixed(1)}h',
                                        ),
                                        _SafetyRow(
                                          label: 'Appeals reversed',
                                          value: '${overview.safetyOutcomes.appealsReversed} of ${overview.safetyOutcomes.appealsTotal}',
                                          color: AppColors.adminGreen,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: AppColors.adminTextSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.adminTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

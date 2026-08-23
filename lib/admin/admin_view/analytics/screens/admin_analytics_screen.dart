import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_tag_chip.dart';
import '../../admin_icons.dart';
import '../../widgets/admin_stat_card.dart';

class _PostShare {
  const _PostShare({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final int percent;
  final Color color;
}

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
  int _rangeIndex = 2;

  static const List<_PostShare> _postShares = <_PostShare>[
    _PostShare(label: 'Short video', percent: 64, color: AppColors.moderatorPink),
    _PostShare(label: 'Text posts', percent: 24, color: AppColors.adminPurple),
    _PostShare(label: 'Image posts', percent: 12, color: AppColors.gradientCyan),
  ];

  static const List<String> _hashtags = <String>[
    '#chosenfamily',
    '#pridprep2026',
    '#binderfitcheck',
    '#queerbooktok',
    '#transjoy',
  ];

  static const List<(String, String, Color?)> _safetyOutcomes =
      <(String, String, Color?)>[
    ('Reports received', '1,284', null),
    ('Content hidden', '402', null),
    ('Accounts warned', '318', null),
    ('Accounts suspended', '96', null),
    ('Accounts banned', '31', null),
    ('Appeals upheld', '22 of 74', AppColors.adminGreen),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Analytics',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 24,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '1 July - 2 August 2026',
                          style: TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.adminSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.adminBorder),
                    ),
                    child: Row(
                      children: <Widget>[
                        for (final (int i, String label) in const <(
                          int,
                          String
                        )>[
                          (0, 'Today'),
                          (1, '7 days'),
                          (2, '30 days'),
                        ])
                          GestureDetector(
                            onTap: () => setState(() => _rangeIndex = i),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: _rangeIndex == i
                                    ? AppColors.moderatorChipSelected
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                label,
                                style: TextStyle(
                                  color: _rangeIndex == i
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

              const Row(
                children: <Widget>[
                  Expanded(
                    child: AdminStatCard(
                      label: 'Retention',
                      value: '48%',
                      delta: '+3 pts',
                      iconPath: AdminIcons.chart,
                      iconColor: AppColors.adminGreen,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AdminStatCard(
                      label: 'Avg session',
                      value: '18m 40s',
                      delta: '+52s',
                      iconPath: AdminIcons.globe,
                      iconColor: AppColors.gradientCyan,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AdminStatCard(
                      label: 'Posts per person',
                      value: '2.4',
                      delta: 'Weekly average',
                      deltaColor: AppColors.adminTextMuted,
                      iconPath: AdminIcons.image,
                      iconColor: AppColors.adminPurpleSoft,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AdminStatCard(
                      label: 'Reports per 1k posts',
                      value: '14.3',
                      delta: '-1.8 vs June',
                      deltaColor: AppColors.adminOrange,
                      iconPath: AdminIcons.shield,
                      iconColor: AppColors.adminOrange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.adminSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.adminBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'What people post',
                              style: TextStyle(
                                  color: AppColors.adminTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            for (final _PostShare share in _postShares)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Text(share.label,
                                            style: const TextStyle(
                                                color: AppColors.adminTextSecondary,
                                                fontSize: 13)),
                                        Text('${share.percent}%',
                                            style: const TextStyle(
                                                color: AppColors.adminTextPrimary,
                                                fontSize: 12,
                                                fontWeight:
                                                    FontWeight.w700)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: share.percent / 100,
                                        minHeight: 6,
                                        backgroundColor: const Color(
                                          0xFF1C1824,
                                        ),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                share.color),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              'Top hashtags',
                              style: TextStyle(
                                  color: AppColors.adminTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                for (final String tag in _hashtags)
                                  AppTagChip(
                                    label: tag,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    textStyle: const TextStyle(
                                        color: AppColors.adminTextSecondary, fontSize: 12),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.adminSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.adminBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Safety outcomes · 30 days',
                              style: TextStyle(
                                  color: AppColors.adminTextPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            for (final (String label, String value, Color? color)
                                in _safetyOutcomes)
                              Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(label,
                                        style: const TextStyle(
                                            color: AppColors.adminTextSecondary,
                                            fontSize: 13)),
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
                              ),
                          ],
                        ),
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

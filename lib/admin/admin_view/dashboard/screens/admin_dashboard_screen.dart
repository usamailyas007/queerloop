import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../admin_icons.dart';
import '../../analytics/models/analytics_dashboard.dart';
import '../../analytics/models/analytics_overview.dart';
import '../../analytics/provider/analytics_provider.dart';
import '../../widgets/admin_stat_card.dart';

class _Bar {
  const _Bar({required this.height, required this.style});

  final double height;
  final _BarStyle style;
}

enum _BarStyle { muted, pink, purple }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const List<String> _rangeKeys = <String>['1d', '7d', '30d'];

  static const List<_Bar> _dailyActiveBars = <_Bar>[
    _Bar(height: 53.19, style: _BarStyle.muted),
    _Bar(height: 61.59, style: _BarStyle.muted),
    _Bar(height: 57.39, style: _BarStyle.muted),
    _Bar(height: 72.8, style: _BarStyle.muted),
    _Bar(height: 68.59, style: _BarStyle.muted),
    _Bar(height: 81.19, style: _BarStyle.muted),
    _Bar(height: 88.19, style: _BarStyle.muted),
    _Bar(height: 79.8, style: _BarStyle.muted),
    _Bar(height: 92.39, style: _BarStyle.pink),
    _Bar(height: 103.59, style: _BarStyle.pink),
    _Bar(height: 96.59, style: _BarStyle.pink),
    _Bar(height: 114.8, style: _BarStyle.pink),
    _Bar(height: 109.19, style: _BarStyle.purple),
    _Bar(height: 127.39, style: _BarStyle.purple),
    _Bar(height: 120.39, style: _BarStyle.purple),
    _Bar(height: 140, style: _BarStyle.purple),
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

  int _getRangeIndex(String key) {
    final int idx = _rangeKeys.indexOf(key);
    return idx >= 0 ? idx : 2;
  }

  @override
  Widget build(BuildContext context) {
    final AnalyticsProvider provider = context.watch<AnalyticsProvider>();
    final AnalyticsDashboard? dash = provider.dashboard;
    final AnalyticsOverview? overview = provider.overview;

    final int maxMembers = (overview?.communitySizes.isNotEmpty == true)
        ? overview!.communitySizes
            .map((CommunitySizeItem e) => e.memberCount)
            .reduce((int a, int b) => a > b ? a : b)
        : 1;

    return Scaffold(
      backgroundColor: AppColors.adminBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ── Header Bar ──────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Platform overview',
                          style: TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 26,
                            letterSpacing: -0.52,
                          ),
                        ),
                        const SizedBox(height: 4),
                        RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              color: AppColors.adminTextSecondary,
                              fontSize: 13,
                            ),
                            children: <TextSpan>[
                              const TextSpan(text: 'Range: '),
                              TextSpan(
                                text: provider.range,
                                style: const TextStyle(
                                  color: AppColors.adminTextPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 240,
                    height: 38,
                    child: AppTextField(
                      hintText: 'Search users, cases, communities…',
                      prefixIconPath: AdminIcons.search,
                      fillColor: AppColors.adminSurface,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  _RangePills(
                    selectedIndex: _getRangeIndex(provider.range),
                    onChanged: (int index) =>
                        provider.setRange(_rangeKeys[index]),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Stat Cards ────────────────────────────────────────────
              Row(
                children: <Widget>[
                  Expanded(
                    child: AdminStatCard(
                      label: 'Daily active',
                      value: dash?.dailyActive != null
                          ? '${dash!.dailyActive}'
                          : 'N/A',
                      delta: provider.range,
                      deltaColor: AppColors.adminTextMuted,
                      iconPath: AdminIcons.users,
                      iconColor: AppColors.adminPurple,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AdminStatCard(
                      label: 'New sign-ups',
                      value: '${dash?.newSignups ?? 0}',
                      delta: provider.range,
                      deltaColor: AppColors.adminTextMuted,
                      iconPath: AdminIcons.userSingle,
                      iconColor: AppColors.adminTeal,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AdminStatCard(
                      label: 'Posts in range',
                      value: '${dash?.postsInRange ?? 0}',
                      delta: '${(dash?.videoSharePct ?? 0.0).toStringAsFixed(0)}% video',
                      deltaColor: AppColors.adminTextSecondary,
                      iconPath: AdminIcons.image,
                      iconColor: AppColors.adminBlue,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AdminStatCard(
                      label: 'Open reports',
                      value: '${dash?.openReports ?? 0}',
                      valueColor: AppColors.adminOrange,
                      delta: 'Avg response ${(dash?.avgResponseHours ?? 0.0).toStringAsFixed(1)}h',
                      deltaColor: AppColors.adminOrange,
                      iconPath: AdminIcons.shield,
                      iconColor: AppColors.adminOrange,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // ── Charts Row ────────────────────────────────────────────
              SizedBox(
                height: 486,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      flex: 3,
                      child: _ChartCard(
                        title: 'Daily active people',
                        subtitle: provider.range,
                        trailing: Text(
                          dash?.dailyActive != null
                              ? '${dash!.dailyActive} active'
                              : 'Live analytics',
                          style: const TextStyle(
                            color: AppColors.adminTeal,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              for (final _Bar bar in _dailyActiveBars)
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    child: FractionallySizedBox(
                                      heightFactor: bar.height / 140,
                                      alignment: Alignment.bottomCenter,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: bar.style == _BarStyle.muted
                                              ? AppColors.adminSurfaceAlt
                                              : null,
                                          gradient: bar.style == _BarStyle.muted
                                              ? null
                                              : LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: bar.style ==
                                                          _BarStyle.pink
                                                      ? const <Color>[
                                                          AppColors.adminPink,
                                                          AppColors
                                                              .adminPinkFaded,
                                                        ]
                                                      : const <Color>[
                                                          AppColors.adminPurple,
                                                          AppColors
                                                              .adminPurpleFaded,
                                                        ],
                                                ),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                            top: Radius.circular(3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: _ChartCard(
                        title: 'Community size',
                        subtitle: 'Members per group',
                        child: Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.md),
                          child: (overview != null &&
                                  overview.communitySizes.isNotEmpty)
                              ? SingleChildScrollView(
                                  child: Column(
                                    children: <Widget>[
                                      for (final CommunitySizeItem item
                                          in overview.communitySizes)
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
                                                    item.name,
                                                    style: const TextStyle(
                                                      color: AppColors.adminTextPrimary,
                                                      fontSize: 12.5,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    '${item.memberCount} members',
                                                    style: const TextStyle(
                                                      color: AppColors.adminTextSecondary,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                                child: LinearProgressIndicator(
                                                  value: maxMembers > 0
                                                      ? item.memberCount / maxMembers
                                                      : 0.0,
                                                  minHeight: 8,
                                                  backgroundColor: const Color(
                                                    0xFF1C1824,
                                                  ),
                                                  valueColor:
                                                      const AlwaysStoppedAnimation<
                                                        Color
                                                      >(AppColors.adminPurple),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                )
                              : const Center(
                                  child: Text(
                                    'No community size data available',
                                    style: TextStyle(
                                      color: AppColors.adminTextMuted,
                                      fontSize: 12,
                                    ),
                                  ),
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
      ),
    );
  }
}

class _RangePills extends StatelessWidget {
  const _RangePills({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  static const List<String> _labels = <String>['Today', '7 days', '30 days'];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Row(
        children: <Widget>[
          for (int i = 0; i < _labels.length; i++)
            GestureDetector(
              onTap: () => onChanged(i),
              child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: selectedIndex == i
                      ? AppColors.adminSurfaceAlt
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    color: selectedIndex == i
                        ? AppColors.adminTextPrimary
                        : AppColors.adminTextSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.adminTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.adminTextMuted,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
              ?trailing,
            ],
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

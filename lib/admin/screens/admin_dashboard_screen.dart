import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_text_field.dart';
import '../admin_icons.dart';
import '../widgets/admin_stat_card.dart';

class _Bar {
  const _Bar({required this.height, required this.style});

  final double height;
  final _BarStyle style;
}

enum _BarStyle { muted, pink, purple }

class _CommunitySize {
  const _CommunitySize({
    required this.label,
    required this.members,
    required this.fraction,
  });

  final String label;
  final String members;
  final double fraction;
}

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _rangeIndex = 2; // 0: Today, 1: 7 days, 2: 30 days

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

  static const List<_CommunitySize> _communitySizes = <_CommunitySize>[
    _CommunitySize(label: 'Gay', members: '312K', fraction: 1.0),
    _CommunitySize(label: 'Queer', members: '227K', fraction: 0.7276),
    _CommunitySize(label: 'Bisexual', members: '201K', fraction: 0.644),
    _CommunitySize(label: 'Lesbian', members: '184K', fraction: 0.590),
    _CommunitySize(label: 'Transgender', members: '156K', fraction: 0.5),
    _CommunitySize(label: 'Non-binary', members: '98K', fraction: 0.314),
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
                          text: const TextSpan(
                            style: TextStyle(
                              color: AppColors.adminTextSecondary,
                              fontSize: 13,
                            ),
                            children: <TextSpan>[
                              TextSpan(
                                text: 'Sunday, 2 August · last updated ',
                              ),
                              TextSpan(
                                text: '2 minutes ago',
                                style: TextStyle(
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
                    selectedIndex: _rangeIndex,
                    onChanged: (int index) =>
                        setState(() => _rangeIndex = index),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Stat Cards ────────────────────────────────────────────
              const Row(
                children: <Widget>[
                  Expanded(
                    child: AdminStatCard(
                      label: 'Daily active',
                      value: '86,412',
                      delta: '+7.4% vs last week',
                      iconPath: AdminIcons.users,
                      iconColor: AppColors.adminPurple,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AdminStatCard(
                      label: 'New sign-ups',
                      value: '3,208',
                      delta: '+12.1%',
                      iconPath: AdminIcons.userSingle,
                      iconColor: AppColors.adminTeal,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AdminStatCard(
                      label: 'Posts today',
                      value: '21,749',
                      delta: '64% video',
                      deltaColor: AppColors.adminTextSecondary,
                      iconPath: AdminIcons.image,
                      iconColor: AppColors.adminBlue,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: AdminStatCard(
                      label: 'Open reports',
                      value: '28',
                      valueColor: AppColors.adminOrange,
                      delta: 'Avg response 4.2h',
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
                        subtitle: '30 days',
                        trailing: const Text(
                          'Peak 91.2K on 28 Jul',
                          style: TextStyle(
                            color: AppColors.adminTeal,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        footer: const Padding(
                          padding: EdgeInsets.only(top: AppSpacing.sm),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                '3 Jul',
                                style: TextStyle(
                                  color: AppColors.adminTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '18 Jul',
                                style: TextStyle(
                                  color: AppColors.adminTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                '2 Aug',
                                style: TextStyle(
                                  color: AppColors.adminTextMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
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
                                                  colors:
                                                      bar.style ==
                                                          _BarStyle.pink
                                                      ? const <Color>[
                                                          AppColors.adminPink,
                                                          AppColors.adminPinkFaded,
                                                        ]
                                                      : const <Color>[
                                                          AppColors.adminPurple,
                                                          AppColors.adminPurpleFaded,
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
                          child: Column(
                            children: <Widget>[
                              for (final _CommunitySize item in _communitySizes)
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
                                            item.label,
                                            style: const TextStyle(
                                              color: AppColors.adminTextPrimary,
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Text(
                                            item.members,
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
                                        borderRadius: BorderRadius.circular(5),
                                        child: LinearProgressIndicator(
                                          value: item.fraction,
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
    this.footer,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final Widget? footer;

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
          ?footer,
        ],
      ),
    );
  }
}

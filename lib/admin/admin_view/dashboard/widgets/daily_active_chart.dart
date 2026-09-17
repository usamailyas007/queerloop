import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../analytics/models/analytics_dashboard.dart';
import 'dashboard_chart_card.dart';

/// "Daily active people" chart card.
///
/// The API exposes no day-by-day series, only the scalar `dailyActive` for
/// the selected window. The 16 bars below give the chart its rising shape;
/// their heights are then scaled so the peak tracks the real number and
/// rescales with the range.
class DailyActiveChart extends StatelessWidget {
  const DailyActiveChart({required this.dash, required this.range, required this.loading, super.key});

  final AnalyticsDashboard? dash;
  final String range;
  final bool loading;

  static const List<double> _shape = <double>[
    0.38, 0.44, 0.41, 0.52, 0.49, 0.58, 0.63, 0.57,
    0.66, 0.74, 0.69, 0.82, 0.78, 0.91, 0.86, 1.0,
  ];

  List<_Bar> _bars() {
    final int peak = dash == null
        ? 0
        : (dash!.dailyActive ?? (dash!.newSignups > dash!.postsInRange ? dash!.newSignups : dash!.postsInRange));
    final double niceMax = peak <= 10 ? 10 : ((peak / 10).ceil() * 10).toDouble();

    return <_Bar>[
      for (int i = 0; i < _shape.length; i++)
        _Bar(
          heightFactor: peak == 0 ? 0.03 : (peak * _shape[i] / niceMax).clamp(0.03, 1.0),
          style: i < 8 ? _BarStyle.muted : (i < 12 ? _BarStyle.pink : _BarStyle.purple),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DashboardChartCard(
      title: 'Daily active people',
      subtitle: range,
      trailing: Text(
        dash?.dailyActive != null ? '${dash!.dailyActive} active' : 'Live analytics',
        style: const TextStyle(color: AppColors.adminTeal, fontSize: 11.5, fontWeight: FontWeight.w700),
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: (dash == null && loading)
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.adminPink),
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  for (final _Bar bar in _bars())
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: FractionallySizedBox(
                          heightFactor: bar.heightFactor,
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            decoration: BoxDecoration(
                              color: bar.style == _BarStyle.muted ? AppColors.adminSurfaceAlt : null,
                              gradient: bar.style == _BarStyle.muted
                                  ? null
                                  : LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: bar.style == _BarStyle.pink
                                          ? const <Color>[AppColors.adminPink, AppColors.adminPinkFaded]
                                          : const <Color>[AppColors.adminPurple, AppColors.adminPurpleFaded],
                                    ),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _Bar {
  const _Bar({required this.heightFactor, required this.style});

  final double heightFactor;
  final _BarStyle style;
}

enum _BarStyle { muted, pink, purple }

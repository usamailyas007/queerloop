import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../reports/models/mod_report.dart';
import '../../reports/provider/mod_reports_provider.dart';
import '../../reports_queue/screens/moderator_case_detail_review_screen.dart';

class ModeratorDashboardScreen extends StatefulWidget {
  const ModeratorDashboardScreen({this.onOpenQueue, super.key});

  final VoidCallback? onOpenQueue;

  @override
  State<ModeratorDashboardScreen> createState() =>
      _ModeratorDashboardScreenState();
}

class _ModeratorDashboardScreenState extends State<ModeratorDashboardScreen> {
  bool _reviewing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ModReportsProvider>().loadDashboard();
      }
    });
  }

  Future<void> _open(ModReport report) async {
    await context.read<ModReportsProvider>().openReport(report: report);
    if (mounted) {
      setState(() => _reviewing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewing) {
      return ModeratorCaseDetailReviewScreen(
        onBack: () {
          setState(() => _reviewing = false);
          context.read<ModReportsProvider>().refreshDashboard();
        },
      );
    }

    return Scaffold(
      backgroundColor: AppColors.moderatorBackground,
      body: SafeArea(
        child: Consumer<ModReportsProvider>(
          builder: (_, ModReportsProvider provider, _) {
            final ModDashboard d = provider.dashboard;
            final bool blank = d.inQueue == 0 &&
                d.reportsByReason.isEmpty &&
                d.needsYouFirst.isEmpty &&
                d.nextUp.isEmpty;

            if (provider.isLoadingDashboard && blank) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.moderatorPink),
              );
            }

            return RefreshIndicator(
              color: AppColors.moderatorPink,
              backgroundColor: AppColors.moderatorSurface,
              onRefresh: provider.refreshDashboard,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.xl),
                children: <Widget>[
                  _headerRow(d),
                  if (provider.dashboardError != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.md),
                    _ErrorBanner(
                      message: provider.dashboardError!,
                      onRetry: provider.refreshDashboard,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  _metricRow(d),
                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: _reasonsCard(d)),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(child: _needsYouCard(d)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  _nextUpCard(d),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _headerRow(ModDashboard d) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Moderator dashboard',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              d.avgResponseHours == 0
                  ? '${d.inQueue} in queue'
                  : '${d.inQueue} in queue · avg response '
                      '${d.avgResponseHours.toStringAsFixed(1)}h',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.moderatorTextMuted,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const Spacer(),
        GestureDetector(
          onTap: widget.onOpenQueue,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: <Color>[
                  AppColors.moderatorPink,
                  AppColors.gradientCyan,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(Icons.flag_outlined,
                    color: AppColors.moderatorTextPrimary, size: 16),
                SizedBox(width: 6),
                Text(
                  'Open queue',
                  style: TextStyle(
                    color: AppColors.moderatorTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Metric cards ──────────────────────────────────────────────────────────

  Widget _metricRow(ModDashboard d) {
    return Row(
      children: <Widget>[
        _metricCard(
          'IN QUEUE',
          '${d.inQueue}',
          '${d.waitingOver12h} waiting over 12h',
        ),
        const SizedBox(width: AppSpacing.md),
        _metricCard(
          'RESOLVED TODAY',
          '${d.resolvedToday}',
          'You handled ${d.resolvedTodayByMe}',
        ),
        const SizedBox(width: AppSpacing.md),
        _metricCard(
          'ESCALATED',
          '${d.escalated}',
          d.escalated == 0
              ? 'None waiting on an admin'
              : '${d.escalated} waiting on an admin',
        ),
        const SizedBox(width: AppSpacing.md),
        _metricCard(
          'AVG RESPONSE',
          d.avgResponseHours == 0
              ? '—'
              : '${d.avgResponseHours.toStringAsFixed(1)}h',
          'Across the last 30 days',
          valueColor: AppColors.gradientCyan,
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, String subtext,
      {Color? valueColor}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.moderatorSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.moderatorBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.moderatorTextFaint,
                fontSize: 11,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtext,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.moderatorTextMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Reports by reason ─────────────────────────────────────────────────────

  Widget _reasonsCard(ModDashboard d) {
    final int maxCount = d.reportsByReason.isEmpty
        ? 1
        : d.reportsByReason
            .map((ReasonCount r) => r.count)
            .reduce((int a, int b) => a > b ? a : b);
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Reports by reason',
            style: TextStyle(
              color: AppColors.moderatorTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Last 7 days',
            style: TextStyle(
              color: AppColors.moderatorTextFaint,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (d.reportsByReason.isEmpty)
            const Text(
              'No reports in this window.',
              style: TextStyle(
                color: AppColors.moderatorTextFaint,
                fontSize: 12,
              ),
            )
          else
            for (final ReasonCount r in d.reportsByReason)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Column(
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          r.label,
                          style: const TextStyle(
                            color: AppColors.moderatorTextSecondary,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${r.count}',
                          style: const TextStyle(
                            color: AppColors.moderatorTextMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: r.count / maxCount,
                        minHeight: 6,
                        backgroundColor: AppColors.moderatorDivider,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.moderatorPink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  // ── Needs you first ───────────────────────────────────────────────────────

  Widget _needsYouCard(ModDashboard d) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Needs you first',
            style: TextStyle(
              color: AppColors.moderatorTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Assigned to you or unassigned',
            style: TextStyle(
              color: AppColors.moderatorTextFaint,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (d.needsYouFirst.isEmpty)
            const Text(
              "You're all caught up.",
              style: TextStyle(
                color: AppColors.moderatorTextFaint,
                fontSize: 12,
              ),
            )
          else
            for (final ModReport r in d.needsYouFirst)
              _needsItem(r),
        ],
      ),
    );
  }

  Widget _needsItem(ModReport r) {
    return GestureDetector(
      onTap: () => _open(r),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.moderatorSurfaceAlt2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.moderatorDivider),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: r.badge.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: r.badge.color.withValues(alpha: 0.4)),
              ),
              child: Text(
                r.badge.label,
                style: TextStyle(
                  color: r.badge.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    '${r.reasonLabel} · ${r.displayId}',
                    style: const TextStyle(
                      color: AppColors.moderatorTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.status.label,
                    style: const TextStyle(
                      color: AppColors.moderatorTextFaint,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.moderatorIconMuted, size: 18),
          ],
        ),
      ),
    );
  }

  // ── Next up ───────────────────────────────────────────────────────────────

  Widget _nextUpCard(ModDashboard d) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.moderatorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.moderatorBorder),
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Reports queue · next up',
                      style: TextStyle(
                        color: AppColors.moderatorTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Oldest and most severe first',
                      style: TextStyle(
                        color: AppColors.moderatorTextFaint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: widget.onOpenQueue,
                  child: const Text(
                    'Open full queue →',
                    style: TextStyle(
                      color: AppColors.moderatorPink,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.moderatorDividerLine),
          if (d.nextUp.isEmpty)
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Text(
                'Nothing waiting.',
                style: TextStyle(
                  color: AppColors.moderatorTextFaint,
                  fontSize: 13,
                ),
              ),
            )
          else
            for (final ModReport r in d.nextUp) _nextUpRow(r),
        ],
      ),
    );
  }

  Widget _nextUpRow(ModReport r) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md - 2,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              r.displayId,
              style: const TextStyle(
                color: AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              r.reasonLabel,
              style: const TextStyle(
                color: AppColors.moderatorTextSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              r.status.label,
              style: const TextStyle(
                color: AppColors.moderatorTextMuted,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: r.badge.color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  r.badge.label,
                  style: TextStyle(
                    color: r.badge.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _open(r),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.moderatorSurfaceAlt2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.moderatorButtonBorder),
              ),
              child: const Text(
                'Review',
                style: TextStyle(
                  color: AppColors.moderatorTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.moderatorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.moderatorBorder),
      ),
      child: child,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.moderatorTextSecondary,
                fontSize: 12,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRetry,
            child: const Text(
              'Retry',
              style: TextStyle(
                color: AppColors.moderatorPink,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

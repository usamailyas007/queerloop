import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_icons.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../reports_queue/screens/moderator_case_detail_review_screen.dart';

class ModeratorDashboardScreen extends StatefulWidget {
  const ModeratorDashboardScreen({
    this.onOpenQueue,
    super.key,
  });

  final VoidCallback? onOpenQueue;

  @override
  State<ModeratorDashboardScreen> createState() => _ModeratorDashboardScreenState();
}

class _ModeratorDashboardScreenState extends State<ModeratorDashboardScreen> {
  int _dateFilterIndex = 0; // 0: Today, 1: 7 days, 2: 30 days
  String? _reviewingCaseId;

  Widget _buildMetricCard({
    required String label,
    required String value,
    required String subtext,
    Color? valueColor,
    Widget? iconWidget,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.moderatorSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.moderatorBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                ?iconWidget,
              ],
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

  Widget _buildProgressBar({
    required String label,
    required int count,
    required double fraction,
    required Color barColor,
  }) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: AppColors.moderatorTextSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
            Text(
              '$count',
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
            value: fraction,
            minHeight: 6,
            backgroundColor: AppColors.moderatorDivider,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 14),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_reviewingCaseId != null) {
      return ModeratorCaseDetailReviewScreen(
        caseId: _reviewingCaseId!,
        reason: 'Harassment',
        reportedBy: '@ashinorbit',
        reportedUser: '@dg_returns',
        onBack: () => setState(() => _reviewingCaseId = null),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.moderatorBackground,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: <Widget>[
            // ── Top Header Bar ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Good morning, Priya',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.moderatorTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sunday, 2 August · 28 reports waiting · your average response is 4.2h',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.moderatorTextMuted,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                // Search Bar Input Field using AppTextField
                SizedBox(
                  width: 220,
                  child: AppTextField(
                    hintText: 'Search case ID, account...',
                    prefixIconPath: AppIcons.searchSvg,
                    fillColor: AppColors.moderatorSurfaceAlt,
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Date Filter Pill Tabs (Today | 7 days | 30 days)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.moderatorSurfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.moderatorBorder,
                    ),
                  ),
                  child: Row(
                    children: <Widget>[
                      for (int i = 0; i < 3; i++)
                        GestureDetector(
                          onTap: () => setState(() => _dateFilterIndex = i),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _dateFilterIndex == i
                                  ? AppColors.moderatorChipSelected
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              i == 0
                                  ? 'Today'
                                  : i == 1
                                      ? '7 days'
                                      : '30 days',
                              style: TextStyle(
                                color: _dateFilterIndex == i
                                    ? AppColors.moderatorTextPrimary
                                    : AppColors.moderatorTextMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Open Queue Button
                GestureDetector(
                  onTap: widget.onOpenQueue,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: <Color>[
                          AppColors.moderatorPink,
                          AppColors.gradientCyan,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const <Widget>[
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
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Top 4 Metric Cards Row ──────────────────────────────────────
            Row(
              children: <Widget>[
                _buildMetricCard(
                  label: 'IN QUEUE',
                  value: '28',
                  subtext: '6 waiting longer than 12h',
                ),
                const SizedBox(width: AppSpacing.md),
                _buildMetricCard(
                  label: 'RESOLVED TODAY',
                  value: '41',
                  subtext: 'You personally handled 12',
                  iconWidget: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.moderatorGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_rounded,
                        color: AppColors.moderatorTextPrimary, size: 14),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _buildMetricCard(
                  label: 'ESCALATED',
                  value: '3',
                  subtext: 'Waiting on an admin',
                  iconWidget: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined,
                        color: AppColors.moderatorTextPrimary, size: 14),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                _buildMetricCard(
                  label: 'AVG RESPONSE',
                  value: '4.2h',
                  valueColor: AppColors.gradientCyan,
                  subtext: 'Target under 24h',
                  iconWidget: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.moderatorPurple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.access_time_rounded,
                        color: AppColors.moderatorTextPrimary, size: 14),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Middle Section (2 Columns) ──────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Left Card: Reports by reason
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.moderatorSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.moderatorBorder,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Reports by reason',
                                  style: TextStyle(
                                    color: AppColors.moderatorTextPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'This week · 312 total reports',
                                  style: TextStyle(
                                    color: AppColors.moderatorTextFaint,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'View breakdown',
                              style: TextStyle(
                                color: AppColors.moderatorPink,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),

                        _buildProgressBar(
                          label: 'Harassment or bullying',
                          count: 118,
                          fraction: 0.85,
                          barColor: AppColors.moderatorPink,
                        ),
                        _buildProgressBar(
                          label: 'Hate speech or slurs',
                          count: 87,
                          fraction: 0.65,
                          barColor: AppColors.moderatorPurple,
                        ),
                        _buildProgressBar(
                          label: 'Spam or fake account',
                          count: 54,
                          fraction: 0.42,
                          barColor: AppColors.gradientCyan,
                        ),
                        _buildProgressBar(
                          label: 'Outing without consent',
                          count: 31,
                          fraction: 0.25,
                          barColor: AppColors.warning,
                        ),
                        _buildProgressBar(
                          label: 'Sexual content',
                          count: 22,
                          fraction: 0.18,
                          barColor: AppColors.moderatorGreen,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.xl),

                // Right Card: Needs you first
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.moderatorSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.moderatorBorder,
                      ),
                    ),
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
                          'Ranked above queue order',
                          style: TextStyle(
                            color: AppColors.moderatorTextFaint,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Priority List Items
                        _buildNeedsItem(
                          badgeLabel: 'Urgent',
                          badgeColor: AppColors.danger,
                          title: 'Threats · QL-84402',
                          subtext: '4 reports · 22 min waiting',
                          onTap: () =>
                              setState(() => _reviewingCaseId = 'QL-84402'),
                        ),
                        _buildNeedsItem(
                          badgeLabel: 'Urgent',
                          badgeColor: AppColors.danger,
                          title: 'Self-harm · QL-84397',
                          subtext: '2 reports · 51 min waiting',
                          onTap: () =>
                              setState(() => _reviewingCaseId = 'QL-84397'),
                        ),
                        _buildNeedsItem(
                          badgeLabel: '14h',
                          badgeColor: AppColors.warning,
                          title: 'Harassment · QL-84213',
                          subtext: 'In review, continue your work',
                          onTap: () =>
                              setState(() => _reviewingCaseId = 'QL-84213'),
                        ),
                        _buildNeedsItem(
                          badgeLabel: '13h',
                          badgeColor: AppColors.warning,
                          title: 'Hate speech · QL-84190',
                          subtext: '9 reports · unassigned',
                          onTap: () =>
                              setState(() => _reviewingCaseId = 'QL-84190'),
                        ),
                        _buildNeedsItem(
                          badgeLabel: 'Appeal',
                          badgeColor: AppColors.moderatorPurple,
                          title: 'QL-83988',
                          subtext: 'Reassigned to a second moderator',
                          onTap: () =>
                              setState(() => _reviewingCaseId = 'QL-83988'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xl),

            // ── Bottom Table Section: Reports queue · next up ───────────────
            Container(
              decoration: BoxDecoration(
                color: AppColors.moderatorSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.moderatorBorder,
                ),
              ),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const <Widget>[
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

                  // Table Row 1
                  _buildQueueNextRow(
                    caseId: 'QL-84402',
                    reason: 'Threats',
                    reasonColor: AppColors.danger,
                    content: 'Comment · @nine_hex',
                    reportedBy: '4 reports',
                    waiting: '22 min',
                    status: 'Unassigned',
                    statusColor: AppColors.warning,
                    buttonText: 'Review',
                    onTap: () => setState(() => _reviewingCaseId = 'QL-84402'),
                  ),
                  // Table Row 2
                  _buildQueueNextRow(
                    caseId: 'QL-84397',
                    reason: 'Self-harm',
                    reasonColor: AppColors.danger,
                    content: 'Video · @lost.orbit',
                    reportedBy: '2 reports',
                    waiting: '51 min',
                    status: 'Unassigned',
                    statusColor: AppColors.warning,
                    buttonText: 'Review',
                    onTap: () => setState(() => _reviewingCaseId = 'QL-84397'),
                  ),
                  // Table Row 3
                  _buildQueueNextRow(
                    caseId: 'QL-84213',
                    reason: 'Harassment',
                    reasonColor: AppColors.warning,
                    content: 'Comment · @dg_returns',
                    reportedBy: '@ashinorbit',
                    waiting: '14h',
                    status: 'You · in review',
                    statusColor: AppColors.moderatorGreen,
                    buttonText: 'Continue',
                    isGradientButton: true,
                    onTap: () => setState(() => _reviewingCaseId = 'QL-84213'),
                  ),
                  // Table Row 4
                  _buildQueueNextRow(
                    caseId: 'QL-84190',
                    reason: 'Hate speech',
                    reasonColor: AppColors.warning,
                    content: 'Text post · @truth_ftw',
                    reportedBy: '9 reports',
                    waiting: '13h',
                    status: 'Unassigned',
                    statusColor: AppColors.warning,
                    buttonText: 'Review',
                    onTap: () => setState(() => _reviewingCaseId = 'QL-84190'),
                  ),
                  // Table Row 5
                  _buildQueueNextRow(
                    caseId: 'QL-84077',
                    reason: 'Spam',
                    reasonColor: AppColors.moderatorGray,
                    content: 'Profile · @free_giftcards',
                    reportedBy: '17 reports',
                    waiting: '6h',
                    status: 'Unassigned',
                    statusColor: AppColors.warning,
                    buttonText: 'Review',
                    onTap: () => setState(() => _reviewingCaseId = 'QL-84077'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNeedsItem({
    required String badgeLabel,
    required Color badgeColor,
    required String title,
    required String subtext,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.moderatorSurfaceAlt2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.moderatorDivider,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
              ),
              child: Text(
                badgeLabel,
                style: TextStyle(
                  color: badgeColor,
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
                    title,
                    style: const TextStyle(
                      color: AppColors.moderatorTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtext,
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

  Widget _buildQueueNextRow({
    required String caseId,
    required String reason,
    required Color reasonColor,
    required String content,
    required String reportedBy,
    required String waiting,
    required String status,
    required Color statusColor,
    required String buttonText,
    bool isGradientButton = false,
    VoidCallback? onTap,
  }) {
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
              caseId,
              style: const TextStyle(
                color: AppColors.moderatorTextPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: reasonColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  reason,
                  style: TextStyle(
                    color: reasonColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              content,
              style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              reportedBy,
              style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              waiting,
              style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                gradient: isGradientButton
                    ? const LinearGradient(
                        colors: <Color>[
                          AppColors.moderatorPink,
                          AppColors.gradientCyan,
                        ],
                      )
                    : null,
                color: isGradientButton ? null : AppColors.moderatorSurfaceAlt2,
                borderRadius: BorderRadius.circular(14),
                border: isGradientButton
                    ? null
                    : Border.all(color: AppColors.moderatorButtonBorder),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
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
}

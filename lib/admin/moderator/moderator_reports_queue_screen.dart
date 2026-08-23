import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import 'moderator_case_detail_review_screen.dart';

class QueueReportItem {
  const QueueReportItem({
    required this.caseId,
    required this.reason,
    required this.reportedAccount,
    required this.reporter,
    required this.age,
    required this.priority,
    required this.priorityColor,
  });

  final String caseId;
  final String reason;
  final String reportedAccount;
  final String reporter;
  final String age;
  final String priority;
  final Color priorityColor;
}

class ModeratorReportsQueueScreen extends StatefulWidget {
  const ModeratorReportsQueueScreen({
    this.onSelectCase,
    super.key,
  });

  final ValueChanged<QueueReportItem>? onSelectCase;

  @override
  State<ModeratorReportsQueueScreen> createState() => _ModeratorReportsQueueScreenState();
}

class _ModeratorReportsQueueScreenState extends State<ModeratorReportsQueueScreen> {
  int _reasonFilter = 0; // 0: All reasons, 1: Urgent only
  String _searchQuery = '';
  QueueReportItem? _activeReviewCase;

  static const List<QueueReportItem> _reports = <QueueReportItem>[
    QueueReportItem(
      caseId: 'QL-84402',
      reason: 'Threats',
      reportedAccount: '@hexnine1',
      reporter: '@ashinorbit',
      age: '1h',
      priority: 'Urgent',
      priorityColor: AppColors.danger,
    ),
    QueueReportItem(
      caseId: 'QL-84397',
      reason: 'Self-harm content',
      reportedAccount: '@dg_returns',
      reporter: 'System flag',
      age: '2h',
      priority: 'Urgent',
      priorityColor: AppColors.danger,
    ),
    QueueReportItem(
      caseId: 'QL-84213',
      reason: 'Harassment',
      reportedAccount: '@dg_returns',
      reporter: '@ashinorbit',
      age: '14h',
      priority: 'High',
      priorityColor: AppColors.warning,
    ),
    QueueReportItem(
      caseId: 'QL-84190',
      reason: 'Hate speech / slurs',
      reportedAccount: '@truth_ftw',
      reporter: '@jules.does',
      age: '13h',
      priority: 'High',
      priorityColor: AppColors.warning,
    ),
    QueueReportItem(
      caseId: 'QL-84150',
      reason: 'Spam / fake account',
      reportedAccount: '@free_giftcards',
      reporter: 'System flag',
      age: '9h',
      priority: 'Normal',
      priorityColor: AppColors.moderatorGray,
    ),
    QueueReportItem(
      caseId: 'QL-84102',
      reason: 'Outing without consent',
      reportedAccount: '@m.callahan',
      reporter: '@rowankeeps',
      age: '7h',
      priority: 'Escalate',
      priorityColor: AppColors.moderatorPurple,
    ),
    QueueReportItem(
      caseId: 'QL-84002',
      reason: 'Threats',
      reportedAccount: '@m.callahan',
      reporter: '@rowankeeps',
      age: '7h',
      priority: 'Escalate',
      priorityColor: AppColors.moderatorPurple,
    ),
    QueueReportItem(
      caseId: 'QL-83988',
      reason: 'Appeal · reassigned',
      reportedAccount: '@nadia.builds',
      reporter: '—',
      age: '1d',
      priority: 'Appeal',
      priorityColor: AppColors.moderatorPurple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_activeReviewCase != null) {
      return ModeratorCaseDetailReviewScreen(
        caseId: _activeReviewCase!.caseId,
        reason: _activeReviewCase!.reason,
        reportedBy: _activeReviewCase!.reporter,
        reportedUser: _activeReviewCase!.reportedAccount,
        onBack: () => setState(() => _activeReviewCase = null),
      );
    }

    final List<QueueReportItem> filtered = _reports.where((QueueReportItem item) {
      final bool matchesSearch = _searchQuery.isEmpty ||
          item.caseId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.reportedAccount.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item.reason.toLowerCase().contains(_searchQuery.toLowerCase());

      final bool matchesFilter =
          _reasonFilter == 0 || item.priority == 'Urgent';

      return matchesSearch && matchesFilter;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.moderatorBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ── Header Bar ──────────────────────────────────────────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Reports queue',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.moderatorTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '28 waiting · sorted urgent first',
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
                    width: 260,
                    child: AppTextField(
                      hintText: 'Search by case ID, username...',
                      prefixIconPath: AppIcons.searchSvg,
                      fillColor: AppColors.moderatorSurfaceAlt,
                      onChanged: (String val) =>
                          setState(() => _searchQuery = val),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Filter Pill Tabs (All reasons | Urgent only)
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
                        GestureDetector(
                          onTap: () => setState(() => _reasonFilter = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _reasonFilter == 0
                                  ? AppColors.moderatorChipSelected
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'All reasons',
                              style: TextStyle(
                                color: _reasonFilter == 0
                                    ? AppColors.moderatorTextPrimary
                                    : AppColors.moderatorTextMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _reasonFilter = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _reasonFilter == 1
                                  ? AppColors.moderatorChipSelected
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'Urgent only',
                              style: TextStyle(
                                color: _reasonFilter == 1
                                    ? AppColors.moderatorTextPrimary
                                    : AppColors.moderatorTextMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Sort Dropdown Button (Oldest first)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.moderatorSurfaceAlt,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.moderatorBorder,
                      ),
                    ),
                    child: const Text(
                      'Oldest first',
                      style: TextStyle(
                        color: AppColors.moderatorTextPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.xl),

              // ── Main Table Card Container ──────────────────────────────────
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.moderatorSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.moderatorBorder,
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      // Sub Header Row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const <Widget>[
                            Text(
                              '28 reports',
                              style: TextStyle(
                                color: AppColors.moderatorTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'All communities',
                              style: TextStyle(
                                color: AppColors.moderatorTextFaint,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: AppColors.moderatorDividerLine),

                      // Table Header Columns
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md - 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppColors.moderatorDivider,
                            ),
                          ),
                        ),
                        child: Row(
                          children: const <Widget>[
                            Expanded(
                              flex: 2,
                              child: Text('CASE',
                                  style: TextStyle(
                                      color: AppColors.moderatorTextFaint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('REASON',
                                  style: TextStyle(
                                      color: AppColors.moderatorTextFaint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('REPORTED ACCOUNT',
                                  style: TextStyle(
                                      color: AppColors.moderatorTextFaint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('REPORTER',
                                  style: TextStyle(
                                      color: AppColors.moderatorTextFaint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('AGE',
                                  style: TextStyle(
                                      color: AppColors.moderatorTextFaint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('PRIORITY',
                                  style: TextStyle(
                                      color: AppColors.moderatorTextFaint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ),
                            SizedBox(width: 80), // Action button column header space
                          ],
                        ),
                      ),

                      // Table Rows List
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (BuildContext context, int index) => Divider(
                            height: 1,
                            color: AppColors.moderatorRowDivider,
                          ),
                          itemBuilder: (_, int index) {
                            final QueueReportItem item = filtered[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.md - 2,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item.caseId,
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
                                      item.reason,
                                      style: const TextStyle(
                                        color: AppColors.moderatorTextSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.reportedAccount,
                                      style: const TextStyle(
                                        color: AppColors.moderatorTextSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.reporter,
                                      style: const TextStyle(
                                        color: AppColors.moderatorTextMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      item.age,
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
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.priorityColor
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: item.priorityColor
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          item.priority,
                                          style: TextStyle(
                                            color: item.priorityColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 80,
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() => _activeReviewCase = item);
                                        widget.onSelectCase?.call(item);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.moderatorSurfaceAlt2,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: AppColors.moderatorTextPrimary
                                                .withValues(alpha: 0.12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Review',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: AppColors.moderatorTextPrimary,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Table Footer Pagination
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.moderatorDivider,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Showing ${filtered.length} of 28 reports',
                              style: const TextStyle(
                                color: AppColors.moderatorTextFaint,
                                fontSize: 12,
                              ),
                            ),
                            Row(
                              children: <Widget>[
                                _buildPageButton('Previous'),
                                const SizedBox(width: 8),
                                _buildPageButton('Next'),
                              ],
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
      ),
    );
  }

  Widget _buildPageButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.moderatorSurfaceAlt,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.moderatorBorder,
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.moderatorTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

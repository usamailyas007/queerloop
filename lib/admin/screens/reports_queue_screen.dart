import 'package:flutter/material.dart';

import '../../core/theme/app_icons.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/app_text_field.dart';
import 'case_detail_review_screen.dart';

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

class ReportsQueueScreen extends StatefulWidget {
  const ReportsQueueScreen({
    this.onSelectCase,
    super.key,
  });

  final ValueChanged<QueueReportItem>? onSelectCase;

  @override
  State<ReportsQueueScreen> createState() => _ReportsQueueScreenState();
}

class _ReportsQueueScreenState extends State<ReportsQueueScreen> {
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
      priorityColor: Color(0xFFDC2626),
    ),
    QueueReportItem(
      caseId: 'QL-84397',
      reason: 'Self-harm content',
      reportedAccount: '@dg_returns',
      reporter: 'System flag',
      age: '2h',
      priority: 'Urgent',
      priorityColor: Color(0xFFDC2626),
    ),
    QueueReportItem(
      caseId: 'QL-84213',
      reason: 'Harassment',
      reportedAccount: '@dg_returns',
      reporter: '@ashinorbit',
      age: '14h',
      priority: 'High',
      priorityColor: Color(0xFFD97706),
    ),
    QueueReportItem(
      caseId: 'QL-84190',
      reason: 'Hate speech / slurs',
      reportedAccount: '@truth_ftw',
      reporter: '@jules.does',
      age: '13h',
      priority: 'High',
      priorityColor: Color(0xFFD97706),
    ),
    QueueReportItem(
      caseId: 'QL-84150',
      reason: 'Spam / fake account',
      reportedAccount: '@free_giftcards',
      reporter: 'System flag',
      age: '9h',
      priority: 'Normal',
      priorityColor: Color(0xFF4B5563),
    ),
    QueueReportItem(
      caseId: 'QL-84102',
      reason: 'Outing without consent',
      reportedAccount: '@m.callahan',
      reporter: '@rowankeeps',
      age: '7h',
      priority: 'Escalate',
      priorityColor: Color(0xFF9333EA),
    ),
    QueueReportItem(
      caseId: 'QL-84002',
      reason: 'Threats',
      reportedAccount: '@m.callahan',
      reporter: '@rowankeeps',
      age: '7h',
      priority: 'Escalate',
      priorityColor: Color(0xFF9333EA),
    ),
    QueueReportItem(
      caseId: 'QL-83988',
      reason: 'Appeal · reassigned',
      reportedAccount: '@nadia.builds',
      reporter: '—',
      age: '1d',
      priority: 'Appeal',
      priorityColor: Color(0xFF9333EA),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    if (_activeReviewCase != null) {
      return CaseDetailReviewScreen(
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
      backgroundColor: const Color(0xFF121019),
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
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '28 waiting · sorted urgent first',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: Colors.white54,
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
                      fillColor: const Color(0xFF191622),
                      onChanged: (String val) =>
                          setState(() => _searchQuery = val),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Filter Pill Tabs (All reasons | Urgent only)
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF191622),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
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
                                  ? const Color(0xFF2C2738)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'All reasons',
                              style: TextStyle(
                                color: _reasonFilter == 0
                                    ? Colors.white
                                    : Colors.white54,
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
                                  ? const Color(0xFF2C2738)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'Urgent only',
                              style: TextStyle(
                                color: _reasonFilter == 1
                                    ? Colors.white
                                    : Colors.white54,
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
                      color: const Color(0xFF191622),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: const Text(
                      'Oldest first',
                      style: TextStyle(
                        color: Colors.white,
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
                    color: const Color(0xFF16131D),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
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
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'All communities',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Colors.white10),

                      // Table Header Columns
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md - 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        child: Row(
                          children: const <Widget>[
                            Expanded(
                              flex: 2,
                              child: Text('CASE',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('REASON',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('REPORTED ACCOUNT',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('REPORTER',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text('AGE',
                                  style: TextStyle(
                                      color: Colors.white38,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('PRIORITY',
                                  style: TextStyle(
                                      color: Colors.white38,
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
                            color: Colors.white.withValues(alpha: 0.04),
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
                                        color: Colors.white,
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
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.reportedAccount,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      item.reporter,
                                      style: const TextStyle(
                                        color: Colors.white54,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Text(
                                      item.age,
                                      style: const TextStyle(
                                        color: Colors.white54,
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
                                          color: const Color(0xFF1D1927),
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.12),
                                          ),
                                        ),
                                        child: const Text(
                                          'Review',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
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
                              color: Colors.white.withValues(alpha: 0.06),
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(
                              'Showing ${filtered.length} of 28 reports',
                              style: const TextStyle(
                                color: Colors.white38,
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
        color: const Color(0xFF191622),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

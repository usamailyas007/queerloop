import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';

class ActionLogItem {
  const ActionLogItem({
    required this.when,
    required this.caseId,
    required this.moderator,
    required this.action,
    required this.actionColor,
    required this.account,
    required this.note,
  });

  final String when;
  final String caseId;
  final String moderator;
  final String action;
  final Color actionColor;
  final String account;
  final String note;
}

class ModeratorActionLogScreen extends StatefulWidget {
  const ModeratorActionLogScreen({super.key});

  @override
  State<ModeratorActionLogScreen> createState() => _ModeratorActionLogScreenState();
}

class _ModeratorActionLogScreenState extends State<ModeratorActionLogScreen> {
  int _filterTab = 0; // 0: All moderators, 1: Just me

  static const List<ActionLogItem> _logs = <ActionLogItem>[
    ActionLogItem(
      when: '2 Aug 09:41',
      caseId: 'QL-84213',
      moderator: 'MOD-04',
      action: 'Warned',
      actionColor: AppColors.warning,
      account: '@dg_returns',
      note: 'Second warning, comment removed',
    ),
    ActionLogItem(
      when: '2 Aug 09:12',
      caseId: 'QL-84150',
      moderator: 'MOD-02',
      action: 'Hidden',
      actionColor: AppColors.danger,
      account: '@truth_ftw',
      note: 'Slur in caption, rule 1',
    ),
    ActionLogItem(
      when: '2 Aug 08:50',
      caseId: 'QL-84102',
      moderator: 'MOD-02',
      action: 'Escalated',
      actionColor: AppColors.moderatorPurple,
      account: '@m.callahan',
      note: "Outing a minor's relative, needs admin",
    ),
    ActionLogItem(
      when: '1 Aug 22:07',
      caseId: 'QL-83994',
      moderator: 'MOD-01',
      action: 'No action',
      actionColor: AppColors.moderatorGray,
      account: '@jules.does',
      note: 'Report was retaliatory, content is fine',
    ),
    ActionLogItem(
      when: '1 Aug 21:30',
      caseId: 'QL-83988',
      moderator: 'MOD-03',
      action: 'Reversed',
      actionColor: AppColors.moderatorGreen,
      account: '@nadia.builds',
      note: 'Appeal upheld, suspension lifted',
    ),
    ActionLogItem(
      when: '1 Aug 19:44',
      caseId: 'QL-83901',
      moderator: 'MOD-04',
      action: 'Muted 7d',
      actionColor: AppColors.danger,
      account: '@hexnine1',
      note: 'Repeat pile-on in comments',
    ),
  ];

  @override
  Widget build(BuildContext context) {
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
                        'ACTION LOG',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.gradientCyan,
                          letterSpacing: 1.2,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Action log',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: AppColors.moderatorTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Every decision is permanent and attributed. Export for audits.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.moderatorTextMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),

                  // Filter Pill Tabs (All moderators | Just me)
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
                          onTap: () => setState(() => _filterTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _filterTab == 0
                                  ? AppColors.moderatorChipSelected
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'All moderators',
                              style: TextStyle(
                                color: _filterTab == 0
                                    ? AppColors.moderatorTextPrimary
                                    : AppColors.moderatorTextMuted,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _filterTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: _filterTab == 1
                                  ? AppColors.moderatorChipSelected
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text(
                              'Just me',
                              style: TextStyle(
                                color: _filterTab == 1
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

                  // Date Filter Button (Last 30 days)
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
                      'Last 30 days',
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
                      // Table Headers
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: AppSpacing.md,
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
                              child: Text(
                                'WHEN',
                                style: TextStyle(
                                  color: AppColors.moderatorTextFaint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'CASE',
                                style: TextStyle(
                                  color: AppColors.moderatorTextFaint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'MODERATOR',
                                style: TextStyle(
                                  color: AppColors.moderatorTextFaint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'ACTION',
                                style: TextStyle(
                                  color: AppColors.moderatorTextFaint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'ACCOUNT',
                                style: TextStyle(
                                  color: AppColors.moderatorTextFaint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                'NOTE',
                                style: TextStyle(
                                  color: AppColors.moderatorTextFaint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Table Rows List
                      Expanded(
                        child: ListView.separated(
                          itemCount: _logs.length,
                          separatorBuilder: (BuildContext context, int index) => Divider(
                            height: 1,
                            color: AppColors.moderatorRowDivider,
                          ),
                          itemBuilder: (_, int index) {
                            final ActionLogItem item = _logs[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.xl,
                                vertical: AppSpacing.md,
                              ),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item.when,
                                      style: const TextStyle(
                                        color: AppColors.moderatorTextMuted,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
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
                                    flex: 2,
                                    child: Text(
                                      item.moderator,
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
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: item.actionColor
                                              .withValues(alpha: 0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          border: Border.all(
                                            color: item.actionColor
                                                .withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          item.action,
                                          style: TextStyle(
                                            color: item.actionColor,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      item.account,
                                      style: const TextStyle(
                                        color: AppColors.moderatorTextSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      item.note,
                                      style: const TextStyle(
                                        color: AppColors.moderatorTextMuted,
                                        fontSize: 13,
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
                            const Text(
                              'Showing 6 of 1,284 entries',
                              style: TextStyle(
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

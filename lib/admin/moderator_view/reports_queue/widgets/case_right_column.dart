import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../reports/models/mod_report.dart';
import 'wide_button.dart';

/// Right column: account history, assign/reopen affordances, and the
/// decision picker with its note field and apply button.
class CaseRightColumn extends StatelessWidget {
  const CaseRightColumn({
    required this.report,
    required this.history,
    required this.acting,
    required this.decisions,
    required this.selectedDecision,
    required this.noteController,
    required this.noteValid,
    required this.onDecisionChanged,
    required this.onNoteChanged,
    required this.onApply,
    required this.onAssign,
    required this.onReopen,
    super.key,
  });

  final ModReport report;
  final AccountHistory? history;
  final bool acting;
  final List<ModDecision> decisions;
  final ModDecision? selectedDecision;
  final TextEditingController noteController;
  final bool noteValid;
  final ValueChanged<ModDecision> onDecisionChanged;
  final VoidCallback onNoteChanged;
  final VoidCallback onApply;
  final VoidCallback onAssign;
  final VoidCallback onReopen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Account history',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 15),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (history == null)
          const Text('No history available.', style: TextStyle(color: AppColors.moderatorTextFaint, fontSize: 12))
        else ...<Widget>[
          _histRow('Joined', history!.joinedAt == null ? '—' : DateFormat('d MMM yyyy').format(history!.joinedAt!)),
          _histRow('Account status', history!.accountStatus),
          _histRow('Reports against', '${history!.reportsAgainst30d} in 30 days', highlight: history!.reportsAgainst30d > 3),
          _histRow('Blocked by', '${history!.blockedByCount} people'),
          const SizedBox(height: AppSpacing.md),
          const Text('Previous actions', style: TextStyle(color: AppColors.moderatorTextFaint, fontSize: 12)),
          const SizedBox(height: 6),
          if (history!.previousActions.isEmpty)
            const Text(
              'None',
              style: TextStyle(color: AppColors.moderatorTextPrimary, fontSize: 12, fontWeight: FontWeight.w700),
            )
          else
            for (final PreviousAction a in history!.previousActions) _PrevAction(action: a),
        ],
        const SizedBox(height: AppSpacing.xl),

        if (report.isResolved)
          WideButton(label: acting ? 'Working…' : 'Reopen to re-decide', onTap: acting ? null : onReopen)
        else if (!report.isAssigned)
          WideButton(label: acting ? 'Working…' : 'Assign to me', onTap: acting ? null : onAssign),

        const SizedBox(height: AppSpacing.lg),
        Text(
          'Decision',
          style: AppTextStyles.titleMedium.copyWith(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: AppSpacing.md),

        if (report.isResolved)
          const Text(
            'This report is resolved. Reopen it before making another decision.',
            style: TextStyle(color: AppColors.moderatorTextFaint, fontSize: 12),
          )
        else ...<Widget>[
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: Text(
              'Decisions are recorded and audited. Account status '
              '(suspend / ban) is enforced separately from the Users tab.',
              style: TextStyle(color: AppColors.moderatorTextFaint, fontSize: 11, height: 1.4),
            ),
          ),
          for (final ModDecision d in decisions)
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: acting ? null : () => onDecisionChanged(d),
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md - 2),
                  decoration: BoxDecoration(
                    color: AppColors.moderatorSurfaceAlt2,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: selectedDecision == d ? AppColors.moderatorPink : AppColors.moderatorTextPrimary.withValues(alpha: 0.08),
                      width: selectedDecision == d ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        d.title,
                        style: TextStyle(
                          color: AppColors.moderatorTextPrimary,
                          fontWeight: selectedDecision == d ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          d.subtitle,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            color: selectedDecision == d ? AppColors.moderatorPink : AppColors.moderatorTextFaint,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: noteController,
            enabled: !acting,
            hintText: 'Note for the log (required, 1–1000 chars)',
            fillColor: AppColors.moderatorSurfaceAlt2,
            maxLines: 3,
            maxLength: 1000,
            onChanged: (_) => onNoteChanged(),
          ),
          const SizedBox(height: AppSpacing.md),
          WideButton(
            label: acting ? 'Applying…' : (selectedDecision == ModDecision.escalate ? 'Escalate' : 'Apply decision'),
            gradient: true,
            onTap: (acting || selectedDecision == null || !noteValid) ? null : onApply,
          ),
        ],
      ],
    );
  }

  Widget _histRow(String k, String v, {bool highlight = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(k, style: const TextStyle(color: AppColors.moderatorTextFaint, fontSize: 12)),
        Flexible(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: highlight ? AppColors.moderatorPink : AppColors.moderatorTextPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}

class _PrevAction extends StatelessWidget {
  const _PrevAction({required this.action});

  final PreviousAction action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.moderatorSurfaceAlt2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.moderatorDivider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                action.displayId,
                style: const TextStyle(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 12),
              ),
              const SizedBox(width: 6),
              Text('· ${action.decisionLabel}', style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 12)),
              const Spacer(),
              if (action.resolvedAt != null)
                Text(DateFormat('d MMM').format(action.resolvedAt!), style: const TextStyle(color: AppColors.moderatorTextFaint, fontSize: 11)),
            ],
          ),
          if (action.moderatorNote != null && action.moderatorNote!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              action.moderatorNote!,
              style: const TextStyle(color: AppColors.moderatorTextMuted, fontSize: 11, height: 1.3),
            ),
          ],
        ],
      ),
    );
  }
}

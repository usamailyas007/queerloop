import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../auth/provider/admin_auth_provider.dart';
import '../../reports/models/mod_report.dart';
import '../../reports/provider/mod_reports_provider.dart';
import '../widgets/case_centered_error.dart';
import '../widgets/case_panel.dart';
import '../widgets/case_right_column.dart';
import '../widgets/case_top_bar.dart';
import '../widgets/note_prompt_dialog.dart';
import '../widgets/reported_content_panel.dart';

class ModeratorCaseDetailReviewScreen extends StatefulWidget {
  const ModeratorCaseDetailReviewScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<ModeratorCaseDetailReviewScreen> createState() => _ModeratorCaseDetailReviewScreenState();
}

class _ModeratorCaseDetailReviewScreenState extends State<ModeratorCaseDetailReviewScreen> {
  final TextEditingController _noteController = TextEditingController();
  ModDecision? _decision;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _noteValid {
    final int len = _noteController.text.trim().length;
    return len >= 1 && len <= 1000;
  }

  List<ModDecision> _decisionsFor(bool isAdmin) =>
      ModDecision.values.where((ModDecision d) => (isAdmin || !d.adminOnly) && (!isAdmin || d != ModDecision.escalate)).toList();

  Future<void> _apply() async {
    if (_decision == null || !_noteValid) {
      return;
    }
    final ModReportsProvider provider = context.read<ModReportsProvider>();
    final bool ok = await provider.decideSelected(_decision!, _noteController.text.trim());
    if (!mounted) {
      return;
    }
    _snack(
      ok ? (_decision == ModDecision.escalate ? 'Escalated to an admin.' : 'Decision applied.') : (provider.detailError ?? 'Could not apply the decision.'),
    );
    if (ok) {
      _noteController.clear();
      setState(() => _decision = null);
    } else {
      provider.clearDetailError();
    }
  }

  Future<void> _assign() async {
    final ModReportsProvider provider = context.read<ModReportsProvider>();
    final bool ok = await provider.assignSelected();
    if (!mounted) return;
    if (!ok) {
      _snack(provider.detailError ?? 'Could not assign this report.');
      provider.clearDetailError();
    }
  }

  Future<void> _reopen() async {
    final String? note = await _promptNote(
      title: 'Reopen report',
      subtitle: "This moves the report back to in-review and permanently marks it as an appeal.",
      hint: "Why it's being reopened…",
      confirmLabel: 'Reopen',
    );
    if (note == null || !mounted) return;
    final ModReportsProvider provider = context.read<ModReportsProvider>();
    final bool ok = await provider.reopenSelected(note);
    if (!mounted) return;
    _snack(ok ? 'Report reopened as an appeal.' : (provider.detailError ?? 'Could not reopen this report.'));
    if (!ok) provider.clearDetailError();
  }

  Future<String?> _promptNote({required String title, required String subtitle, required String hint, required String confirmLabel}) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext ctx) => NotePromptDialog(title: title, subtitle: subtitle, hint: hint, confirmLabel: confirmLabel),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = context.select<AdminAuthProvider, bool>((AdminAuthProvider p) => p.role == AdminRole.admin);

    return Scaffold(
      backgroundColor: AppColors.moderatorBackground,
      body: SafeArea(
        child: Consumer<ModReportsProvider>(
          builder: (_, ModReportsProvider provider, _) {
            final ModReport? report = provider.selectedReport;

            if (provider.isLoadingDetail && report == null) {
              return const Center(child: CircularProgressIndicator(color: AppColors.moderatorPink));
            }
            if (report == null) {
              return CaseCenteredError(message: provider.detailError ?? 'Report not found.', onBack: widget.onBack);
            }

            return Column(
              children: <Widget>[
                CaseTopBar(report: report, onBack: widget.onBack),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(flex: 5, child: CasePanel(child: ReportedContentPanel(report: report))),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          flex: 5,
                          child: CasePanel(
                            child: CaseRightColumn(
                              report: report,
                              history: provider.accountHistory,
                              acting: provider.isActing,
                              decisions: _decisionsFor(isAdmin),
                              selectedDecision: _decision,
                              noteController: _noteController,
                              noteValid: _noteValid,
                              onDecisionChanged: (ModDecision d) => setState(() => _decision = d),
                              onNoteChanged: () => setState(() {}),
                              onApply: _apply,
                              onAssign: _assign,
                              onReopen: _reopen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            );
          },
        ),
      ),
    );
  }
}

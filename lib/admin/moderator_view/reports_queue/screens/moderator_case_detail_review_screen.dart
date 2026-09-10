import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../admin_view/content/models/content_post.dart';
import '../../../admin_view/content/provider/content_provider.dart';
import '../../../admin_view/content/screens/admin_post_detail_dialog.dart';
import '../../../auth/provider/admin_auth_provider.dart';
import '../../reports/models/mod_report.dart';
import '../../reports/provider/mod_reports_provider.dart';

class ModeratorCaseDetailReviewScreen extends StatefulWidget {
  const ModeratorCaseDetailReviewScreen({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  State<ModeratorCaseDetailReviewScreen> createState() =>
      _ModeratorCaseDetailReviewScreenState();
}

class _ModeratorCaseDetailReviewScreenState
    extends State<ModeratorCaseDetailReviewScreen> {
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

  List<ModDecision> _decisionsFor(bool isAdmin) => ModDecision.values
      .where((ModDecision d) => isAdmin || !d.adminOnly)
      .toList();

  Future<void> _apply() async {
    if (_decision == null || !_noteValid) {
      return;
    }
    final ModReportsProvider provider = context.read<ModReportsProvider>();
    final bool ok =
        await provider.decideSelected(_decision!, _noteController.text.trim());
    if (!mounted) {
      return;
    }
    _snack(ok
        ? (_decision == ModDecision.escalate
            ? 'Escalated to an admin.'
            : 'Decision applied.')
        : (provider.detailError ?? 'Could not apply the decision.'));
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
      subtitle:
          "This moves the report back to in-review and permanently marks it as an appeal.",
      hint: "Why it's being reopened…",
      confirmLabel: 'Reopen',
    );
    if (note == null || !mounted) return;
    final ModReportsProvider provider = context.read<ModReportsProvider>();
    final bool ok = await provider.reopenSelected(note);
    if (!mounted) return;
    _snack(ok
        ? 'Report reopened as an appeal.'
        : (provider.detailError ?? 'Could not reopen this report.'));
    if (!ok) provider.clearDetailError();
  }

  Future<String?> _promptNote({
    required String title,
    required String subtitle,
    required String hint,
    required String confirmLabel,
  }) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (BuildContext ctx) =>
          _NotePromptDialog(title: title, subtitle: subtitle, hint: hint, confirmLabel: confirmLabel),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdmin = context.select<AdminAuthProvider, bool>(
      (AdminAuthProvider p) => p.role == AdminRole.admin,
    );

    return Scaffold(
      backgroundColor: AppColors.moderatorBackground,
      body: SafeArea(
        child: Consumer<ModReportsProvider>(
          builder: (_, ModReportsProvider provider, _) {
            final ModReport? report = provider.selectedReport;

            if (provider.isLoadingDetail && report == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.moderatorPink),
              );
            }
            if (report == null) {
              return _CenteredError(
                message: provider.detailError ?? 'Report not found.',
                onBack: widget.onBack,
              );
            }

            return Column(
              children: <Widget>[
                _TopBar(report: report, onBack: widget.onBack),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 5,
                          child: _Panel(
                            child: _ReportedContent(report: report),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xl),
                        Expanded(
                          flex: 5,
                          child: _Panel(
                            child: _RightColumn(
                              report: report,
                              history: provider.accountHistory,
                              acting: provider.isActing,
                              decisions: _decisionsFor(isAdmin),
                              selectedDecision: _decision,
                              noteController: _noteController,
                              noteValid: _noteValid,
                              onDecisionChanged: (ModDecision d) =>
                                  setState(() => _decision = d),
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

// ── Top bar ─────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.report, required this.onBack});

  final ModReport report;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    report.displayId,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.moderatorTextPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(width: 10),
                  _Badge(badge: report.badge),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${report.reasonLabel} · ${report.status.label} · '
                'reported ${_ago(report.createdAt)}',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.moderatorTextMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const Spacer(),
          _TopButton(label: 'Back to queue', onTap: onBack),
        ],
      ),
    );
  }

  static String _ago(DateTime t) {
    final Duration d = DateTime.now().difference(t);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _TopButton extends StatelessWidget {
  const _TopButton({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.moderatorSurfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.moderatorInputBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.moderatorTextPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.moderatorSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.moderatorBorder),
      ),
      child: SingleChildScrollView(child: child),
    );
  }
}

// ── Left column: the report facts ──────────────────────────────────────────

class _ReportedContent extends StatelessWidget {
  const _ReportedContent({required this.report});

  final ModReport report;

  @override
  Widget build(BuildContext context) {
    final bool canViewPost = report.targetType.toLowerCase() == 'post' &&
        report.targetId != null &&
        report.targetId!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _sectionTitle('Report'),
        const SizedBox(height: AppSpacing.md),
        if (canViewPost) ...<Widget>[
          _ViewReportedPostButton(postId: report.targetId!),
          const SizedBox(height: AppSpacing.md),
        ],
        _kv('Case', report.displayId),
        _kv('Reason', report.reasonLabel),
        _kv('Status', report.status.label),
        _kv('Priority', _priorityLabel(report.priority)),
        _kv('Target type', report.targetType),
        if (report.communityName != null && report.communityName!.isNotEmpty)
          _kv('Community', report.communityName!),
        if (report.assignedToLabel != null)
          _kv('Assigned to', report.assignedToLabel!),
        if (report.isAppeal) _kv('Appeal', 'Yes'),
        _kv('Created', DateFormat('d MMM yyyy · h:mm a').format(report.createdAt)),
        if (report.resolvedAt != null)
          _kv('Resolved',
              DateFormat('d MMM yyyy · h:mm a').format(report.resolvedAt!)),
        if (report.resolvedByLabel != null)
          _kv('Resolved by', report.resolvedByLabel!),
        const SizedBox(height: AppSpacing.xl),
        _sectionTitle('IDs'),
        const SizedBox(height: AppSpacing.md),
        _kv('Target', report.targetId ?? '—', mono: true),
        _kv('Target owner', report.targetOwnerId ?? '—', mono: true),
        _kv('Reporter', report.reporterId ?? '—', mono: true),
        _kv('Community', report.communityId ?? '—', mono: true),
        if (report.decision != null) ...<Widget>[
          const SizedBox(height: AppSpacing.xl),
          _sectionTitle('Last decision'),
          const SizedBox(height: AppSpacing.md),
          _kv('Decision', report.decision!.title),
          if (report.moderatorNote != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.moderatorSurfaceAlt2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.moderatorDivider),
              ),
              child: Text(
                report.moderatorNote!,
                style: const TextStyle(
                  color: AppColors.moderatorTextSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ],
    );
  }

  static String _priorityLabel(int p) => switch (p) {
        1 => 'Urgent (1)',
        2 => 'High (2)',
        _ => 'Normal (3)',
      };

  Widget _sectionTitle(String text) => Text(
        text,
        style: AppTextStyles.titleMedium.copyWith(
          color: AppColors.moderatorTextPrimary,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      );

  Widget _kv(String k, String v, {bool mono = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 120,
              child: Text(
                k,
                style: const TextStyle(
                  color: AppColors.moderatorTextFaint,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: TextStyle(
                  color: AppColors.moderatorTextPrimary,
                  fontSize: mono ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

/// Loads the reported post via [ContentProvider] and opens it in the shared
/// post-detail dialog, so the reviewer can see the actual content before
/// choosing a decision.
class _ViewReportedPostButton extends StatefulWidget {
  const _ViewReportedPostButton({required this.postId});

  final String postId;

  @override
  State<_ViewReportedPostButton> createState() =>
      _ViewReportedPostButtonState();
}

class _ViewReportedPostButtonState extends State<_ViewReportedPostButton> {
  bool _loading = false;

  Future<void> _open() async {
    if (_loading) return;
    setState(() => _loading = true);
    final ContentPost? post =
        await context.read<ContentProvider>().loadPostById(widget.postId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (post == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('That post could not be loaded (it may be deleted).'),
        ));
      return;
    }
    await showPostDetailDialog(context, post);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: <Color>[AppColors.gradientPink, AppColors.gradientPurple],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_loading)
              const SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.visibility_outlined,
                  size: 16, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _loading ? 'Loading post…' : 'View reported post',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Right column: history + decision ───────────────────────────────────────

class _RightColumn extends StatelessWidget {
  const _RightColumn({
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
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.moderatorTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (history == null)
          const Text(
            'No history available.',
            style: TextStyle(color: AppColors.moderatorTextFaint, fontSize: 12),
          )
        else ...<Widget>[
          _histRow(
            'Joined',
            history!.joinedAt == null
                ? '—'
                : DateFormat('d MMM yyyy').format(history!.joinedAt!),
          ),
          _histRow('Account status', history!.accountStatus),
          _histRow(
            'Reports against',
            '${history!.reportsAgainst30d} in 30 days',
            highlight: history!.reportsAgainst30d > 3,
          ),
          _histRow('Blocked by', '${history!.blockedByCount} people'),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Previous actions',
            style: TextStyle(
              color: AppColors.moderatorTextFaint,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          if (history!.previousActions.isEmpty)
            const Text(
              'None',
              style: TextStyle(
                color: AppColors.moderatorTextPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            )
          else
            for (final PreviousAction a in history!.previousActions)
              _PrevAction(action: a),
        ],
        const SizedBox(height: AppSpacing.xl),

        // Assign / reopen affordances
        if (report.isResolved)
          _WideButton(
            label: acting ? 'Working…' : 'Reopen to re-decide',
            onTap: acting ? null : onReopen,
          )
        else if (!report.isAssigned)
          _WideButton(
            label: acting ? 'Working…' : 'Assign to me',
            onTap: acting ? null : onAssign,
          ),

        const SizedBox(height: AppSpacing.lg),
        Text(
          'Decision',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.moderatorTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
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
              style: TextStyle(
                color: AppColors.moderatorTextFaint,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
          for (final ModDecision d in decisions)
            GestureDetector(
              onTap: acting ? null : () => onDecisionChanged(d),
              child: Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md - 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.moderatorSurfaceAlt2,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedDecision == d
                        ? AppColors.moderatorPink
                        : AppColors.moderatorTextPrimary.withValues(alpha: 0.08),
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
                        fontWeight: selectedDecision == d
                            ? FontWeight.w700
                            : FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        d.subtitle,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: selectedDecision == d
                              ? AppColors.moderatorPink
                              : AppColors.moderatorTextFaint,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
          _WideButton(
            label: acting
                ? 'Applying…'
                : (selectedDecision == ModDecision.escalate
                    ? 'Escalate'
                    : 'Apply decision'),
            gradient: true,
            onTap: (acting || selectedDecision == null || !noteValid)
                ? null
                : onApply,
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
            Text(k,
                style: const TextStyle(
                    color: AppColors.moderatorTextFaint, fontSize: 12)),
            Flexible(
              child: Text(
                v,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: highlight
                      ? AppColors.moderatorPink
                      : AppColors.moderatorTextPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}

// ── Themed note-prompt dialog (Reopen, etc.) ───────────────────────────────

class _NotePromptDialog extends StatefulWidget {
  const _NotePromptDialog({
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.confirmLabel,
  });

  final String title;
  final String subtitle;
  final String hint;
  final String confirmLabel;

  @override
  State<_NotePromptDialog> createState() => _NotePromptDialogState();
}

class _NotePromptDialogState extends State<_NotePromptDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final int len = _controller.text.trim().length;
    final bool valid = len >= 1 && len <= 1000;
    final bool focused = _focusNode.hasFocus;

    return Dialog(
      backgroundColor: AppColors.moderatorSurface,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.moderatorBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                widget.title,
                style: const TextStyle(
                  color: AppColors.moderatorTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: AppColors.moderatorTextMuted,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                decoration: BoxDecoration(
                  color: AppColors.moderatorSurfaceAlt2,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: focused
                        ? AppColors.gradientCyan
                        : AppColors.moderatorInputBorder,
                    width: focused ? 1.5 : 1,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 1000,
                  cursorColor: AppColors.gradientCyan,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    color: AppColors.moderatorTextPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle:
                        const TextStyle(color: AppColors.moderatorTextFaint),
                    counterText: '',
                    contentPadding: const EdgeInsets.all(AppSpacing.md),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$len / 1000',
                  style: const TextStyle(
                    color: AppColors.moderatorTextFaint,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _WideButton(
                      label: 'Cancel',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _WideButton(
                      label: widget.confirmLabel,
                      gradient: true,
                      onTap: valid
                          ? () => Navigator.pop(
                              context, _controller.text.trim())
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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
                style: const TextStyle(
                  color: AppColors.moderatorTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '· ${action.decisionLabel}',
                style: const TextStyle(
                  color: AppColors.moderatorTextSecondary,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (action.resolvedAt != null)
                Text(
                  DateFormat('d MMM').format(action.resolvedAt!),
                  style: const TextStyle(
                    color: AppColors.moderatorTextFaint,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
          if (action.moderatorNote != null &&
              action.moderatorNote!.isNotEmpty) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              action.moderatorNote!,
              style: const TextStyle(
                color: AppColors.moderatorTextMuted,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WideButton extends StatelessWidget {
  const _WideButton({
    required this.label,
    this.onTap,
    this.gradient = false,
  });

  final String label;
  final VoidCallback? onTap;
  final bool gradient;

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 46,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: gradient
                ? const LinearGradient(
                    colors: <Color>[
                      AppColors.moderatorPink,
                      AppColors.moderatorPurpleAccent,
                      AppColors.gradientCyan,
                    ],
                  )
                : null,
            color: gradient ? null : AppColors.moderatorSurfaceAlt2,
            borderRadius: BorderRadius.circular(23),
            border: gradient
                ? null
                : Border.all(
                    color: AppColors.moderatorTextPrimary.withValues(alpha: 0.1),
                  ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.moderatorTextPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.badge});

  final ReportBadge badge;

  @override
  Widget build(BuildContext context) {
    if (badge == ReportBadge.none) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badge.color.withValues(alpha: 0.4)),
      ),
      child: Text(
        badge.label,
        style: TextStyle(
          color: badge.color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _CenteredError extends StatelessWidget {
  const _CenteredError({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            message,
            style: const TextStyle(
              color: AppColors.moderatorTextSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _TopButton(label: 'Back to queue', onTap: onBack),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../admin_view/content/models/content_post.dart';
import '../../../admin_view/content/provider/content_provider.dart';
import '../../../admin_view/content/screens/admin_post_detail_dialog.dart';
import '../../../admin_view/widgets/admin_kv_row.dart';
import '../../reports/models/mod_report.dart';

/// Left column: the report facts, ids, and the last decision (if any).
class ReportedContentPanel extends StatelessWidget {
  const ReportedContentPanel({required this.report, super.key});

  final ModReport report;

  @override
  Widget build(BuildContext context) {
    final bool canViewPost =
        report.targetType.toLowerCase() == 'post' && report.targetId != null && report.targetId!.isNotEmpty;

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
        if (report.communityName != null && report.communityName!.isNotEmpty) _kv('Community', report.communityName!),
        if (report.assignedToLabel != null) _kv('Assigned to', report.assignedToLabel!),
        if (report.isAppeal) _kv('Appeal', 'Yes'),
        _kv('Created', DateFormat('d MMM yyyy · h:mm a').format(report.createdAt)),
        if (report.resolvedAt != null) _kv('Resolved', DateFormat('d MMM yyyy · h:mm a').format(report.resolvedAt!)),
        if (report.resolvedByLabel != null) _kv('Resolved by', report.resolvedByLabel!),
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
                style: const TextStyle(color: AppColors.moderatorTextSecondary, fontSize: 13, height: 1.4),
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
    style: AppTextStyles.titleMedium.copyWith(color: AppColors.moderatorTextPrimary, fontWeight: FontWeight.w700, fontSize: 16),
  );

  Widget _kv(String k, String v, {bool mono = false}) =>
      AdminKvRow(k, v, mono: mono, labelColor: AppColors.moderatorTextFaint, valueColor: AppColors.moderatorTextPrimary);
}

/// Loads the reported post via [ContentProvider] and opens it in the shared
/// post-detail dialog, so the reviewer can see the actual content before
/// choosing a decision.
class _ViewReportedPostButton extends StatefulWidget {
  const _ViewReportedPostButton({required this.postId});

  final String postId;

  @override
  State<_ViewReportedPostButton> createState() => _ViewReportedPostButtonState();
}

class _ViewReportedPostButtonState extends State<_ViewReportedPostButton> {
  bool _loading = false;

  Future<void> _open() async {
    if (_loading) return;
    setState(() => _loading = true);
    final ContentPost? post = await context.read<ContentProvider>().loadPostById(widget.postId);
    if (!mounted) return;
    setState(() => _loading = false);
    if (post == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('That post could not be loaded (it may be deleted).')));
      return;
    }
    await showPostDetailDialog(context, post);
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _open,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: <Color>[AppColors.gradientPink, AppColors.gradientPurple]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              if (_loading)
                const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              else
                const Icon(Icons.visibility_outlined, size: 16, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                _loading ? 'Loading post…' : 'View reported post',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

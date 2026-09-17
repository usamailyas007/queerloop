import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_centered_message.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../../widgets/admin_delete_icon_button.dart';
import '../../widgets/admin_table_column_header.dart';
import '../models/cotd_models.dart';
import '../provider/cotd_provider.dart';

/// Past-questions table on the History screen: header row + filtered body.
class CotdHistoryTable extends StatelessWidget {
  const CotdHistoryTable({
    required this.provider,
    required this.search,
    required this.onOpenAnswers,
    super.key,
  });

  final CotdProvider provider;
  final String search;
  final ValueChanged<CotdQuestion> onOpenAnswers;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adminBorder),
      ),
      child: Column(
        children: <Widget>[
          const _HistoryHeaderRow(),
          Expanded(
            child: _HistoryBody(
              provider: provider,
              search: search,
              onOpenAnswers: onOpenAnswers,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({
    required this.provider,
    required this.search,
    required this.onOpenAnswers,
  });

  final CotdProvider provider;
  final String search;
  final ValueChanged<CotdQuestion> onOpenAnswers;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingHistory && provider.history.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.adminPink),
        ),
      );
    }
    if (provider.historyError != null && provider.history.isEmpty) {
      return AdminCenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: provider.historyError!,
        onRetry: provider.refreshHistory,
      );
    }
    if (provider.isHistoryEmpty) {
      return const AdminCenteredMessage(
        icon: Icons.forum_outlined,
        message: 'No questions published yet.',
      );
    }

    final List<CotdQuestion> items = provider.history
        .where((CotdQuestion q) =>
            search.isEmpty || q.question.toLowerCase().contains(search.toLowerCase()))
        .toList();

    if (items.isEmpty) {
      return const AdminCenteredMessage(
        icon: Icons.search_off_rounded,
        message: 'No questions match your search.',
      );
    }

    return RefreshIndicator(
      color: AppColors.adminPink,
      backgroundColor: AppColors.adminSurface,
      onRefresh: provider.refreshHistory,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.adminRowDivider),
        itemBuilder: (_, int index) => _HistoryRow(
          question: items[index],
          onOpenAnswers: onOpenAnswers,
          busy: provider.isQuestionDeleting(items[index].id),
          onDelete: () => provider.deleteQuestion(items[index].id),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.question,
    required this.onOpenAnswers,
    required this.busy,
    required this.onDelete,
  });

  final CotdQuestion question;
  final ValueChanged<CotdQuestion> onOpenAnswers;
  final bool busy;
  final VoidCallback onDelete;

  static final DateFormat _date = DateFormat('d MMM yyyy');

  @override
  Widget build(BuildContext context) {
    final CotdQuestion q = question;
    final Color chip = q.isLive ? AppColors.adminTeal : AppColors.adminTextSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                q.question,
                style: const TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _date.format(q.publishedAt),
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 12.5),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              NumberFormat.decimalPattern().format(q.answerCount),
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 12.5),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '${q.reports}',
              style: TextStyle(
                color: q.reports > 0 ? AppColors.adminOrange : AppColors.adminTextSecondary,
                fontWeight: q.reports > 0 ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: chip.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: chip.withValues(alpha: 0.4)),
                ),
                child: Text(
                  q.status.label,
                  style: TextStyle(color: chip, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 156,
            child: Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => onOpenAnswers(q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.adminSurfaceAlt,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.adminBorder),
                      ),
                      child: const Text(
                        'View answers',
                        style: TextStyle(
                          color: AppColors.adminTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (busy)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
                    )
                  else
                    AdminDeleteIconButton(
                      tooltip: 'Delete question',
                      onTap: () => _confirmDeleteQuestion(context, onDelete),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteQuestion(BuildContext context, VoidCallback onDelete) async {
  final bool ok = await showAdminConfirmDialog(
    context,
    title: 'Delete question permanently?',
    message: 'This question and all of its answers will be permanently deleted. This cannot be undone.',
  );
  if (ok) {
    onDelete();
  }
}

class _HistoryHeaderRow extends StatelessWidget {
  const _HistoryHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md - 2,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.adminDivider)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 4, child: AdminTableColumnHeader('QUESTION', fontSize: 9.5)),
          Expanded(flex: 2, child: AdminTableColumnHeader('PUBLISHED', fontSize: 9.5)),
          Expanded(flex: 2, child: AdminTableColumnHeader('ANSWERS', fontSize: 9.5)),
          Expanded(flex: 1, child: AdminTableColumnHeader('REPORTS', fontSize: 9.5)),
          Expanded(flex: 2, child: AdminTableColumnHeader('STATUS', fontSize: 9.5)),
          SizedBox(width: 156),
        ],
      ),
    );
  }
}

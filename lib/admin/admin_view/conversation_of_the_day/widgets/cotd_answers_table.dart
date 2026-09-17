import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_centered_message.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../../widgets/admin_remote_avatar.dart';
import '../../widgets/admin_table_column_header.dart';
import '../models/cotd_models.dart';
import '../provider/cotd_provider.dart';

/// Answers table for one Conversation-of-the-day question: header row +
/// scrollable, feature/hide-able body.
class CotdAnswersTable extends StatelessWidget {
  const CotdAnswersTable({required this.provider, super.key});

  final CotdProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _AnswersHeaderRow(),
        Expanded(child: _AnswersBody(provider: provider)),
      ],
    );
  }
}

class _AnswersBody extends StatelessWidget {
  const _AnswersBody({required this.provider});

  final CotdProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoadingAnswers && provider.answers.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.adminPink),
        ),
      );
    }
    if (provider.answersError != null && provider.answers.isEmpty) {
      return AdminCenteredMessage(message: provider.answersError!, onRetry: provider.refreshAnswers);
    }
    if (provider.isAnswersEmpty) {
      return const AdminCenteredMessage(message: 'No answers yet.');
    }

    return RefreshIndicator(
      color: AppColors.adminPink,
      backgroundColor: AppColors.adminSurface,
      onRefresh: provider.refreshAnswers,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: provider.answers.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.adminRowDivider),
        itemBuilder: (_, int index) {
          final CotdAnswer a = provider.answers[index];
          return _AnswerRow(
            answer: a,
            busy: provider.isAnswerMutating(a.id),
            onFeature: () => provider.featureAnswer(a.id),
            onHide: () => provider.hideAnswer(a.id),
            onDelete: () => provider.deleteAnswer(a.id),
          );
        },
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  const _AnswerRow({
    required this.answer,
    required this.busy,
    required this.onFeature,
    required this.onHide,
    required this.onDelete,
  });

  final CotdAnswer answer;
  final bool busy;
  final VoidCallback onFeature;
  final VoidCallback onHide;
  final VoidCallback onDelete;

  static final DateFormat _date = DateFormat('d MMM · h:mm a');

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: answer.hidden ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: Row(
                children: <Widget>[
                  AdminRemoteAvatar(seed: answer.name, imageUrl: answer.avatarUrl, size: 26),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          answer.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.adminTextPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          answer.handle,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    answer.body,
                    style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
                  ),
                  if (answer.featured || answer.hidden) ...<Widget>[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: <Widget>[
                        if (answer.featured)
                          const _Tag(text: 'Featured', color: AppColors.adminTeal),
                        if (answer.hidden)
                          const _Tag(text: 'Hidden', color: AppColors.adminPinkLight),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                _date.format(answer.createdAt.toLocal()),
                style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
              ),
            ),
            SizedBox(
              width: 210,
              child: Align(
                alignment: Alignment.centerRight,
                child: busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _MiniButton(
                            label: 'Feature',
                            color: AppColors.adminTeal,
                            enabled: !answer.featured,
                            onTap: onFeature,
                          ),
                          const SizedBox(width: 6),
                          _MiniButton(
                            label: 'Hide',
                            color: AppColors.adminPinkLight,
                            enabled: !answer.hidden,
                            onTap: onHide,
                          ),
                          const SizedBox(width: 6),
                          _MiniButton(
                            label: 'Delete',
                            color: AppColors.adminPink,
                            enabled: true,
                            onTap: () => _confirmDeleteAnswer(context, onDelete),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteAnswer(BuildContext context, VoidCallback onDelete) async {
  final bool ok = await showAdminConfirmDialog(
    context,
    title: 'Delete answer permanently?',
    message: 'This answer will be permanently deleted. This cannot be undone.',
  );
  if (ok) {
    onDelete();
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: enabled ? onTap : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.adminSurfaceAlt,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 10)),
    );
  }
}

class _AnswersHeaderRow extends StatelessWidget {
  const _AnswersHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.adminDivider)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 2, child: AdminTableColumnHeader('PERSON')),
          Expanded(flex: 4, child: AdminTableColumnHeader('ANSWER')),
          Expanded(flex: 1, child: AdminTableColumnHeader('POSTED')),
          SizedBox(width: 210),
        ],
      ),
    );
  }
}

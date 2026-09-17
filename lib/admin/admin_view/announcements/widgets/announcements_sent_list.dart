import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../widgets/admin_badge.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../../widgets/admin_delete_icon_button.dart';
import '../models/announcement.dart';
import '../provider/announcements_provider.dart';

class AnnouncementsSentList extends StatelessWidget {
  const AnnouncementsSentList({required this.provider, super.key});

  final AnnouncementsProvider provider;

  static final DateFormat _dateFormat = DateFormat('d MMM · h:mm a');

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.announcements.isEmpty) {
      return const Center(
        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink)),
      );
    }

    if (provider.error != null && provider.announcements.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              provider.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(width: 110, child: AppOutlineButton(text: 'Retry', height: 36, onPressed: provider.refresh)),
          ],
        ),
      );
    }

    if (provider.isEmpty) {
      return const Center(
        child: Text('Nothing published yet.', style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12)),
      );
    }

    final List<Announcement> items = provider.pageItems;
    return Column(
      children: <Widget>[
        Expanded(
          child: RefreshIndicator(
            color: AppColors.adminPink,
            backgroundColor: AppColors.adminSurface,
            onRefresh: provider.refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, int index) => _AnnouncementTile(
                announcement: items[index],
                dateFormat: _dateFormat,
                busy: provider.isDeleting(items[index].id),
                onDelete: () => provider.deleteAnnouncement(items[index].id),
              ),
            ),
          ),
        ),
        _AnnouncementsPager(provider: provider),
      ],
    );
  }
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({
    required this.announcement,
    required this.dateFormat,
    required this.busy,
    required this.onDelete,
  });

  final Announcement announcement;
  final DateFormat dateFormat;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Announcement a = announcement;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(color: AppColors.adminSurfaceAlt, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  a.title,
                  style: const TextStyle(color: AppColors.adminTextPrimary, fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const AdminBadge(text: 'Sent', color: AppColors.adminTeal),
              const SizedBox(width: 6),
              if (busy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
                )
              else
                AdminDeleteIconButton(
                  tooltip: 'Delete announcement',
                  onTap: () => _confirmDeleteAnnouncement(context, a.title, onDelete),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            '${a.audience.label} · ${dateFormat.format(a.publishedAt.toLocal())}',
            style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 11),
          ),
          if (a.body.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              a.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteAnnouncement(BuildContext context, String title, VoidCallback onDelete) async {
  final bool ok = await showAdminConfirmDialog(
    context,
    title: 'Delete announcement permanently?',
    message: '"$title" will be permanently deleted and removed from every user\'s notifications.',
  );
  if (ok) {
    onDelete();
  }
}

/// Client-side pager: Back · 1 2 3 · Next
class _AnnouncementsPager extends StatelessWidget {
  const _AnnouncementsPager({required this.provider});

  final AnnouncementsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.pageCount <= 1) {
      return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.md),
      padding: const EdgeInsets.only(top: AppSpacing.md),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.adminDivider))),
      child: Row(
        children: <Widget>[
          Flexible(
            child: Text(
              'Showing ${provider.rangeStart}–${provider.rangeEnd} of ${provider.total}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
            ),
          ),
          const Spacer(),
          _PagerChip(label: 'Back', enabled: provider.canPrev, onTap: provider.prevPage),
          for (int p = 1; p <= provider.pageCount; p++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: _PagerChip(label: '$p', selected: p == provider.page, onTap: () => provider.goToPage(p)),
            ),
          _PagerChip(label: 'Next', enabled: provider.canNext, onTap: provider.nextPage),
        ],
      ),
    );
  }
}

class _PagerChip extends StatelessWidget {
  const _PagerChip({required this.label, required this.onTap, this.selected = false, this.enabled = true});

  final String label;
  final VoidCallback onTap;
  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final bool interactive = enabled && !selected;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: selected ? AppColors.moderatorChipSelected : AppColors.adminSurfaceAlt,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          borderRadius: BorderRadius.circular(9),
          onTap: interactive ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minWidth: 30),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: selected ? Colors.transparent : AppColors.adminButtonBorder),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.adminTextPrimary : AppColors.adminTextSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_centered_message.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../../widgets/admin_delete_icon_button.dart';
import '../../widgets/admin_remote_avatar.dart';
import '../../widgets/admin_table_column_header.dart';
import '../models/community.dart';
import '../provider/communities_provider.dart';

/// The communities data table: header row + scrollable body (loading / error
/// / empty / list states).
class CommunitiesTable extends StatelessWidget {
  const CommunitiesTable({required this.provider, super.key});

  final CommunitiesProvider provider;

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
          const _TableHeaderRow(),
          Expanded(child: _CommunitiesBody(provider: provider)),
        ],
      ),
    );
  }
}

class _CommunitiesBody extends StatelessWidget {
  const _CommunitiesBody({required this.provider});

  final CommunitiesProvider provider;

  static final NumberFormat _count = NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.communities.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.adminPink),
        ),
      );
    }

    if (provider.error != null && provider.communities.isEmpty) {
      return AdminCenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: provider.error!,
        onRetry: provider.refresh,
      );
    }

    if (provider.isEmpty) {
      return const AdminCenteredMessage(
        icon: Icons.groups_2_outlined,
        message: 'No communities yet — add your first one.',
      );
    }

    final List<Community> items = provider.communities;
    return RefreshIndicator(
      color: AppColors.adminPink,
      backgroundColor: AppColors.adminSurface,
      onRefresh: provider.refresh,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.adminRowDivider),
        itemBuilder: (_, int index) => _CommunityRow(
          community: items[index],
          count: _count,
          busy: provider.isDeleting(items[index].id),
          onDelete: () => provider.deleteCommunity(items[index].id),
        ),
      ),
    );
  }
}

class _CommunityRow extends StatelessWidget {
  const _CommunityRow({
    required this.community,
    required this.count,
    required this.busy,
    required this.onDelete,
  });

  final Community community;
  final NumberFormat count;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final bool isPrivate = community.visibility == CommunityVisibility.private;
    final Color chip = isPrivate ? AppColors.adminPurple : AppColors.adminTeal;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 3,
            child: Row(
              children: <Widget>[
                AdminRemoteAvatar(seed: community.name, imageUrl: community.imageUrl),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        community.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.adminTextPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        community.slug,
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
            flex: 2,
            child: Text(
              count.format(community.memberCount),
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              count.format(community.postCount),
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              count.format(community.reportCount),
              style: TextStyle(
                color: community.reportCount > 50
                    ? AppColors.adminOrange
                    : AppColors.adminTextSecondary,
                fontWeight:
                    community.reportCount > 50 ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              community.moderatorsLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
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
                  community.visibility.label,
                  style: TextStyle(color: chip, fontWeight: FontWeight.w700, fontSize: 11),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 44,
            child: Align(
              alignment: Alignment.centerRight,
              child: busy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
                    )
                  : AdminDeleteIconButton(
                      tooltip: 'Delete community',
                      onTap: () => _confirmDeleteCommunity(context, community.name, onDelete),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _confirmDeleteCommunity(BuildContext context, String name, VoidCallback onDelete) async {
  final bool ok = await showAdminConfirmDialog(
    context,
    title: 'Delete community permanently?',
    message: '"$name" and all of its posts will be permanently deleted. This cannot be undone.',
  );
  if (ok) {
    onDelete();
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

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
          Expanded(flex: 3, child: AdminTableColumnHeader('COMMUNITY')),
          Expanded(flex: 2, child: AdminTableColumnHeader('MEMBERS')),
          Expanded(flex: 2, child: AdminTableColumnHeader('POSTS')),
          Expanded(flex: 1, child: AdminTableColumnHeader('REPORTS')),
          Expanded(flex: 2, child: AdminTableColumnHeader('MODERATORS')),
          Expanded(flex: 2, child: AdminTableColumnHeader('VISIBILITY')),
          SizedBox(width: 44),
        ],
      ),
    );
  }
}

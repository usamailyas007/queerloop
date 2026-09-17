import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_centered_message.dart';
import '../../widgets/admin_table_column_header.dart';
import '../models/moderator.dart';
import '../provider/moderators_provider.dart';
import 'moderator_row_tile.dart';

class ModeratorsTable extends StatelessWidget {
  const ModeratorsTable({required this.provider, super.key});

  final ModeratorsProvider provider;

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
          Expanded(child: _ModeratorsBody(provider: provider)),
        ],
      ),
    );
  }
}

class _ModeratorsBody extends StatelessWidget {
  const _ModeratorsBody({required this.provider});

  final ModeratorsProvider provider;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.moderators.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.adminPink),
        ),
      );
    }

    if (provider.error != null && provider.moderators.isEmpty) {
      return AdminCenteredMessage(
        icon: Icons.cloud_off_rounded,
        message: provider.error!,
        onRetry: provider.refresh,
      );
    }

    if (provider.isEmpty) {
      return const AdminCenteredMessage(icon: Icons.shield_outlined, message: 'No moderators yet.');
    }

    final List<Moderator> items = provider.moderators;
    return RefreshIndicator(
      color: AppColors.adminPink,
      backgroundColor: AppColors.adminSurface,
      onRefresh: provider.refresh,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: AppColors.adminRowDivider),
        itemBuilder: (BuildContext context, int index) {
          final Moderator mod = items[index];
          return ModeratorRowTile(
            mod: mod,
            resending: provider.isResending(mod.id),
            deleting: provider.isDeleting(mod.id),
            onResend: () => _resend(context, mod),
            onDelete: () => context.read<ModeratorsProvider>().deleteModerator(mod.id),
          );
        },
      ),
    );
  }

  Future<void> _resend(BuildContext context, Moderator mod) async {
    final ModeratorsProvider p = context.read<ModeratorsProvider>();
    final String? message = await p.resendInvite(mod.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message ?? p.error ?? 'Could not re-send the invite.')));
    if (message == null) {
      p.clearError();
    }
  }
}

class _TableHeaderRow extends StatelessWidget {
  const _TableHeaderRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md - 2),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.adminDivider)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(flex: 3, child: AdminTableColumnHeader('MODERATOR')),
          Expanded(flex: 2, child: AdminTableColumnHeader('COMMUNITIES')),
          Expanded(flex: 2, child: AdminTableColumnHeader('RESOLVED · 30D')),
          Expanded(flex: 2, child: AdminTableColumnHeader('AVG RESPONSE')),
          Expanded(flex: 1, child: AdminTableColumnHeader('REVERSED')),
          SizedBox(width: 210, child: AdminTableColumnHeader('STATUS')),
        ],
      ),
    );
  }
}

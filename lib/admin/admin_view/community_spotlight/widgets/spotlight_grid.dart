import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../models/spotlight.dart';
import '../provider/spotlights_provider.dart';
import '../screens/spotlight_image.dart';

/// The past-spotlights grid: loading / error / empty states, or the cards.
class SpotlightGrid extends StatelessWidget {
  const SpotlightGrid({
    required this.provider,
    required this.onView,
    required this.onEdit,
    required this.onRerun,
    required this.onDelete,
    super.key,
  });

  final SpotlightsProvider provider;
  final ValueChanged<Spotlight> onView;
  final ValueChanged<Spotlight> onEdit;
  final ValueChanged<Spotlight> onRerun;
  final ValueChanged<Spotlight> onDelete;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.spotlights.isEmpty) {
      return const Center(
        child: SizedBox(
          width: 26,
          height: 26,
          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.adminPink),
        ),
      );
    }
    if (provider.error != null && provider.spotlights.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              provider.error!,
              style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: 120,
              child: AppOutlineButton(text: 'Retry', height: 38, onPressed: provider.refresh),
            ),
          ],
        ),
      );
    }
    if (provider.isEmpty) {
      return const Center(
        child: Text('No spotlights yet.', style: TextStyle(color: AppColors.adminTextMuted, fontSize: 13)),
      );
    }

    final List<Spotlight> items = provider.spotlights;
    return RefreshIndicator(
      color: AppColors.adminPink,
      backgroundColor: AppColors.adminSurface,
      onRefresh: provider.refresh,
      child: GridView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.5,
        ),
        itemBuilder: (_, int index) {
          final Spotlight s = items[index];
          return _Card(
            spotlight: s,
            busy: provider.isRerunning(s.id) || provider.isDeleting(s.id),
            onView: () => onView(s),
            onEdit: () => onEdit(s),
            onRerun: () => onRerun(s),
            onDelete: () => onDelete(s),
          );
        },
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.spotlight,
    required this.busy,
    required this.onView,
    required this.onEdit,
    required this.onRerun,
    required this.onDelete,
  });

  final Spotlight spotlight;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onEdit;
  final VoidCallback onRerun;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.adminSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adminBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                SpotlightImage(url: spotlight.imageUrl, borderRadius: 0),
                if (spotlight.live)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.adminTeal.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Live now',
                        style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  spotlight.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.adminTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('d MMM').format(spotlight.createdAt)} · '
                  '${NumberFormat.compact().format(spotlight.views)} views · '
                  '${NumberFormat.compact().format(spotlight.taps)} taps',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 11),
                ),
                const SizedBox(height: AppSpacing.sm),
                busy
                    ? const SizedBox(
                        height: 26,
                        child: Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
                          ),
                        ),
                      )
                    : Row(
                        children: <Widget>[
                          Expanded(child: _MiniButton(label: 'View', onTap: onView)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _MiniButton(
                              label: spotlight.live ? 'Edit' : 'Re-run',
                              onTap: spotlight.live ? onEdit : onRerun,
                            ),
                          ),
                          const SizedBox(width: 6),
                          _MiniButton(
                            label: 'Delete',
                            danger: true,
                            onTap: () => _confirmDeleteSpotlight(context, spotlight.title, onDelete),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  const _MiniButton({required this.label, required this.onTap, this.danger = false});

  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: danger ? AppColors.adminPink.withValues(alpha: 0.14) : AppColors.adminSurfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: danger ? AppColors.adminPink.withValues(alpha: 0.4) : AppColors.adminBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: danger ? AppColors.adminPink : AppColors.adminTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

Future<void> _confirmDeleteSpotlight(BuildContext context, String title, VoidCallback onDelete) async {
  final bool ok = await showAdminConfirmDialog(
    context,
    title: 'Delete spotlight permanently?',
    message: '"$title" will be permanently deleted. This cannot be undone.',
  );
  if (ok) {
    onDelete();
  }
}

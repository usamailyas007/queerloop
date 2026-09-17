import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_outline_button.dart';
import '../../widgets/admin_confirm_dialog.dart';
import '../models/content_post.dart';
import '../provider/content_provider.dart';
import 'content_mini_button.dart';
import 'content_thumb.dart';

/// The main content grid: loading / error / empty states, or the post cards.
class ContentPostGrid extends StatelessWidget {
  const ContentPostGrid({
    required this.provider,
    required this.onView,
    required this.onToggle,
    required this.onDelete,
    super.key,
  });

  final ContentProvider provider;
  final ValueChanged<ContentPost> onView;
  final ValueChanged<ContentPost> onToggle;
  final ValueChanged<ContentPost> onDelete;

  @override
  Widget build(BuildContext context) {
    if (provider.isLoading && provider.posts.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: SizedBox(
            width: 26,
            height: 26,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.adminPink),
          ),
        ),
      );
    }
    if (provider.error != null && provider.posts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(provider.error!, style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 13)),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: 120,
                child: AppOutlineButton(text: 'Retry', height: 38, onPressed: provider.refresh),
              ),
            ],
          ),
        ),
      );
    }
    if (provider.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: Text('No posts yet.', style: TextStyle(color: AppColors.adminTextMuted, fontSize: 13)),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: provider.posts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 0.58,
      ),
      itemBuilder: (_, int i) {
        final ContentPost post = provider.posts[i];
        return _ContentCard(
          post: post,
          busy: provider.isMutating(post.id),
          onView: () => onView(post),
          onToggle: () => onToggle(post),
          onDelete: () => onDelete(post),
        );
      },
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.post,
    required this.busy,
    required this.onView,
    required this.onToggle,
    required this.onDelete,
  });

  final ContentPost post;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final Color statusColor = post.isHidden ? AppColors.adminPink : AppColors.adminTeal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                ContentThumb(post: post),
                Positioned(top: 8, left: 8, child: _pill(post.statusLabel, statusColor)),
                if (post.reportCount > 0)
                  Positioned(top: 8, right: 8, child: _pill('⚑ ${post.reportCount}', AppColors.adminOrange)),
                if (post.type == ContentPostType.video)
                  const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 34)),
                Positioned(
                  bottom: 8,
                  left: 8,
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.remove_red_eye_outlined, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        NumberFormat.compact().format(post.viewCount),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${post.author.handle} · ${post.type.label}',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.adminTextSecondary, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Row(
          children: <Widget>[
            Expanded(child: ContentMiniButton(label: 'View', onTap: onView)),
            const SizedBox(width: 4),
            Expanded(
              child: busy
                  ? const SizedBox(
                      height: 25,
                      child: Center(
                        child: SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
                        ),
                      ),
                    )
                  : ContentMiniButton(
                      label: post.isHidden ? 'Restore' : 'Hide',
                      danger: !post.isHidden,
                      onTap: onToggle,
                    ),
            ),
          ],
        ),
        if (!busy) ...<Widget>[
          const SizedBox(height: 4),
          ContentMiniButton(
            label: 'Delete',
            danger: true,
            onTap: () => _confirmDeletePost(context, onDelete),
          ),
        ],
      ],
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(10)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
      );
}

Future<void> _confirmDeletePost(BuildContext context, VoidCallback onDelete) async {
  final bool ok = await showAdminConfirmDialog(
    context,
    title: 'Delete post permanently?',
    message: 'This post will be permanently deleted. This cannot be undone.',
  );
  if (ok) {
    onDelete();
  }
}

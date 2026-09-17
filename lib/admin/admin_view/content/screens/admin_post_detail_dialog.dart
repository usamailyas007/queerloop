import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_kv_row.dart';
import '../models/content_post.dart';
import '../widgets/post_detail_header.dart';
import '../widgets/post_detail_media_area.dart';
import '../widgets/post_stats_row.dart';

Future<void> showPostDetailDialog(BuildContext context, ContentPost post) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => _PostDetailDialog(post: post),
  );
}

class _PostDetailDialog extends StatelessWidget {
  const _PostDetailDialog({required this.post});

  final ContentPost post;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.adminSurface,
      insetPadding: const EdgeInsets.all(AppSpacing.xl),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppColors.adminBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            PostDetailHeader(post: post),
            const Divider(height: 1, color: AppColors.adminDivider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    PostDetailMediaArea(post: post),
                    const SizedBox(height: AppSpacing.lg),
                    if (post.body.isNotEmpty) ...<Widget>[
                      Text(
                        post.body,
                        style: const TextStyle(
                          color: AppColors.adminTextPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (post.tags.isNotEmpty)
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: <Widget>[
                          for (final String tag in post.tags)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.adminSurfaceAlt,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.adminBorder),
                              ),
                              child: Text(
                                tag,
                                style: const TextStyle(
                                  color: AppColors.adminTextSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.lg),
                    PostStatsRow(post: post),
                    const SizedBox(height: AppSpacing.md),
                    AdminKvRow('Type', post.type.label, labelWidth: 90),
                    AdminKvRow('Status', post.statusLabel, labelWidth: 90),
                    AdminKvRow('Visibility', post.visibility ?? '—', labelWidth: 90),
                    AdminKvRow('Reports', '${post.reportCount}', labelWidth: 90),
                    AdminKvRow(
                      'Posted',
                      DateFormat('d MMM yyyy · h:mm a').format(post.createdAt),
                      labelWidth: 90,
                    ),
                    AdminKvRow('Community', post.communityId ?? '—', mono: true, labelWidth: 90),
                    AdminKvRow('Post ID', post.id, mono: true, labelWidth: 90),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

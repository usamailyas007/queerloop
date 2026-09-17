import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../widgets/admin_badge.dart';
import '../../widgets/admin_remote_avatar.dart';
import '../models/content_post.dart';

/// Author + status row at the top of the post-detail dialog.
class PostDetailHeader extends StatelessWidget {
  const PostDetailHeader({required this.post, super.key});

  final ContentPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: <Widget>[
          AdminRemoteAvatar(seed: post.author.name, imageUrl: post.author.avatarUrl),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  post.author.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.adminTextPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  post.author.handle,
                  style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 11),
                ),
              ],
            ),
          ),
          AdminBadge(
            text: post.statusLabel,
            color: post.isHidden ? AppColors.adminPink : AppColors.adminTeal,
          ),
        ],
      ),
    );
  }
}

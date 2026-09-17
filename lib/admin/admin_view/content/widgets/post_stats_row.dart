import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/content_post.dart';

/// Views / likes / comments / reports strip on the post-detail dialog.
class PostStatsRow extends StatelessWidget {
  const PostStatsRow({required this.post, super.key});

  final ContentPost post;

  @override
  Widget build(BuildContext context) {
    final NumberFormat f = NumberFormat.compact();
    return Row(
      children: <Widget>[
        _stat(Icons.remove_red_eye_outlined, f.format(post.viewCount), 'views'),
        _stat(Icons.favorite_border_rounded, f.format(post.likeCount), 'likes'),
        _stat(Icons.mode_comment_outlined, f.format(post.commentCount), 'comments'),
        if (post.reportCount > 0)
          _stat(Icons.flag_outlined, '${post.reportCount}', 'reports', danger: true),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label, {bool danger = false}) {
    final Color c = danger ? AppColors.adminPink : AppColors.adminTextSecondary;
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text('$value ', style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12)),
          Text(label, style: const TextStyle(color: AppColors.adminTextMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

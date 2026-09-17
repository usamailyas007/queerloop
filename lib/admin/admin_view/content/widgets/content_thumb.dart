import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/content_post.dart';
import '../provider/content_provider.dart';

/// A post's resolved thumbnail, or a type-appropriate placeholder icon while
/// it's loading / unavailable.
class ContentThumb extends StatelessWidget {
  const ContentThumb({required this.post, super.key});

  final ContentPost post;

  @override
  Widget build(BuildContext context) {
    final String? ref = post.primaryMediaRef;
    final MediaAsset? asset =
        ref == null ? null : context.select<ContentProvider, MediaAsset?>((ContentProvider p) => p.media(ref));

    final Widget placeholder = Container(
      color: AppColors.adminSurfaceAlt,
      alignment: Alignment.center,
      child: Icon(
        post.type == ContentPostType.video
            ? Icons.videocam_outlined
            : post.type == ContentPostType.text
                ? Icons.notes_rounded
                : Icons.image_outlined,
        color: AppColors.adminTextMuted,
        size: 22,
      ),
    );

    final String? url = asset?.posterUrl;
    if (url == null) {
      return placeholder;
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}

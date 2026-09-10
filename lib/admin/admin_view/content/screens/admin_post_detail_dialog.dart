import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../models/content_post.dart';
import '../provider/content_provider.dart';

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
            _Header(post: post),
            const Divider(height: 1, color: AppColors.adminDivider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _MediaArea(post: post),
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
                                border:
                                    Border.all(color: AppColors.adminBorder),
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
                    _StatsRow(post: post),
                    const SizedBox(height: AppSpacing.md),
                    _kv('Type', post.type.label),
                    _kv('Status', post.statusLabel),
                    _kv('Visibility', post.visibility ?? '—'),
                    _kv('Reports', '${post.reportCount}'),
                    _kv(
                      'Posted',
                      DateFormat('d MMM yyyy · h:mm a').format(post.createdAt),
                    ),
                    _kv('Community', post.communityId ?? '—', mono: true),
                    _kv('Post ID', post.id, mono: true),
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

  Widget _kv(String k, String v, {bool mono = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 90,
              child: Text(
                k,
                style: const TextStyle(
                  color: AppColors.adminTextMuted,
                  fontSize: 12,
                ),
              ),
            ),
            Expanded(
              child: Text(
                v,
                style: TextStyle(
                  color: AppColors.adminTextPrimary,
                  fontSize: mono ? 11 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.post});

  final ContentPost post;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: <Widget>[
          _Avatar(url: post.author.avatarUrl, name: post.author.name),
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
                  style: const TextStyle(
                    color: AppColors.adminTextMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          _Chip(
            label: post.statusLabel,
            color: post.isHidden ? AppColors.adminPink : AppColors.adminTeal,
          ),
        ],
      ),
    );
  }
}

class _MediaArea extends StatefulWidget {
  const _MediaArea({required this.post});

  final ContentPost post;

  @override
  State<_MediaArea> createState() => _MediaAreaState();
}

class _MediaAreaState extends State<_MediaArea> {
  @override
  void initState() {
    super.initState();
    final String? ref = widget.post.primaryMediaRef;
    if (ref != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<ContentProvider>().ensureMedia(ref);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? ref = widget.post.primaryMediaRef;
    if (ref == null) {
      return _frame(
        const Center(
          child: Text(
            'Text post — no media',
            style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
          ),
        ),
      );
    }

    final MediaAsset? asset =
        context.select<ContentProvider, MediaAsset?>((ContentProvider p) => p.media(ref));

    if (asset == null) {
      return _frame(
        const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.adminPink,
            ),
          ),
        ),
      );
    }

    if (asset.isVideo) {
      return _frame(_VideoPlayerBox(asset: asset));
    }

    final String? url = asset.url ?? asset.posterUrl;
    if (url == null) {
      return _frame(const Center(
        child: Text('Media unavailable',
            style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12)),
      ));
    }
    return _frame(
      Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Center(
          child: Text("Couldn't load image",
              style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12)),
        ),
      ),
    );
  }

  Widget _frame(Widget child) => ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 300,
          width: double.infinity,
          color: AppColors.adminSurfaceAlt,
          child: child,
        ),
      );
}

class _VideoPlayerBox extends StatefulWidget {
  const _VideoPlayerBox({required this.asset});

  final MediaAsset asset;

  @override
  State<_VideoPlayerBox> createState() => _VideoPlayerBoxState();
}

class _VideoPlayerBoxState extends State<_VideoPlayerBox> {
  VideoPlayerController? _controller;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final String? url = widget.asset.playableUrl;
    if (url == null) {
      setState(() => _failed = true);
      return;
    }
    final VideoPlayerController c =
        VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await c.initialize();
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() => _controller = c);
    } catch (_) {
      await c.dispose();
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final VideoPlayerController? c = _controller;

    if (c != null && c.value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AspectRatio(
            aspectRatio: c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
            child: VideoPlayer(c),
          ),
          _PlayToggle(controller: c),
        ],
      );
    }

    // Loading or unplayable → show the poster.
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        if (widget.asset.posterUrl != null)
          Image.network(widget.asset.posterUrl!,
              fit: BoxFit.cover, width: double.infinity, height: double.infinity,
              errorBuilder: (_, _, _) => const SizedBox.shrink()),
        Container(color: Colors.black.withValues(alpha: 0.35)),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              _failed ? Icons.videocam_off_rounded : Icons.play_circle_fill_rounded,
              color: Colors.white,
              size: 44,
            ),
            const SizedBox(height: 8),
            Text(
              _failed
                  ? 'Video preview not supported here'
                  : 'Loading video…',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            if (widget.asset.durationSeconds != null)
              Text(
                '${widget.asset.durationSeconds}s',
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
          ],
        ),
      ],
    );
  }
}

class _PlayToggle extends StatefulWidget {
  const _PlayToggle({required this.controller});

  final VideoPlayerController controller;

  @override
  State<_PlayToggle> createState() => _PlayToggleState();
}

class _PlayToggleState extends State<_PlayToggle> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.controller.value.isPlaying
              ? widget.controller.pause()
              : widget.controller.play();
        });
      },
      child: AnimatedOpacity(
        opacity: widget.controller.value.isPlaying ? 0 : 1,
        duration: const Duration(milliseconds: 200),
        child: const CircleAvatar(
          radius: 26,
          backgroundColor: Colors.black54,
          child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.post});

  final ContentPost post;

  @override
  Widget build(BuildContext context) {
    final NumberFormat f = NumberFormat.compact();
    return Row(
      children: <Widget>[
        _stat(Icons.remove_red_eye_outlined, f.format(post.viewCount), 'views'),
        _stat(Icons.favorite_border_rounded, f.format(post.likeCount), 'likes'),
        _stat(Icons.mode_comment_outlined, f.format(post.commentCount),
            'comments'),
        if (post.reportCount > 0)
          _stat(Icons.flag_outlined, '${post.reportCount}', 'reports',
              danger: true),
      ],
    );
  }

  Widget _stat(IconData icon, String value, String label,
      {bool danger = false}) {
    final Color c =
        danger ? AppColors.adminPink : AppColors.adminTextSecondary;
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            '$value ',
            style: TextStyle(color: c, fontWeight: FontWeight.w700, fontSize: 12),
          ),
          Text(
            label,
            style: const TextStyle(
                color: AppColors.adminTextMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    const double size = 34;
    if (url != null && url!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final String initial =
        name.isEmpty ? '?' : name.characters.first.toUpperCase();
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.adminPurple.withValues(alpha: 0.22),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.adminPurple.withValues(alpha: 0.5)),
      ),
      child: Text(
        initial,
        style: const TextStyle(
          color: AppColors.adminPurple,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

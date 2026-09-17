import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/theme/app_colors.dart';
import '../models/content_post.dart';
import '../provider/content_provider.dart';

/// Resolves and renders a post's primary media — image, video, or a
/// "text post" placeholder when there's none.
class PostDetailMediaArea extends StatefulWidget {
  const PostDetailMediaArea({required this.post, super.key});

  final ContentPost post;

  @override
  State<PostDetailMediaArea> createState() => _PostDetailMediaAreaState();
}

class _PostDetailMediaAreaState extends State<PostDetailMediaArea> {
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
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.adminPink),
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
        child: Text(
          'Media unavailable',
          style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
        ),
      ));
    }
    return _frame(
      Image.network(
        url,
        fit: BoxFit.contain,
        webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
        errorBuilder: (_, _, _) => const Center(
          child: Text(
            "Couldn't load image",
            style: TextStyle(color: AppColors.adminTextMuted, fontSize: 12),
          ),
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
    final VideoPlayerController c = VideoPlayerController.networkUrl(Uri.parse(url));
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
          Image.network(
            widget.asset.posterUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
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
              _failed ? 'Video preview not supported here' : 'Loading video…',
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
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
      ),
    );
  }
}

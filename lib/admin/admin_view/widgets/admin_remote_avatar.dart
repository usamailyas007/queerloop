import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A circular avatar that shows a remote image ([imageUrl]) when one is
/// available and falls back to the first letter of [seed] otherwise.
///
/// On web the image is rendered through a real `<img>` element
/// ([WebHtmlElementStrategy.prefer]) because the media CDN does not send CORS
/// headers — the default CanvasKit path would taint the canvas and fail.
class AdminRemoteAvatar extends StatelessWidget {
  const AdminRemoteAvatar({
    required this.seed,
    this.imageUrl,
    this.size = 34,
    this.faded = false,
    super.key,
  });

  final String seed;
  final String? imageUrl;
  final double size;
  final bool faded;

  static const List<Color> _palette = <Color>[
    AppColors.adminPink,
    AppColors.adminPurple,
    AppColors.adminTeal,
    AppColors.adminOrange,
  ];

  @override
  Widget build(BuildContext context) {
    final String? url = imageUrl;
    if (url != null && url.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          errorBuilder: (_, _, _) => _fallback(),
        ),
      );
    }
    return _fallback();
  }

  Widget _fallback() {
    final String clean = seed.replaceAll('@', '').trim();
    final String initial =
        clean.isEmpty ? '?' : clean.characters.first.toUpperCase();
    final Color bg = _palette[clean.hashCode.abs() % _palette.length];
    final double alpha = faded ? 0.12 : 0.22;

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: alpha),
        shape: BoxShape.circle,
        border: Border.all(color: bg.withValues(alpha: faded ? 0.3 : 0.5)),
      ),
      child: Text(
        initial,
        style: TextStyle(
          color: bg,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

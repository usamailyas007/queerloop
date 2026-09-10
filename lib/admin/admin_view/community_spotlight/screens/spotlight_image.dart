import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// A spotlight cover image with a graceful fallback when the URL is missing,
/// malformed (e.g. invalid scheme like `http:hhhshsh`), or fails to load.
/// Also supports base64 Data URIs (`data:image/...`).
class SpotlightImage extends StatelessWidget {
  const SpotlightImage({
    required this.url,
    this.height,
    this.borderRadius = 12,
    super.key,
  });

  final String? url;
  final double? height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final Widget fallback = Container(
      color: AppColors.adminSurfaceAlt,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.adminTextMuted,
        size: 26,
      ),
    );

    final String? src = url?.trim();
    if (src == null || src.isEmpty) {
      return _clip(fallback);
    }

    // 1. Base64 Data URI check
    if (src.startsWith('data:image/') || src.contains(';base64,')) {
      try {
        final String base64Str = src.contains(',') ? src.split(',').last : src;
        final Uint8List bytes = base64Decode(base64Str);
        return _clip(
          Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: height,
            errorBuilder: (_, _, _) => fallback,
          ),
        );
      } catch (_) {
        return _clip(fallback);
      }
    }

    // 2. Strict HTTP/HTTPS URL validation before calling Image.network
    final Uri? parsed = Uri.tryParse(src);
    if (parsed == null ||
        !parsed.hasScheme ||
        (!parsed.isScheme('http') && !parsed.isScheme('https')) ||
        parsed.host.isEmpty) {
      return _clip(fallback);
    }

    return _clip(
      Image.network(
        src,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }

  Widget _clip(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: child,
      ),
    );
  }
}

import 'package:flutter/material.dart';

/// A single line of text with a light band sweeping across it — used as a
/// loading affordance where a spinner would be too heavy (e.g. button labels).
class ShimmerText extends StatefulWidget {
  const ShimmerText(
    this.text, {
    super.key,
    this.style,
    this.baseColor = Colors.white,
    this.highlightColor = const Color(0x4DFFFFFF),
    this.duration = const Duration(milliseconds: 1100),
  });

  final String text;
  final TextStyle? style;

  /// Colour of the text at rest.
  final Color baseColor;

  /// Colour of the moving band. A translucent value lets the button
  /// gradient shine through as the band passes.
  final Color highlightColor;

  final Duration duration;

  @override
  State<ShimmerText> createState() => _ShimmerTextState();
}

class _ShimmerTextState extends State<ShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: <Color>[
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const <double>[0.35, 0.5, 0.65],
              transform: _SweepTransform(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: Text(
        widget.text,
        maxLines: 1,
        style: (widget.style ?? const TextStyle()).copyWith(
          color: widget.baseColor,
        ),
      ),
    );
  }
}

/// Slides the gradient from just left of the text to just right of it.
class _SweepTransform extends GradientTransform {
  const _SweepTransform(this.t);

  final double t;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final double dx = (t * 2 - 1) * bounds.width;
    return Matrix4.translationValues(dx, 0, 0);
  }
}

import 'package:flutter/material.dart';

/// Sweeps a soft gradient highlight across child widgets (skeletons/placeholders).
class AppShimmer extends StatefulWidget {
  const AppShimmer({
    required this.child,
    super.key,
    this.baseColor,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final Duration duration;

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer>
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color effectiveBase = widget.baseColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFE8E8EE));
    final Color effectiveHighlight = widget.highlightColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.18)
            : Colors.white.withValues(alpha: 0.7));

    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              begin: const Alignment(-1.0, -0.3),
              end: const Alignment(1.0, 0.3),
              colors: <Color>[
                effectiveBase,
                effectiveHighlight,
                effectiveBase,
              ],
              stops: const <double>[0.3, 0.5, 0.7],
              transform: _ShimmerSweepTransform(_controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _ShimmerSweepTransform extends GradientTransform {
  const _ShimmerSweepTransform(this.percent);

  final double percent;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final double dx = (percent * 3.0 - 1.5) * bounds.width;
    return Matrix4.translationValues(dx, 0, 0);
  }
}

/// A lightweight rectangular or circular placeholder block for shimmer skeletons.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.isCircle = false,
    this.color,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color defaultColor = color ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : const Color(0xFFEBEBF0));

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: defaultColor,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      ),
    );
  }
}

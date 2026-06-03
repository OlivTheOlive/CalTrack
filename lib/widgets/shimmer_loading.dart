import 'package:caltrack/core/spacing.dart';
import 'package:flutter/material.dart';

/// Animated shimmer skeleton primitives used while data loads.
///
/// [ShimmerBox] is a single shimmering rectangle; wrap several in a
/// [Column] (or use [ShimmerCard]) to build a placeholder layout. The
/// animation is driven by a single repeating [AnimationController] so the
/// effect stays in sync across boxes within the same subtree.
class ShimmerBox extends StatefulWidget {
  const ShimmerBox({
    super.key,
    required this.width,
    required this.height,
    this.borderRadius = Corners.radiusMd,
  });

  final double width;
  final double height;
  final BorderRadius borderRadius;

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = scheme.surfaceContainerHigh;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(-1 - 2 * (1 - t), 0),
              end: Alignment(1 - 2 * (1 - t), 0),
              colors: [base, highlight, base],
              stops: const [0.25, 0.5, 0.75],
            ),
          ),
        );
      },
    );
  }
}

/// A full-width shimmering card placeholder of the given [height].
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({super.key, required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return ShimmerBox(
      width: double.infinity,
      height: height,
      borderRadius: Corners.radiusLg,
    );
  }
}

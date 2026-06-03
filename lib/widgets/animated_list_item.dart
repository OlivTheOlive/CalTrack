import 'package:flutter/material.dart';

/// Wraps [child] in a staggered fade + slide-up entrance animation.
///
/// [index] controls the stagger delay (index × [stagger]); place these in a
/// list so items cascade in. The animation runs once on first build.
class AnimatedListItem extends StatefulWidget {
  const AnimatedListItem({
    super.key,
    required this.index,
    required this.child,
    this.duration = const Duration(milliseconds: 350),
    this.stagger = const Duration(milliseconds: 50),
    this.maxStaggerItems = 8,
  });

  final int index;
  final Widget child;
  final Duration duration;
  final Duration stagger;

  /// Cap the cumulative delay so long lists don't take forever to appear.
  final int maxStaggerItems;

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.05),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    final cappedIndex =
        widget.index.clamp(0, widget.maxStaggerItems);
    final delay = widget.stagger * cappedIndex;
    Future<void>.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

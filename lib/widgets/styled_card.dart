import 'package:caltrack/core/spacing.dart';
import 'package:flutter/material.dart';

/// Surface tone for a [StyledCard]. Maps to MD3 surface container roles so
/// stacked cards read with a subtle elevation hierarchy without shadows.
enum CardTone {
  low,
  normal,
  high,
  highest,
}

/// A consistent MD3 card wrapper used across the revamped UI.
///
/// Provides uniform corner radius, padding and an optional tap target while
/// letting callers pick a surface tone. Prefer this over raw [Card] +
/// [Padding] so spacing/radii stay in sync.
class StyledCard extends StatelessWidget {
  const StyledCard({
    super.key,
    required this.child,
    this.tone = CardTone.low,
    this.padding = const EdgeInsets.all(Spacing.md),
    this.onTap,
    this.margin = EdgeInsets.zero,
    this.borderRadius = Corners.radiusLg,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final CardTone tone;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final BorderRadius borderRadius;
  final Clip clipBehavior;

  Color _color(ColorScheme scheme) {
    switch (tone) {
      case CardTone.low:
        return scheme.surfaceContainerLow;
      case CardTone.normal:
        return scheme.surfaceContainer;
      case CardTone.high:
        return scheme.surfaceContainerHigh;
      case CardTone.highest:
        return scheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final content = Padding(padding: padding, child: child);
    return Padding(
      padding: margin,
      child: Material(
        color: _color(scheme),
        clipBehavior: clipBehavior,
        borderRadius: borderRadius,
        child: onTap == null
            ? content
            : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

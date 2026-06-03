import 'package:caltrack/core/spacing.dart';
import 'package:flutter/material.dart';

/// Inline chip showing a signed delta with a trend icon and semantic color.
///
/// [delta] is already in display units (kg or lb). [unitLabel] is appended
/// when [showUnit] is true. Coloring is goal-aware: when [lowerIsBetter] is
/// true a negative delta is treated as positive progress (loses weight →
/// primary), otherwise the convention flips.
class ChangeBadge extends StatelessWidget {
  const ChangeBadge({
    super.key,
    required this.delta,
    this.unitLabel = '',
    this.showUnit = true,
    this.lowerIsBetter = true,
    this.decimals = 1,
    this.dense = false,
  });

  final double delta;
  final String unitLabel;
  final bool showUnit;

  /// When true, losing weight (negative delta) is rendered as good progress.
  final bool lowerIsBetter;
  final int decimals;
  final bool dense;

  bool get _isFlat => delta.abs() < 0.05;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final Color fg;
    final IconData icon;
    if (_isFlat) {
      fg = scheme.onSurfaceVariant;
      icon = Icons.trending_flat;
    } else {
      final isGood = lowerIsBetter ? delta < 0 : delta > 0;
      fg = isGood ? scheme.primary : scheme.error;
      icon = delta > 0 ? Icons.arrow_upward : Icons.arrow_downward;
    }

    final sign = delta > 0 ? '+' : (delta < 0 ? '\u2212' : '');
    final magnitude = delta.abs().toStringAsFixed(decimals);
    final unitSuffix = showUnit && unitLabel.isNotEmpty ? ' $unitLabel' : '';
    final label = _isFlat ? '0$unitSuffix' : '$sign$magnitude$unitSuffix';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? Spacing.sm : 10,
        vertical: dense ? 2 : Spacing.xs,
      ),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: Corners.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: dense ? 14 : 16, color: fg),
          const SizedBox(width: Spacing.xs),
          Text(
            label,
            style: (dense ? theme.textTheme.labelSmall : theme.textTheme.labelMedium)
                ?.copyWith(color: fg, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

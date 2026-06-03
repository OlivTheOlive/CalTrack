import 'package:caltrack/core/spacing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A small rounded badge showing the day-of-month and abbreviated month,
/// used as the leading element on weight entry tiles.
class DateBadge extends StatelessWidget {
  const DateBadge({super.key, required this.date, this.highlight = false});

  final DateTime date;

  /// When true (e.g. today's entry), the badge uses the primary container
  /// color for emphasis.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = highlight
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final fg = highlight
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: Corners.radiusMd,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            DateFormat.d().format(date),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: fg,
              height: 1.0,
            ),
          ),
          Text(
            DateFormat.MMM().format(date).toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: fg,
              height: 1.1,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

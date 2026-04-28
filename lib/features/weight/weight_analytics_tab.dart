import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Body for the "Weight" tab inside the root shell. Shows a header
/// summary, a trend chart, and the entries list.
class WeightAnalyticsTab extends StatelessWidget {
  const WeightAnalyticsTab({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();

    return StreamBuilder<List<WeightEntry>>(
      stream: repo.watchWeightEntries(),
      builder: (context, entriesSnap) {
        final entries = entriesSnap.data;
        if (entries == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return FutureBuilder(
          future: _loadHeader(repo),
          builder: (context, headerSnap) {
            final header = headerSnap.data;
            if (header == null) {
              return const Center(child: CircularProgressIndicator());
            }
            final (profile, goal, weeklyDeltaKg) = header;
            final unit = WeightUnit.fromStored(profile.weightUnit);

            if (entries.isEmpty) {
              return _EmptyState(
                bottomInset: bottomInset,
                onLogTap: () => context.push('/log-weight'),
              );
            }

            final streak = computeDayStreak(
              qualifyingDays: {
                for (final e in entries) calendarDay(e.recordedAt),
              },
              referenceDay: DateTime.now(),
            );

            return ListView(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
              children: [
                _SummaryCard(
                  latestKg: entries.first.weightKg,
                  weeklyDeltaKg: weeklyDeltaKg,
                  goalTargetKg: goal?.targetWeightKg,
                  intendedWeeklyKg: goal?.weeklyChangeKgPerWeek,
                  unit: unit,
                  streak: streak,
                ),
                const SizedBox(height: 16),
                _TrendChartCard(entries: entries, unit: unit),
                const SizedBox(height: 16),
                Text(
                  'Recent entries',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                _EntriesList(entries: entries, unit: unit),
              ],
            );
          },
        );
      },
    );
  }

  static Future<(Profile, Goal?, double?)> _loadHeader(
    CalTrackRepository repo,
  ) async {
    final profile = await repo.requireProfile();
    final goal = await repo.currentGoal();
    final delta = await repo.weeklyDeltaKg();
    return (profile, goal, delta);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLogTap, required this.bottomInset});

  final VoidCallback onLogTap;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: EdgeInsets.fromLTRB(24, 64, 24, 24 + bottomInset),
      children: [
        Icon(
          Icons.monitor_weight_outlined,
          size: 56,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 12),
        Text(
          'No weigh-ins yet',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Log your weight to start tracking trends and weekly changes.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: FilledButton.icon(
            onPressed: onLogTap,
            icon: const Icon(Icons.add),
            label: const Text('Log first weight'),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.latestKg,
    required this.weeklyDeltaKg,
    required this.goalTargetKg,
    required this.intendedWeeklyKg,
    required this.unit,
    required this.streak,
  });

  final double latestKg;
  final double? weeklyDeltaKg;
  final double? goalTargetKg;
  final double? intendedWeeklyKg;
  final WeightUnit unit;
  final StreakInfo streak;

  String _fmt(double kg) {
    final v = unit == WeightUnit.kg ? kg : kgToLb(kg);
    return '${v.toStringAsFixed(1)} ${unit.shortLabel}';
  }

  String _fmtSigned(double kg) {
    final v = unit == WeightUnit.kg ? kg : kgToLb(kg);
    final sign = v >= 0 ? '+' : '';
    return '$sign${v.toStringAsFixed(2)} ${unit.shortLabel}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final delta = weeklyDeltaKg;
    final goalKg = goalTargetKg;

    Widget? deltaWidget;
    if (delta != null) {
      final intended = intendedWeeklyKg ?? 0;
      final positiveOk = intended >= 0;
      final onTrack = positiveOk ? delta >= 0 : delta <= 0;
      deltaWidget = Row(
        children: [
          Icon(
            delta >= 0 ? Icons.trending_up : Icons.trending_down,
            size: 18,
            color: onTrack ? scheme.primary : scheme.tertiary,
          ),
          const SizedBox(width: 6),
          Text(
            '${_fmtSigned(delta)} this week',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _fmt(latestKg),
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            ?deltaWidget,
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  size: 18,
                  color: streak.current > 0
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Text(
                  streak.current > 0
                      ? 'Weigh-in streak: ${streak.current} '
                          '${streak.current == 1 ? "day" : "days"}'
                          ' (best ${streak.best})'
                      : 'No active weigh-in streak'
                          '${streak.best > 0 ? " (best ${streak.best})" : ""}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (goalKg != null) ...[
              const Divider(height: 28),
              Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Goal ${_fmt(goalKg)}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const Spacer(),
                  Text(
                    '${_fmtSigned(goalKg - latestKg)} to go',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TrendChartCard extends StatefulWidget {
  const _TrendChartCard({required this.entries, required this.unit});

  final List<WeightEntry> entries;
  final WeightUnit unit;

  @override
  State<_TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends State<_TrendChartCard> {
  static const _windows = <int>[7, 14, 30];
  int _windowDays = 14;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = widget.unit;

    final stats = computeWeightTrendStats(
      entries: widget.entries.map(
        (e) => (recordedAt: e.recordedAt, weightKg: e.weightKg),
      ),
      windowDays: _windowDays,
    );
    final filtered = stats.points;

    double display(double kg) => unit == WeightUnit.kg ? kg : kgToLb(kg);

    final spots = <FlSpot>[];
    for (var i = 0; i < filtered.length; i++) {
      spots.add(FlSpot(i.toDouble(), display(filtered[i].weightKg)));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Trend (${unit.shortLabel})',
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                  SegmentedButton<int>(
                    style: const ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    showSelectedIcon: false,
                    segments: [
                      for (final w in _windows)
                        ButtonSegment<int>(
                          value: w,
                          label: Text('${w}d'),
                        ),
                    ],
                    selected: {_windowDays},
                    onSelectionChanged: (s) =>
                        setState(() => _windowDays = s.first),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: spots.length < 2
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Log at least two weigh-ins in the last '
                          '$_windowDays days to see the trend.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : _buildChart(theme, spots, filtered, display),
            ),
            const SizedBox(height: 8),
            _TrendStatsRow(stats: stats, unit: unit),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(
    ThemeData theme,
    List<FlSpot> spots,
    List<({DateTime recordedAt, double weightKg})> filtered,
    double Function(double kg) display,
  ) {
    final ys = spots.map((s) => s.y);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() < 0.5 ? 2.0 : (maxY - minY) * 0.1;

    return LineChart(
      LineChartData(
        minY: minY - pad,
        maxY: maxY + pad,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval:
              ((maxY - minY).abs() / 4).clamp(0.5, double.infinity),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= filtered.length) {
                  return const SizedBox.shrink();
                }
                final d = filtered[i].recordedAt;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat.Md().format(d),
                    style: theme.textTheme.bodySmall,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (value, meta) => Text(
                value.toStringAsFixed(0),
                style: theme.textTheme.bodySmall,
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: theme.colorScheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: spots.length <= 30,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: theme.colorScheme.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color:
                  theme.colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendStatsRow extends StatelessWidget {
  const _TrendStatsRow({required this.stats, required this.unit});

  final WeightTrendStats stats;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final rate = stats.kgPerWeek;

    String rateLabel;
    if (rate == null) {
      rateLabel = '\u2014';
    } else {
      final v = unit == WeightUnit.kg ? rate : kgToLb(rate);
      final sign = v > 0 ? '+' : (v < 0 ? '' : '');
      rateLabel = '$sign${v.toStringAsFixed(2)} ${unit.shortLabel}/wk';
    }

    final consistencyPct = (stats.consistency * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 4, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              label: 'Rate',
              value: rateLabel,
              color: scheme.primary,
              icon: rate == null
                  ? Icons.show_chart
                  : (rate > 0
                      ? Icons.trending_up
                      : (rate < 0
                          ? Icons.trending_down
                          : Icons.trending_flat)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              label: 'Consistency',
              value:
                  '$consistencyPct% (${stats.distinctDaysLogged}/${stats.windowDays}d)',
              color: scheme.secondary,
              icon: Icons.check_circle_outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EntriesList extends StatelessWidget {
  const _EntriesList({required this.entries, required this.unit});

  final List<WeightEntry> entries;
  final WeightUnit unit;

  String _fmt(double kg) {
    final v = unit == WeightUnit.kg ? kg : kgToLb(kg);
    return '${v.toStringAsFixed(1)} ${unit.shortLabel}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            ListTile(
              dense: true,
              title: Text(_fmt(entries[i].weightKg)),
              subtitle: Text(
                DateFormat.yMMMd().add_jm().format(entries[i].recordedAt),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (entries[i].note != null &&
                      entries[i].note!.isNotEmpty)
                    Icon(
                      Icons.notes_outlined,
                      color: theme.colorScheme.outline,
                    ),
                  IconButton(
                    tooltip: 'Edit',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        context.push('/log-weight?id=${entries[i].id}'),
                  ),
                ],
              ),
              onTap: () => context.push('/log-weight?id=${entries[i].id}'),
            ),
            if (i < entries.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

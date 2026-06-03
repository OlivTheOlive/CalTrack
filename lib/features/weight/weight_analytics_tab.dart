import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/goal_eta.dart';
import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/core/spacing.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/widgets/animated_list_item.dart';
import 'package:caltrack/widgets/change_badge.dart';
import 'package:caltrack/widgets/date_badge.dart';
import 'package:caltrack/widgets/empty_state.dart';
import 'package:caltrack/widgets/goal_editor_sheet.dart';
import 'package:caltrack/widgets/shimmer_loading.dart';
import 'package:caltrack/widgets/stat_chip.dart';
import 'package:caltrack/widgets/styled_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

final _fmtYmd = DateFormat.yMMMd();

/// Header data loaded alongside the weight entries stream.
typedef _HeaderData = ({Profile profile, Goal? goal, double? weeklyDeltaKg, double? trendKgWeek});

/// Body for the "Weight" tab inside the root shell. Shows a hero summary,
/// mini stats, a trend chart and a swipe-to-delete entries list.
class WeightAnalyticsTab extends StatefulWidget {
  const WeightAnalyticsTab({super.key, this.bottomInset = 0});

  final double bottomInset;

  @override
  State<WeightAnalyticsTab> createState() => _WeightAnalyticsTabState();
}

class _WeightAnalyticsTabState extends State<WeightAnalyticsTab> {
  Future<_HeaderData>? _headerFuture;

  @override
  void initState() {
    super.initState();
    _headerFuture = _loadHeader();
  }

  Future<_HeaderData> _loadHeader() async {
    final repo = context.read<CalTrackRepository>();
    final profile = await repo.requireProfile();
    final goal = await repo.currentGoal();
    final delta = await repo.weeklyDeltaKg();
    final trend = await repo.trendKgPerWeek(windowDays: 14);
    return (profile: profile, goal: goal, weeklyDeltaKg: delta, trendKgWeek: trend);
  }

  Future<void> _refresh() async {
    final fut = _loadHeader();
    setState(() => _headerFuture = fut);
    await fut;
    if (mounted) {
      await context.read<ProfileController>().refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();

    return StreamBuilder<List<WeightEntry>>(
      stream: repo.watchWeightEntries(),
      builder: (context, entriesSnap) {
        final entries = entriesSnap.data;
        if (entries == null) {
          return _WeightSkeletonLoader(bottomInset: widget.bottomInset);
        }
        if (entries.isEmpty) {
          return _WeightEmptyState(
            bottomInset: widget.bottomInset,
            onLogTap: () => context.push('/log-weight'),
          );
        }

        return FutureBuilder<_HeaderData>(
          future: _headerFuture,
          builder: (context, headerSnap) {
            final header = headerSnap.data;
            if (header == null) {
              return _WeightSkeletonLoader(bottomInset: widget.bottomInset);
            }
            final unit = WeightUnit.fromStored(header.profile.weightUnit);
            return _WeightContent(
              entries: entries,
              header: header,
              unit: unit,
              bottomInset: widget.bottomInset,
              onRefresh: _refresh,
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Formatting helpers
// ---------------------------------------------------------------------------

String _fmtWeight(double kg, WeightUnit unit) {
  final v = unit == WeightUnit.kg ? kg : kgToLb(kg);
  return '${v.toStringAsFixed(1)} ${unit.shortLabel}';
}

double _toDisplay(double kg, WeightUnit unit) =>
    unit == WeightUnit.kg ? kg : kgToLb(kg);

String _relativeDay(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final entryDay = DateTime(dt.year, dt.month, dt.day);
  if (entryDay == today) return 'Today';
  if (entryDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat.MMMEd().format(dt);
}

// ---------------------------------------------------------------------------
// Main content
// ---------------------------------------------------------------------------

class _WeightContent extends StatelessWidget {
  const _WeightContent({
    required this.entries,
    required this.header,
    required this.unit,
    required this.bottomInset,
    required this.onRefresh,
  });

  final List<WeightEntry> entries;
  final _HeaderData header;
  final WeightUnit unit;
  final double bottomInset;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = WeightStats.fromEntries(entries)!;
    final streak = computeDayStreak(
      qualifyingDays: {for (final e in entries) calendarDay(e.recordedAt)},
      referenceDay: DateTime.now(),
    );

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.md,
              Spacing.md,
              Spacing.sm,
            ),
            sliver: SliverList.list(
              children: [
                _WeightHeroHeader(
                  entries: entries,
                  weeklyDeltaKg: header.weeklyDeltaKg,
                  goalTargetKg: header.goal?.targetWeightKg,
                  intendedWeeklyKg: header.goal?.weeklyChangeKgPerWeek,
                  unit: unit,
                  streak: streak,
                ),
                Spacing.vMd,
                if (header.goal != null)
                  _GoalSummaryCard(
                    goal: header.goal!,
                    profile: header.profile,
                    trendKgWeek: header.trendKgWeek,
                    latestKg: entries.first.weightKg,
                  ),
                if (header.goal != null) Spacing.vMd,
                _MiniStatsRow(stats: stats, unit: unit),
                Spacing.vMd,
                _TrendChartCard(entries: entries, unit: unit),
                Spacing.vMd,
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Recent entries',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${entries.length} total',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Spacing.vSm,
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              Spacing.md,
              0,
              Spacing.md,
              Spacing.md + bottomInset,
            ),
            sliver: SliverList.builder(
              itemCount: entries.length,
              itemBuilder: (context, i) {
                final entry = entries[i];
                final older = i + 1 < entries.length ? entries[i + 1] : null;
                final deltaKg =
                    older == null ? null : entry.weightKg - older.weightKg;
                return AnimatedListItem(
                  key: ValueKey(entry.id),
                  index: i,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.sm),
                    child: _WeightEntryTile(
                      entry: entry,
                      unit: unit,
                      deltaKg: deltaKg,
                      lowerIsBetter:
                          (header.goal?.weeklyChangeKgPerWeek ?? -1) <= 0,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero header
// ---------------------------------------------------------------------------

class _WeightHeroHeader extends StatelessWidget {
  const _WeightHeroHeader({
    required this.entries,
    required this.weeklyDeltaKg,
    required this.goalTargetKg,
    required this.intendedWeeklyKg,
    required this.unit,
    required this.streak,
  });

  final List<WeightEntry> entries;
  final double? weeklyDeltaKg;
  final double? goalTargetKg;
  final double? intendedWeeklyKg;
  final WeightUnit unit;
  final StreakInfo streak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final latestKg = entries.first.weightKg;
    final lowerIsBetter = (intendedWeeklyKg ?? -1) <= 0;

    return StyledCard(
      tone: CardTone.low,
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current weight',
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  _fmtWeight(latestKg, unit),
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.0,
                  ),
                ),
              ),
              if (weeklyDeltaKg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: Spacing.xs),
                  child: ChangeBadge(
                    delta: _toDisplay(weeklyDeltaKg!, unit),
                    unitLabel: unit.shortLabel,
                    lowerIsBetter: lowerIsBetter,
                    decimals: 2,
                  ),
                ),
            ],
          ),
          if (weeklyDeltaKg != null) ...[
            const SizedBox(height: Spacing.xs),
            Text(
              'this week',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
          if (goalTargetKg != null) ...[
            const SizedBox(height: Spacing.md),
            _GoalProgress(
              entries: entries,
              targetKg: goalTargetKg!,
              unit: unit,
            ),
          ],
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                size: 18,
                color: streak.current > 0
                    ? scheme.primary
                    : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: Spacing.xs),
              Expanded(
                child: Text(
                  streak.current > 0
                      ? 'Weigh-in streak: ${streak.current} '
                          '${streak.current == 1 ? "day" : "days"}'
                          ' (best ${streak.best})'
                      : 'No active weigh-in streak'
                          '${streak.best > 0 ? " (best ${streak.best})" : ""}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GoalProgress extends StatelessWidget {
  const _GoalProgress({
    required this.entries,
    required this.targetKg,
    required this.unit,
  });

  final List<WeightEntry> entries;
  final double targetKg;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final currentKg = entries.first.weightKg;
    final startKg = entries.last.weightKg;

    final totalDelta = startKg - targetKg;
    double progress;
    if (totalDelta.abs() < 0.01) {
      progress = 1;
    } else {
      progress = ((startKg - currentKg) / totalDelta).clamp(0.0, 1.0);
    }
    final pct = (progress * 100).round();
    final remaining = (targetKg - currentKg).abs();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.flag_outlined, size: 16, color: scheme.onSurfaceVariant),
            const SizedBox(width: Spacing.xs),
            Text(
              'Goal ${_fmtWeight(targetKg, unit)}',
              style: theme.textTheme.bodyMedium,
            ),
            const Spacer(),
            Text(
              '$pct%',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: scheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          '${_fmtWeight(remaining, unit)} to go',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Mini stats row
// ---------------------------------------------------------------------------

class _MiniStatsRow extends StatelessWidget {
  const _MiniStatsRow({required this.stats, required this.unit});

  final WeightStats stats;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      StatChip(
        label: 'Avg',
        value: _fmtWeight(stats.averageKg, unit),
        icon: Icons.bar_chart,
      ),
      StatChip(
        label: 'Lowest',
        value: _fmtWeight(stats.minKg, unit),
        icon: Icons.arrow_downward,
      ),
      StatChip(
        label: 'Highest',
        value: _fmtWeight(stats.maxKg, unit),
        icon: Icons.arrow_upward,
      ),
      StatChip(
        label: 'Entries',
        value: '${stats.count}',
        icon: Icons.playlist_add_check,
      ),
    ];
    return Row(
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(width: Spacing.sm),
          Expanded(child: items[i]),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Trend chart
// ---------------------------------------------------------------------------

class _TrendChartCard extends StatefulWidget {
  const _TrendChartCard({required this.entries, required this.unit});

  final List<WeightEntry> entries;
  final WeightUnit unit;

  @override
  State<_TrendChartCard> createState() => _TrendChartCardState();
}

class _TrendChartCardState extends State<_TrendChartCard> {
  static const _windows = <int>[7, 30, 90];
  int _windowDays = 30;

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

    final spots = <FlSpot>[];
    for (var i = 0; i < filtered.length; i++) {
      spots.add(FlSpot(i.toDouble(), _toDisplay(filtered[i].weightKg, unit)));
    }

    return StyledCard(
      tone: CardTone.low,
      padding: const EdgeInsets.fromLTRB(Spacing.sm, Spacing.md, Spacing.md, Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.sm, 0, 0, Spacing.sm),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Trend (${unit.shortLabel})',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  segments: [
                    for (final w in _windows)
                      ButtonSegment<int>(value: w, label: Text('${w}d')),
                  ],
                  selected: {_windowDays},
                  onSelectionChanged: (s) =>
                      setState(() => _windowDays = s.first),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 220,
            child: spots.length < 2
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
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
                : _buildChart(theme, spots, filtered),
          ),
          const SizedBox(height: Spacing.md),
          _TrendStatsRow(stats: stats, unit: unit),
        ],
      ),
    );
  }

  Widget _buildChart(
    ThemeData theme,
    List<FlSpot> spots,
    List<({DateTime recordedAt, double weightKg})> filtered,
  ) {
    final scheme = theme.colorScheme;
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
          getDrawingHorizontalLine: (_) => FlLine(
            color: scheme.outlineVariant.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: (filtered.length / 4).clamp(1, double.infinity),
              getTitlesWidget: (value, meta) {
                final i = value.round();
                if (i < 0 || i >= filtered.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: Spacing.xs),
                  child: Text(
                    DateFormat.Md().format(filtered[i].recordedAt),
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
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            getTooltipItems: (touched) => [
              for (final t in touched)
                LineTooltipItem(
                  '${t.y.toStringAsFixed(1)} ${widget.unit.shortLabel}',
                  theme.textTheme.labelMedium!.copyWith(
                    color: scheme.onInverseSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            preventCurveOverShooting: true,
            color: scheme.primary,
            barWidth: 3,
            dotData: FlDotData(
              show: spots.length <= 30,
              getDotPainter: (spot, _, _, _) => FlDotCirclePainter(
                radius: 3,
                color: scheme.primary,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  scheme.primary.withValues(alpha: 0.18),
                  scheme.primary.withValues(alpha: 0.0),
                ],
              ),
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
      final v = _toDisplay(rate, unit);
      final sign = v > 0 ? '+' : '';
      rateLabel = '$sign${v.toStringAsFixed(2)} ${unit.shortLabel}/wk';
    }

    final consistencyPct = (stats.consistency * 100).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
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
          const SizedBox(width: Spacing.md),
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
        const SizedBox(width: Spacing.xs),
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

// ---------------------------------------------------------------------------
// Entry tile (swipe-to-delete + undo)
// ---------------------------------------------------------------------------

class _WeightEntryTile extends StatelessWidget {
  const _WeightEntryTile({
    required this.entry,
    required this.unit,
    required this.deltaKg,
    required this.lowerIsBetter,
  });

  final WeightEntry entry;
  final WeightUnit unit;
  final double? deltaKg;
  final bool lowerIsBetter;

  Future<void> _delete(BuildContext context) async {
    final repo = context.read<CalTrackRepository>();
    final profileCtl = context.read<ProfileController>();
    final messenger = ScaffoldMessenger.of(context);
    final removed = entry;
    await repo.deleteWeightEntry(removed.id);
    await profileCtl.refresh();
    AppSnackBar.showUndoDetached(
      messenger,
      message: 'Entry deleted',
      onUndo: () async {
        await repo.restoreWeightEntry(removed);
        await profileCtl.refresh();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isToday =
        calendarDay(entry.recordedAt) == calendarDay(DateTime.now());

    return Dismissible(
      key: ValueKey('dismiss-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBackground(scheme),
      confirmDismiss: (_) async {
        await _delete(context);
        // Return false so the widget stays in the tree; the stream rebuild
        // (or undo) reconciles the list naturally.
        return false;
      },
      child: StyledCard(
        tone: CardTone.high,
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm + 2,
        ),
        onTap: () => context.push('/log-weight?id=${entry.id}'),
        child: Row(
          children: [
            DateBadge(date: entry.recordedAt, highlight: isToday),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _fmtWeight(entry.weightKg, unit),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.note?.isNotEmpty == true
                        ? entry.note!
                        : _relativeDay(entry.recordedAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (deltaKg != null)
              ChangeBadge(
                delta: _toDisplay(deltaKg!, unit),
                showUnit: false,
                lowerIsBetter: lowerIsBetter,
                dense: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _deleteBackground(ColorScheme scheme) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: Spacing.lg),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: Corners.radiusLg,
      ),
      child: Icon(Icons.delete_outline, color: scheme.onErrorContainer),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state + skeleton
// ---------------------------------------------------------------------------

class _WeightEmptyState extends StatelessWidget {
  const _WeightEmptyState({required this.onLogTap, required this.bottomInset});

  final VoidCallback onLogTap;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: EmptyState(
        icon: Icons.monitor_weight_outlined,
        title: 'Track your progress',
        message:
            'Log your weight regularly to see trends, weekly changes and '
            'how you are tracking toward your goal.',
        actionLabel: 'Add your first weigh-in',
        onAction: onLogTap,
      ),
    );
  }
}

class _WeightSkeletonLoader extends StatelessWidget {
  const _WeightSkeletonLoader({required this.bottomInset});

  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.md + bottomInset,
      ),
      children: const [
        ShimmerCard(height: 180),
        SizedBox(height: Spacing.md),
        ShimmerCard(height: 72),
        SizedBox(height: Spacing.md),
        ShimmerCard(height: 300),
        SizedBox(height: Spacing.md),
        ShimmerCard(height: 64),
        SizedBox(height: Spacing.sm),
        ShimmerCard(height: 64),
        SizedBox(height: Spacing.sm),
        ShimmerCard(height: 64),
      ],
    );
  }
}

class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({
    required this.goal,
    required this.profile,
    required this.trendKgWeek,
    required this.latestKg,
  });

  final Goal goal;
  final Profile profile;
  final double? trendKgWeek;
  final double latestKg;

  Future<void> _openEditor(BuildContext context) async {
    final repo = context.read<CalTrackRepository>();
    final profile = await repo.requireProfile();
    if (!context.mounted) return;
    await showGoalEditorSheet(context, repo: repo, profile: profile);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unit = WeightUnit.fromStored(profile.weightUnit);
    final target = unit == WeightUnit.kg
        ? '${goal.targetWeightKg.toStringAsFixed(1)} kg'
        : '${kgToLb(goal.targetWeightKg).toStringAsFixed(1)} lb';
    final rate = goal.weeklyChangeKgPerWeek;
    final displayRate = unit == WeightUnit.kg ? rate : kgToLb(rate);
    String pace;
    if (goal.status == 'maintain' || rate.abs() < 0.001) {
      pace = 'Maintenance';
    } else if (rate < 0) {
      pace = 'Losing ~${(-displayRate).abs().toStringAsFixed(2)} ${unit.shortLabel}/week';
    } else {
      pace = 'Gaining ~${displayRate.toStringAsFixed(2)} ${unit.shortLabel}/week';
    }
    final subtitleText =
        goal.status == 'pending_choice' ? 'Choose next step' : pace;

    return StyledCard(
      tone: CardTone.low,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.sm,
        Spacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: Corners.radiusSm,
                ),
                child: Icon(
                  Icons.flag_outlined,
                  size: 20,
                  color: scheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Goal: $target',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit goal',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _openEditor(context),
              ),
            ],
          ),
          if (goal.status != 'maintain' && goal.status != 'pending_choice')
            _GoalEtaSection(
              goal: goal,
              currentKg: latestKg,
              trendKgWeek: trendKgWeek,
              unit: unit,
            ),
        ],
      ),
    );
  }
}

class _GoalEtaSection extends StatelessWidget {
  const _GoalEtaSection({
    required this.goal,
    required this.currentKg,
    required this.trendKgWeek,
    required this.unit,
  });

  final Goal goal;
  final double? currentKg;
  final double? trendKgWeek;
  final WeightUnit unit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final current = currentKg;
    if (current == null) return const SizedBox.shrink();

    final atGoal = atGoalWeight(
      currentWeightKg: current,
      targetWeightKg: goal.targetWeightKg,
    );
    if (atGoal) {
      return Padding(
        padding: const EdgeInsets.only(top: 12, right: 12),
        child: Text(
          'You are at your goal weight.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final staticEta = estimateGoalEta(
      currentWeightKg: current,
      targetWeightKg: goal.targetWeightKg,
      weeklyKg: goal.weeklyChangeKgPerWeek,
    );
    final trend = trendKgWeek;
    final trendEta = trend == null
        ? null
        : estimateGoalEta(
            currentWeightKg: current,
            targetWeightKg: goal.targetWeightKg,
            weeklyKg: trend,
          );

    if (staticEta == null && trendEta == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 14, right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (staticEta != null)
            _EtaRow(
              icon: Icons.timer_outlined,
              label: 'At your chosen pace',
              eta: staticEta,
              color: scheme.primary,
            ),
          if (trendEta != null) ...[
            const SizedBox(height: 6),
            _EtaRow(
              icon: Icons.trending_flat,
              label: 'At your recent trend',
              eta: trendEta,
              color: scheme.secondary,
              trailingNote:
                  unit == WeightUnit.kg
                      ? 'based on last ~14 days (${trendEta.weeklyKg.toStringAsFixed(2)} kg/wk)'
                      : 'based on last ~14 days (${kgToLb(trendEta.weeklyKg).toStringAsFixed(2)} lb/wk)',
            ),
          ] else if (staticEta != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Trend ETA appears once you have a few weigh-ins.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EtaRow extends StatelessWidget {
  const _EtaRow({
    required this.icon,
    required this.label,
    required this.eta,
    required this.color,
    this.trailingNote,
  });

  final IconData icon;
  final String label;
  final GoalEta eta;
  final Color color;
  final String? trailingNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateLabel = _fmtYmd.format(eta.eta);
    final weeksLabel =
        eta.weeks == 1 ? '~1 week' : '~${eta.weeks} weeks';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$label · $weeksLabel',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'around $dateLabel'
                '${trailingNote == null ? '' : ' · $trailingNote'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

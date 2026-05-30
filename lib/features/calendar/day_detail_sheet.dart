import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DayDetailSheet extends StatelessWidget {
  const DayDetailSheet({super.key, required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final repo = context.read<CalTrackRepository>();
    final nf = NumberFormat('#,###');
    final isToday = calendarDay(day) == calendarDay(DateTime.now());

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (context, scrollController) {
        return StreamBuilder<DailyIntakeTotals>(
          stream: repo.watchIntakeForDay(day),
          builder: (context, intakeSnap) {
            final intake = intakeSnap.data ?? DailyIntakeTotals.zero;
            return FutureBuilder<Profile>(
              future: repo.requireProfile(),
              builder: (context, profileSnap) {
                final profile = profileSnap.data;
                final target = profile?.dailyCalorieTarget;
                final hasTarget = target != null && target > 0;

                final consumed = intake.kcal;
                final remaining = hasTarget ? (target - consumed).round() : 0;
                final over = hasTarget && consumed > target;
                final calRatio = hasTarget
                    ? (consumed / target).clamp(0.0, 1.0)
                    : 0.0;

                final dateLabel = isToday
                    ? 'Today'
                    : DateFormat('EEEE, MMMM d').format(day);

                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  children: [
                    // Date + calorie summary
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            dateLabel,
                            style: theme.textTheme.titleLarge,
                          ),
                        ),
                        if (hasTarget)
                          Text(
                            over
                                ? '${nf.format(-remaining)} kcal over'
                                : '${nf.format(remaining)} kcal left',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: over ? scheme.error : scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (hasTarget) ...[
                      RichText(
                        text: TextSpan(
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: scheme.onSurface,
                          ),
                          children: [
                            TextSpan(text: nf.format(consumed.round())),
                            TextSpan(
                              text: ' / ${nf.format(target.round())} kcal',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          minHeight: 10,
                          value: over ? 1.0 : calRatio,
                          backgroundColor: scheme.surfaceContainerHighest,
                          color: over ? scheme.error : scheme.primary,
                        ),
                      ),
                    ] else
                      Card(
                        color: scheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 18, color: scheme.onSurfaceVariant),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  target == null
                                      ? 'Set a calorie goal in Settings to see tracking status.'
                                      : 'No calorie target set.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${nf.format(consumed.round())} kcal · '
                      '${nf.format(intake.proteinG.round())}g protein · '
                      '${nf.format(intake.carbsG.round())}g carbs · '
                      '${nf.format(intake.fatG.round())}g fat',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Divider(height: 24),
                    // Meal sections
                    _MealSections(day: day, repo: repo),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: () {
                              final path = isToday
                                  ? '/log-food'
                                  : '/log-food?day=${_formatDayParam(day)}';
                              context.push(path);
                            },
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Log food'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              context.push('/log-weight');
                            },
                            icon: const Icon(Icons.monitor_weight_outlined,
                                size: 18),
                            label: const Text('Log weight'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _formatDayParam(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _MealSections extends StatelessWidget {
  const _MealSections({required this.day, required this.repo});

  final DateTime day;
  final CalTrackRepository repo;

  static const _periodOrder = [
    MealPeriod.breakfast,
    MealPeriod.lunch,
    MealPeriod.dinner,
    MealPeriod.snack,
  ];

  static final _nf = NumberFormat('#,###');

  static String _periodLabel(MealPeriod p) =>
      p.name[0].toUpperCase() + p.name.substring(1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<Map<MealPeriod?, List<FoodLogEntry>>>(
      stream: repo.watchFoodLogsForDayByPeriod(day),
      builder: (context, snap) {
        final grouped = snap.data ?? const <MealPeriod?, List<FoodLogEntry>>{};
        final allEntries = grouped.values.expand((l) => l).toList();

        if (allEntries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No food logged on this day.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }

        final sections = <Widget>[];
        for (final period in _periodOrder) {
          final entries = grouped[period] ?? [];
          if (entries.isEmpty) continue;
          sections.add(_PeriodSection(
            period: period,
            entries: entries,
            scheme: scheme,
            theme: theme,
            nf: _nf,
          ));
        }
        final uncategorized = grouped[null] ?? [];
        if (uncategorized.isNotEmpty) {
          sections.add(_PeriodSection(
            period: null,
            entries: uncategorized,
            scheme: scheme,
            theme: theme,
            nf: _nf,
          ));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: sections,
        );
      },
    );
  }
}

class _PeriodSection extends StatelessWidget {
  const _PeriodSection({
    required this.period,
    required this.entries,
    required this.scheme,
    required this.theme,
    required this.nf,
  });

  final MealPeriod? period;
  final List<FoodLogEntry> entries;
  final ColorScheme scheme;
  final ThemeData theme;
  final NumberFormat nf;

  @override
  Widget build(BuildContext context) {
    final sectionKcal = entries.fold<double>(0, (a, e) => a + e.kcal).round();
    final label =
        period != null ? _MealSections._periodLabel(period!) : 'Other';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Row(
            children: [
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${nf.format(sectionKcal)} kcal',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        ...entries.map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      e.displayName,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${nf.format(e.kcal.round())} kcal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )),
        const Divider(height: 16),
      ],
    );
  }
}

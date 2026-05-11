import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/food_emoji.dart';
import 'package:caltrack/core/goal_eta.dart';
import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/features/food/food_entry_sheet.dart';
import 'package:caltrack/features/food/quick_add_sheet.dart';
import 'package:caltrack/widgets/goal_choice_sheet.dart';
import 'package:caltrack/widgets/goal_editor_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// Intl formatters are relatively expensive to construct; reuse them.
final _nfDecimal = NumberFormat.decimalPattern();
final _fmtDayShort = DateFormat.MMMd();
final _fmtDayLong = DateFormat.yMMMEd();
final _fmtTime = DateFormat.jm();
final _fmtMonthDay = DateFormat.MMMEd();
final _fmtYmd = DateFormat.yMMMd();

/// Dashboard tab body. Owns the goal-completion celebration sheet and
/// the scrolling cards. Pure body content — the surrounding shell
/// provides the [AppBar], [FloatingActionButton], and [NavigationBar].
class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key, this.bottomInset = 0});

  /// Extra padding to leave under the last item, e.g. space for the
  /// shell's FAB or NavigationBar.
  final double bottomInset;

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  bool _celebrationHandled = false;
  late DateTime _selectedDay = calendarDay(DateTime.now());

  void _shiftDay(int days) {
    setState(() {
      _selectedDay = _selectedDay.add(Duration(days: days));
    });
  }

  Future<void> _pickDay() async {
    final today = calendarDay(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDay,
      firstDate: today.subtract(const Duration(days: 365 * 5)),
      lastDate: today,
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedDay = calendarDay(picked));
  }

  void _resetToToday() {
    setState(() => _selectedDay = calendarDay(DateTime.now()));
  }

  @override
  Widget build(BuildContext context) {
    final sw = Stopwatch()..start();
    final repo = context.read<CalTrackRepository>();
    final profileCtl = context.watch<ProfileController>();

    return StreamBuilder<Goal?>(
      stream: repo.watchCurrentGoal(),
      builder: (context, goalSnap) {
        final goal = goalSnap.data;
        if (goal?.status == 'pending_choice' && !_celebrationHandled) {
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            setState(() => _celebrationHandled = true);
            final profile = await repo.requireProfile();
            if (!context.mounted) return;
            await showGoalChoiceSheet(
              context: context,
              repo: repo,
              profile: profile,
            );
          });
        } else if (goal?.status != 'pending_choice') {
          _celebrationHandled = false;
        }

        if (profileCtl.loading || profileCtl.profile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final out = RefreshIndicator(
          onRefresh: () async {
            await profileCtl.refresh();
          },
          child: _DashboardListView(
            repo: repo,
            profileCtl: profileCtl,
            goal: goal,
            bottomInset: widget.bottomInset,
            selectedDay: _selectedDay,
            onPrevDay: () => _shiftDay(-1),
            onNextDay: () => _shiftDay(1),
            onPickDay: _pickDay,
            onResetToday: _resetToToday,
          ),
        );
        assert(() {
          // Debug-only: helps spot unexpected rebuild churn during scroll.
          sw.stop();
          // ignore: avoid_print
          print('DashboardTab.build ${sw.elapsedMilliseconds}ms');
          return true;
        }());
        return out;
      },
    );
  }
}

/// Modal bottom sheet with disclaimer and quick links. Used by the
/// AppBar's info icon in the shell.
void showDashboardInfoSheet(BuildContext context) {
  final theme = Theme.of(context);
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxWidth: MediaQuery.sizeOf(context).width,
    ),
    builder: (ctx) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('About your plan', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              Text(
                'Calorie targets are estimates based on common formulas '
                '(~7700 kcal per kg of fat change per week). '
                'Not medical advice—consult a professional for health '
                'conditions or aggressive deficits.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              Text('Shortcuts', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('Weekly review'),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/weekly-review');
                },
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: const Text('Calorie bands'),
                subtitle: const Text(
                  'Floor, maintenance, and goal target side-by-side.',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  context.push('/calorie-bands');
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DashboardListView extends StatelessWidget {
  const _DashboardListView({
    required this.repo,
    required this.profileCtl,
    required this.goal,
    required this.bottomInset,
    required this.selectedDay,
    required this.onPrevDay,
    required this.onNextDay,
    required this.onPickDay,
    required this.onResetToday,
  });

  final CalTrackRepository repo;
  final ProfileController profileCtl;
  final Goal? goal;
  final double bottomInset;
  final DateTime selectedDay;
  final VoidCallback onPrevDay;
  final VoidCallback onNextDay;
  final VoidCallback onPickDay;
  final VoidCallback onResetToday;

  @override
  Widget build(BuildContext context) {
    final currentGoal = goal;
    final today = calendarDay(DateTime.now());
    final isToday = selectedDay == today;
    final canGoForward = selectedDay.isBefore(today);
    final profile = profileCtl.profile!;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      children: [
        _DayNavigator(
          selectedDay: selectedDay,
          isToday: isToday,
          canGoForward: canGoForward,
          onPrev: onPrevDay,
          onNext: canGoForward ? onNextDay : null,
          onPick: onPickDay,
          onReset: isToday ? null : onResetToday,
        ),
        const SizedBox(height: 16),
        FutureBuilder<ComputedPlan?>(
          future: repo.computePlanForProfile(profileCtl.profile!, currentGoal),
          builder: (context, planSnap) {
            final plan = planSnap.data;
            if (plan == null) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Log your weight to see calorie and macro targets.',
                  ),
                ),
              );
            }
            return StreamBuilder<DailyIntakeTotals>(
              stream: repo.watchIntakeForDay(selectedDay),
              builder: (context, intakeSnap) {
                final intake = intakeSnap.data ?? DailyIntakeTotals.zero;
                return _TodaySummaryCard(
                  plan: plan,
                  intake: intake,
                  selectedDay: selectedDay,
                  isToday: isToday,
                );
              },
            );
          },
        ),
        const SizedBox(height: 16),
        _FoodAdherenceStreakCard(
          repo: repo,
          dailyTarget: profileCtl.profile!.dailyCalorieTarget,
          referenceDay: selectedDay,
        ),
        const SizedBox(height: 16),
        _TodayFoodLogCard(repo: repo, selectedDay: selectedDay, isToday: isToday),
        const SizedBox(height: 16),
        if (currentGoal != null) _GoalSummary(goal: currentGoal, profile: profile),
        const SizedBox(height: 16),
        FutureBuilder<List<WeightEntry>>(
          future: repo.weightEntriesLimit(1),
          builder: (context, wSnap) {
            final list = wSnap.data;
            final last = list == null || list.isEmpty ? null : list.first;
            if (last == null) {
              return const SizedBox.shrink();
            }
            final overdue =
                DateTime.now().difference(last.recordedAt).inDays;
            if (overdue >= 8) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer
                      .withValues(alpha: 0.35),
                  child: ListTile(
                    title: const Text('Weigh-in overdue'),
                    subtitle: Text(
                      'Last entry ${_fmtYmd.format(last.recordedAt)}. '
                      'Weekly check-ins help adjust your plan.',
                    ),
                    trailing: TextButton(
                      onPressed: () => context.push('/log-weight'),
                      child: const Text('Log'),
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}

/// One unified card showing today's intake against the daily plan:
/// calories (consumed / target) plus per-macro progress bars.
class _TodaySummaryCard extends StatelessWidget {
  const _TodaySummaryCard({
    required this.plan,
    required this.intake,
    required this.selectedDay,
    required this.isToday,
  });

  final ComputedPlan plan;
  final DailyIntakeTotals intake;
  final DateTime selectedDay;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nf = _nfDecimal;

    final consumed = intake.kcal;
    final target = plan.dailyCalories;
    final remaining = (target - consumed).round();
    final overCal = consumed > target;
    final calRatio =
        target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);

    final remainingLabel = overCal
        ? '${nf.format(-remaining)} kcal over'
        : '${nf.format(remaining)} kcal left';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    isToday
                        ? 'Today'
                        : _fmtMonthDay.format(selectedDay),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Text(
                  remainingLabel,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: overCal ? scheme.error : scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                style: theme.textTheme.headlineMedium?.copyWith(
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
            const SizedBox(height: 4),
            Text(
              'TDEE ~${nf.format(plan.tdee.round())} kcal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: target <= 0 ? null : (overCal ? 1.0 : calRatio),
                backgroundColor: scheme.surfaceContainerHighest,
                color: overCal ? scheme.error : scheme.primary,
              ),
            ),
            const Divider(height: 32),
            _MacroIntakeProgressLinear(
              label: 'Protein',
              consumed: intake.proteinG,
              target: plan.macros.protein,
              color: scheme.primary,
            ),
            _CarbsStackedBar(
              consumed: intake.carbsG,
              sugar: intake.sugarG,
              fiber: intake.fiberG,
              target: plan.macros.carbs,
            ),
            _MacroIntakeProgressLinear(
              label: 'Fat',
              consumed: intake.fatG,
              target: plan.macros.fat,
              color: scheme.tertiary,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Material 3 linear progress toward daily macro gram targets.
class _MacroIntakeProgressLinear extends StatelessWidget {
  const _MacroIntakeProgressLinear({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
    this.isLast = false,
  });

  final String label;
  final double consumed;
  final double target;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final safeTarget = target > 0 ? target : 1.0;
    final ratio = (consumed / safeTarget).clamp(0.0, 1.0);
    final over = target > 0 && consumed > target;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: theme.textTheme.titleSmall),
              ),
              Text(
                '${consumed.round()} / ${target.round()} g',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: over ? scheme.error : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              minHeight: 8,
              value: target <= 0 ? null : (over ? 1.0 : ratio),
              backgroundColor: scheme.surfaceContainerHighest,
              color: over ? scheme.error : color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carbs macro row that visually splits the progress bar into fiber, sugar,
/// and remaining complex carbs so the user sees carb quality at a glance.
class _CarbsStackedBar extends StatelessWidget {
  const _CarbsStackedBar({
    required this.consumed,
    required this.sugar,
    required this.fiber,
    required this.target,
  });

  final double consumed;
  final double sugar;
  final double fiber;
  final double target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final safeTarget = target > 0 ? target : 1.0;
    final ratio = (consumed / safeTarget).clamp(0.0, 1.0);
    final over = target > 0 && consumed > target;
    final hasCarbs = consumed > 0;

    // Proportions within the filled portion of the bar.
    final fiberPct =
        hasCarbs ? (fiber / consumed).clamp(0.0, 1.0) : 0.0;
    final sugarPct =
        hasCarbs ? (sugar / consumed).clamp(0.0, 1.0) : 0.0;
    // Guard: fiber + sugar ≤ total carbs.
    final complex = (1.0 - fiberPct - sugarPct).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Carbs', style: theme.textTheme.titleSmall),
              ),
              Text(
                '${consumed.round()} / ${target.round()} g',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: over ? scheme.error : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  final fillWidth = totalWidth * ratio;
                  return Stack(
                    children: [
                      // Background track.
                      Positioned.fill(
                        child: Container(color: scheme.surfaceContainerHighest),
                      ),
                      // Filled portion — sized in actual pixels.
                      if (fillWidth > 0)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          width: fillWidth,
                          child: Row(
                            children: [
                              if (fiberPct > 0)
                                Expanded(
                                  flex: (fiberPct * 1000).round().clamp(1, 1000),
                                  child: Container(
                                    color: _fiberColor(scheme),
                                  ),
                                ),
                              if (sugarPct > 0)
                                Expanded(
                                  flex: (sugarPct * 1000).round().clamp(1, 1000),
                                  child: Container(
                                    color: _sugarColor(scheme),
                                  ),
                                ),
                              if (complex > 0)
                                Expanded(
                                  flex: (complex * 1000).round().clamp(1, 1000),
                                  child: Container(
                                    color: over
                                        ? scheme.error
                                        : _complexColor(scheme),
                                  ),
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
          // Legend row
          if (hasCarbs) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                if (fiber > 0)
                  _LegendDot(
                    color: _fiberColor(scheme),
                    label: 'Fiber ${fiber.round()} g',
                  ),
                if (sugar > 0)
                  _LegendDot(
                    color: _sugarColor(scheme),
                    label: 'Sugar ${sugar.round()} g',
                  ),
                _LegendDot(
                  color: _complexColor(scheme),
                  label:
                      'Complex ${((consumed - fiber - sugar).round()).clamp(0, 9999)} g',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // Fixed, hue-separated palette so fiber/sugar/complex stay distinguishable
  // regardless of the active Material theme. Brightness-aware so each segment
  // keeps enough contrast against `surfaceContainerHighest` in light/dark mode.
  static Color _fiberColor(ColorScheme scheme) =>
      // Green — fiber is generally desirable.
      scheme.brightness == Brightness.dark
          ? const Color(0xFF66BB6A)
          : const Color(0xFF2E7D32);

  static Color _sugarColor(ColorScheme scheme) =>
      // Warm amber — draws attention without being alarmist.
      scheme.brightness == Brightness.dark
          ? const Color(0xFFFFB74D)
          : const Color(0xFFEF6C00);

  static Color _complexColor(ColorScheme scheme) =>
      // Cool blue — neutral starch/complex carbs, distinct from green/amber.
      scheme.brightness == Brightness.dark
          ? const Color(0xFF64B5F6)
          : const Color(0xFF1565C0);
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _GoalSummary extends StatelessWidget {
  const _GoalSummary({required this.goal, required this.profile});

  final Goal goal;
  final Profile profile;

  Future<({double? latestKg, double? trendKgWeek})> _loadDetails(
    CalTrackRepository repo,
  ) async {
    final results = await Future.wait([
      repo.weightEntriesLimit(1),
      repo.trendKgPerWeek(windowDays: 14),
    ]);
    final entries = results[0] as List<WeightEntry>;
    final trend = results[1] as double?;
    return (
      latestKg: entries.isEmpty ? null : entries.first.weightKg,
      trendKgWeek: trend,
    );
  }

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
    final repo = context.read<CalTrackRepository>();
    return FutureBuilder<({double? latestKg, double? trendKgWeek})>(
      future: _loadDetails(repo),
      builder: (context, snap) {
        final data = snap.data;
        if (data == null) return const SizedBox.shrink();
        final unit = WeightUnit.fromStored(profile.weightUnit);
        final target = unit == WeightUnit.kg
            ? '${goal.targetWeightKg.toStringAsFixed(1)} kg'
            : '${kgToLb(goal.targetWeightKg).toStringAsFixed(1)} lb';
        final rate = goal.weeklyChangeKgPerWeek;
        String pace;
        if (goal.status == 'maintain' || rate.abs() < 0.001) {
          pace = 'Maintenance';
        } else if (rate < 0) {
          pace = 'Losing ~${(-rate).toStringAsFixed(2)} kg/week';
        } else {
          pace = 'Gaining ~${rate.toStringAsFixed(2)} kg/week';
        }
        final subtitleText =
            goal.status == 'pending_choice' ? 'Choose next step' : pace;

        return Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 8, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Goal: $target',
                            style: theme.textTheme.titleMedium,
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
                    currentKg: data.latestKg,
                    trendKgWeek: data.trendKgWeek,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Static + trend ETA rows under the dashboard goal card. Hidden when
/// neither prediction is meaningful (no weigh-in, at-goal, etc.).
class _GoalEtaSection extends StatelessWidget {
  const _GoalEtaSection({
    required this.goal,
    required this.currentKg,
    required this.trendKgWeek,
  });

  final Goal goal;
  final double? currentKg;
  final double? trendKgWeek;

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
                  'based on last ~14 days (${trendEta.weeklyKg.toStringAsFixed(2)} kg/wk)',
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

/// Lists every food log entry for the selected calendar day, with
/// swipe-to-delete and an undo SnackBar. Header shows total kcal +
/// entry count and a quick-add button.
class _TodayFoodLogCard extends StatelessWidget {
  const _TodayFoodLogCard({
    required this.repo,
    required this.selectedDay,
    required this.isToday,
  });

  final CalTrackRepository repo;
  final DateTime selectedDay;
  final bool isToday;

  String _formatDayParam(DateTime day) {
    final y = day.year.toString().padLeft(4, '0');
    final m = day.month.toString().padLeft(2, '0');
    final d = day.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nf = _nfDecimal;
    return StreamBuilder<List<FoodLogEntry>>(
      stream: repo.watchFoodLogsForDay(selectedDay),
      builder: (context, snap) {
        final entries = snap.data ?? const <FoodLogEntry>[];
        final totalKcal =
            entries.fold<double>(0, (acc, e) => acc + e.kcal).round();
        final title = isToday
            ? "Today's food"
            : 'Food · ${_fmtDayShort.format(selectedDay)}';
        final emptyMsg = isToday
            ? 'Nothing logged yet today.'
            : 'Nothing logged on this day.';
        final entriesLabel =
            entries.length == 1 ? '1 entry' : '${entries.length} entries';
        return Card(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            entries.isEmpty
                                ? 'No entries yet'
                                : '$entriesLabel · ${nf.format(totalKcal)} kcal',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quick add + full food log buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.bolt_rounded, size: 20),
                          tooltip: 'Quick add',
                          style: IconButton.styleFrom(
                            minimumSize: const Size(40, 40),
                          ),
                          onPressed: () async {
                            // Snap to noon on past days so the entry falls
                            // inside the correct day bounds.
                            final loggedAt = isToday
                                ? null
                                : DateTime(
                                    selectedDay.year,
                                    selectedDay.month,
                                    selectedDay.day,
                                    12,
                                  );
                            await showQuickAddSheet(
                              context,
                              loggedAt: loggedAt,
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonalIcon(
                          onPressed: () {
                            final path = isToday
                                ? '/log-food'
                                : '/log-food?day=${_formatDayParam(selectedDay)}';
                            context.push(path);
                          },
                          icon: const Icon(Icons.search_rounded, size: 18),
                          label: const Text('Search'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    emptyMsg,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.4),
                      indent: 16,
                      endIndent: 16,
                    ),
                  _FoodLogTile(entry: entries[i], repo: repo),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _FoodLogTile extends StatelessWidget {
  const _FoodLogTile({required this.entry, required this.repo});

  final FoodLogEntry entry;
  final CalTrackRepository repo;

  Future<void> _openEdit(BuildContext context) async {
    // Quick-add entries are calorie estimates, not food items — reopen the
    // quick-add sheet instead of the food entry sheet.
    if (entry.source == 'quick') {
      await showQuickAddSheet(context, editingEntry: entry);
      return;
    }

    double kcal100 = entry.grams > 0 ? entry.kcal * 100 / entry.grams : 0;
    double p100 = entry.grams > 0 ? entry.proteinG * 100 / entry.grams : 0;
    double c100 = entry.grams > 0 ? entry.carbsG * 100 / entry.grams : 0;
    double s100 = entry.grams > 0 ? entry.sugarG * 100 / entry.grams : 0;
    double fi100 = entry.grams > 0 ? entry.fiberG * 100 / entry.grams : 0;
    double f100 = entry.grams > 0 ? entry.fatG * 100 / entry.grams : 0;
    var unitLabel = 'g';

    String displayName = entry.displayName;
    String? catalogFoodId = entry.catalogFoodId;
    List<CatalogGroupPreset> presets = const [];
    String? initialPresetLabel;
    double? initialPresetQty;

    final id = entry.catalogFoodId;
    if (id != null) {
      final catalog = context.read<OpenNutritionCatalog>();
      final food = await catalog.byId(id);
      final group = await catalog.groupForFood(id);
      // When the logged row is part of a group, re-render via the
      // canonical food so the same macros + presets list back the sheet.
      final canonical = (group != null && group.canonicalFoodId != id)
          ? await catalog.byId(group.canonicalFoodId) ?? food
          : food;
      if (canonical != null) {
        kcal100 = canonical.kcalPer100g;
        p100 = canonical.proteinPer100g;
        c100 = canonical.carbsPer100g;
        f100 = canonical.fatPer100g;
        s100 = canonical.sugarPer100g;
        fi100 = canonical.fiberPer100g;
      }
      if (group != null) {
        displayName = group.label;
        catalogFoodId = group.canonicalFoodId;
        presets = group.presets;
        final matched = group.presetForFoodId(id);
        if (matched != null && matched.grams > 0) {
          initialPresetLabel = matched.label;
          initialPresetQty = entry.grams / matched.grams;
        }
      }
    }

    final customId = entry.customFoodId;
    if (customId != null) {
      final custom = await repo.customFoodById(customId);
      if (custom != null) {
        final serving = custom.servingSize;
        final factor = serving > 0 ? 100.0 / serving : 1.0;
        kcal100 = custom.calories * factor;
        p100 = custom.proteinG * factor;
        c100 = custom.carbsG * factor;
        s100 = custom.sugarG * factor;
        fi100 = custom.fiberG * factor;
        f100 = custom.fatG * factor;
        unitLabel = custom.servingUnit;
      }
    }

    if (!context.mounted) return;
    await showFoodEntrySheet(
      context,
      FoodEntrySheetConfig(
        displayName: displayName,
        source: entry.source,
        catalogFoodId: catalogFoodId,
        customFoodId: entry.customFoodId,
        kcalPer100g: kcal100,
        proteinPer100g: p100,
        carbsPer100g: c100,
        sugarPer100g: s100,
        fiberPer100g: fi100,
        fatPer100g: f100,
        initialGrams: entry.grams,
        editingEntryId: entry.id,
        loggedAtForEdit: entry.loggedAt,
        unitLabel: unitLabel,
        presets: presets,
        initialPresetLabel: initialPresetLabel,
        initialPresetQty: initialPresetQty,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = _fmtTime.format(entry.loggedAt);
    return Dismissible(
      key: ValueKey('food-${entry.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: theme.colorScheme.errorContainer,
        child: Icon(
          Icons.delete_outline,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) async {
        await repo.deleteFoodLog(entry.id);
        if (!context.mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          SnackBar(
            content: Text('Removed ${entry.displayName}'),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                repo.addFoodLogReturnId(
                  source: entry.source,
                  catalogFoodId: entry.catalogFoodId,
                  customFoodId: entry.customFoodId,
                  displayName: entry.displayName,
                  grams: entry.grams,
                  kcal: entry.kcal,
                  proteinG: entry.proteinG,
                  carbsG: entry.carbsG,
                  sugarG: entry.sugarG,
                  fiberG: entry.fiberG,
                  fatG: entry.fatG,
                  loggedAt: entry.loggedAt,
                );
              },
            ),
          ),
        );
      },
      child: ListTile(
        leading: _FoodEmojiAvatar(name: entry.displayName),
        title: Text(
          entry.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.source == 'quick'
                    ? 'Estimated · $time'
                    : '${entry.grams.round()} g · $time',
              ),
              if (entry.source != 'quick' ||
                  entry.proteinG > 0 ||
                  entry.carbsG > 0 ||
                  entry.fatG > 0) ...[
                const SizedBox(height: 2),
                Text(
                  'P ${entry.proteinG.round()}g · '
                  'C ${entry.carbsG.round()}g · '
                  'F ${entry.fatG.round()}g',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: Text(
          '${entry.kcal.round()} kcal',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        onTap: () => _openEdit(context),
      ),
    );
  }
}

/// Round chip showing the food's emoji (or a fallback icon when no
/// rule matches the name).
class _FoodEmojiAvatar extends StatelessWidget {
  const _FoodEmojiAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emoji = emojiForFood(name);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji, style: const TextStyle(fontSize: 20))
          : Icon(
              Icons.restaurant_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
    );
  }
}

/// Compact day picker on top of the dashboard. Lets the user navigate to
/// previous days to add or modify logs without leaving the home screen.
class _DayNavigator extends StatelessWidget {
  const _DayNavigator({
    required this.selectedDay,
    required this.isToday,
    required this.canGoForward,
    required this.onPrev,
    required this.onNext,
    required this.onPick,
    required this.onReset,
  });

  final DateTime selectedDay;
  final bool isToday;
  final bool canGoForward;
  final VoidCallback onPrev;
  final VoidCallback? onNext;
  final VoidCallback onPick;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final today = calendarDay(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));

    String label;
    if (isToday) {
      label = 'Today';
    } else if (selectedDay == yesterday) {
      label = 'Yesterday';
    } else {
      label = _fmtDayLong.format(selectedDay);
    }

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Previous day',
              onPressed: onPrev,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: TextButton.icon(
                onPressed: onPick,
                icon: const Icon(Icons.calendar_today_outlined, size: 18),
                label: Text(
                  label,
                  style: theme.textTheme.titleSmall,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Next day',
              onPressed: canGoForward ? onNext : null,
              icon: const Icon(Icons.chevron_right),
            ),
            if (onReset != null)
              TextButton(
                onPressed: onReset,
                child: const Text('Today'),
              ),
          ],
        ),
      ),
    );
  }
}

/// Shows a compact food-logging adherence streak ("X days >= 80% of target")
/// based on the cached daily calorie target. Hidden if the user has no
/// daily target yet (e.g. before onboarding completes a plan).
class _FoodAdherenceStreakCard extends StatelessWidget {
  const _FoodAdherenceStreakCard({
    required this.repo,
    required this.dailyTarget,
    required this.referenceDay,
  });

  final CalTrackRepository repo;
  final double? dailyTarget;
  final DateTime referenceDay;

  static const _lookbackDays = 60;
  static const _adherenceFraction = 0.8;

  @override
  Widget build(BuildContext context) {
    final target = dailyTarget;
    if (target == null || target <= 0) {
      return const SizedBox.shrink();
    }
    final ref = calendarDay(referenceDay);
    final start = ref.subtract(const Duration(days: _lookbackDays - 1));
    final endExclusive = ref.add(const Duration(days: 1));

    return StreamBuilder<Map<DateTime, double>>(
      stream: repo.watchDailyKcalTotals(
        start: start,
        endExclusive: endExclusive,
      ),
      builder: (context, snap) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final totals = snap.data ?? const <DateTime, double>{};
        final qualifying = <DateTime>{
          for (final entry in totals.entries)
            if (entry.value >= target * _adherenceFraction) entry.key,
        };
        final streak = computeDayStreak(
          qualifyingDays: qualifying,
          referenceDay: ref,
        );

        final headline = streak.current > 0
            ? 'Logging streak: ${streak.current} '
                '${streak.current == 1 ? "day" : "days"}'
            : 'No active logging streak';
        final sub =
            'Days where you logged at least ${(_adherenceFraction * 100).round()}% '
            'of your calorie target.${streak.best > 0 ? " Best: ${streak.best}." : ""}';

        return Card(
          child: ListTile(
            leading: Icon(
              Icons.local_fire_department_outlined,
              color: streak.current > 0
                  ? scheme.primary
                  : scheme.onSurfaceVariant,
            ),
            title: Text(headline),
            subtitle: Text(
              sub,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }
}

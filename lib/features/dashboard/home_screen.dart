import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/app/nutrition_display_controller.dart';
import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/food_emoji.dart';
import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/core/spacing.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/features/food/food_entry_sheet.dart';
import 'package:caltrack/features/food/quick_add_sheet.dart';
import 'package:caltrack/widgets/animated_list_item.dart';
import 'package:caltrack/widgets/goal_choice_sheet.dart';
import 'package:caltrack/widgets/nutrient_display.dart';
import 'package:caltrack/widgets/styled_card.dart';
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
      lastDate: today.add(const Duration(days: 365)),
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
    const canGoForward = true;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.md + bottomInset,
      ),
      children: [
        _DayNavigator(
          selectedDay: selectedDay,
          isToday: isToday,
          canGoForward: canGoForward,
          onPrev: onPrevDay,
          onNext: onNextDay,
          onPick: onPickDay,
          onReset: isToday ? null : onResetToday,
        ),
        const SizedBox(height: Spacing.md),
        AnimatedListItem(
          index: 0,
          child: FutureBuilder<ComputedPlan?>(
            future:
                repo.computePlanForProfile(profileCtl.profile!, currentGoal),
            builder: (context, planSnap) {
              final plan = planSnap.data;
              if (plan == null) {
                return const StyledCard(
                  tone: CardTone.low,
                  padding: EdgeInsets.all(Spacing.md),
                  child: Text(
                    'Log your weight to see calorie and macro targets.',
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
        ),
        const SizedBox(height: Spacing.md),
        AnimatedListItem(
          index: 1,
          child: _FoodAdherenceStreakCard(
            repo: repo,
            dailyTarget: profileCtl.profile!.dailyCalorieTarget,
            referenceDay: selectedDay,
          ),
        ),
        const SizedBox(height: Spacing.md),
        AnimatedListItem(
          index: 2,
          child: _TodayFoodLogCard(
            repo: repo,
            selectedDay: selectedDay,
            isToday: isToday,
          ),
        ),
        const SizedBox(height: Spacing.md),
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
                padding: const EdgeInsets.only(bottom: Spacing.md),
                child: StyledCard(
                  tone: CardTone.high,
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Icon(
                      Icons.event_busy_outlined,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    title: const Text('Weigh-in overdue'),
                    subtitle: Text(
                      'Last entry ${_fmtMonthDay.format(last.recordedAt)}. '
                      'Weekly check-ins help adjust your plan.',
                    ),
                    trailing: FilledButton.tonal(
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
    final displayCtl = context.watch<NutritionDisplayController>();

    final consumed = intake.kcal;
    final target = plan.dailyCalories;
    final remaining = (target - consumed).round();
    final overCal = consumed > target;
    final calRatio =
        target <= 0 ? 0.0 : (consumed / target).clamp(0.0, 1.0);

    final remainingLabel = overCal
        ? '${nf.format(-remaining)} over'
        : '${nf.format(remaining)} left';

    return StyledCard(
      tone: CardTone.low,
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isToday ? 'Today' : _fmtMonthDay.format(selectedDay),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              _ModeChip(mode: displayCtl.mode),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              _CalorieRing(
                ratio: calRatio,
                over: overCal,
                consumed: consumed.round(),
                target: target.round(),
              ),
              const SizedBox(width: Spacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      remainingLabel,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: overCal ? scheme.error : scheme.onSurface,
                      ),
                    ),
                    Text(
                      'kcal ${overCal ? 'over budget' : 'remaining'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: Spacing.sm),
                    _MiniMetric(
                      icon: Icons.restaurant_outlined,
                      label: 'Eaten',
                      value: '${nf.format(consumed.round())} kcal',
                    ),
                    const SizedBox(height: Spacing.xs),
                    _MiniMetric(
                      icon: Icons.flag_outlined,
                      label: 'Target',
                      value: '${nf.format(target.round())} kcal',
                    ),
                    const SizedBox(height: Spacing.xs),
                    _MiniMetric(
                      icon: Icons.local_fire_department_outlined,
                      label: 'TDEE',
                      value: '~${nf.format(plan.tdee.round())} kcal',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: Spacing.xl),
          if (displayCtl.mode == NutritionDisplayMode.simple) ...[
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
          ] else
            DetailedNutrientBreakdown(
              intake: intake,
              mode: displayCtl.mode,
              customSelection: displayCtl.customSelection,
            ),
        ],
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.mode});

  final NutritionDisplayMode mode;

  String get _label {
    switch (mode) {
      case NutritionDisplayMode.simple:
        return 'Simple';
      case NutritionDisplayMode.detailed:
        return 'All nutrients';
      case NutritionDisplayMode.custom:
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Circular calorie progress ring with consumed/target labels in the center.
class _CalorieRing extends StatelessWidget {
  const _CalorieRing({
    required this.ratio,
    required this.over,
    required this.consumed,
    required this.target,
  });

  final double ratio;
  final bool over;
  final int consumed;
  final int target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final pct = target <= 0 ? 0 : ((consumed / target) * 100).round();

    return SizedBox(
      width: 104,
      height: 104,
      child: CustomPaint(
        painter: _RingPainter(
          ratio: over ? 1.0 : ratio,
          trackColor: scheme.surfaceContainerHighest,
          progressColor: over ? scheme.error : scheme.primary,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$pct%',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: over ? scheme.error : scheme.onSurface,
                ),
              ),
              Text(
                'of goal',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.ratio,
    required this.trackColor,
    required this.progressColor,
  });

  final double ratio;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide - stroke) / 2;

    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = trackColor;
    canvas.drawCircle(center, radius, trackPaint);

    if (ratio > 0) {
      final progressPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round
        ..color = progressColor;
      const start = -1.5707963267948966; // -90° (top)
      final sweep = 6.283185307179586 * ratio.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.ratio != ratio ||
      old.trackColor != trackColor ||
      old.progressColor != progressColor;
}

/// One icon + label + value row used beside the calorie ring.
class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      children: [
        Icon(icon, size: 15, color: scheme.onSurfaceVariant),
        const SizedBox(width: Spacing.xs),
        Text(
          '$label ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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

  static const _periodOrder = [
    MealPeriod.breakfast,
    MealPeriod.lunch,
    MealPeriod.dinner,
    MealPeriod.snack,
  ];

  static String _periodLabel(MealPeriod p) {
    return p.name[0].toUpperCase() + p.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nf = _nfDecimal;
    return StreamBuilder<Map<MealPeriod?, List<FoodLogEntry>>>(
      stream: repo.watchFoodLogsForDayByPeriod(selectedDay),
      builder: (context, snap) {
        final grouped = snap.data ?? const <MealPeriod?, List<FoodLogEntry>>{};
        final allEntries = grouped.values.expand((l) => l).toList();
        final totalKcal =
            allEntries.fold<double>(0, (acc, e) => acc + e.kcal).round();
        final title = isToday
            ? "Today's food"
            : 'Food · ${_fmtDayShort.format(selectedDay)}';
        final emptyMsg = isToday
            ? 'Nothing logged yet today.'
            : 'Nothing logged on this day.';
        final entriesLabel = allEntries.length == 1
            ? '1 entry'
            : '${allEntries.length} entries';

        // Build period sections in consistent order.
        final periodSections = <Widget>[];
        for (final period in _periodOrder) {
          final entries = grouped[period] ?? [];
          if (entries.isEmpty) continue;
          periodSections.add(_PeriodSection(
            period: period,
            entries: entries,
            repo: repo,
            theme: theme,
            scheme: scheme,
            nf: nf,
          ));
        }
        // Uncategorized entries (null period) at the end.
        final uncategorized = grouped[null] ?? [];
        if (uncategorized.isNotEmpty) {
          periodSections.add(_PeriodSection(
            period: null,
            entries: uncategorized,
            repo: repo,
            theme: theme,
            scheme: scheme,
            nf: nf,
          ));
        }

        return StyledCard(
          tone: CardTone.low,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  Spacing.lg,
                  Spacing.md,
                  Spacing.sm,
                  Spacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            allEntries.isEmpty
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
              if (allEntries.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    Spacing.lg,
                    0,
                    Spacing.lg,
                    Spacing.lg,
                  ),
                  child: Text(
                    emptyMsg,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                ...periodSections,
            ],
          ),
        );
      },
    );
  }
}

/// A single meal period section within the food log card.
class _PeriodSection extends StatelessWidget {
  const _PeriodSection({
    required this.period,
    required this.entries,
    required this.repo,
    required this.theme,
    required this.scheme,
    required this.nf,
  });

  final MealPeriod? period;
  final List<FoodLogEntry> entries;
  final CalTrackRepository repo;
  final ThemeData theme;
  final ColorScheme scheme;
  final NumberFormat nf;

  @override
  Widget build(BuildContext context) {
    final sectionKcal =
        entries.fold<double>(0, (acc, e) => acc + e.kcal).round();
    final label = period != null ? _TodayFoodLogCard._periodLabel(period!) : 'Other';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.4),
          indent: 16,
          endIndent: 16,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
          child: Text(
            '$label · ${nf.format(sectionKcal)} kcal',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            ),
          ),
        ),
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0)
            Divider(
              height: 1,
              color: scheme.outlineVariant.withValues(alpha: 0.3),
              indent: 16,
              endIndent: 16,
            ),
          _FoodLogTile(entry: entries[i], repo: repo),
        ],
      ],
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
        initialMealPeriod: MealPeriod.fromDb(entry.mealPeriod),
        initialIsPlanned: entry.isPlanned,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = _fmtTime.format(entry.loggedAt);
    final isPlanned = entry.isPlanned;
    final tile = ListTile(
      leading: _FoodEmojiAvatar(name: entry.displayName),
      title: Text(
        entry.displayName,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          fontStyle: isPlanned ? FontStyle.italic : null,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  entry.source == 'quick'
                      ? 'Estimated · $time'
                      : '${entry.grams.round()} g · $time',
                ),
                if (isPlanned) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiaryContainer,
                      borderRadius: Corners.radiusSm,
                    ),
                    child: Text(
                      'Planned',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
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
    );

    if (isPlanned) {
      return Opacity(
        opacity: 0.75,
        child: Dismissible(
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
            context.showAppSnackBar(
              'Removed ${entry.displayName}',
              actionLabel: 'Undo',
              onAction: () {
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
                  mealPeriod: MealPeriod.fromDb(entry.mealPeriod),
                  isPlanned: entry.isPlanned,
                );
              },
              replaceCurrent: true,
            );
          },
          child: tile,
        ),
      );
    }

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
        context.showAppSnackBar(
          'Removed ${entry.displayName}',
          actionLabel: 'Undo',
          onAction: () {
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
              mealPeriod: MealPeriod.fromDb(entry.mealPeriod),
              isPlanned: entry.isPlanned,
            );
          },
          replaceCurrent: true,
        );
      },
      child: tile,
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

    return StyledCard(
      tone: CardTone.high,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs, vertical: Spacing.xs),
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
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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

        return StyledCard(
          tone: CardTone.low,
          padding: EdgeInsets.zero,
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

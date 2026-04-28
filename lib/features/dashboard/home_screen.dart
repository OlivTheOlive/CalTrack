import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/features/food/food_entry_sheet.dart';
import 'package:caltrack/widgets/goal_choice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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

  @override
  Widget build(BuildContext context) {
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

        return RefreshIndicator(
          onRefresh: () async {
            await profileCtl.refresh();
          },
          child: _DashboardListView(
            repo: repo,
            profileCtl: profileCtl,
            goal: goal,
            bottomInset: widget.bottomInset,
          ),
        );
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
  });

  final CalTrackRepository repo;
  final ProfileController profileCtl;
  final Goal? goal;
  final double bottomInset;

  @override
  Widget build(BuildContext context) {
    final currentGoal = goal;
    return ListView(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      children: [
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
              stream: repo.watchIntakeForDay(DateTime.now()),
              builder: (context, intakeSnap) {
                final intake = intakeSnap.data ?? DailyIntakeTotals.zero;
                return _TodaySummaryCard(plan: plan, intake: intake);
              },
            );
          },
        ),
        const SizedBox(height: 16),
        _TodayFoodLogCard(repo: repo),
        const SizedBox(height: 16),
        if (currentGoal != null) _GoalSummary(goal: currentGoal),
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
                      'Last entry ${DateFormat.yMMMd().format(last.recordedAt)}. '
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
  const _TodaySummaryCard({required this.plan, required this.intake});

  final ComputedPlan plan;
  final DailyIntakeTotals intake;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nf = NumberFormat.decimalPattern();

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
                  child: Text('Today', style: theme.textTheme.titleMedium),
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
            _MacroIntakeProgressLinear(
              label: 'Carbs',
              consumed: intake.carbsG,
              target: plan.macros.carbs,
              color: scheme.secondary,
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

class _GoalSummary extends StatelessWidget {
  const _GoalSummary({required this.goal});

  final Goal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repo = context.read<CalTrackRepository>();
    return FutureBuilder<Profile>(
      future: repo.requireProfile(),
      builder: (context, snap) {
        final profile = snap.data;
        if (profile == null) return const SizedBox.shrink();
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
        return Card(
          child: ListTile(
            title: Text('Goal: $target'),
            subtitle: Text(
              goal.status == 'pending_choice' ? 'Choose next step' : pace,
              style: theme.textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }
}

/// Lists every food log entry for the current calendar day, with
/// swipe-to-delete and an undo SnackBar.
class _TodayFoodLogCard extends StatelessWidget {
  const _TodayFoodLogCard({required this.repo});

  final CalTrackRepository repo;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder<List<FoodLogEntry>>(
      stream: repo.watchFoodLogsForDay(DateTime.now()),
      builder: (context, snap) {
        final entries = snap.data ?? const <FoodLogEntry>[];
        return Card(
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Today's food",
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    Text(
                      entries.isEmpty ? '' : '${entries.length} entries',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => context.push('/log-food'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
              ),
              if (entries.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    'Nothing logged yet today.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              else
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
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
    double kcal100 = entry.grams > 0 ? entry.kcal * 100 / entry.grams : 0;
    double p100 = entry.grams > 0 ? entry.proteinG * 100 / entry.grams : 0;
    double c100 = entry.grams > 0 ? entry.carbsG * 100 / entry.grams : 0;
    double f100 = entry.grams > 0 ? entry.fatG * 100 / entry.grams : 0;

    final id = entry.catalogFoodId;
    if (id != null) {
      final catalog = context.read<OpenNutritionCatalog>();
      final food = await catalog.byId(id);
      if (food != null) {
        kcal100 = food.kcalPer100g;
        p100 = food.proteinPer100g;
        c100 = food.carbsPer100g;
        f100 = food.fatPer100g;
      }
    }

    if (!context.mounted) return;
    await showFoodEntrySheet(
      context,
      FoodEntrySheetConfig(
        displayName: entry.displayName,
        source: entry.source,
        catalogFoodId: entry.catalogFoodId,
        kcalPer100g: kcal100,
        proteinPer100g: p100,
        carbsPer100g: c100,
        fatPer100g: f100,
        initialGrams: entry.grams,
        editingEntryId: entry.id,
        loggedAtForEdit: entry.loggedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat.jm().format(entry.loggedAt);
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
                  displayName: entry.displayName,
                  grams: entry.grams,
                  kcal: entry.kcal,
                  proteinG: entry.proteinG,
                  carbsG: entry.carbsG,
                  fatG: entry.fatG,
                  loggedAt: entry.loggedAt,
                );
              },
            ),
          ),
        );
      },
      child: ListTile(
        title: Text(
          entry.displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text('${entry.grams.round()} g · $time'),
        trailing: Text(
          '${entry.kcal.round()} kcal',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        onTap: () => _openEdit(context),
      ),
    );
  }
}

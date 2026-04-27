import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/widgets/goal_choice_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

        return Scaffold(
          appBar: AppBar(
            title: const Text('CalTrack'),
            actions: [
              IconButton(
                tooltip: 'Settings',
                onPressed: () => context.push('/settings'),
                icon: const Icon(Icons.settings_outlined),
              ),
            ],
          ),
          body: profileCtl.loading || profileCtl.profile == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    await profileCtl.refresh();
                  },
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _DisclaimerCard(),
                      const SizedBox(height: 16),
                      FutureBuilder<ComputedPlan?>(
                        future: repo.computePlanForProfile(
                          profileCtl.profile!,
                          goal,
                        ),
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
                          return _PlanCard(
                            plan: plan,
                            profile: profileCtl.profile!,
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      if (goal != null) _GoalSummary(goal: goal),
                      const SizedBox(height: 16),
                      FutureBuilder<List<WeightEntry>>(
                        future: repo.weightEntriesLimit(1),
                        builder: (context, wSnap) {
                          final list = wSnap.data;
                          final last = list == null || list.isEmpty
                              ? null
                              : list.first;
                          if (last == null) {
                            return const SizedBox.shrink();
                          }
                          final overdue = DateTime.now()
                              .difference(last.recordedAt)
                              .inDays;
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
                                    onPressed: () =>
                                        context.push('/log-weight'),
                                    child: const Text('Log'),
                                  ),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      FilledButton.icon(
                        onPressed: () => context.push('/log-weight'),
                        icon: const Icon(Icons.monitor_weight_outlined),
                        label: const Text('Log weight'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/weekly-review'),
                        icon: const Icon(Icons.insights_outlined),
                        label: const Text('Weekly review'),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => context.push('/history'),
                        icon: const Icon(Icons.show_chart),
                        label: const Text('Weight history'),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}

class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Calorie targets are estimates based on common formulas (~7700 kcal per kg '
          'of fat change per week). Not medical advice—consult a professional for '
          'health conditions or aggressive deficits.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.profile,
  });

  final ComputedPlan plan;
  final Profile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cal = NumberFormat.decimalPattern().format(plan.dailyCalories.round());
    final m = plan.macros;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily target',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$cal kcal',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'TDEE ~${plan.tdee.round()} kcal',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Divider(height: 24),
            Text('Macros', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            _MacroRow(
              label: 'Protein',
              grams: m.protein,
              pct: profile.proteinPct,
              color: theme.colorScheme.primary,
            ),
            _MacroRow(
              label: 'Carbs',
              grams: m.carbs,
              pct: profile.carbsPct,
              color: theme.colorScheme.secondary,
            ),
            _MacroRow(
              label: 'Fat',
              grams: m.fat,
              pct: profile.fatPct,
              color: theme.colorScheme.tertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.grams,
    required this.pct,
    required this.color,
  });

  final String label;
  final double grams;
  final int pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            '${grams.round()} g',
            style: theme.textTheme.titleSmall,
          ),
          const SizedBox(width: 12),
          Text(
            '$pct%',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
          pace =
              'Losing ~${(-rate).toStringAsFixed(2)} kg/week';
        } else {
          pace =
              'Gaining ~${rate.toStringAsFixed(2)} kg/week';
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

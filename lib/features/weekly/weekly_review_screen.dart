import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Future<(Profile, Goal?, double?)> _loadReviewData(
  CalTrackRepository repo,
) async {
  final profile = await repo.requireProfile();
  final goal = await repo.currentGoal();
  final delta = await repo.weeklyDeltaKg();
  return (profile, goal, delta);
}

class WeeklyReviewScreen extends StatelessWidget {
  const WeeklyReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();
    final profileCtl = context.read<ProfileController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly review'),
        actions: [
          IconButton(
            tooltip: 'How adjustment works',
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showMethodologySheet(context),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadReviewData(repo),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (profile, goal, delta) = snap.data!;

          final intended = goal?.weeklyChangeKgPerWeek;
          final targetCal = profile.dailyCalorieTarget?.round();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Progress check',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (delta == null)
                  Text(
                    'Log weight at least twice spanning about a week to estimate weekly change.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  )
                else ...[
                  Text(
                    'Estimated change vs ~7 days ago: '
                    '${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(2)} kg',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (intended != null &&
                      goal?.status == 'active' &&
                      intended.abs() > 0.001)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Your plan aimed for ~${intended.toStringAsFixed(2)} kg/week.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                ],
                const SizedBox(height: 24),
                if (targetCal != null)
                  Text(
                    'Current calorie target: $targetCal kcal/day',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                const SizedBox(height: 24),
                _MethodologyCard(
                  intendedWeeklyKg: intended,
                  isMaintain: goal?.status != 'active',
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: delta == null
                      ? null
                      : () async {
                          await repo.applyWeeklyAdjustment();
                          await profileCtl.refresh();
                          await NotificationService.instance.scheduleWeeklyWeighIn(
                            repo: repo,
                          );
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Adjusted calories by ±'
                                '${defaultProgressStepKcal.round()} kcal '
                                'because actual change was outside the '
                                '±${defaultProgressBandKgPerWeek.toStringAsFixed(2)} '
                                'kg/week band.',
                              ),
                            ),
                          );
                          context.pop();
                        },
                  icon: const Icon(Icons.tune),
                  label: const Text('Adjust targets automatically'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    await repo.keepCurrentPlan();
                    await profileCtl.refresh();
                    await NotificationService.instance.scheduleWeeklyWeighIn(
                      repo: repo,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Keeping current target.')),
                    );
                    context.pop();
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Keep current plan'),
                ),
                const SizedBox(height: 24),
                Text(
                  'Weekly reviews work best after you log weight on a steady schedule.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Inline summary of the auto-adjust rules so users understand what
/// "Adjust targets automatically" will (and will not) do before tapping it.
class _MethodologyCard extends StatelessWidget {
  const _MethodologyCard({
    required this.intendedWeeklyKg,
    required this.isMaintain,
  });

  final double? intendedWeeklyKg;
  final bool isMaintain;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final intent = intendedWeeklyKg;
    final intentLine = isMaintain || intent == null || intent.abs() < 0.001
        ? 'Plan: maintenance.'
        : 'Plan: ${intent.toStringAsFixed(2)} kg/week.';

    return Card(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'How adjustment works',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              intentLine,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Within ±${defaultProgressBandKgPerWeek.toStringAsFixed(2)} '
              'kg/week of plan, we leave your target alone. Outside that '
              'band we nudge by ±${defaultProgressStepKcal.round()} kcal '
              '(clamped to ${defaultMinDailyCalories.round()}–'
              '${defaultMaxDailyCalories.round()} kcal/day).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => _showMethodologySheet(context),
              icon: const Icon(Icons.help_outline, size: 16),
              label: const Text('More detail'),
            ),
          ],
        ),
      ),
    );
  }
}

void _showMethodologySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final scheme = theme.colorScheme;
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('How weekly adjustments work', style: theme.textTheme.titleLarge),
              const SizedBox(height: 12),
              _MethodologyBullet(
                title: 'Compare intent vs. reality',
                body: 'Each week we estimate your weight change versus '
                    '~7 days ago and compare it to the pace your plan '
                    'aims for.',
              ),
              _MethodologyBullet(
                title: 'Tolerance band: '
                    '±${defaultProgressBandKgPerWeek.toStringAsFixed(2)} kg/week',
                body: 'Inside this band, normal day-to-day fluctuation '
                    'dominates. We assume the plan is fine and leave '
                    'your target alone.',
              ),
              _MethodologyBullet(
                title: 'Step: ±${defaultProgressStepKcal.round()} kcal',
                body: 'Outside the band we nudge calories one step at a '
                    'time — small, predictable changes are easier to '
                    'follow than big swings.',
              ),
              _MethodologyBullet(
                title: 'Floor & ceiling: '
                    '${defaultMinDailyCalories.round()}–'
                    '${defaultMaxDailyCalories.round()} kcal/day',
                body: 'Auto-adjust will not push your target below the '
                    'sustainable floor or above a sensible ceiling. See '
                    'the calorie bands screen for what these mean.',
              ),
              const SizedBox(height: 8),
              Text(
                'These are estimates — body weight bounces day-to-day. '
                'Trust the trend over a single weigh-in.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _MethodologyBullet extends StatelessWidget {
  const _MethodologyBullet({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 2),
          Text(
            body,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

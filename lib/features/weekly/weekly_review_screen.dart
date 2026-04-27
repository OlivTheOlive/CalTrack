import 'package:caltrack/app/profile_controller.dart';
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
      appBar: AppBar(title: const Text('Weekly review')),
      body: FutureBuilder(
        future: _loadReviewData(repo),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final (profile, goal, delta) = snap.data!;

          final intended = goal?.weeklyChangeKgPerWeek;
          final targetCal = profile.dailyCalorieTarget?.round();

          return Padding(
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
                const Spacer(),
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
                            const SnackBar(
                              content: Text(
                                'Adjusted calories using simple band rules '
                                '(±100 kcal step if off pace).',
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

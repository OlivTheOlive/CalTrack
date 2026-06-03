import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Standalone "calorie bands" screen showing the user's current floor,
/// maintenance and goal target, plus a "what if" panel that lets them
/// nudge activity and weekly pace to see how the numbers move — without
/// editing the saved plan or asking for any new personal data.
class CalorieBandsScreen extends StatefulWidget {
  const CalorieBandsScreen({super.key});

  @override
  State<CalorieBandsScreen> createState() => _CalorieBandsScreenState();
}

class _CalorieBandsScreenState extends State<CalorieBandsScreen> {
  Future<_BandsContext>? _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BandsContext> _load() async {
    final repo = context.read<CalTrackRepository>();
    final profile = await repo.requireProfile();
    final goal = await repo.currentGoal();
    final entries = await repo.weightEntriesLimit(1);
    final weightKg = entries.isEmpty ? null : entries.first.weightKg;
    return _BandsContext(profile: profile, goal: goal, weightKg: weightKg);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calorie bands')),
      body: FutureBuilder<_BandsContext>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _BandsBody(ctx: snap.data!);
        },
      ),
    );
  }
}

class _BandsContext {
  const _BandsContext({
    required this.profile,
    required this.goal,
    required this.weightKg,
  });

  final Profile profile;
  final Goal? goal;
  final double? weightKg;
}

class _BandsBody extends StatefulWidget {
  const _BandsBody({required this.ctx});

  final _BandsContext ctx;

  @override
  State<_BandsBody> createState() => _BandsBodyState();
}

class _BandsBodyState extends State<_BandsBody> {
  late int _activityIndex;
  late double _weeklyKg;

  bool get _hasOverride =>
      _activityIndex != widget.ctx.profile.activityLevel ||
      (_planWeeklyKg - _weeklyKg).abs() > 0.001;

  double get _planWeeklyKg {
    final goal = widget.ctx.goal;
    if (goal == null) return 0;
    return goal.status == 'maintain' ? 0 : goal.weeklyChangeKgPerWeek;
  }

  @override
  void initState() {
    super.initState();
    _activityIndex = widget.ctx.profile.activityLevel;
    _weeklyKg = _planWeeklyKg;
  }

  void _resetToPlan() {
    setState(() {
      _activityIndex = widget.ctx.profile.activityLevel;
      _weeklyKg = _planWeeklyKg;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ctx = widget.ctx;
    final weight = ctx.weightKg;
    final unit = WeightUnit.fromStored(ctx.profile.weightUnit);
    final displayWeeklyKg = unit == WeightUnit.kg ? _weeklyKg : kgToLb(_weeklyKg);
    final displayWeeklyKgAbs = displayWeeklyKg.abs();
    final unitLabel = unit.shortLabel;
    if (weight == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Log a weight first so we can show your calorie bands.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final activity = ActivityLevel.fromIndex(_activityIndex);
    final ageYears = ageYearsForProfile(ctx.profile);
    final tdeeVal = tdee(
      isMale: ctx.profile.sex == 'male',
      weightKg: weight,
      heightCm: ctx.profile.heightCm,
      ageYears: ageYears,
      activity: activity,
    );
    final bands = computeCalorieBands(
      tdee: tdeeVal,
      weeklyChangeKgPerWeek: _weeklyKg,
    );
    final pace = paceLevelForKgPerWeek(_weeklyKg);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'How your numbers are derived',
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'Built from your latest weight, height, age band and activity '
          'level. Estimates only — not medical advice.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        _BandTile(
          icon: Icons.shield_outlined,
          color: scheme.error,
          title: 'Floor',
          value: bands.floor,
          caption: 'Lowest daily target we suggest sustaining. Going '
              'below this is harder to maintain and easier to under-fuel.',
        ),
        const SizedBox(height: 12),
        _BandTile(
          icon: Icons.balance,
          color: scheme.tertiary,
          title: 'Maintenance',
          value: bands.maintenance,
          caption: 'About what you would eat to keep weight roughly '
              'stable at your current activity level (TDEE).',
        ),
        const SizedBox(height: 12),
        _BandTile(
          icon: Icons.flag_outlined,
          color: scheme.primary,
          title: 'Goal target',
          value: bands.goalDaily,
          caption: _weeklyKg.abs() < 0.001
              ? 'Same as maintenance — you are aiming to stay put.'
              : '${_weeklyKg < 0 ? "Loss" : "Gain"} pace of '
                  '${displayWeeklyKgAbs.toStringAsFixed(2)} $unitLabel/week using '
                  '~7700 kcal per kg.',
        ),
        const SizedBox(height: 24),
        Card(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'What if…',
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                    if (_hasOverride)
                      TextButton.icon(
                        onPressed: _resetToPlan,
                        icon: const Icon(Icons.restart_alt, size: 18),
                        label: const Text('Reset to my plan'),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Slide to see how maintenance and goal target shift. '
                  'These are previews only — your saved plan does not '
                  'change.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Activity: ${_activityLabel(activity)}',
                  style: theme.textTheme.titleSmall,
                ),
                Slider(
                  value: _activityIndex.toDouble(),
                  min: 0,
                  max: (ActivityLevel.values.length - 1).toDouble(),
                  divisions: ActivityLevel.values.length - 1,
                  label: _activityLabel(activity),
                  onChanged: (v) =>
                      setState(() => _activityIndex = v.round()),
                ),
                const SizedBox(height: 8),
                Text(
                  'Weekly pace: '
                  '${displayWeeklyKg >= 0 ? "+" : ""}'
                  '${displayWeeklyKgAbs.toStringAsFixed(2)} $unitLabel/week '
                  '(${_paceLabel(pace)})',
                  style: theme.textTheme.titleSmall,
                ),
                Slider(
                  value: _weeklyKg.clamp(-1.0, 1.0),
                  min: -1.0,
                  max: 1.0,
                  divisions: 40,
                  label: unit == WeightUnit.kg
                      ? '${_weeklyKg.toStringAsFixed(2)} kg/wk'
                      : '${kgToLb(_weeklyKg).toStringAsFixed(2)} lb/wk',
                  onChanged: (v) => setState(() => _weeklyKg = v),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static String _activityLabel(ActivityLevel a) {
    switch (a) {
      case ActivityLevel.sedentary:
        return 'Sedentary';
      case ActivityLevel.light:
        return 'Light';
      case ActivityLevel.moderate:
        return 'Moderate';
      case ActivityLevel.active:
        return 'Active';
      case ActivityLevel.veryActive:
        return 'Very active';
    }
  }

  static String _paceLabel(PaceLevel p) {
    switch (p) {
      case PaceLevel.gentle:
        return 'gentle';
      case PaceLevel.moderate:
        return 'moderate';
      case PaceLevel.aggressive:
        return 'aggressive';
    }
  }
}

class _BandTile extends StatelessWidget {
  const _BandTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
    required this.caption,
  });

  final IconData icon;
  final Color color;
  final String title;
  final double value;
  final String caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nf = NumberFormat.decimalPattern();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(title, style: theme.textTheme.titleMedium),
                      ),
                      Text(
                        '${nf.format(value.round())} kcal',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    caption,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

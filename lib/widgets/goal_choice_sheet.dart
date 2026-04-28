import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<void> showGoalChoiceSheet({
  required BuildContext context,
  required CalTrackRepository repo,
  required Profile profile,
}) async {
  final unit = WeightUnit.fromStored(profile.weightUnit);
  final goal = await repo.currentGoal();
  if (!context.mounted || goal == null) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: 24 + MediaQuery.of(ctx).viewPadding.bottom,
        ),
        child: GoalChoiceBody(
          profile: profile,
          unit: unit,
          repo: repo,
          currentTargetKg: goal.targetWeightKg,
        ),
      );
    },
  );
}

class GoalChoiceBody extends StatefulWidget {
  const GoalChoiceBody({
    super.key,
    required this.profile,
    required this.unit,
    required this.repo,
    required this.currentTargetKg,
  });

  final Profile profile;
  final WeightUnit unit;
  final CalTrackRepository repo;
  final double currentTargetKg;

  @override
  State<GoalChoiceBody> createState() => _GoalChoiceBodyState();
}

class _GoalChoiceBodyState extends State<GoalChoiceBody> {
  final _newGoalController = TextEditingController();

  @override
  void dispose() {
    _newGoalController.dispose();
    super.dispose();
  }

  Future<void> _maintain() async {
    await widget.repo.chooseMaintainWeight();
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Switched to maintenance calories.')),
    );
  }

  Future<void> _submitNewGoal() async {
    final raw = _newGoalController.text.trim().replaceAll(',', '.');
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid goal weight.')),
      );
      return;
    }
    final kg = widget.unit == WeightUnit.kg ? parsed : lbToKg(parsed);
    await widget.repo.setNewGoal(
      targetWeightKg: kg,
      weeklyChangeKgPerWeek: -0.5,
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New goal saved.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suffix = widget.unit == WeightUnit.kg ? 'kg' : 'lb';
    final hint =
        widget.unit == WeightUnit.kg ? 'e.g. 72.5' : 'e.g. 160';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Goal reached',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'You are near your target weight. Choose how you want to continue.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: _maintain,
          child: const Text('Maintain weight'),
        ),
        const SizedBox(height: 12),
        Text(
          'New goal weight ($suffix)',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _newGoalController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Default pace: 0.5 kg/week loss until you adjust in Settings.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _submitNewGoal,
          child: const Text('Set new goal'),
        ),
      ],
    );
  }
}

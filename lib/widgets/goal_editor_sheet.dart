import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Shows the reusable goal editor as a modal bottom sheet. Returns
/// `true` when the goal was saved (caller can refresh UI accordingly).
Future<bool?> showGoalEditorSheet(
  BuildContext context, {
  required CalTrackRepository repo,
  required Profile profile,
}) async {
  final unit = WeightUnit.fromStored(profile.weightUnit);
  final goal = await repo.currentGoal();
  final latest = await repo.weightEntriesLimit(1);
  if (!context.mounted) return null;
  final currentWeightKg = latest.isEmpty ? null : latest.first.weightKg;

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 4,
          bottom: 24 + MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: GoalEditorBody(
          repo: repo,
          unit: unit,
          initialTargetKg: goal?.targetWeightKg,
          initialWeeklyKg: goal?.weeklyChangeKgPerWeek,
          initialStatus: goal?.status,
          currentWeightKg: currentWeightKg,
        ),
      );
    },
  );
}

/// Reusable form body. Lets the user pick a goal weight and a weekly
/// pace magnitude (sign is inferred from current vs target weight).
class GoalEditorBody extends StatefulWidget {
  const GoalEditorBody({
    super.key,
    required this.repo,
    required this.unit,
    required this.initialTargetKg,
    required this.initialWeeklyKg,
    required this.initialStatus,
    required this.currentWeightKg,
  });

  final CalTrackRepository repo;
  final WeightUnit unit;
  final double? initialTargetKg;
  final double? initialWeeklyKg;
  final String? initialStatus;

  /// Most recent weigh-in (kg). Used to infer the sign of the weekly
  /// pace and to label the direction (lose / gain / maintain).
  final double? currentWeightKg;

  @override
  State<GoalEditorBody> createState() => _GoalEditorBodyState();
}

class _GoalEditorBodyState extends State<GoalEditorBody> {
  final _targetCtl = TextEditingController();
  double _paceKg = 0.5;
  bool _maintain = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final initialTarget = widget.initialTargetKg;
    if (initialTarget != null) {
      final shown = widget.unit == WeightUnit.kg
          ? initialTarget
          : kgToLb(initialTarget);
      _targetCtl.text = shown.toStringAsFixed(1);
    }
    final w = widget.initialWeeklyKg;
    final status = widget.initialStatus;
    if (status == 'maintain' || (w != null && w.abs() < 0.001)) {
      _maintain = true;
    } else if (w != null) {
      _paceKg = w.abs().clamp(0.1, 1.0);
    }
  }

  @override
  void dispose() {
    _targetCtl.dispose();
    super.dispose();
  }

  double? _parseTargetKg() {
    final raw = _targetCtl.text.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return null;
    return widget.unit == WeightUnit.kg ? v : lbToKg(v);
  }

  double _signedWeekly(double currentKg, double targetKg) {
    final diff = targetKg - currentKg;
    if (diff.abs() < 0.05) return 0;
    return diff < 0 ? -_paceKg : _paceKg;
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final profileCtl = context.read<ProfileController>();

    if (_maintain) {
      setState(() => _saving = true);
      try {
        final goal = await widget.repo.currentGoal();
        if (goal == null) {
          final latestKg = widget.currentWeightKg;
          await widget.repo.setNewGoal(
            targetWeightKg: latestKg ?? 0,
            weeklyChangeKgPerWeek: 0,
          );
        }
        await widget.repo.chooseMaintainWeight();
        await profileCtl.refresh();
        if (!mounted) return;
        navigator.pop(true);
        AppSnackBar.showDetached(messenger, message: 'Switched to maintenance.');
      } finally {
        if (mounted) setState(() => _saving = false);
      }
      return;
    }

    final targetKg = _parseTargetKg();
    if (targetKg == null) {
      AppSnackBar.showError(context, 'Enter a valid goal weight.');
      return;
    }
    final currentKg = widget.currentWeightKg;
    final weekly = currentKg == null
        ? -_paceKg
        : _signedWeekly(currentKg, targetKg);
    setState(() => _saving = true);
    try {
      await widget.repo.setNewGoal(
        targetWeightKg: targetKg,
        weeklyChangeKgPerWeek: weekly,
      );
      await profileCtl.refresh();
      if (!mounted) return;
      navigator.pop(true);
      AppSnackBar.showDetached(messenger, message: 'Goal updated.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _directionLabel(double currentKg, double targetKg) {
    final diff = targetKg - currentKg;
    if (diff.abs() < 0.05) return 'Maintain current weight';
    return diff < 0
        ? 'Losing ~${_paceKg.toStringAsFixed(2)} kg/week'
        : 'Gaining ~${_paceKg.toStringAsFixed(2)} kg/week';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final suffix = widget.unit == WeightUnit.kg ? 'kg' : 'lb';
    final hint = widget.unit == WeightUnit.kg ? 'e.g. 72.5' : 'e.g. 160';
    final parsedTargetKg = _parseTargetKg();
    final currentKg = widget.currentWeightKg;
    String? subtitle;
    if (_maintain) {
      subtitle = 'Calories will match your maintenance estimate.';
    } else if (parsedTargetKg != null && currentKg != null) {
      subtitle = _directionLabel(currentKg, parsedTargetKg);
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initialTargetKg == null ? 'Set goal' : 'Edit goal',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Goal weight and weekly pace shape your daily calorie target.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Maintain current weight'),
            subtitle: const Text(
              'Stay at your current weight; ignore the inputs below.',
            ),
            value: _maintain,
            onChanged: _saving
                ? null
                : (v) => setState(() => _maintain = v),
          ),
          const SizedBox(height: 8),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _maintain ? 0.4 : 1.0,
            child: IgnorePointer(
              ignoring: _maintain,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Goal weight ($suffix)',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _targetCtl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: InputDecoration(
                      hintText: hint,
                      suffixText: suffix,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Weekly pace: ${_paceKg.toStringAsFixed(2)} kg/week',
                    style: theme.textTheme.titleSmall,
                  ),
                  Slider(
                    value: _paceKg.clamp(0.1, 1.0),
                    min: 0.1,
                    max: 1.0,
                    divisions: 18,
                    label: '${_paceKg.toStringAsFixed(2)} kg',
                    onChanged: (v) => setState(() => _paceKg = v),
                  ),
                  Text(
                    'Smaller paces (e.g. 0.25–0.5 kg/week) are easier to '
                    'sustain. 1.0 kg/week is aggressive and harder to '
                    'maintain long-term.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: scheme.secondaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: scheme.onSecondaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save goal'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const int _pageCount = 9;

  final _pageController = PageController();
  int _page = 0;

  WeightUnit _unit = WeightUnit.kg;
  String _sex = 'male';
  // Default age band: 25–30 (upper bound 30) — middle of typical onboarding.
  int _ageBandMaxYears = 30;
  double _heightCm = 175;
  final _heightCmController = TextEditingController(text: '175');
  int _activityIndex = 2;

  final _weightController = TextEditingController();
  final _goalWeightController = TextEditingController();

  double _weeklyRateKg = 0.5;

  double _proteinPct = 30;
  double _carbsPct = 40;
  double _fatPct = 30;

  int _reminderWeekday = DateTime.sunday;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    _goalWeightController.dispose();
    _heightCmController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final t = await showTimePicker(context: context, initialTime: _reminderTime);
    if (t != null) setState(() => _reminderTime = t);
  }

  double _parseWeightKg() {
    final raw = _weightController.text.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return -1;
    return _unit == WeightUnit.kg ? v : lbToKg(v);
  }

  double _parseGoalKg() {
    final raw = _goalWeightController.text.trim().replaceAll(',', '.');
    final v = double.tryParse(raw);
    if (v == null || v <= 0) return -1;
    return _unit == WeightUnit.kg ? v : lbToKg(v);
  }

  double _weeklySignedKg(double currentKg, double goalKg) {
    final diff = goalKg - currentKg;
    if (diff.abs() < 0.05) return 0;
    if (diff < 0) return -_weeklyRateKg;
    return _weeklyRateKg;
  }

  bool _macroValid() {
    final sum = _proteinPct.round() + _carbsPct.round() + _fatPct.round();
    return sum == 100;
  }

  void _normalizeMacrosForSubmit() {
    final p = _proteinPct.round().clamp(5, 90);
    final c = _carbsPct.round().clamp(5, 90);
    final f = (100 - p - c).clamp(5, 90);
    var fp = p;
    var fc = c;
    var ff = f;
    if (fp + fc + ff != 100) {
      ff = 100 - fp - fc;
      if (ff < 5) {
        fc = 100 - fp - 5;
        ff = 5;
      }
    }
    _proteinPct = fp.toDouble();
    _carbsPct = fc.toDouble();
    _fatPct = ff.toDouble();
  }

  Future<void> _finish() async {
    final hv = double.tryParse(_heightCmController.text.replaceAll(',', '.'));
    if (hv != null && hv > 50 && hv < 280) _heightCm = hv;

    final repo = context.read<CalTrackRepository>();
    final profileCtl = context.read<ProfileController>();
    final cw = _parseWeightKg();
    final gw = _parseGoalKg();
    _normalizeMacrosForSubmit();
    if (cw <= 0 || gw <= 0 || !_macroValid()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check all fields and macro percentages (100%).')),
      );
      return;
    }
    final weekly = _weeklySignedKg(cw, gw);

    await repo.submitOnboarding(
      sex: _sex,
      ageBandMaxYears: _ageBandMaxYears,
      heightCm: _heightCm,
      activityLevelIndex: _activityIndex,
      weightUnit: _unit,
      currentWeightKg: cw,
      targetWeightKg: gw,
      weeklyChangeKgPerWeek: weekly,
      proteinPct: _proteinPct.round(),
      carbsPct: _carbsPct.round(),
      fatPct: _fatPct.round(),
      reminderWeekday: _reminderWeekday,
      reminderHour: _reminderTime.hour,
      reminderMinute: _reminderTime.minute,
    );
    await profileCtl.refresh();
    await NotificationService.instance.scheduleWeeklyWeighIn(repo: repo);
    if (!mounted) return;
    context.go('/');
  }

  void _next() {
    if (_page < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finish();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome · ${_page + 1}/$_pageCount'),
        leading: _page > 0
            ? IconButton(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_page + 1) / _pageCount),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (i) => setState(() => _page = i),
              children: [
                _welcome(theme),
                _unitsProfile(theme),
                _activity(theme),
                _currentWeight(theme),
                _tdeePreview(theme),
                _goalPace(theme),
                _macros(theme),
                _reminder(theme),
                _summary(theme),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _page == _pageCount - 1 ? 'Start tracking' : 'Continue',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _welcome(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.eco_rounded, size: 72, color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'CalTrack',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Offline macro tracking tuned to your weight trend. '
            'Your data stays on this device.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _unitsProfile(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Units & profile', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        SegmentedButton<WeightUnit>(
          segments: const [
            ButtonSegment(value: WeightUnit.kg, label: Text('Metric')),
            ButtonSegment(value: WeightUnit.lb, label: Text('Imperial')),
          ],
          selected: {_unit},
          onSelectionChanged: (s) => setState(() => _unit = s.first),
        ),
        const SizedBox(height: 16),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'male', label: Text('Male')),
            ButtonSegment(value: 'female', label: Text('Female')),
          ],
          selected: {_sex},
          onSelectionChanged: (s) => setState(() => _sex = s.first),
        ),
        const SizedBox(height: 16),
        Text('Age range', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(
          'Pick the band that contains your age. We use the upper number to '
          'estimate energy needs — that keeps the math conservative without '
          'asking for an exact birth date.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final upper in ageBandUpperBoundsYears)
              ChoiceChip(
                label: Text(ageBandLabel(upper)),
                selected: _ageBandMaxYears == upper,
                onSelected: (_) =>
                    setState(() => _ageBandMaxYears = upper),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Text('Height', style: theme.textTheme.titleSmall),
        Text(
          'Enter height in centimeters for accuracy (your weight can stay in ${_unit.name}).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _heightCmController,
          decoration: const InputDecoration(labelText: 'Height (cm)'),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          onChanged: (t) {
            final v = double.tryParse(t.replaceAll(',', '.'));
            if (v != null && v > 50 && v < 280) setState(() => _heightCm = v);
          },
        ),
      ],
    );
  }

  Widget _activity(ThemeData theme) {
    final labels = ActivityLevel.values
        .map((e) => e.name.replaceFirstMapped(RegExp(r'^[a-z]'), (m) => m[0]!.toUpperCase()))
        .toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Activity level', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Used to estimate your daily energy needs.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(ActivityLevel.values.length, (i) {
          final selected = _activityIndex == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ChoiceChip(
              label: SizedBox(
                width: double.infinity,
                child: Text(labels[i]),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _activityIndex = i),
            ),
          );
        }),
      ],
    );
  }

  Widget _currentWeight(ThemeData theme) {
    final suffix = _unit == WeightUnit.kg ? 'kg' : 'lb';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current weight', style: theme.textTheme.titleLarge),
          const SizedBox(height: 16),
          TextField(
            controller: _weightController,
            decoration: InputDecoration(
              labelText: 'Weight ($suffix)',
              hintText: _unit == WeightUnit.kg ? 'e.g. 78.5' : 'e.g. 175',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tdeePreview(ThemeData theme) {
    final scheme = theme.colorScheme;
    final cw = _parseWeightKg();
    final hv = double.tryParse(
      _heightCmController.text.replaceAll(',', '.'),
    );
    final h = (hv != null && hv > 50 && hv < 280) ? hv : _heightCm;

    if (cw <= 0) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your TDEE estimate', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'Go back and enter your current weight so we can show how '
              'your daily energy needs are estimated.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    final isMale = _sex == 'male';
    final activity = ActivityLevel.fromIndex(_activityIndex);
    final bmr = mifflinStJeorBmr(
      isMale: isMale,
      weightKg: cw,
      heightCm: h,
      ageYears: _ageBandMaxYears,
    );
    final tdeeVal = bmr * activity.multiplier;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Your TDEE estimate', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'TDEE is your estimated daily calories at the activity level you '
          'picked. We use the Mifflin–St Jeor equation, which is widely '
          'cited and only needs the inputs you already provided.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 20),
        _TdeeStepRow(
          label: 'Inputs',
          value: '${cw.toStringAsFixed(1)} kg · ${h.round()} cm · '
              '${ageBandLabel(_ageBandMaxYears)} · '
              '${isMale ? "Male" : "Female"}',
        ),
        const Divider(height: 24),
        _TdeeStepRow(
          label: 'BMR (Mifflin–St Jeor)',
          value: '${bmr.round()} kcal/day',
        ),
        const SizedBox(height: 8),
        _TdeeStepRow(
          label: 'Activity multiplier',
          value:
              '×${activity.multiplier.toStringAsFixed(2)} (${_activityLabel(activity)})',
        ),
        const Divider(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.local_fire_department_outlined,
                  color: scheme.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TDEE',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      '${tdeeVal.round()} kcal/day',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Next we will pick a weekly pace. Your daily target is just TDEE '
          'plus or minus the calories needed for that pace (~7700 kcal '
          'per kg of fat).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _goalPace(ThemeData theme) {
    final suffix = _unit == WeightUnit.kg ? 'kg' : 'lb';
    final rateLabel =
        _unit == WeightUnit.kg ? '${_weeklyRateKg.toStringAsFixed(2)} kg/week' : '${kgToLb(_weeklyRateKg).toStringAsFixed(2)} lb/week';
    final pace = paceLevelForKgPerWeek(_weeklyRateKg);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Goal weight & pace', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        TextField(
          controller: _goalWeightController,
          decoration: InputDecoration(
            labelText: 'Goal weight ($suffix)',
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'Weekly change magnitude',
                style: theme.textTheme.titleSmall,
              ),
            ),
            _PaceBadge(level: pace),
          ],
        ),
        SliderTheme(
          data: theme.sliderTheme.copyWith(
            activeTrackColor: _paceColorFor(theme.colorScheme, pace),
            thumbColor: _paceColorFor(theme.colorScheme, pace),
          ),
          child: Slider(
            value: _weeklyRateKg.clamp(0.1, 1.0),
            min: 0.1,
            max: 1.0,
            divisions: 18,
            label: rateLabel,
            onChanged: (v) => setState(() => _weeklyRateKg = v),
          ),
        ),
        const SizedBox(height: 4),
        _PaceGradient(level: pace),
        const SizedBox(height: 12),
        Text(
          _paceCopy(pace),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Direction follows your goal: below current weight means fat loss '
          'pace; above means gain pace. Same number if you only maintain.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
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

  String _paceCopy(PaceLevel level) {
    switch (level) {
      case PaceLevel.gentle:
        return 'Gentle pace — usually the easiest to sustain over months.';
      case PaceLevel.moderate:
        return 'Moderate pace — noticeable progress with some discipline.';
      case PaceLevel.aggressive:
        return 'Aggressive pace — fast results but harder to keep up '
            'and easier to overshoot the calorie floor.';
    }
  }

  Widget _macros(ThemeData theme) {
    final sum = _proteinPct.round() + _carbsPct.round() + _fatPct.round();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Macro split', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Adjust percentages — they must total 100%.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Total: $sum%',
          style: theme.textTheme.titleMedium?.copyWith(
            color: sum == 100 ? theme.colorScheme.primary : theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Text('Protein ${_proteinPct.round()}%'),
            ),
          ],
        ),
        Slider(
          value: _proteinPct.clamp(10, 80),
          min: 10,
          max: 80,
          divisions: 70,
          onChanged: (v) => setState(() {
            _proteinPct = v;
            final rem = 100 - v.round() - _fatPct.round();
            _carbsPct = rem.clamp(10, 80).toDouble();
          }),
        ),
        Text('Carbs ${_carbsPct.round()}%'),
        Slider(
          value: _carbsPct.clamp(10, 80),
          min: 10,
          max: 80,
          divisions: 70,
          onChanged: (v) => setState(() {
            _carbsPct = v;
            final rem = 100 - _proteinPct.round() - v.round();
            _fatPct = rem.clamp(10, 80).toDouble();
          }),
        ),
        Text('Fat ${_fatPct.round()}%'),
        Slider(
          value: _fatPct.clamp(10, 80),
          min: 10,
          max: 80,
          divisions: 70,
          onChanged: (v) => setState(() {
            _fatPct = v;
            final rem = 100 - _proteinPct.round() - v.round();
            _carbsPct = rem.clamp(10, 80).toDouble();
          }),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Balanced 30/40/30'),
              onPressed: () => setState(() {
                _proteinPct = 30;
                _carbsPct = 40;
                _fatPct = 30;
              }),
            ),
            ActionChip(
              label: const Text('Higher protein'),
              onPressed: () => setState(() {
                _proteinPct = 40;
                _carbsPct = 35;
                _fatPct = 25;
              }),
            ),
            ActionChip(
              label: const Text('Lower carb'),
              onPressed: () => setState(() {
                _proteinPct = 35;
                _carbsPct = 25;
                _fatPct = 40;
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _reminder(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Weekly reminder', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'We will remind you once a week to weigh in and review whether your calorie target is working.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        DropdownButtonFormField<int>(
          // Controlled selection; `value` still matches user weekday state.
          // ignore: deprecated_member_use
          value: _reminderWeekday,
          decoration: const InputDecoration(labelText: 'Day'),
          items: const [
            DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
            DropdownMenuItem(value: DateTime.tuesday, child: Text('Tuesday')),
            DropdownMenuItem(value: DateTime.wednesday, child: Text('Wednesday')),
            DropdownMenuItem(value: DateTime.thursday, child: Text('Thursday')),
            DropdownMenuItem(value: DateTime.friday, child: Text('Friday')),
            DropdownMenuItem(value: DateTime.saturday, child: Text('Saturday')),
            DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _reminderWeekday = v);
          },
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Time'),
          subtitle: Text(_reminderTime.format(context)),
          trailing: const Icon(Icons.schedule),
          onTap: _pickReminderTime,
        ),
      ],
    );
  }

  Widget _summary(ThemeData theme) {
    final macroOk = _macroValid();
    final cw = _parseWeightKg();
    final gw = _parseGoalKg();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Review', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Text(
          'Targets use the Mifflin–St Jeor equation and ~7700 kcal per kg of fat '
          'change per week (approximation).',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          title: const Text('Weight units'),
          subtitle: Text(_unit.name),
        ),
        ListTile(
          title: const Text('Profile'),
          subtitle: Text(
            '${_sex == "male" ? "Male" : "Female"} · '
            'Age ${ageBandLabel(_ageBandMaxYears)} · '
            '${_heightCm.round()} cm',
          ),
        ),
        ListTile(
          title: const Text('Goal'),
          subtitle: Text(
            cw > 0 && gw > 0
                ? '${cw.toStringAsFixed(1)} kg → ${gw.toStringAsFixed(1)} kg (${_weeklySignedKg(cw, gw).toStringAsFixed(2)} kg/wk)'
                : 'Enter weights on previous steps',
          ),
        ),
        ListTile(
          title: const Text('Macros'),
          subtitle: Text(
            macroOk
                ? '${_proteinPct.round()} / ${_carbsPct.round()} / ${_fatPct.round()}'
                : 'Must total 100%',
          ),
        ),
        ListTile(
          title: const Text('Reminder'),
          subtitle: Text(
            '${_weekdayName(_reminderWeekday)} at ${_reminderTime.format(context)}',
          ),
        ),
      ],
    );
  }

  static String _weekdayName(int weekday) {
    const names = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday.clamp(1, 7)];
  }
}

/// Two-column row used in the TDEE breakdown step.
class _TdeeStepRow extends StatelessWidget {
  const _TdeeStepRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: theme.textTheme.titleSmall,
        ),
      ],
    );
  }
}

String _paceLabelText(PaceLevel level) {
  switch (level) {
    case PaceLevel.gentle:
      return 'Gentle';
    case PaceLevel.moderate:
      return 'Moderate';
    case PaceLevel.aggressive:
      return 'Aggressive';
  }
}

IconData _paceIcon(PaceLevel level) {
  switch (level) {
    case PaceLevel.gentle:
      return Icons.spa_outlined;
    case PaceLevel.moderate:
      return Icons.directions_walk;
    case PaceLevel.aggressive:
      return Icons.warning_amber_rounded;
  }
}

Color _paceColorFor(ColorScheme scheme, PaceLevel level) {
  switch (level) {
    case PaceLevel.gentle:
      return scheme.primary;
    case PaceLevel.moderate:
      return scheme.tertiary;
    case PaceLevel.aggressive:
      return scheme.error;
  }
}

/// Compact icon + label "chip" indicating pace sustainability.
class _PaceBadge extends StatelessWidget {
  const _PaceBadge({required this.level});

  final PaceLevel level;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = _paceColorFor(scheme, level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_paceIcon(level), size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            _paceLabelText(level),
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Three-zone gradient bar that highlights the active sustainability tier
/// alongside the slider, reinforcing the chosen pace beyond colour alone.
class _PaceGradient extends StatelessWidget {
  const _PaceGradient({required this.level});

  final PaceLevel level;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color zone(PaceLevel z) {
      final base = _paceColorFor(scheme, z);
      return level == z ? base : base.withValues(alpha: 0.25);
    }

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: zone(PaceLevel.gentle),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Container(
            height: 6,
            color: zone(PaceLevel.moderate),
          ),
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Container(
            height: 6,
            decoration: BoxDecoration(
              color: zone(PaceLevel.aggressive),
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

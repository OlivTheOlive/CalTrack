import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  WeightUnit _unit = WeightUnit.kg;
  String _sex = 'male';
  DateTime _birthDate =
      DateTime(DateTime.now().year - 28, DateTime.now().month, DateTime.now().day);
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

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(now.year - 100),
      lastDate: DateTime(now.year - 14),
    );
    if (picked != null) setState(() => _birthDate = picked);
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
      birthDate: _birthDate,
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
    if (_page < 7) {
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
        title: Text('Welcome · ${_page + 1}/8'),
        leading: _page > 0
            ? IconButton(
                onPressed: _back,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(value: (_page + 1) / 8),
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
                  child: Text(_page == 7 ? 'Start tracking' : 'Continue'),
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
        ListTile(
          title: const Text('Birth date'),
          subtitle: Text(DateFormat.yMMMd().format(_birthDate)),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: _pickBirthDate,
        ),
        const SizedBox(height: 8),
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

  Widget _goalPace(ThemeData theme) {
    final suffix = _unit == WeightUnit.kg ? 'kg' : 'lb';
    final rateLabel =
        _unit == WeightUnit.kg ? '${_weeklyRateKg.toStringAsFixed(2)} kg/week' : '${kgToLb(_weeklyRateKg).toStringAsFixed(2)} lb/week';

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
        Text('Weekly change magnitude', style: theme.textTheme.titleSmall),
        Slider(
          value: _weeklyRateKg.clamp(0.1, 1.0),
          min: 0.1,
          max: 1.0,
          divisions: 18,
          label: rateLabel,
          onChanged: (v) => setState(() => _weeklyRateKg = v),
        ),
        Text(
          'Direction follows your goal: below current weight means fat loss pace; '
          'above means gain pace. Same number if you only maintain.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
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

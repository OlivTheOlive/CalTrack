import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/app/meal_time_controller.dart';
import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/app/theme_controller.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/services/notification_service.dart';
import 'package:caltrack/widgets/goal_editor_sheet.dart';
import 'package:caltrack/widgets/opennutrition_attribution.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _protein = 30;
  double _carbs = 40;
  double _fat = 30;

  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();
    final profileCtl = context.read<ProfileController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder(
        future: repo.requireProfile(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = snap.data!;
          if (!_loaded) {
            _protein = profile.proteinPct.toDouble();
            _carbs = profile.carbsPct.toDouble();
            _fat = profile.fatPct.toDouble();
            _loaded = true;
          }
          final unit = WeightUnit.fromStored(profile.weightUnit);
          final sum = _protein.round() + _carbs.round() + _fat.round();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Profile',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Theme',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              const _StylePicker(),
              const SizedBox(height: 12),
              const _ThemePicker(),
              const Divider(height: 40),
              Text(
                'Meal times',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const _MealTimeSettings(),
              const Divider(height: 40),
              Text(
                'Weight display',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SegmentedButton<WeightUnit>(
                segments: const [
                  ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
                  ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
                ],
                selected: {unit},
                onSelectionChanged: (s) async {
                  await repo.updateWeightUnit(s.first);
                  await profileCtl.refresh();
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),
              Text(
                'Macro percentages',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Total: $sum%',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: sum == 100
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.error,
                    ),
              ),
              Text('Protein ${_protein.round()}%'),
              Slider(
                value: _protein.clamp(10, 80),
                min: 10,
                max: 80,
                divisions: 70,
                onChanged: (v) => setState(() {
                  _protein = v;
                  final rem = 100 - v.round() - _fat.round();
                  _carbs = rem.clamp(10, 80).toDouble();
                }),
              ),
              Text('Carbs ${_carbs.round()}%'),
              Slider(
                value: _carbs.clamp(10, 80),
                min: 10,
                max: 80,
                divisions: 70,
                onChanged: (v) => setState(() {
                  _carbs = v;
                  final rem = 100 - _protein.round() - v.round();
                  _fat = rem.clamp(10, 80).toDouble();
                }),
              ),
              Text('Fat ${_fat.round()}%'),
              Slider(
                value: _fat.clamp(10, 80),
                min: 10,
                max: 80,
                divisions: 70,
                onChanged: (v) => setState(() {
                  _fat = v;
                  final rem = 100 - _protein.round() - v.round();
                  _carbs = rem.clamp(10, 80).toDouble();
                }),
              ),
              FilledButton(
                onPressed: sum != 100
                    ? null
                    : () async {
                        await repo.updateMacroSplit(
                          proteinPct: _protein.round(),
                          carbsPct: _carbs.round(),
                          fatPct: _fat.round(),
                        );
                        await profileCtl.refresh();
                        if (!context.mounted) return;
                        context.showAppSnackBar('Macros updated');
                      },
                child: const Text('Save macros'),
              ),
              const Divider(height: 40),
              Text('Plan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _GoalSettingsTile(unit: unit),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune),
                title: const Text('Calorie bands'),
                subtitle: const Text(
                  'Floor, maintenance and goal target, plus what-if sliders.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/calorie-bands'),
              ),
              const Divider(height: 40),
              Text(
                'Notifications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Reschedule'),
                subtitle: Text(
                  'Change day and time from the onboarding flow values in database — '
                  'edit below (weekday ${_weekdayLabel(profile.reminderWeekday)})',
                ),
              ),
              DropdownButtonFormField<int>(
                // ignore: deprecated_member_use
                value: profile.reminderWeekday,
                decoration: const InputDecoration(labelText: 'Day'),
                items: const [
                  DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
                  DropdownMenuItem(value: DateTime.tuesday, child: Text('Tuesday')),
                  DropdownMenuItem(
                    value: DateTime.wednesday,
                    child: Text('Wednesday'),
                  ),
                  DropdownMenuItem(value: DateTime.thursday, child: Text('Thursday')),
                  DropdownMenuItem(value: DateTime.friday, child: Text('Friday')),
                  DropdownMenuItem(value: DateTime.saturday, child: Text('Saturday')),
                  DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
                ],
                onChanged: (v) async {
                  if (v == null) return;
                  await repo.updateReminderSchedule(
                    weekday: v,
                    hour: profile.reminderHour,
                    minute: profile.reminderMinute,
                  );
                  await NotificationService.instance.scheduleWeeklyWeighIn(repo: repo);
                  await profileCtl.refresh();
                  setState(() {});
                },
              ),
              ListTile(
                title: const Text('Time'),
                subtitle: Text(
                  '${profile.reminderHour.toString().padLeft(2, '0')}:'
                  '${profile.reminderMinute.toString().padLeft(2, '0')}',
                ),
                trailing: const Icon(Icons.schedule),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay(
                      hour: profile.reminderHour,
                      minute: profile.reminderMinute,
                    ),
                  );
                  if (t == null) return;
                  await repo.updateReminderSchedule(
                    weekday: profile.reminderWeekday,
                    hour: t.hour,
                    minute: t.minute,
                  );
                  await NotificationService.instance.scheduleWeeklyWeighIn(repo: repo);
                  await profileCtl.refresh();
                  setState(() {});
                },
              ),
              const Divider(height: 40),
              Text('Food data', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const OpenNutritionAttribution(),
              const SizedBox(height: 12),
              const _FoodDataCounts(),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.restaurant_outlined),
                title: const Text('Custom foods'),
                subtitle: const Text('View, edit, or delete your custom foods.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/custom-foods'),
              ),
              const SizedBox(height: 12),
              Text(
                'Portions of the catalog originate from Open Food Facts. '
                'When displaying that data, maintain attribution to '
                '(c) Open Food Facts contributors — see their terms.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              TextButton(
                onPressed: () async {
                  final uri = Uri.parse(
                    'https://world.openfoodfacts.org/terms-of-use',
                  );
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Open Food Facts terms'),
              ),
              const Divider(height: 40),
              Text('Data tools', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.import_export_outlined),
                title: const Text('Backup / export / import'),
                subtitle: const Text('Export your data or restore from a backup file.'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/data-tools'),
              ),
              const Divider(height: 40),
              Text('About', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              _VersionInfoTile(),
            ],
          );
        },
      ),
    );
  }

  static String _weekdayLabel(int weekday) {
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

/// Tile showing the active goal weight + pace and opening the editor.
/// Live-updates via [CalTrackRepository.watchCurrentGoal].
class _GoalSettingsTile extends StatelessWidget {
  const _GoalSettingsTile({required this.unit});

  final WeightUnit unit;

  String _formatTarget(double kg) {
    final shown = unit == WeightUnit.kg ? kg : kgToLb(kg);
    return '${shown.toStringAsFixed(1)} ${unit.shortLabel}';
  }

  String _paceDescription(Goal goal) {
    final rate = goal.weeklyChangeKgPerWeek;
    if (goal.status == 'maintain' || rate.abs() < 0.001) {
      return 'Maintenance — calories match your TDEE.';
    }
    final dir = rate < 0 ? 'Losing' : 'Gaining';
    return '$dir ~${rate.abs().toStringAsFixed(2)} kg/week';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();
    return StreamBuilder<Goal?>(
      stream: repo.watchCurrentGoal(),
      builder: (context, snap) {
        final goal = snap.data;
        final title = goal == null
            ? 'Set a weight goal'
            : 'Goal: ${_formatTarget(goal.targetWeightKg)}';
        final subtitle = goal == null
            ? 'Pick a target weight and weekly pace.'
            : _paceDescription(goal);
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.flag_outlined),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final profile = await repo.requireProfile();
            if (!context.mounted) return;
            await showGoalEditorSheet(
              context,
              repo: repo,
              profile: profile,
            );
          },
        );
      },
    );
  }
}

/// Two-line summary of how many foods are stored locally: catalog rows
/// (bundled OpenNutrition) versus user-created entries.
class _FoodDataCounts extends StatelessWidget {
  const _FoodDataCounts();

  Future<({int catalog, int custom})> _load(BuildContext context) async {
    final catalog = context.read<OpenNutritionCatalog>();
    final repo = context.read<CalTrackRepository>();
    final results = await Future.wait([
      catalog.foodRowCount(),
      repo.customFoodCount(),
    ]);
    return (catalog: results[0], custom: results[1]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final nf = NumberFormat.decimalPattern();

    return FutureBuilder<({int catalog, int custom})>(
      future: _load(context),
      builder: (context, snap) {
        final data = snap.data;
        final catalogText = data == null ? '—' : nf.format(data.catalog);
        final customText = data == null ? '—' : nf.format(data.custom);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.menu_book_outlined, color: scheme.primary),
              title: const Text('OpenNutrition catalog'),
              trailing: Text(
                '$catalogText foods',
                style: theme.textTheme.titleSmall,
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.edit_note_outlined, color: scheme.secondary),
              title: const Text('Your foods'),
              trailing: Text(
                '$customText foods',
                style: theme.textTheme.titleSmall,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Meal time auto-selection settings
// ---------------------------------------------------------------------------

class _MealTimeSettings extends StatelessWidget {
  const _MealTimeSettings();

  @override
  Widget build(BuildContext context) {
    final ctl = context.watch<MealTimeController>();
    final config = ctl.config;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('Auto-select meal time'),
          subtitle: const Text(
            'Picks Breakfast/Lunch/Dinner based on the current hour.',
          ),
          value: config.enabled,
          onChanged: (v) => ctl.setEnabled(v),
          contentPadding: EdgeInsets.zero,
          dense: true,
        ),
        if (config.enabled) ...[
          const SizedBox(height: 8),
          _MealWindowRow(
            label: 'Breakfast',
            start: config.breakfastStart,
            end: config.breakfastEnd,
            onStartChanged: (h) => ctl.setBreakfastWindow(h, config.breakfastEnd),
            onEndChanged: (h) => ctl.setBreakfastWindow(config.breakfastStart, h),
          ),
          _MealWindowRow(
            label: 'Lunch',
            start: config.lunchStart,
            end: config.lunchEnd,
            onStartChanged: (h) => ctl.setLunchWindow(h, config.lunchEnd),
            onEndChanged: (h) => ctl.setLunchWindow(config.lunchStart, h),
          ),
          _MealWindowRow(
            label: 'Dinner',
            start: config.dinnerStart,
            end: config.dinnerEnd,
            onStartChanged: (h) => ctl.setDinnerWindow(h, config.dinnerEnd),
            onEndChanged: (h) => ctl.setDinnerWindow(config.dinnerStart, h),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              'Windows are checked in order: Breakfast → Lunch → Dinner. First match wins.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// One labeled row with two hour pickers (start / end).
class _MealWindowRow extends StatelessWidget {
  const _MealWindowRow({
    required this.label,
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final String label;
  final int start;
  final int end;
  final ValueChanged<int> onStartChanged;
  final ValueChanged<int> onEndChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
          ),
          _HourChip(hour: start, label: '${start.toString().padLeft(2, '0')}:00', onChanged: onStartChanged),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('to', style: theme.textTheme.bodySmall),
          ),
          _HourChip(hour: end, label: '${end.toString().padLeft(2, '0')}:00', onChanged: onEndChanged),
        ],
      ),
    );
  }
}

/// Tap to pick an hour (0–23) via a simple dialog.
class _HourChip extends StatelessWidget {
  const _HourChip({
    required this.hour,
    required this.label,
    required this.onChanged,
  });

  final int hour;
  final String label;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(hour: hour, minute: 0),
          helpText: 'Pick hour',
        );
        if (picked != null && context.mounted) {
          onChanged(picked.hour);
        }
      },
    );
  }
}

/// Segmented button that lets the user pick a theme style (classic, cyberpunk).
class _StylePicker extends StatelessWidget {
  const _StylePicker();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Style',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<AppThemeStyle>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: AppThemeStyle.classic,
              icon: Icon(Icons.palette_outlined),
              label: Text('Classic'),
            ),
            ButtonSegment(
              value: AppThemeStyle.cyberpunk,
              icon: Icon(Icons.flash_on),
              label: Text('Cyberpunk'),
            ),
          ],
          selected: {controller.style},
          onSelectionChanged: (s) => controller.setStyle(s.first),
        ),
      ],
    );
  }
}

/// Segmented button that lets the user pick between System, Light, Dark, OLED.
class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    return SegmentedButton<AppThemeMode>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: AppThemeMode.system,
          icon: Icon(Icons.brightness_auto),
          label: Text('System'),
        ),
        ButtonSegment(
          value: AppThemeMode.light,
          icon: Icon(Icons.light_mode),
          label: Text('Light'),
        ),
        ButtonSegment(
          value: AppThemeMode.dark,
          icon: Icon(Icons.dark_mode),
          label: Text('Dark'),
        ),
        ButtonSegment(
          value: AppThemeMode.oled,
          icon: Icon(Icons.circle),
          label: Text('OLED'),
        ),
      ],
      selected: {controller.mode},
      onSelectionChanged: (s) => controller.setMode(s.first),
    );
  }
}

class _VersionInfoTile extends StatelessWidget {
  const _VersionInfoTile();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final info = snap.data;
        final version = info == null ? '...' : info.version;
        final buildNumber = info == null ? '' : ' (${info.buildNumber})';
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.info_outline),
          title: Text('CalTrack v$version$buildNumber'),
          subtitle: const Text('Check for updates on GitHub.'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () async {
            final uri = Uri.parse(
              'https://github.com/OlivTheOlive/CalTrack/releases',
            );
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            }
          },
        );
      },
    );
  }
}

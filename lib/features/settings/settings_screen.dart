import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/services/notification_service.dart';
import 'package:caltrack/widgets/opennutrition_attribution.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
              Text('Weight display', style: Theme.of(context).textTheme.titleMedium),
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
              const SizedBox(height: 24),
              Text('Macro percentages', style: Theme.of(context).textTheme.titleMedium),
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Macros updated')),
                        );
                      },
                child: const Text('Save macros'),
              ),
              const Divider(height: 40),
              Text(
                'Plan',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tune),
                title: const Text('Calorie bands'),
                subtitle: const Text(
                  'See your floor, maintenance and goal target, '
                  'and try out what-if scenarios.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/calorie-bands'),
              ),
              const Divider(height: 40),
              Text('Weekly reminder', style: Theme.of(context).textTheme.titleMedium),
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

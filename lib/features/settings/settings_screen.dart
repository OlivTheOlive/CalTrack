import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/app/meal_time_controller.dart';
import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/app/theme_controller.dart';
import 'package:caltrack/core/spacing.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/services/notification_service.dart';
import 'package:caltrack/widgets/goal_editor_sheet.dart';
import 'package:caltrack/widgets/opennutrition_attribution.dart';
import 'package:caltrack/widgets/styled_card.dart';
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

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.md,
              Spacing.md,
              Spacing.xl,
            ),
            children: [
              _SettingsSection(
                title: 'Appearance',
                icon: Icons.palette_outlined,
                children: const [
                  Padding(
                    padding: EdgeInsets.all(Spacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StylePicker(),
                        SizedBox(height: Spacing.md),
                        _ThemeModePicker(),
                      ],
                    ),
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Units & macros',
                icon: Icons.straighten_outlined,
                children: [
                  _WeightUnitRow(
                    unit: unit,
                    onChanged: (u) async {
                      await repo.updateWeightUnit(u);
                      await profileCtl.refresh();
                      setState(() {});
                    },
                  ),
                  const Divider(
                    height: 1,
                    indent: Spacing.md,
                    endIndent: Spacing.md,
                  ),
                  _MacroEditor(
                    protein: _protein,
                    carbs: _carbs,
                    fat: _fat,
                    onChanged: (p, c, f) => setState(() {
                      _protein = p;
                      _carbs = c;
                      _fat = f;
                    }),
                    onSave: () async {
                      await repo.updateMacroSplit(
                        proteinPct: _protein.round(),
                        carbsPct: _carbs.round(),
                        fatPct: _fat.round(),
                      );
                      await profileCtl.refresh();
                      if (!context.mounted) return;
                      context.showAppSnackBar('Macros updated');
                    },
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Meal times',
                icon: Icons.schedule_outlined,
                children: const [
                  Padding(
                    padding: EdgeInsets.all(Spacing.md),
                    child: _MealTimeSettings(),
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Plan',
                icon: Icons.flag_outlined,
                children: [
                  _GoalSettingsTile(unit: unit),
                  const Divider(
                    height: 1,
                    indent: Spacing.md,
                    endIndent: Spacing.md,
                  ),
                  _SettingsNavTile(
                    icon: Icons.tune,
                    title: 'Calorie bands',
                    subtitle:
                        'Floor, maintenance and goal target, plus what-if sliders.',
                    onTap: () => context.push('/calorie-bands'),
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Notifications',
                icon: Icons.notifications_outlined,
                children: [
                  _ReminderSettings(
                    profile: profile,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              _SettingsSection(
                title: 'Food data',
                icon: Icons.restaurant_menu_outlined,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(Spacing.md),
                    child: Column(
                      children: [
                        OpenNutritionAttribution(),
                        SizedBox(height: Spacing.md),
                        _FoodDataCounts(),
                      ],
                    ),
                  ),
                  const Divider(
                    height: 1,
                    indent: Spacing.md,
                    endIndent: Spacing.md,
                  ),
                  _SettingsNavTile(
                    icon: Icons.restaurant_outlined,
                    title: 'Custom foods',
                    subtitle: 'View, edit, or delete your custom foods.',
                    onTap: () => context.push('/custom-foods'),
                  ),
                  const Divider(
                    height: 1,
                    indent: Spacing.md,
                    endIndent: Spacing.md,
                  ),
                  const _OpenFoodFactsTerms(),
                ],
              ),
              _SettingsSection(
                title: 'Data tools',
                icon: Icons.storage_outlined,
                children: [
                  _SettingsNavTile(
                    icon: Icons.import_export_outlined,
                    title: 'Backup / export / import',
                    subtitle: 'Export your data or restore from a backup file.',
                    onTap: () => context.push('/data-tools'),
                  ),
                ],
              ),
              _SettingsSection(
                title: 'About',
                icon: Icons.info_outline,
                children: const [_VersionInfoTile()],
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section + tile scaffolding
// ---------------------------------------------------------------------------

/// A titled group: a small section header followed by a [StyledCard]
/// containing [children] (typically tiles separated by thin dividers).
class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.children,
    this.icon,
  });

  final String title;
  final IconData? icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.xs,
              0,
              Spacing.xs,
              Spacing.sm,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: scheme.primary),
                  const SizedBox(width: Spacing.sm),
                ],
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          StyledCard(
            tone: CardTone.low,
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable navigation row used inside a [_SettingsSection].
class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      shape: const RoundedRectangleBorder(),
    );
  }
}

// ---------------------------------------------------------------------------
// Units & macros
// ---------------------------------------------------------------------------

class _WeightUnitRow extends StatelessWidget {
  const _WeightUnitRow({required this.unit, required this.onChanged});

  final WeightUnit unit;
  final ValueChanged<WeightUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text('Weight display', style: theme.textTheme.bodyLarge),
          ),
          SegmentedButton<WeightUnit>(
            segments: const [
              ButtonSegment(value: WeightUnit.kg, label: Text('kg')),
              ButtonSegment(value: WeightUnit.lb, label: Text('lb')),
            ],
            selected: {unit},
            showSelectedIcon: false,
            onSelectionChanged: (s) => onChanged(s.first),
          ),
        ],
      ),
    );
  }
}

class _MacroEditor extends StatelessWidget {
  const _MacroEditor({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.onChanged,
    required this.onSave,
  });

  final double protein;
  final double carbs;
  final double fat;

  /// Reports the new (protein, carbs, fat) tuple after a slider drag.
  final void Function(double protein, double carbs, double fat) onChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sum = protein.round() + carbs.round() + fat.round();
    final balanced = sum == 100;

    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Macro percentages',
                  style: theme.textTheme.bodyLarge,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: (balanced ? scheme.primary : scheme.error).withValues(
                    alpha: 0.12,
                  ),
                  borderRadius: Corners.radiusSm,
                ),
                child: Text(
                  'Total $sum%',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: balanced ? scheme.primary : scheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          _MacroSlider(
            label: 'Protein',
            value: protein,
            color: scheme.primary,
            onChanged: (v) {
              final rem = 100 - v.round() - fat.round();
              onChanged(v, rem.clamp(10, 80).toDouble(), fat);
            },
          ),
          _MacroSlider(
            label: 'Carbs',
            value: carbs,
            color: scheme.tertiary,
            onChanged: (v) {
              final rem = 100 - protein.round() - v.round();
              onChanged(protein, v, rem.clamp(10, 80).toDouble());
            },
          ),
          _MacroSlider(
            label: 'Fat',
            value: fat,
            color: scheme.secondary,
            onChanged: (v) {
              final rem = 100 - protein.round() - v.round();
              onChanged(protein, rem.clamp(10, 80).toDouble(), v);
            },
          ),
          const SizedBox(height: Spacing.sm),
          FilledButton(
            onPressed: balanced ? onSave : null,
            child: const Text('Save macros'),
          ),
        ],
      ),
    );
  }
}

class _MacroSlider extends StatelessWidget {
  const _MacroSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        SizedBox(
          width: 92,
          child: Text(
            '$label ${value.round()}%',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(
              context,
            ).copyWith(activeTrackColor: color, thumbColor: color),
            child: Slider(
              value: value.clamp(10, 80),
              min: 10,
              max: 80,
              divisions: 70,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Notifications
// ---------------------------------------------------------------------------

class _ReminderSettings extends StatelessWidget {
  const _ReminderSettings({required this.profile, required this.onChanged});

  final Profile profile;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();
    final profileCtl = context.read<ProfileController>();
    final timeLabel =
        '${profile.reminderHour.toString().padLeft(2, '0')}:'
        '${profile.reminderMinute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.md,
            Spacing.md,
            Spacing.sm,
          ),
          child: DropdownButtonFormField<int>(
            // ignore: deprecated_member_use
            value: profile.reminderWeekday,
            decoration: const InputDecoration(
              labelText: 'Weekly weigh-in day',
              prefixIcon: Icon(Icons.event_outlined),
            ),
            items: const [
              DropdownMenuItem(value: DateTime.monday, child: Text('Monday')),
              DropdownMenuItem(value: DateTime.tuesday, child: Text('Tuesday')),
              DropdownMenuItem(
                value: DateTime.wednesday,
                child: Text('Wednesday'),
              ),
              DropdownMenuItem(
                value: DateTime.thursday,
                child: Text('Thursday'),
              ),
              DropdownMenuItem(value: DateTime.friday, child: Text('Friday')),
              DropdownMenuItem(
                value: DateTime.saturday,
                child: Text('Saturday'),
              ),
              DropdownMenuItem(value: DateTime.sunday, child: Text('Sunday')),
            ],
            onChanged: (v) async {
              if (v == null) return;
              await repo.updateReminderSchedule(
                weekday: v,
                hour: profile.reminderHour,
                minute: profile.reminderMinute,
              );
              await NotificationService.instance.scheduleWeeklyWeighIn(
                repo: repo,
              );
              await profileCtl.refresh();
              onChanged();
            },
          ),
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Reminder time'),
          subtitle: Text(timeLabel),
          trailing: const Icon(Icons.edit_outlined),
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
            await NotificationService.instance.scheduleWeeklyWeighIn(
              repo: repo,
            );
            await profileCtl.refresh();
            onChanged();
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Open Food Facts attribution / terms
// ---------------------------------------------------------------------------

class _OpenFoodFactsTerms extends StatelessWidget {
  const _OpenFoodFactsTerms();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Portions of the catalog originate from Open Food Facts. '
            'When displaying that data, maintain attribution to '
            '(c) Open Food Facts contributors — see their terms.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              icon: const Icon(Icons.open_in_new, size: 16),
              onPressed: () async {
                final uri = Uri.parse(
                  'https://world.openfoodfacts.org/terms-of-use',
                );
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              label: const Text('Open Food Facts terms'),
            ),
          ),
        ],
      ),
    );
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
    final displayRate = unit == WeightUnit.kg ? rate.abs() : kgToLb(rate.abs());
    return '$dir ~${displayRate.toStringAsFixed(2)} ${unit.shortLabel}/week';
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();
    final scheme = Theme.of(context).colorScheme;
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
          leading: Icon(Icons.flag_outlined, color: scheme.onSurfaceVariant),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final profile = await repo.requireProfile();
            if (!context.mounted) return;
            await showGoalEditorSheet(context, repo: repo, profile: profile);
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
          const SizedBox(height: Spacing.sm),
          _MealWindowRow(
            label: 'Breakfast',
            start: config.breakfastStart,
            end: config.breakfastEnd,
            onStartChanged: (h) =>
                ctl.setBreakfastWindow(h, config.breakfastEnd),
            onEndChanged: (h) =>
                ctl.setBreakfastWindow(config.breakfastStart, h),
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
          const SizedBox(height: Spacing.sm),
          Text(
            'Windows are checked in order: Breakfast → Lunch → Dinner. '
            'First match wins.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _HourChip(
            hour: start,
            label: '${start.toString().padLeft(2, '0')}:00',
            onChanged: onStartChanged,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
            child: Text('to', style: theme.textTheme.bodySmall),
          ),
          _HourChip(
            hour: end,
            label: '${end.toString().padLeft(2, '0')}:00',
            onChanged: onEndChanged,
          ),
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
        const SizedBox(height: Spacing.sm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AppThemeStyle>(
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
        ),
      ],
    );
  }
}

/// Segmented button that lets the user pick between System, Light, Dark, OLED.
class _ThemeModePicker extends StatelessWidget {
  const _ThemeModePicker();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AppThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: AppThemeMode.system,
                icon: Icon(Icons.brightness_auto),
                label: Text('Auto'),
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
          ),
        ),
      ],
    );
  }
}

class _VersionInfoTile extends StatelessWidget {
  const _VersionInfoTile();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (context, snap) {
        final info = snap.data;
        final version = info == null ? '...' : info.version;
        final buildNumber = info == null ? '' : ' (${info.buildNumber})';
        return ListTile(
          leading: Icon(Icons.info_outline, color: scheme.onSurfaceVariant),
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

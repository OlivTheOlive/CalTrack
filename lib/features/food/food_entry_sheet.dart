import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/app/meal_time_controller.dart';
import 'package:caltrack/core/nutrients.dart';
import 'package:caltrack/core/nutrition_scaling.dart';
import 'package:caltrack/core/validation.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/widgets/opennutrition_attribution.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Outcome bubbled back from the food entry sheet.
enum FoodEntryAction { added, updated, deleted }

/// Mode of the amount selector inside the sheet.
enum _AmountMode { servings, grams }

class FoodEntrySheetConfig {
  const FoodEntrySheetConfig({
    required this.displayName,
    required this.source,
    this.catalogFoodId,
    this.customFoodId,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    this.sugarPer100g = 0,
    this.fiberPer100g = 0,
    required this.fatPer100g,
    this.extraNutrientsPer100g = const {},
    this.onSelectIngredient,
    this.initialGrams = 100,
    this.editingEntryId,
    this.loggedAtForEdit,
    this.subtitle,
    this.unitLabel = 'g',
    this.showOpenNutritionAttribution = false,
    this.presets = const [],
    this.initialPresetLabel,
    this.initialPresetQty,
    this.initialMealPeriod,
    this.showPresetPicker = true,
  });

  final String displayName;
  final String source;
  final String? catalogFoodId;
  final int? customFoodId;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double sugarPer100g;
  final double fiberPer100g;
  final double fatPer100g;
  final Map<NutrientKey, double> extraNutrientsPer100g;
  final void Function(double grams, String label)? onSelectIngredient;
  final double initialGrams;

  /// When non-null, the sheet is in **edit mode** for this entry id.
  final int? editingEntryId;
  final DateTime? loggedAtForEdit;

  final String? subtitle;
  final String unitLabel;
  final bool showOpenNutritionAttribution;

  /// Optional serving presets (e.g. Small/Medium/Large/XL/Jumbo egg).
  /// When non-empty the sheet defaults to "Servings" mode with the
  /// default preset selected.
  final List<CatalogGroupPreset> presets;

  /// Preselected preset label (for reopening a saved log). Falls back to
  /// the group's default when null.
  final String? initialPresetLabel;

  /// Preselected quantity (e.g. 2 for "2 × Large egg").
  final double? initialPresetQty;

  /// Initial meal period selection.
  final MealPeriod? initialMealPeriod;

  /// When false, hides the preset dropdown even when there are presets.
  /// Useful for single-preset foods (e.g. custom foods with one serving).
  final bool showPresetPicker;

  bool get isEdit => editingEntryId != null;

  bool get hasPresets => presets.isNotEmpty;
}

/// Modal bottom sheet to add or edit a food log entry. Returns the
/// resulting action (or null if dismissed).
Future<FoodEntryAction?> showFoodEntrySheet(
  BuildContext context,
  FoodEntrySheetConfig config,
) {
  return showModalBottomSheet<FoodEntryAction>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    useSafeArea: true,
    builder: (ctx) => _FoodEntrySheet(config: config),
  );
}

class _FoodEntrySheet extends StatefulWidget {
  const _FoodEntrySheet({required this.config});

  final FoodEntrySheetConfig config;

  @override
  State<_FoodEntrySheet> createState() => _FoodEntrySheetState();
}

class _FoodEntrySheetState extends State<_FoodEntrySheet> {
  late final TextEditingController _grams = TextEditingController(
    text: _formatNumber(widget.config.initialGrams),
  );
  late final TextEditingController _qty = TextEditingController();
  bool _busy = false;

  String? _foodKey;
  bool _loadingPrefs = true;
  double? _savedServingAmount;
  String? _savedServingUnit; // 'g' | 'ml'

  late _AmountMode _mode;
  CatalogGroupPreset? _selectedPreset;

  MealPeriod? _selectedPeriod;

  @override
  void initState() {
    super.initState();
    _mode = widget.config.hasPresets ? _AmountMode.servings : _AmountMode.grams;
    _selectedPeriod = widget.config.initialMealPeriod;
    if (widget.config.hasPresets) {
      _selectedPreset = _resolveInitialPreset();
      final qty = widget.config.initialPresetQty ?? _inferQtyFromGrams();
      _qty.text = _formatNumber(qty);
      _syncGramsFromPreset();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPrefs();
      _applyAutoMealPeriod();
    });
  }

  CatalogGroupPreset? _resolveInitialPreset() {
    final presets = widget.config.presets;
    if (presets.isEmpty) return null;
    final byLabel = widget.config.initialPresetLabel;
    if (byLabel != null) {
      for (final preset in presets) {
        if (preset.label == byLabel) return preset;
      }
    }
    for (final preset in presets) {
      if (preset.isDefault) return preset;
    }
    return presets.first;
  }

  double _inferQtyFromGrams() {
    final preset = _selectedPreset;
    if (preset == null || preset.grams <= 0) return 1;
    final qty = widget.config.initialGrams / preset.grams;
    if (qty <= 0) return 1;
    // Snap to the nearest quarter serving; most users pick whole/half.
    final snapped = (qty * 4).round() / 4;
    return snapped <= 0 ? 1 : snapped;
  }

  void _applyAutoMealPeriod() {
    if (_selectedPeriod != null || widget.config.isEdit) return;
    final mealCtl = context.read<MealTimeController>();
    final suggested = mealCtl.suggestMealPeriod();
    if (suggested != null && mounted) {
      setState(() => _selectedPeriod = suggested);
    }
  }

  Future<void> _loadPrefs() async {
    final repo = context.read<CalTrackRepository>();
    final cfg = widget.config;
    final key = cfg.catalogFoodId != null
        ? foodLogKeyForCatalogId(cfg.catalogFoodId!)
        : (cfg.customFoodId != null
              ? foodLogKeyForCustomId(cfg.customFoodId!)
              : foodLogKeyForName(cfg.displayName));
    if (cfg.catalogFoodId != null) {
      final catalog = context.read<OpenNutritionCatalog>();
      await catalog.byId(cfg.catalogFoodId!);
    }
    final pref = await repo.foodPrefByKey(key);
    if (!mounted) return;
    setState(() {
      _foodKey = key;
      _savedServingAmount = pref?.savedServingAmount;
      _savedServingUnit = pref?.savedServingUnit;
      // When no explicit initial preset was passed (i.e. fresh open) and
      // the user has a remembered preset for this food, prefer that.
      if (cfg.hasPresets &&
          cfg.initialPresetLabel == null &&
          pref?.lastServingLabel != null &&
          pref?.lastServingQty != null) {
        CatalogGroupPreset? match;
        for (final preset in cfg.presets) {
          if (preset.label == pref!.lastServingLabel) {
            match = preset;
            break;
          }
        }
        if (match != null) {
          _selectedPreset = match;
          _qty.text = _formatNumber(pref!.lastServingQty!);
          _syncGramsFromPreset();
        }
      }
      _loadingPrefs = false;
    });
  }

  String get _effectiveUnitLabel => widget.config.unitLabel;

  @override
  void dispose() {
    _grams.dispose();
    _qty.dispose();
    super.dispose();
  }

  static String _formatNumber(double n) =>
      n == n.roundToDouble() ? n.round().toString() : n.toStringAsFixed(1);

  double? _parseGrams() {
    final err = validatePositiveDouble(
      _grams.text,
      fieldLabel: 'Amount',
      max: 100000,
    );
    if (err != null) return null;
    return parseDouble(_grams.text);
  }

  double? _parseQty() {
    final err = validatePositiveDouble(
      _qty.text,
      fieldLabel: 'Servings',
      max: 1000,
    );
    if (err != null) return null;
    return parseDouble(_qty.text);
  }

  /// Resolve the effective grams for the current mode. Returns null if
  /// the input is invalid.
  double? _effectiveGrams() {
    if (_mode == _AmountMode.grams) {
      return _parseGrams();
    }
    final preset = _selectedPreset;
    final qty = _parseQty();
    if (preset == null || qty == null) return null;
    return preset.grams * qty;
  }

  void _syncGramsFromPreset() {
    final preset = _selectedPreset;
    final qty = parseDouble(_qty.text);
    if (preset == null || qty == null) return;
    _grams.text = _formatNumber(preset.grams * qty);
  }

  ScaledNutrition _scale(double grams) => scaleFromPer100g(
    grams: grams,
    kcalPer100g: widget.config.kcalPer100g,
    proteinPer100g: widget.config.proteinPer100g,
    carbsPer100g: widget.config.carbsPer100g,
    fatPer100g: widget.config.fatPer100g,
  );

  Future<void> _saveServing() async {
    final key = _foodKey;
    if (key == null) return;
    final amount = _effectiveGrams();
    if (amount == null) return;
    final unit = _effectiveUnitLabel;
    final repo = context.read<CalTrackRepository>();
    await repo.setSavedServing(foodKey: key, amount: amount, unit: unit);
    if (!mounted) return;
    setState(() {
      _savedServingAmount = amount;
      _savedServingUnit = unit;
    });
    context.showAppSnackBar('Saved serving: ${amount.round()} $unit');
  }

  void _applyServing() {
    final a = _savedServingAmount;
    if (a == null) return;
    setState(() {
      _mode = _AmountMode.grams;
      _grams.text = _formatNumber(a);
    });
  }

  void _setMode(_AmountMode next) {
    if (next == _mode) return;
    if (next == _AmountMode.servings) {
      final preset = _selectedPreset;
      final grams = _parseGrams();
      if (preset != null && preset.grams > 0 && grams != null) {
        final qty = grams / preset.grams;
        _qty.text = _formatNumber(
          qty <= 0 ? 1 : ((qty * 4).round() / 4).clamp(0.25, 100),
        );
      } else if (_qty.text.trim().isEmpty) {
        _qty.text = '1';
      }
    } else {
      // Moving Grams -> Servings-unaware field; carry the current
      // preset-computed grams forward so the user doesn't lose their
      // portion.
      final g = _effectiveGrams();
      if (g != null) _grams.text = _formatNumber(g);
    }
    setState(() => _mode = next);
  }

  void _pickPreset(CatalogGroupPreset? preset) {
    if (preset == null) return;
    setState(() {
      _selectedPreset = preset;
      if (_qty.text.trim().isEmpty) _qty.text = '1';
      _syncGramsFromPreset();
    });
  }

  void _bumpQty(double delta) {
    final current = parseDouble(_qty.text) ?? 1;
    final next = (current + delta).clamp(0.25, 1000.0);
    // Round to a nice 0.25 step so increments stay predictable.
    final snapped = (next * 4).round() / 4;
    setState(() {
      _qty.text = _formatNumber(snapped);
      _syncGramsFromPreset();
    });
  }

  Future<void> _save() async {
    final grams = _effectiveGrams();
    if (grams == null) return;

    if (widget.config.onSelectIngredient != null) {
      String label;
      if (_mode == _AmountMode.servings && _selectedPreset != null) {
        final qtyVal = parseDouble(_qty.text);
        if (qtyVal != null) {
          final isInteger = qtyVal == qtyVal.roundToDouble();
          final formattedQty = isInteger ? qtyVal.round().toString() : qtyVal.toStringAsFixed(1);
          label = '$formattedQty × ${_selectedPreset!.label}';
        } else {
          label = _selectedPreset!.label;
        }
      } else {
        final isLiquid = widget.config.unitLabel == 'ml';
        label = '${grams.round()}${isLiquid ? 'ml' : 'g'}';
      }
      widget.config.onSelectIngredient!(grams, label);
      Navigator.of(context).pop(FoodEntryAction.added);
      return;
    }

    final scaled = _scale(grams);
    final factor = grams / 100.0;
    final sugar = widget.config.sugarPer100g * factor;
    final fiber = widget.config.fiberPer100g * factor;
    final scaledExtra = widget.config.extraNutrientsPer100g.map(
      (k, v) => MapEntry(k, v * factor),
    );
    final extraJson = encodeExtraNutrients(scaledExtra);

    final repo = context.read<CalTrackRepository>();
    setState(() => _busy = true);
    try {
      if (widget.config.isEdit) {
        await repo.updateFoodLog(
          id: widget.config.editingEntryId!,
          grams: grams,
          kcal: scaled.kcal,
          proteinG: scaled.proteinG,
          carbsG: scaled.carbsG,
          sugarG: sugar,
          fiberG: fiber,
          fatG: scaled.fatG,
          mealPeriod: _selectedPeriod,
          extraNutrients: extraJson,
        );
        await _persistLastServing();
        if (!mounted) return;
        Navigator.of(context).pop(FoodEntryAction.updated);
      } else {
        await repo.addFoodLogReturnId(
          source: widget.config.source,
          catalogFoodId: widget.config.catalogFoodId,
          customFoodId: widget.config.customFoodId,
          displayName: widget.config.displayName,
          grams: grams,
          kcal: scaled.kcal,
          proteinG: scaled.proteinG,
          carbsG: scaled.carbsG,
          sugarG: sugar,
          fiberG: fiber,
          fatG: scaled.fatG,
          loggedAt: widget.config.loggedAtForEdit,
          mealPeriod: _selectedPeriod,
          extraNutrients: extraJson,
        );
        await _persistLastServing();
        if (!mounted) return;
        Navigator.of(context).pop(FoodEntryAction.added);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _persistLastServing() async {
    final key = _foodKey;
    if (key == null) return;
    final repo = context.read<CalTrackRepository>();
    if (_mode == _AmountMode.servings) {
      final preset = _selectedPreset;
      final qty = _parseQty();
      if (preset != null && qty != null) {
        await repo.setLastUsedServing(
          foodKey: key,
          label: preset.label,
          quantity: qty,
        );
        return;
      }
    }
    // Switched to grams or invalid preset state -> clear remembered preset.
    await repo.setLastUsedServing(foodKey: key, label: null, quantity: null);
  }

  Future<void> _delete() async {
    final id = widget.config.editingEntryId;
    if (id == null) return;
    setState(() => _busy = true);
    try {
      await context.read<CalTrackRepository>().deleteFoodLog(id);
      if (!mounted) return;
      Navigator.of(context).pop(FoodEntryAction.deleted);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cfg = widget.config;
    final grams = _effectiveGrams() ?? 0;
    final scaled = _scale(grams);
    final unitLabel = _effectiveUnitLabel;
    final amountError = _mode == _AmountMode.grams
        ? validatePositiveDouble(_grams.text, fieldLabel: 'Amount', max: 100000)
        : validatePositiveDouble(_qty.text, fieldLabel: 'Servings', max: 1000);
    final hasPresets = cfg.hasPresets;
    final saveEnabled = !_busy && _effectiveGrams() != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
        left: 20,
        right: 20,
        top: 4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(cfg.displayName, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        cfg.subtitle ??
                            '${cfg.kcalPer100g.round()} kcal · '
                                'P ${cfg.proteinPer100g.round()} / '
                                'C ${cfg.carbsPer100g.round()} / '
                                'F ${cfg.fatPer100g.round()} g per 100 g',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hasPresets) ...[
              SegmentedButton<_AmountMode>(
                segments: const [
                  ButtonSegment(
                    value: _AmountMode.servings,
                    label: Text('Servings'),
                    icon: Icon(Icons.restaurant_menu),
                  ),
                  ButtonSegment(
                    value: _AmountMode.grams,
                    label: Text('Grams'),
                    icon: Icon(Icons.scale_outlined),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _busy ? null : (s) => _setMode(s.first),
              ),
              const SizedBox(height: 12),
            ],
            if (hasPresets && _mode == _AmountMode.servings)
              _ServingsInput(
                presets: cfg.presets,
                selected: _selectedPreset,
                qtyController: _qty,
                onPresetChanged: _busy ? null : _pickPreset,
                onQtyChanged: (_) => setState(_syncGramsFromPreset),
                onBump: _busy ? null : _bumpQty,
                errorText: amountError,
                unitLabel: unitLabel,
                showPresetPicker: cfg.showPresetPicker,
              )
            else
              TextField(
                controller: _grams,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                autofocus: !cfg.isEdit,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Amount',
                  suffixText: unitLabel,
                  errorText: amountError,
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
            if (_mode == _AmountMode.grams) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final g in const [25.0, 50.0, 100.0, 200.0, 250.0])
                    ActionChip(
                      label: Text('${g.round()} $unitLabel'),
                      onPressed: () {
                        setState(() {
                          _grams.text = _formatNumber(g);
                        });
                      },
                    ),
                ],
              ),
            ],
            if (!_loadingPrefs) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Serving', style: theme.textTheme.titleSmall),
                  if (_savedServingAmount != null && _savedServingUnit != null)
                    ActionChip(
                      avatar: const Icon(Icons.restaurant_menu, size: 18),
                      label: Text(
                        '1 serving (${_savedServingAmount!.round()} ${_savedServingUnit!})',
                      ),
                      onPressed: _applyServing,
                    ),
                  ActionChip(
                    avatar: const Icon(Icons.bookmark_add_outlined, size: 18),
                    label: const Text('Save current as serving'),
                    onPressed: _busy || _effectiveGrams() == null
                        ? null
                        : _saveServing,
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            _NutritionPreviewCard(scaled: scaled, grams: grams),
            if (cfg.showOpenNutritionAttribution) ...[
              const SizedBox(height: 12),
              const OpenNutritionAttribution(),
            ],
            if (cfg.onSelectIngredient == null) ...[
              const SizedBox(height: 16),
              MealPeriodPicker(
                selected: _selectedPeriod,
                onChanged: (p) => setState(() => _selectedPeriod = p),
                enabled: !_busy,
              ),
            ],
            const SizedBox(height: 20),
            if (cfg.isEdit)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : _delete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                        side: BorderSide(color: theme.colorScheme.error),
                      ),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: saveEnabled ? _save : null,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              )
            else
              FilledButton.icon(
                onPressed: saveEnabled ? _save : null,
                icon: const Icon(Icons.add),
                label: Text(widget.config.onSelectIngredient != null ? 'Add to recipe' : 'Add to diary'),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Servings" mode controls: preset dropdown + qty stepper + live summary.
class _ServingsInput extends StatelessWidget {
  const _ServingsInput({
    required this.presets,
    required this.selected,
    required this.qtyController,
    required this.onPresetChanged,
    required this.onQtyChanged,
    required this.onBump,
    required this.errorText,
    required this.unitLabel,
    this.showPresetPicker = true,
  });

  final List<CatalogGroupPreset> presets;
  final CatalogGroupPreset? selected;
  final TextEditingController qtyController;
  final ValueChanged<CatalogGroupPreset?>? onPresetChanged;
  final ValueChanged<String> onQtyChanged;
  final ValueChanged<double>? onBump;
  final String? errorText;
  final String unitLabel;
  final bool showPresetPicker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final qty = double.tryParse(qtyController.text.replaceAll(',', '.'));
    final preset = selected;
    final totalGrams = (preset != null && qty != null && qty > 0)
        ? preset.grams * qty
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showPresetPicker)
          DropdownButtonFormField<CatalogGroupPreset>(
            initialValue: preset,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Serving size',
            ),
            items: [
              for (final p in presets)
                DropdownMenuItem(
                  value: p,
                  child: Text('${p.label} · ${_formatGrams(p.grams)} g'),
                ),
            ],
            onChanged: onPresetChanged,
          )
        else if (preset != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                const Icon(Icons.restaurant, size: 18),
                const SizedBox(width: 6),
                Text(
                  '1 serving = ${_formatGrams(preset.grams)} $unitLabel',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        if (showPresetPicker) const SizedBox(height: 12),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: onBump == null ? null : () => onBump!(-0.5),
              icon: const Icon(Icons.remove),
              tooltip: 'Decrease',
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: qtyController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textAlign: TextAlign.center,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Servings',
                  errorText: errorText,
                ),
                onChanged: onQtyChanged,
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: onBump == null ? null : () => onBump!(0.5),
              icon: const Icon(Icons.add),
              tooltip: 'Increase',
            ),
          ],
        ),
        if (totalGrams != null) ...[
          const SizedBox(height: 8),
          Text(
            '${_formatQty(qty!)} × ${preset!.label} = '
            '${_formatGrams(totalGrams)} $unitLabel',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  static String _formatGrams(double g) =>
      g == g.roundToDouble() ? g.round().toString() : g.toStringAsFixed(1);
  static String _formatQty(double q) =>
      q == q.roundToDouble() ? q.round().toString() : q.toStringAsFixed(2);
}

class _NutritionPreviewCard extends StatelessWidget {
  const _NutritionPreviewCard({required this.scaled, required this.grams});

  final ScaledNutrition scaled;
  final double grams;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final pKcal = scaled.proteinG * 4;
    final cKcal = scaled.carbsG * 4;
    final fKcal = scaled.fatG * 9;
    final macroKcal = pKcal + cKcal + fKcal;
    final shareDenom = macroKcal > 0 ? macroKcal : 1.0;

    return Card(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '${scaled.kcal.round()} kcal',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'in ${grams.toStringAsFixed(grams == grams.roundToDouble() ? 0 : 1)} g',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _MacroComposition(
              label: 'Protein',
              grams: scaled.proteinG,
              kcalShare: pKcal / shareDenom,
              color: scheme.primary,
            ),
            _MacroComposition(
              label: 'Carbs',
              grams: scaled.carbsG,
              kcalShare: cKcal / shareDenom,
              color: scheme.secondary,
            ),
            _MacroComposition(
              label: 'Fat',
              grams: scaled.fatG,
              kcalShare: fKcal / shareDenom,
              color: scheme.tertiary,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroComposition extends StatelessWidget {
  const _MacroComposition({
    required this.label,
    required this.grams,
    required this.kcalShare,
    required this.color,
    this.isLast = false,
  });

  final String label;
  final double grams;
  final double kcalShare;
  final Color color;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (kcalShare * 100).clamp(0, 100).round();

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 64,
            child: Text(label, style: theme.textTheme.bodyMedium),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: kcalShare.clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 56,
            child: Text(
              '${grams.round()} g',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              '$pct%',
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Row of chips to select a meal period for the entry.
class MealPeriodPicker extends StatelessWidget {
  const MealPeriodPicker({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final MealPeriod? selected;
  final ValueChanged<MealPeriod?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meal period', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final period in MealPeriod.values)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      period.name[0].toUpperCase() + period.name.substring(1),
                    ),
                    selected: selected == period,
                    onSelected: enabled ? (_) => onChanged(period) : null,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Toggle to mark the entry as planned (pre-logged for future).

import 'dart:async';
import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/core/nutrients.dart';
import 'package:caltrack/core/spacing.dart';
import 'package:caltrack/core/validation.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/features/food/add_custom_food_screen.dart';
import 'package:caltrack/features/food/food_entry_sheet.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MealIngredient {
  MealIngredient({
    required this.displayName,
    required this.grams,
    required this.servingLabel,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.sugarPer100g,
    required this.fiberPer100g,
    required this.extraNutrientsPer100g,
    required this.foodSource,
    this.catalogFoodId,
    this.customFoodId,
  });

  final String displayName;
  double grams;
  final String servingLabel; // e.g. "1 cup", "1 slice", "100g"
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double sugarPer100g;
  final double fiberPer100g;
  final Map<NutrientKey, double> extraNutrientsPer100g;
  final String foodSource;
  final String? catalogFoodId;
  final int? customFoodId;

  double get kcal => kcalPer100g * (grams / 100.0);
  double get proteinG => proteinPer100g * (grams / 100.0);
  double get carbsG => carbsPer100g * (grams / 100.0);
  double get fatG => fatPer100g * (grams / 100.0);
  double get sugarG => sugarPer100g * (grams / 100.0);
  double get fiberG => fiberPer100g * (grams / 100.0);
  Map<NutrientKey, double> get extraNutrients => extraNutrientsPer100g.map(
    (k, v) => MapEntry(k, v * (grams / 100.0)),
  );
}

class CreateMealScreen extends StatefulWidget {
  const CreateMealScreen({super.key, this.existingMeal});

  final Meal? existingMeal;

  @override
  State<CreateMealScreen> createState() => _CreateMealScreenState();
}

class _CreateMealScreenState extends State<CreateMealScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _servingCount;
  late final TextEditingController _servingLabel;
  final List<MealIngredient> _ingredients = [];
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existingMeal?.name ?? '');
    _description = TextEditingController(text: widget.existingMeal?.description ?? '');
    _servingCount = TextEditingController(text: widget.existingMeal?.servingCount.toString() ?? '1');
    _servingLabel = TextEditingController(text: widget.existingMeal?.servingLabel ?? 'serving');
    _servingCount.addListener(() {
      if (mounted) setState(() {});
    });
    _servingLabel.addListener(() {
      if (mounted) setState(() {});
    });
    if (widget.existingMeal != null) {
      _loadExistingIngredients();
    }
  }

  Future<void> _loadExistingIngredients() async {
    final repo = context.read<CalTrackRepository>();
    final items = await repo.mealItemsForMeal(widget.existingMeal!.id);
    if (!mounted) return;
    setState(() {
      for (final item in items) {
        final double denom = item.grams <= 0 ? 1.0 : item.grams;
        final factor = 100.0 / denom;
        final decodedExtra = decodeExtraNutrients(item.extraNutrients);
        final extra100 = decodedExtra.map((k, v) => MapEntry(k, v * factor));
        _ingredients.add(
          MealIngredient(
            displayName: item.displayName,
            grams: item.grams,
            servingLabel: '${item.grams.toStringAsFixed(0)}g',
            kcalPer100g: item.kcal * factor,
            proteinPer100g: item.proteinG * factor,
            carbsPer100g: item.carbsG * factor,
            fatPer100g: item.fatG * factor,
            sugarPer100g: item.sugarG * factor,
            fiberPer100g: item.fiberG * factor,
            extraNutrientsPer100g: extra100,
            foodSource: item.foodSource,
            catalogFoodId: item.catalogFoodId,
            customFoodId: item.customFoodId,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _servingCount.dispose();
    _servingLabel.dispose();
    super.dispose();
  }

  double get _totalGrams => _ingredients.fold(0.0, (s, i) => s + i.grams);
  double get _totalKcal => _ingredients.fold(0.0, (s, i) => s + i.kcal);
  double get _totalProtein => _ingredients.fold(0.0, (s, i) => s + i.proteinG);
  double get _totalCarbs => _ingredients.fold(0.0, (s, i) => s + i.carbsG);
  double get _totalFat => _ingredients.fold(0.0, (s, i) => s + i.fatG);
  double get _totalSugar => _ingredients.fold(0.0, (s, i) => s + i.sugarG);
  double get _totalFiber => _ingredients.fold(0.0, (s, i) => s + i.fiberG);

  Map<NutrientKey, double> get _totalExtra {
    final out = <NutrientKey, double>{};
    for (final ing in _ingredients) {
      for (final entry in ing.extraNutrients.entries) {
        out[entry.key] = (out[entry.key] ?? 0) + entry.value;
      }
    }
    return out;
  }

  void _addIngredient(MealIngredient ing) => setState(() => _ingredients.add(ing));

  Future<void> _editServing(int index) async {
    final ing = _ingredients[index];
    final ctrl = TextEditingController(text: ing.grams.toString());
    final labelCtrl = TextEditingController(text: ing.servingLabel);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ing.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Serving label', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(labelText: 'Weight (g)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final val = parseDouble(ctrl.text);
      if (val != null && val > 0) {
        setState(() {
          ing.grams = val;
        });
        if (labelCtrl.text.isNotEmpty) {
          // mutable field — this is fine
        }
      }
    }
  }

  Future<void> _saveMeal() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      context.showAppSnackBar('Please add at least one ingredient.');
      return;
    }
    setState(() => _busy = true);
    final repo = context.read<CalTrackRepository>();

    final List<MealItemsCompanion> companions = [];
    for (final ing in _ingredients) {
      companions.add(
        MealItemsCompanion.insert(
          mealId: 0,
          foodSource: ing.foodSource,
          catalogFoodId: Value(ing.catalogFoodId),
          customFoodId: Value(ing.customFoodId),
          displayName: ing.displayName,
          grams: ing.grams,
          kcal: ing.kcal,
          proteinG: ing.proteinG,
          carbsG: ing.carbsG,
          fatG: ing.fatG,
          sugarG: ing.sugarG,
          fiberG: ing.fiberG,
          extraNutrients: Value(encodeExtraNutrients(ing.extraNutrients)),
        ),
      );
    }

    final count = int.tryParse(_servingCount.text) ?? 1;
    final label = _servingLabel.text.trim().isEmpty ? 'serving' : _servingLabel.text.trim();

    try {
      await repo.upsertMeal(
        id: widget.existingMeal?.id,
        name: _name.text,
        description: _description.text.isEmpty ? null : _description.text,
        calories: _totalKcal,
        proteinG: _totalProtein,
        carbsG: _totalCarbs,
        fatG: _totalFat,
        sugarG: _totalSugar,
        fiberG: _totalFiber,
        extraNutrients: encodeExtraNutrients(_totalExtra),
        totalGrams: _totalGrams,
        servingCount: count,
        servingLabel: label,
        items: companions,
      );
      if (!mounted) return;
      context.showAppSnackBar(widget.existingMeal != null ? 'MealPrep updated.' : 'MealPrep created.');
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showIngredientPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _IngredientPicker(
          onSelected: (ing) {
            Navigator.pop(context);
            _addIngredient(ing);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final totalG = _totalGrams;

    return Scaffold(
      appBar: AppBar(title: Text(widget.existingMeal != null ? 'Edit MealPrep' : 'Create MealPrep')),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(Spacing.md),
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'MealPrep Name', border: OutlineInputBorder()),
                    validator: (v) => v == null || v.trim().isEmpty ? 'MealPrep name is required.' : null,
                  ),
                  const SizedBox(height: Spacing.md),
                  TextFormField(
                    controller: _description,
                    decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: Spacing.md),
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: TextFormField(
                          controller: _servingCount,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: 'Servings',
                            border: OutlineInputBorder(),
                            helperText: 'How many servings the meal makes',
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            final num = int.tryParse(v);
                            if (num == null || num < 1) return 'Must be >= 1';
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _servingLabel,
                          decoration: const InputDecoration(
                            labelText: 'Serving Label',
                            border: OutlineInputBorder(),
                            helperText: 'e.g. serving, bowl, plate',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.lg),

                  // Nutrition summary card
                  Card(
                    color: t.colorScheme.surfaceContainerLow,
                    child: Padding(
                      padding: const EdgeInsets.all(Spacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text('Recipe Totals', style: t.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
                              if (totalG > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: t.colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('Total ${totalG.round()}g', style: t.textTheme.labelMedium?.copyWith(color: t.colorScheme.primary, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: Spacing.sm),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _Stat(label: 'Calories', value: '${_totalKcal.round()} kcal'),
                              _Stat(label: 'Protein', value: '${_totalProtein.toStringAsFixed(1)}g'),
                              _Stat(label: 'Carbs', value: '${_totalCarbs.toStringAsFixed(1)}g'),
                              _Stat(label: 'Fat', value: '${_totalFat.toStringAsFixed(1)}g'),
                            ],
                          ),
                          if (totalG > 0) ...[
                            const SizedBox(height: Spacing.md),
                            const Divider(height: 1),
                            const SizedBox(height: Spacing.md),
                            Builder(
                              builder: (context) {
                                final count = int.tryParse(_servingCount.text) ?? 1;
                                final divisor = count <= 0 ? 1 : count;
                                final label = _servingLabel.text.trim().isEmpty ? 'serving' : _servingLabel.text.trim();
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Per-Serving Estimate (1 $label)',
                                      style: t.textTheme.labelMedium?.copyWith(
                                        color: t.colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: Spacing.sm),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _Stat(label: 'Weight', value: '${(totalG / divisor).round()}g'),
                                        _Stat(label: 'Calories', value: '${(_totalKcal / divisor).round()} kcal'),
                                        _Stat(label: 'Protein', value: '${(_totalProtein / divisor).toStringAsFixed(1)}g'),
                                        _Stat(label: 'Carbs', value: '${(_totalCarbs / divisor).toStringAsFixed(1)}g'),
                                        _Stat(label: 'Fat', value: '${(_totalFat / divisor).toStringAsFixed(1)}g'),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: Spacing.lg),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Ingredients', style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      FilledButton.tonalIcon(
                        onPressed: _showIngredientPicker,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                  const SizedBox(height: Spacing.xs),

                  if (_ingredients.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No ingredients added yet.', style: t.textTheme.bodyMedium?.copyWith(color: t.colorScheme.onSurfaceVariant)),
                      ),
                    )
                  else
                    ..._ingredients.asMap().entries.map((entry) {
                      final i = entry.key;
                      final ing = entry.value;
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: t.colorScheme.secondaryContainer,
                            radius: 18,
                            child: Text(
                              ing.displayName.isNotEmpty ? ing.displayName[0].toUpperCase() : '?',
                              style: TextStyle(fontWeight: FontWeight.bold, color: t.colorScheme.onSecondaryContainer, fontSize: 14),
                            ),
                          ),
                          title: Text(ing.displayName, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('${ing.servingLabel} · ${ing.kcal.round()} kcal'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 20),
                                tooltip: 'Edit serving',
                                onPressed: () => _editServing(i),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, size: 20),
                                tooltip: 'Remove',
                                onPressed: () => setState(() => _ingredients.removeAt(i)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Spacing.md),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _saveMeal,
                  child: _busy ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save MealPrep'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Column(children: [
      Text(label, style: t.textTheme.labelSmall?.copyWith(color: t.colorScheme.onSurfaceVariant)),
      const SizedBox(height: 2),
      Text(value, style: t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Full-screen ingredient picker
// ---------------------------------------------------------------------------

class _IngredientPicker extends StatefulWidget {
  const _IngredientPicker({required this.onSelected});
  final ValueChanged<MealIngredient> onSelected;
  @override
  State<_IngredientPicker> createState() => _IngredientPickerState();
}

class _IngredientPickerState extends State<_IngredientPicker> {
  final _search = TextEditingController();
  Timer? _debounce;
  List<CatalogFood> _results = [];
  List<CustomFood> _customResults = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    final result = await context.push<Object?>('/scan-barcode');
    if (!mounted || result == null) return;
    if (result is CatalogFood) {
      await _pickCatalogFood(result);
    } else if (result is CustomFood) {
      await _pickCustomFood(result);
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _search.text.trim();
    if (q.length < 2) { setState(() { _results = []; _customResults = []; }); return; }
    _debounce = Timer(const Duration(milliseconds: 260), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    if (!mounted) return;
    setState(() => _searching = true);
    try {
      final (catRes, custRes) = await (
        context.read<OpenNutritionCatalog>().search(q, limit: 12),
        context.read<CalTrackRepository>().searchCustomFoods(q, limit: 12),
      ).wait;
      if (!mounted) return;
      // Boost recently selected items to the top
      setState(() {
        _results = _boostRecent(catRes);
        _customResults = _boostRecentCust(custRes);
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  List<CatalogFood> _boostRecent(List<CatalogFood> foods) {
    // Simply return — the rank by frequency already handles this in log_food_screen
    return foods;
  }
  List<CustomFood> _boostRecentCust(List<CustomFood> foods) => foods;

  Future<void> _pickCatalogFood(CatalogFood food) async {
    final catalog = context.read<OpenNutritionCatalog>();
    final group = await catalog.groupForFood(food.id);
    if (!mounted) return;
    final canonical = (group != null && group.canonicalFoodId != food.id)
        ? await catalog.byId(group.canonicalFoodId) ?? food
        : food;
    if (!mounted) return;

    final displayName = group?.label ?? canonical.name;
    final presets = group?.presets ?? const <CatalogGroupPreset>[];
    final defaultPreset = group?.defaultPreset;
    final resolved = defaultPreset?.grams ?? 100.0;

    await showFoodEntrySheet(
      context,
      FoodEntrySheetConfig(
        displayName: displayName,
        source: 'opennutrition',
        catalogFoodId: canonical.id,
        kcalPer100g: canonical.kcalPer100g,
        proteinPer100g: canonical.proteinPer100g,
        carbsPer100g: canonical.carbsPer100g,
        sugarPer100g: canonical.sugarPer100g,
        fiberPer100g: canonical.fiberPer100g,
        fatPer100g: canonical.fatPer100g,
        initialGrams: resolved,
        showOpenNutritionAttribution: true,
        presets: presets,
        initialPresetLabel: presets.isNotEmpty ? presets.first.label : null,
        showPresetPicker: presets.isNotEmpty,
        onSelectIngredient: (grams, label) {
          widget.onSelected(MealIngredient(
            displayName: displayName,
            grams: grams,
            servingLabel: label,
            kcalPer100g: canonical.kcalPer100g,
            proteinPer100g: canonical.proteinPer100g,
            carbsPer100g: canonical.carbsPer100g,
            fatPer100g: canonical.fatPer100g,
            sugarPer100g: canonical.sugarPer100g,
            fiberPer100g: canonical.fiberPer100g,
            extraNutrientsPer100g: const {},
            foodSource: 'opennutrition',
            catalogFoodId: canonical.id,
          ));
        },
      ),
    );
  }

  Future<void> _pickCustomFood(CustomFood food) async {
    final repo = context.read<CalTrackRepository>();
    final servings = await repo.customFoodServings(food.id);
    if (!mounted) return;
    final presets = repo.presetsFromServings(servings, food.id);

    final serving = food.servingSize;
    final factor = serving > 0 ? 100.0 / serving : 1.0;
    final unit = ServingUnit.values.byName(food.servingUnit);

    final resolvedPresets = presets.isNotEmpty
        ? presets
        : (serving > 0
            ? [CatalogGroupPreset(foodId: 'custom:${food.id}', label: '1 serving', grams: serving, isDefault: true, sortOrder: 0)]
            : const <CatalogGroupPreset>[]);

    await showFoodEntrySheet(
      context,
      FoodEntrySheetConfig(
        displayName: food.name,
        source: 'custom',
        customFoodId: food.id,
        kcalPer100g: food.calories * factor,
        proteinPer100g: food.proteinG * factor,
        carbsPer100g: food.carbsG * factor,
        sugarPer100g: food.sugarG * factor,
        fiberPer100g: food.fiberG * factor,
        fatPer100g: food.fatG * factor,
        initialGrams: serving > 0 ? serving : 100.0,
        subtitle: food.brand,
        unitLabel: unit.name,
        presets: resolvedPresets,
        initialPresetLabel: resolvedPresets.isNotEmpty ? resolvedPresets.first.label : null,
        showPresetPicker: resolvedPresets.isNotEmpty,
        onSelectIngredient: (grams, label) {
          final extra = decodeExtraNutrients(food.extraNutrients);
          final extra100 = extra.map((k, v) => MapEntry(k, v * factor));
          widget.onSelected(MealIngredient(
            displayName: food.name,
            grams: grams,
            servingLabel: label,
            kcalPer100g: food.calories * factor,
            proteinPer100g: food.proteinG * factor,
            carbsPer100g: food.carbsG * factor,
            fatPer100g: food.fatG * factor,
            sugarPer100g: food.sugarG * factor,
            fiberPer100g: food.fiberG * factor,
            extraNutrientsPer100g: extra100,
            foodSource: 'custom',
            customFoodId: food.id,
          ));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Ingredient'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: _buildSearch(t),
    );
  }

  Widget _buildSearch(ThemeData t) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextFormField(
            controller: _search,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Search ingredients...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searching)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    tooltip: 'Scan barcode',
                    onPressed: _scanBarcode,
                  ),
                ],
              ),
              border: const OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: _searching
              ? const Center(child: CircularProgressIndicator())
              : _results.isEmpty && _customResults.isEmpty
                  ? const Center(child: Text('Search for foods to add.'))
                  : ListView(
                      children: [
                        if (_customResults.isNotEmpty) ...[
                          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text('My Foods', style: t.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: t.colorScheme.primary))),
                          ..._customResults.map((f) => ListTile(
                            leading: CircleAvatar(backgroundColor: t.colorScheme.secondaryContainer, child: Text(f.name[0].toUpperCase(), style: TextStyle(color: t.colorScheme.onSecondaryContainer, fontWeight: FontWeight.bold))),
                            title: Text(f.name),
                            subtitle: Text('${f.calories.round()} kcal per ${f.servingSize.round()}${f.servingUnit}'),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              tooltip: 'Edit custom food',
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => AddCustomFoodScreen(existingFood: f),
                                  ),
                                );
                                if (mounted) {
                                  _runSearch(_search.text.trim());
                                }
                              },
                            ),
                            onTap: () => _pickCustomFood(f),
                          )),
                        ],
                        if (_results.isNotEmpty) ...[
                          Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 4), child: Text('Catalog', style: t.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold, color: t.colorScheme.tertiary))),
                          ..._results.map((f) => ListTile(
                            title: Text(f.name),
                            subtitle: Text('${f.kcalPer100g.round()} kcal/100g'),
                            onTap: () => _pickCatalogFood(f),
                          )),
                        ],
                      ],
                    ),
        ),
      ],
    );
  }
}

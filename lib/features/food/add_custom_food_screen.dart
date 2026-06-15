import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/core/nutrients.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/core/validation.dart';
import 'package:caltrack/features/food/food_entry_sheet.dart';
import 'package:caltrack/features/food/nutrition_label_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

enum _UnsavedAction { save, discard, cancel }

class AddCustomFoodScreen extends StatefulWidget {
  const AddCustomFoodScreen({
    super.key,
    this.initialBarcode,
    this.existingFood,
    this.loggedAtForEdit,
  });

  final String? initialBarcode;

  /// When non-null, the screen is in **edit mode** for this custom food.
  final CustomFood? existingFood;

  /// Timestamp used when the user taps "Save & log" from an alternate-day
  /// [LogFoodScreen]. Null defaults to the current time.
  final DateTime? loggedAtForEdit;

  bool get isEdit => existingFood != null;

  @override
  State<AddCustomFoodScreen> createState() => _AddCustomFoodScreenState();
}

class _AddCustomFoodScreenState extends State<AddCustomFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name;
  late final TextEditingController _brand;
  late final TextEditingController _barcode;

  late final TextEditingController _servingSize;
  late ServingUnit _unit;

  late final TextEditingController _calories;
  late final TextEditingController _fat;
  late final TextEditingController _saturatedFat;
  late final TextEditingController _transFat;
  late final TextEditingController _cholesterol;
  late final TextEditingController _sodium;
  late final TextEditingController _carbs;
  late final TextEditingController _sugar;
  late final TextEditingController _addedSugars;
  late final TextEditingController _fiber;
  late final TextEditingController _protein;
  late final TextEditingController _vitaminD;
  late final TextEditingController _calcium;
  late final TextEditingController _iron;
  late final TextEditingController _potassium;

  final List<_ServingDraft> _additionalServings = [];

  bool _busy = false;
  int? _savedId;
  Map<String, Object?>? _originalSnapshot;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingFood;
    _name = TextEditingController(text: existing?.name ?? '');
    _brand = TextEditingController(text: existing?.brand ?? '');
    _barcode = TextEditingController(
      text: existing?.barcode ?? widget.initialBarcode ?? '',
    );
    _servingSize = TextEditingController(
      text: existing?.servingSize.toString() ?? '100',
    );
    _unit = existing != null
        ? ServingUnit.values.firstWhere(
            (u) => u.name == existing.servingUnit,
            orElse: () => ServingUnit.g,
          )
        : ServingUnit.g;
    _calories = TextEditingController(text: existing?.calories.toString() ?? '');
    _fat = TextEditingController(text: existing?.fatG.toString() ?? '');
    _carbs = TextEditingController(text: existing?.carbsG.toString() ?? '');
    _sugar = TextEditingController(text: existing?.sugarG.toString() ?? '');
    _fiber = TextEditingController(text: existing?.fiberG.toString() ?? '');
    _protein = TextEditingController(text: existing?.proteinG.toString() ?? '');

    final extra = decodeExtraNutrients(existing?.extraNutrients);
    _saturatedFat = TextEditingController(text: extra[NutrientKey.saturatedFatG]?.toString() ?? '');
    _transFat = TextEditingController(text: extra[NutrientKey.transFatG]?.toString() ?? '');
    _cholesterol = TextEditingController(text: extra[NutrientKey.cholesterolMg]?.toString() ?? '');
    _sodium = TextEditingController(text: extra[NutrientKey.sodiumMg]?.toString() ?? '');
    _addedSugars = TextEditingController(text: extra[NutrientKey.addedSugarsG]?.toString() ?? '');
    _vitaminD = TextEditingController(text: extra[NutrientKey.vitaminD2D3Ug]?.toString() ?? '');
    _calcium = TextEditingController(text: extra[NutrientKey.calciumMg]?.toString() ?? '');
    _iron = TextEditingController(text: extra[NutrientKey.ironMg]?.toString() ?? '');
    _potassium = TextEditingController(text: extra[NutrientKey.potassiumMg]?.toString() ?? '');

    _savedId = existing?.id;
    _takeSnapshot();
    _loadServings();
  }

  Future<void> _loadServings() async {
    if (_savedId == null) return;
    final repo = context.read<CalTrackRepository>();
    final servings = await repo.customFoodServings(_savedId!);
    if (!mounted) return;
    setState(() {
      _additionalServings.clear();
      for (final s in servings) {
        _additionalServings.add(_ServingDraft(label: s.label, grams: s.grams, id: s.id));
      }
    });
  }

  void _takeSnapshot() {
    _originalSnapshot = {
      'name': _name.text,
      'brand': _brand.text,
      'barcode': _barcode.text,
      'servingSize': _servingSize.text,
      'unit': _unit,
      'calories': _calories.text,
      'fat': _fat.text,
      'saturatedFat': _saturatedFat.text,
      'transFat': _transFat.text,
      'cholesterol': _cholesterol.text,
      'sodium': _sodium.text,
      'carbs': _carbs.text,
      'sugar': _sugar.text,
      'addedSugars': _addedSugars.text,
      'fiber': _fiber.text,
      'protein': _protein.text,
      'vitaminD': _vitaminD.text,
      'calcium': _calcium.text,
      'iron': _iron.text,
      'potassium': _potassium.text,
    };
  }

  bool get _hasUnsavedChanges {
    if (_originalSnapshot == null) return false;
    return _name.text != _originalSnapshot!['name'] ||
        _brand.text != _originalSnapshot!['brand'] ||
        _barcode.text != _originalSnapshot!['barcode'] ||
        _servingSize.text != _originalSnapshot!['servingSize'] ||
        _unit != _originalSnapshot!['unit'] ||
        _calories.text != _originalSnapshot!['calories'] ||
        _fat.text != _originalSnapshot!['fat'] ||
        _saturatedFat.text != _originalSnapshot!['saturatedFat'] ||
        _transFat.text != _originalSnapshot!['transFat'] ||
        _cholesterol.text != _originalSnapshot!['cholesterol'] ||
        _sodium.text != _originalSnapshot!['sodium'] ||
        _carbs.text != _originalSnapshot!['carbs'] ||
        _sugar.text != _originalSnapshot!['sugar'] ||
        _addedSugars.text != _originalSnapshot!['addedSugars'] ||
        _fiber.text != _originalSnapshot!['fiber'] ||
        _protein.text != _originalSnapshot!['protein'] ||
        _vitaminD.text != _originalSnapshot!['vitaminD'] ||
        _calcium.text != _originalSnapshot!['calcium'] ||
        _iron.text != _originalSnapshot!['iron'] ||
        _potassium.text != _originalSnapshot!['potassium'];
  }

  Future<bool> _maybePop() async {
    if (!_hasUnsavedChanges) {
      Navigator.of(context).maybePop();
      return true;
    }
    final action = await showDialog<_UnsavedAction>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unsaved changes'),
        content: const Text(
          'You have unsaved changes to this food.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, _UnsavedAction.cancel),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx, _UnsavedAction.discard),
            child: const Text('Exit without saving'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, _UnsavedAction.save),
            child: const Text('Save and exit'),
          ),
        ],
      ),
    );
    switch (action) {
      case _UnsavedAction.save:
        final id = await _saveCustomFood();
        if (id != null) {
          if (!mounted) return true;
          context.showAppSnackBar('Updated.');
          Navigator.of(context).pop();
          return true;
        }
        return false;
      case _UnsavedAction.discard:
        _originalSnapshot = null;
        if (!mounted) return true;
        Navigator.of(context).pop();
        return true;
      case _UnsavedAction.cancel:
        return false;
      case null:
        return false;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _barcode.dispose();
    _servingSize.dispose();
    _calories.dispose();
    _fat.dispose();
    _saturatedFat.dispose();
    _transFat.dispose();
    _cholesterol.dispose();
    _sodium.dispose();
    _carbs.dispose();
    _sugar.dispose();
    _addedSugars.dispose();
    _fiber.dispose();
    _protein.dispose();
    _vitaminD.dispose();
    _calcium.dispose();
    _iron.dispose();
    _potassium.dispose();
    super.dispose();
  }

  static double? _parseNum(String raw, {bool allowZero = true}) {
    final v = parseDouble(raw);
    if (v == null) return null;
    if (!allowZero && v <= 0) return null;
    if (v < 0) return null;
    return v;
  }

  Future<int?> _saveCustomFood() async {
    if (!_formKey.currentState!.validate()) return null;
    final repo = context.read<CalTrackRepository>();

    final serving = _parseNum(_servingSize.text, allowZero: false)!;
    final calories = _parseNum(_calories.text)!;
    final fat = _parseNum(_fat.text)!;
    final carbs = _parseNum(_carbs.text)!;
    final sugar = _parseNum(_sugar.text)!;
    final fiber = _parseNum(_fiber.text)!;
    final protein = _parseNum(_protein.text)!;

    final extraMap = <NutrientKey, double>{};
    final sat = _parseNum(_saturatedFat.text);
    if (sat != null) extraMap[NutrientKey.saturatedFatG] = sat;
    final trans = _parseNum(_transFat.text);
    if (trans != null) extraMap[NutrientKey.transFatG] = trans;
    final chol = _parseNum(_cholesterol.text);
    if (chol != null) extraMap[NutrientKey.cholesterolMg] = chol;
    final sod = _parseNum(_sodium.text);
    if (sod != null) extraMap[NutrientKey.sodiumMg] = sod;
    final addSug = _parseNum(_addedSugars.text);
    if (addSug != null) extraMap[NutrientKey.addedSugarsG] = addSug;
    final vitD = _parseNum(_vitaminD.text);
    if (vitD != null) extraMap[NutrientKey.vitaminD2D3Ug] = vitD;
    final calc = _parseNum(_calcium.text);
    if (calc != null) extraMap[NutrientKey.calciumMg] = calc;
    final iron = _parseNum(_iron.text);
    if (iron != null) extraMap[NutrientKey.ironMg] = iron;
    final pot = _parseNum(_potassium.text);
    if (pot != null) extraMap[NutrientKey.potassiumMg] = pot;

    final extraJson = encodeExtraNutrients(extraMap);

    final defaultGrams = _parseNum(_servingSize.text) ?? 100;
    final List<CustomFoodServingsCompanion> companions = [];
    // Main serving is always the default one
    companions.add(CustomFoodServingsCompanion.insert(
      customFoodId: 0, // placeholder
      label: '1 serving',
      grams: defaultGrams,
      isDefault: const Value(true),
      sortOrder: const Value(0),
    ));
    for (var i = 0; i < _additionalServings.length; i++) {
      final s = _additionalServings[i];
      companions.add(CustomFoodServingsCompanion.insert(
        customFoodId: 0, // placeholder
        label: s.label,
        grams: s.grams,
        isDefault: const Value(false),
        sortOrder: Value(i + 1),
      ));
    }

    setState(() => _busy = true);
    try {
      final id = await repo.upsertCustomFoodWithServings(
        id: _savedId,
        name: _name.text,
        brand: _brand.text.trim().isEmpty ? null : _brand.text,
        barcode: _barcode.text.trim().isEmpty ? null : _barcode.text,
        servingSize: serving,
        servingUnit: _unit.name,
        calories: calories,
        fatG: fat,
        carbsG: carbs,
        sugarG: sugar,
        fiberG: fiber,
        proteinG: protein,
        extraNutrients: extraJson,
        servings: companions,
      );
      _savedId = id;
      _takeSnapshot();
      return id;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  (double kcal100, double p100, double c100, double s100, double fi100, double f100)
      _toPer100({
    required double servingSize,
    required double calories,
    required double protein,
    required double carbs,
    required double sugar,
    required double fiber,
    required double fat,
  }) {
    final denom = servingSize <= 0 ? 1.0 : servingSize;
    final factor = 100.0 / denom;
    return (
      calories * factor,
      protein * factor,
      carbs * factor,
      sugar * factor,
      fiber * factor,
      fat * factor,
    );
  }

  Future<void> _saveAndLog() async {
    final id = await _saveCustomFood();
    if (!mounted || id == null) return;

    final serving = _parseNum(_servingSize.text, allowZero: false)!;
    final calories = _parseNum(_calories.text)!;
    final fat = _parseNum(_fat.text)!;
    final carbs = _parseNum(_carbs.text)!;
    final sugar = _parseNum(_sugar.text)!;
    final fiber = _parseNum(_fiber.text)!;
    final protein = _parseNum(_protein.text)!;

    final (k100, p100, c100, s100, fi100, f100) = _toPer100(
      servingSize: serving,
      calories: calories,
      protein: protein,
      carbs: carbs,
      sugar: sugar,
      fiber: fiber,
      fat: fat,
    );

    final extraMap = <NutrientKey, double>{};
    final sat = _parseNum(_saturatedFat.text);
    if (sat != null) extraMap[NutrientKey.saturatedFatG] = sat;
    final trans = _parseNum(_transFat.text);
    if (trans != null) extraMap[NutrientKey.transFatG] = trans;
    final chol = _parseNum(_cholesterol.text);
    if (chol != null) extraMap[NutrientKey.cholesterolMg] = chol;
    final sod = _parseNum(_sodium.text);
    if (sod != null) extraMap[NutrientKey.sodiumMg] = sod;
    final addSug = _parseNum(_addedSugars.text);
    if (addSug != null) extraMap[NutrientKey.addedSugarsG] = addSug;
    final vitD = _parseNum(_vitaminD.text);
    if (vitD != null) extraMap[NutrientKey.vitaminD2D3Ug] = vitD;
    final calc = _parseNum(_calcium.text);
    if (calc != null) extraMap[NutrientKey.calciumMg] = calc;
    final iron = _parseNum(_iron.text);
    if (iron != null) extraMap[NutrientKey.ironMg] = iron;
    final pot = _parseNum(_potassium.text);
    if (pot != null) extraMap[NutrientKey.potassiumMg] = pot;

    final denom = serving <= 0 ? 1.0 : serving;
    final factor = 100.0 / denom;
    final extraPer100 = extraMap.map((k, v) => MapEntry(k, v * factor));

    final action = await showFoodEntrySheet(
      context,
      FoodEntrySheetConfig(
        displayName: _name.text.trim(),
        source: 'custom',
        customFoodId: id,
        kcalPer100g: k100,
        proteinPer100g: p100,
        carbsPer100g: c100,
        sugarPer100g: s100,
        fiberPer100g: fi100,
        fatPer100g: f100,
        extraNutrientsPer100g: extraPer100,
        initialGrams: serving,
        subtitle: 'Per $serving ${_unit.name}',
        unitLabel: _unit.name,
        presets: serving > 0
            ? [
                CatalogGroupPreset(
                  foodId: 'custom:$id',
                  label: 'serving',
                  grams: serving,
                  isDefault: true,
                  sortOrder: 0,
                )
              ]
            : const <CatalogGroupPreset>[],
        initialPresetLabel: serving > 0 ? 'serving' : null,
        showPresetPicker: false,
        loggedAtForEdit: widget.loggedAtForEdit,
      ),
    );
    if (!mounted) return;
    if (action == FoodEntryAction.added) {
      Navigator.of(context).maybePop();
    }
  }

  Future<void> _addServing() async {
    final labelCtrl = TextEditingController();
    final gramCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add serving'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: labelCtrl,
              decoration: const InputDecoration(labelText: 'Label (e.g. 1 cup)', border: OutlineInputBorder()),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: gramCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
              decoration: const InputDecoration(labelText: 'Weight (g)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final label = labelCtrl.text.trim();
      final grams = parseDouble(gramCtrl.text);
      if (label.isNotEmpty && grams != null && grams > 0) {
        setState(() {
          _additionalServings.add(_ServingDraft(label: label, grams: grams));
        });
      }
    }
  }

  Future<void> _scanBarcode() async {
    final scanned = await context.push<Object?>('/scan-barcode?raw=1');
    if (!mounted || scanned is! String || scanned.isEmpty) return;
    setState(() => _barcode.text = scanned);
  }

  Future<void> _scanLabel() async {
    final draft = await context.push<NutritionFactsDraft>('/scan-nutrition-label');
    if (!mounted || draft == null) return;
    if (draft.servingSize != null) {
      _servingSize.text = draft.servingSize!.toString();
    }
    if (draft.servingUnit != null) {
      _unit = draft.servingUnit!;
    }
    if (draft.calories != null) _calories.text = draft.calories!.toString();
    if (draft.fatG != null) _fat.text = draft.fatG!.toString();
    if (draft.carbsG != null) _carbs.text = draft.carbsG!.toString();
    if (draft.sugarG != null) _sugar.text = draft.sugarG!.toString();
    if (draft.fiberG != null) _fiber.text = draft.fiberG!.toString();
    if (draft.proteinG != null) _protein.text = draft.proteinG!.toString();

    // Scan sub-nutrients/extraNutrients
    final extra = draft.extraNutrients;
    if (extra.containsKey(NutrientKey.saturatedFatG)) {
      _saturatedFat.text = extra[NutrientKey.saturatedFatG]!.toString();
    }
    if (extra.containsKey(NutrientKey.transFatG)) {
      _transFat.text = extra[NutrientKey.transFatG]!.toString();
    }
    if (extra.containsKey(NutrientKey.cholesterolMg)) {
      _cholesterol.text = extra[NutrientKey.cholesterolMg]!.toString();
    }
    if (extra.containsKey(NutrientKey.sodiumMg)) {
      _sodium.text = extra[NutrientKey.sodiumMg]!.toString();
    }
    if (extra.containsKey(NutrientKey.addedSugarsG)) {
      _addedSugars.text = extra[NutrientKey.addedSugarsG]!.toString();
    }
    if (extra.containsKey(NutrientKey.vitaminD2D3Ug)) {
      _vitaminD.text = extra[NutrientKey.vitaminD2D3Ug]!.toString();
    }
    if (extra.containsKey(NutrientKey.calciumMg)) {
      _calcium.text = extra[NutrientKey.calciumMg]!.toString();
    }
    if (extra.containsKey(NutrientKey.ironMg)) {
      _iron.text = extra[NutrientKey.ironMg]!.toString();
    }
    if (extra.containsKey(NutrientKey.potassiumMg)) {
      _potassium.text = extra[NutrientKey.potassiumMg]!.toString();
    }

    setState(() {});
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete food?'),
        content: Text(
          'Delete "${_name.text.trim()}"? This cannot be undone. '
          'Existing log entries will not be affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || _savedId == null) return;
    if (!mounted) return;
    final repo = context.read<CalTrackRepository>();
    setState(() => _busy = true);
    try {
      await repo.deleteCustomFood(_savedId!);
      if (!mounted) return;
      context.showAppSnackBar('Deleted "${_name.text.trim()}".');
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEdit ? 'Edit food' : 'Add food')),
      body: PopScope(
        canPop: !_hasUnsavedChanges,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          await _maybePop();
        },
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Food name',
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Food name is required.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _brand,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Brand (optional)',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _barcode,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Barcode (optional)',
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    tooltip: 'Scan barcode',
                    onPressed: _busy ? null : _scanBarcode,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Serving', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _servingSize,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Serving size',
                      ),
                      validator: (v) {
                        return validatePositiveDouble(
                          v ?? '',
                          fieldLabel: 'Serving size',
                          min: 0.1,
                          max: 5000,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<ServingUnit>(
                    segments: const [
                      ButtonSegment(value: ServingUnit.g, label: Text('g')),
                      ButtonSegment(value: ServingUnit.ml, label: Text('ml')),
                    ],
                    selected: {_unit},
                    onSelectionChanged: (s) {
                      setState(() => _unit = s.first);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('Additional servings'),
                subtitle: Text('${_additionalServings.length} custom serving${_additionalServings.length == 1 ? '' : 's'}'),
                children: [
                  if (_additionalServings.isNotEmpty)
                    ..._additionalServings.asMap().entries.map((e) {
                      final s = e.value;
                      return ListTile(
                        dense: true,
                        title: Text(s.label),
                        subtitle: Text('${s.grams.toStringAsFixed(0)}g'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          onPressed: () => setState(() => _additionalServings.removeAt(e.key)),
                        ),
                      );
                    }),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Add serving (e.g. "1 cup", "1 slice")'),
                      onPressed: _addServing,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Nutrition per serving', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              _numField(_calories, label: 'Calories', suffix: 'kcal'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _numField(_fat, label: 'Total fat', suffix: 'g')),
                  const SizedBox(width: 12),
                  Expanded(child: _numField(_protein, label: 'Protein', suffix: 'g')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _numField(_carbs, label: 'Total carbs', suffix: 'g')),
                  const SizedBox(width: 12),
                  Expanded(child: _numField(_sugar, label: 'Sugar', suffix: 'g')),
                ],
              ),
              const SizedBox(height: 12),
              _numField(_fiber, label: 'Fiber', suffix: 'g'),
              const SizedBox(height: 12),
              ExpansionTile(
                title: const Text('Sub-nutrients & Vitamins'),
                subtitle: const Text('Saturated fat, trans fat, cholesterol, sodium, etc.'),
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _numField(_saturatedFat, label: 'Saturated fat', suffix: 'g', isOptional: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _numField(_transFat, label: 'Trans fat', suffix: 'g', isOptional: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _numField(_cholesterol, label: 'Cholesterol', suffix: 'mg', isOptional: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _numField(_sodium, label: 'Sodium', suffix: 'mg', isOptional: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _numField(_addedSugars, label: 'Added sugars', suffix: 'g', isOptional: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _numField(_vitaminD, label: 'Vitamin D', suffix: 'mcg', isOptional: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _numField(_calcium, label: 'Calcium', suffix: 'mg', isOptional: true)),
                      const SizedBox(width: 12),
                      Expanded(child: _numField(_iron, label: 'Iron', suffix: 'mg', isOptional: true)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _numField(_potassium, label: 'Potassium', suffix: 'mg', isOptional: true),
                  const SizedBox(height: 12),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy ? null : _scanLabel,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Take nutrition label picture'),
              ),
              const SizedBox(height: 20),
              if (widget.isEdit) ...[
                FilledButton.icon(
                  onPressed: _busy ? null : () async {
                    final id = await _saveCustomFood();
                    if (id == null) return;
                    if (!context.mounted) return;
                    context.showAppSnackBar('Updated.');
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete food'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(color: theme.colorScheme.error),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () async {
                                final id = await _saveCustomFood();
                                if (id == null) return;
                                if (!context.mounted) return;
                                context.showAppSnackBar('Saved.');
                                Navigator.of(context).maybePop();
                              },
                        child: const Text('Save'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _busy ? null : _saveAndLog,
                        child: const Text('Save & log'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      ),
    );
  }

  Widget _numField(
    TextEditingController c, {
    required String label,
    String? suffix,
    bool isOptional = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: label,
        suffixText: suffix,
      ),
      validator: (v) {
        if (isOptional && (v == null || v.trim().isEmpty)) return null;
        final err = validatePositiveDouble(
          v ?? '',
          fieldLabel: label,
          min: 0,
          max: 100000,
        );
        if (err == '$label must be greater than 0.') return null;
        return err;
      },
    );
  }
}

class _ServingDraft {
  _ServingDraft({required this.label, required this.grams, this.id});
  final String label;
  final double grams;
  final int? id;
}

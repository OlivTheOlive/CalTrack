import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:caltrack/features/food/food_entry_sheet.dart';
import 'package:caltrack/features/food/nutrition_label_scan_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class AddCustomFoodScreen extends StatefulWidget {
  const AddCustomFoodScreen({super.key, this.initialBarcode});

  final String? initialBarcode;

  @override
  State<AddCustomFoodScreen> createState() => _AddCustomFoodScreenState();
}

class _AddCustomFoodScreenState extends State<AddCustomFoodScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _name = TextEditingController();
  late final TextEditingController _brand = TextEditingController();
  late final TextEditingController _barcode =
      TextEditingController(text: widget.initialBarcode ?? '');

  late final TextEditingController _servingSize = TextEditingController(text: '100');
  ServingUnit _unit = ServingUnit.g;

  late final TextEditingController _calories = TextEditingController();
  late final TextEditingController _fat = TextEditingController();
  late final TextEditingController _carbs = TextEditingController();
  late final TextEditingController _sugar = TextEditingController();
  late final TextEditingController _fiber = TextEditingController();
  late final TextEditingController _protein = TextEditingController();

  bool _busy = false;
  int? _savedId;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _barcode.dispose();
    _servingSize.dispose();
    _calories.dispose();
    _fat.dispose();
    _carbs.dispose();
    _sugar.dispose();
    _fiber.dispose();
    _protein.dispose();
    super.dispose();
  }

  static double? _parseNum(String raw, {bool allowZero = true}) {
    final v = double.tryParse(raw.trim().replaceAll(',', '.'));
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

    setState(() => _busy = true);
    try {
      final id = await repo.upsertCustomFood(
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
      );
      _savedId = id;
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
        initialGrams: serving,
        subtitle: 'Per $serving ${_unit.name}',
        unitLabel: _unit.name,
      ),
    );
    if (!mounted) return;
    if (action == FoodEntryAction.added) {
      if (context.canPop()) context.pop();
    }
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
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Add food')),
      body: SafeArea(
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
                    v == null || v.trim().isEmpty ? 'Required' : null,
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
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Barcode (optional)',
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
                        final parsed = v == null ? null : _parseNum(v, allowZero: false);
                        if (parsed == null) return 'Enter a number';
                        if (parsed <= 0) return 'Must be > 0';
                        return null;
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
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _busy ? null : _scanLabel,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text('Take nutrition label picture'),
              ),
              const SizedBox(height: 20),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Saved.')),
                              );
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
          ),
        ),
      ),
    );
  }

  Widget _numField(
    TextEditingController c, {
    required String label,
    String? suffix,
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
        final parsed = v == null ? null : _parseNum(v);
        if (parsed == null) return 'Enter a number';
        return null;
      },
    );
  }
}


import 'package:caltrack/core/nutrition_scaling.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/widgets/opennutrition_attribution.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Outcome bubbled back from the food entry sheet.
enum FoodEntryAction { added, updated, deleted }

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
    this.initialGrams = 100,
    this.editingEntryId,
    this.loggedAtForEdit,
    this.subtitle,
    this.unitLabel = 'g',
    this.showOpenNutritionAttribution = false,
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
  final double initialGrams;

  /// When non-null, the sheet is in **edit mode** for this entry id.
  final int? editingEntryId;
  final DateTime? loggedAtForEdit;

  final String? subtitle;
  final String unitLabel;
  final bool showOpenNutritionAttribution;

  bool get isEdit => editingEntryId != null;
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
    text: _formatGrams(widget.config.initialGrams),
  );
  bool _busy = false;

  String? _foodKey;
  bool _loadingPrefs = true;
  bool _catalogLiquidDefault = false;
  bool? _treatAsLiquidOverride;
  double? _savedServingAmount;
  String? _savedServingUnit; // 'g' | 'ml'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPrefs());
  }

  Future<void> _loadPrefs() async {
    final repo = context.read<CalTrackRepository>();
    final cfg = widget.config;
    final key = cfg.catalogFoodId != null
        ? foodLogKeyForCatalogId(cfg.catalogFoodId!)
        : (cfg.customFoodId != null
            ? foodLogKeyForCustomId(cfg.customFoodId!)
            : foodLogKeyForName(cfg.displayName));
    bool catalogDefault = false;
    if (cfg.catalogFoodId != null) {
      final catalog = context.read<OpenNutritionCatalog>();
      final food = await catalog.byId(cfg.catalogFoodId!);
      catalogDefault = food?.isLiquid ?? false;
    }
    final pref = await repo.foodPrefByKey(key);
    if (!mounted) return;
    setState(() {
      _foodKey = key;
      _catalogLiquidDefault = catalogDefault;
      _treatAsLiquidOverride = pref?.treatAsLiquid;
      _savedServingAmount = pref?.savedServingAmount;
      _savedServingUnit = pref?.savedServingUnit;
      _loadingPrefs = false;
    });
  }

  bool get _treatAsLiquidEffective =>
      _treatAsLiquidOverride ?? _catalogLiquidDefault;

  String get _effectiveUnitLabel {
    if (_treatAsLiquidEffective) return 'ml';
    return widget.config.unitLabel;
  }

  @override
  void dispose() {
    _grams.dispose();
    super.dispose();
  }

  static String _formatGrams(double g) =>
      g == g.roundToDouble() ? g.round().toString() : g.toStringAsFixed(1);

  double? _parseGrams() {
    final raw = _grams.text.trim().replaceAll(',', '.');
    final g = double.tryParse(raw);
    if (g == null || g <= 0 || g > 100000) return null;
    return g;
  }

  ScaledNutrition _scale(double grams) => scaleFromPer100g(
        grams: grams,
        kcalPer100g: widget.config.kcalPer100g,
        proteinPer100g: widget.config.proteinPer100g,
        carbsPer100g: widget.config.carbsPer100g,
        fatPer100g: widget.config.fatPer100g,
      );

  Future<void> _setTreatAsLiquid(bool value) async {
    final key = _foodKey;
    if (key == null) return;
    final repo = context.read<CalTrackRepository>();
    await repo.setTreatAsLiquid(foodKey: key, treatAsLiquid: value);
    if (!mounted) return;
    setState(() => _treatAsLiquidOverride = value);
  }

  Future<void> _clearTreatAsLiquidOverride() async {
    final key = _foodKey;
    if (key == null) return;
    final repo = context.read<CalTrackRepository>();
    await repo.setTreatAsLiquid(foodKey: key, treatAsLiquid: null);
    if (!mounted) return;
    setState(() => _treatAsLiquidOverride = null);
  }

  Future<void> _saveServing() async {
    final key = _foodKey;
    if (key == null) return;
    final amount = _parseGrams();
    if (amount == null) return;
    final unit = _effectiveUnitLabel;
    final repo = context.read<CalTrackRepository>();
    await repo.setSavedServing(foodKey: key, amount: amount, unit: unit);
    if (!mounted) return;
    setState(() {
      _savedServingAmount = amount;
      _savedServingUnit = unit;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved serving: ${amount.round()} $unit')),
    );
  }

  void _applyServing() {
    final a = _savedServingAmount;
    if (a == null) return;
    _grams.text = _formatGrams(a);
    setState(() {});
  }

  Future<void> _save() async {
    final grams = _parseGrams();
    if (grams == null) return;
    final scaled = _scale(grams);
    final factor = grams / 100.0;
    final sugar = widget.config.sugarPer100g * factor;
    final fiber = widget.config.fiberPer100g * factor;
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
        );
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
        );
        if (!mounted) return;
        Navigator.of(context).pop(FoodEntryAction.added);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    final grams = _parseGrams() ?? 0;
    final scaled = _scale(grams);
    final unitLabel = _effectiveUnitLabel;

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
                      Text(
                        cfg.displayName,
                        style: theme.textTheme.titleLarge,
                      ),
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
            TextField(
              controller: _grams,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: !cfg.isEdit,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Amount',
                suffixText: unitLabel,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
            if (!_loadingPrefs) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Treat as liquid (ml)'),
                      subtitle: Text(
                        _treatAsLiquidOverride == null
                            ? 'Default: ${_catalogLiquidDefault ? "liquid" : "solid"}'
                            : 'Override saved',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      value: _treatAsLiquidEffective,
                      onChanged: _busy ? null : _setTreatAsLiquid,
                    ),
                  ),
                  if (_treatAsLiquidOverride != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _busy ? null : _clearTreatAsLiquidOverride,
                      child: const Text('Use default'),
                    ),
                  ],
                ],
              ),
              if (_treatAsLiquidEffective)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    'Approx: assumes 1 ml ≈ 1 g for nutrition scaling.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final g in const [25.0, 50.0, 100.0, 200.0, 250.0])
                  ActionChip(
                    label: Text('${g.round()} $unitLabel'),
                    onPressed: () {
                      _grams.text = _formatGrams(g);
                      setState(() {});
                    },
                  ),
              ],
            ),
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
                    onPressed:
                        _busy || _parseGrams() == null ? null : _saveServing,
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
                      onPressed:
                          _busy || _parseGrams() == null ? null : _save,
                      child: const Text('Save'),
                    ),
                  ),
                ],
              )
            else
              FilledButton.icon(
                onPressed: _busy || _parseGrams() == null ? null : _save,
                icon: const Icon(Icons.add),
                label: const Text('Add to diary'),
              ),
          ],
        ),
      ),
    );
  }
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
                backgroundColor:
                    theme.colorScheme.surfaceContainerHighest,
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

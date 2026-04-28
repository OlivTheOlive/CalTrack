import 'package:caltrack/core/nutrition_scaling.dart';
import 'package:caltrack/data/caltrack_repository.dart';
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
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.initialGrams = 100,
    this.editingEntryId,
    this.loggedAtForEdit,
    this.subtitle,
    this.showOpenNutritionAttribution = false,
  });

  final String displayName;
  final String source;
  final String? catalogFoodId;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double initialGrams;

  /// When non-null, the sheet is in **edit mode** for this entry id.
  final int? editingEntryId;
  final DateTime? loggedAtForEdit;

  final String? subtitle;
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

  Future<void> _save() async {
    final grams = _parseGrams();
    if (grams == null) return;
    final scaled = _scale(grams);
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
          fatG: scaled.fatG,
        );
        if (!mounted) return;
        Navigator.of(context).pop(FoodEntryAction.updated);
      } else {
        await repo.addFoodLogReturnId(
          source: widget.config.source,
          catalogFoodId: widget.config.catalogFoodId,
          displayName: widget.config.displayName,
          grams: grams,
          kcal: scaled.kcal,
          proteinG: scaled.proteinG,
          carbsG: scaled.carbsG,
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
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Amount',
                suffixText: 'g',
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                for (final g in const [25.0, 50.0, 100.0, 200.0, 250.0])
                  ActionChip(
                    label: Text('${g.round()} g'),
                    onPressed: () {
                      _grams.text = _formatGrams(g);
                      setState(() {});
                    },
                  ),
              ],
            ),
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

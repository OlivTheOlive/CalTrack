import 'package:caltrack/app/nutrition_display_controller.dart';
import 'package:caltrack/core/nutrients.dart';
import 'package:caltrack/core/spacing.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:flutter/material.dart';

/// Displays all nutrients in the current view mode (detailed or custom).
/// Categories are rendered as expandable/collapsible sections.
class DetailedNutrientBreakdown extends StatelessWidget {
  const DetailedNutrientBreakdown({
    super.key,
    required this.intake,
    required this.mode,
    required this.customSelection,
  });

  final DailyIntakeTotals intake;
  final NutritionDisplayMode mode;
  final Set<NutrientKey> customSelection;

  Map<NutrientKey, double> get _allValues {
    final out = <NutrientKey, double>{};
    out[NutrientKey.kcal] = intake.kcal;
    out[NutrientKey.totalFatG] = intake.fatG;
    out[NutrientKey.totalCarbsG] = intake.carbsG;
    out[NutrientKey.proteinG] = intake.proteinG;
    out[NutrientKey.dietaryFiberG] = intake.fiberG;
    out[NutrientKey.totalSugarsG] = intake.sugarG;
    out.addAll(intake.extra);
    return out;
  }

  List<NutrientKey> _visibleKeys() {
    if (mode == NutritionDisplayMode.custom) {
      return customSelection.toList();
    }
    return nutrientCategoryOrder.expand(nutrientsInCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final keys = _visibleKeys();
    if (keys.isEmpty) {
      return Text(
        'No nutrients selected',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    final grouped = <NutrientCategory, List<NutrientKey>>{};
    for (final k in keys) {
      grouped.putIfAbsent(k.category, () => []).add(k);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cat in nutrientCategoryOrder)
          if (grouped.containsKey(cat))
            _NutrientCategorySection(
              category: cat,
              keys: grouped[cat]!,
              values: _allValues,
            ),
      ],
    );
  }
}

class _NutrientCategorySection extends StatefulWidget {
  const _NutrientCategorySection({
    required this.category,
    required this.keys,
    required this.values,
  });

  final NutrientCategory category;
  final List<NutrientKey> keys;
  final Map<NutrientKey, double> values;

  @override
  State<_NutrientCategorySection> createState() =>
      _NutrientCategorySectionState();
}

class _NutrientCategorySectionState extends State<_NutrientCategorySection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final label = nutrientCategoryLabels[widget.category] ??
        widget.category.name;

    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: Corners.radiusSm,
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: Spacing.sm,
                horizontal: Spacing.xs,
              ),
              child: Row(
                children: [
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: Spacing.xs),
                  Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            ...List.generate(widget.keys.length, (i) {
              final isLast = i == widget.keys.length - 1;
              return _NutrientRow(
                key: ValueKey(widget.keys[i]),
                nutrientKey: widget.keys[i],
                value: widget.values[widget.keys[i]] ?? 0,
                isLast: isLast,
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _NutrientRow extends StatelessWidget {
  const _NutrientRow({
    required super.key,
    required this.nutrientKey,
    required this.value,
    this.isLast = false,
  });

  final NutrientKey nutrientKey;
  final double value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info = nutrientKey.info;
    final dv = nutrientKey.dailyValue;
    final ul = nutrientKey.upperLimit;
    final pct = dv != null && dv > 0 ? (value / dv * 100) : 0.0;
    final overUl = ul != null && value > ul;
    final overUlLabel = overUl ? ' >UL' : '';
    final displayValue = _formatValue(value, info.unit);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 0),
      child: ListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: Spacing.sm,
          vertical: 0,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                info.displayName,
                style: theme.textTheme.bodySmall,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              displayValue,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: Spacing.sm),
            if (dv != null)
              SizedBox(
                width: 52,
                child: Text(
                  '${pct.round()}%$overUlLabel',
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: overUl
                        ? scheme.error
                        : pct >= 90
                            ? scheme.primary
                            : null,
                  ),
                ),
              ),
          ],
        ),
        subtitle: dv != null
            ? Padding(
                padding: const EdgeInsets.only(top: 2),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    minHeight: 4,
                    value: (pct / 100).clamp(0.0, 1.0),
                    backgroundColor: scheme.surfaceContainerHighest,
                    color: overUl
                        ? scheme.error
                        : pct >= 90
                            ? scheme.primary
                            : scheme.secondary,
                  ),
                ),
              )
            : null,
      ),
    );
  }

  String _formatValue(double v, String unit) {
    if (v == 0) return '0 $unit';
    if (v < 0.01) return '<0.01 $unit';
    if (v < 1) return '${v.toStringAsFixed(2)} $unit';
    if (v < 10) return '${v.toStringAsFixed(1)} $unit';
    return '${v.round()} $unit';
  }
}

/// Bottom sheet that allows the user to select which nutrients to track
/// in custom mode. Grouped by nutrient category with checkboxes.
class CustomNutrientSelector extends StatefulWidget {
  const CustomNutrientSelector({
    super.key,
    required this.selection,
    required this.onChanged,
  });

  final Set<NutrientKey> selection;
  final ValueChanged<Set<NutrientKey>> onChanged;

  @override
  State<CustomNutrientSelector> createState() => _CustomNutrientSelectorState();
}

class _CustomNutrientSelectorState extends State<CustomNutrientSelector> {
  late Set<NutrientKey> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.selection);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.md,
                Spacing.md,
                Spacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tracked nutrients',
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _selected = {
                        NutrientKey.kcal,
                        NutrientKey.proteinG,
                        NutrientKey.totalCarbsG,
                        NutrientKey.totalFatG,
                      });
                    },
                    child: const Text('Reset'),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView(
                controller: scrollController,
                children: [
                  for (final cat in nutrientCategoryOrder) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Spacing.md,
                        Spacing.md,
                        Spacing.md,
                        Spacing.xs,
                      ),
                      child: Text(
                        nutrientCategoryLabels[cat] ?? cat.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    for (final key in nutrientsInCategory(cat))
                      CheckboxListTile(
                        dense: true,
                        title: Text(
                          key.displayName,
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          '${key.unit}${key.dailyValue != null ? ' · DV ${_fmtDv(key.dailyValue!, key.unit)}' : ''}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        value: _selected.contains(key),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selected.add(key);
                            } else {
                              _selected.remove(key);
                            }
                          });
                          widget.onChanged(_selected);
                        },
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: Spacing.md,
                        ),
                      ),
                  ],
                  const SizedBox(height: Spacing.xl),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _fmtDv(double v, String unit) {
    if (v >= 100) return '${v.round()} $unit';
    if (v >= 10) return '${v.toStringAsFixed(1)} $unit';
    return '${v.toStringAsFixed(2)} $unit';
  }
}

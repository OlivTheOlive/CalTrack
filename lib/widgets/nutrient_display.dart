import 'package:caltrack/core/nutrients.dart';
import 'package:caltrack/core/spacing.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/widgets/styled_card.dart';
import 'package:flutter/material.dart';

/// Displays logged nutrient amounts grouped by category.
/// Shows only what was consumed — no DV percentages or external benchmarks.
class DetailedNutrientBreakdown extends StatelessWidget {
  const DetailedNutrientBreakdown({
    super.key,
    required this.intake,
    required this.customSelection,
  });

  final DailyIntakeTotals intake;
  final Set<NutrientKey> customSelection;

  Map<NutrientKey, double> get _loggedValues {
    return {
      NutrientKey.kcal: intake.kcal,
      NutrientKey.totalFatG: intake.fatG,
      NutrientKey.totalCarbsG: intake.carbsG,
      NutrientKey.proteinG: intake.proteinG,
      NutrientKey.dietaryFiberG: intake.fiberG,
      NutrientKey.totalSugarsG: intake.sugarG,
      ...intake.extra,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (customSelection.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
        child: Center(
          child: Text(
            'No nutrients selected.\nOpen the selector to add some.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      );
    }

    final grouped = <NutrientCategory, List<NutrientKey>>{};
    for (final k in customSelection) {
      grouped.putIfAbsent(k.category, () => []).add(k);
    }
    final values = _loggedValues;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final cat in nutrientCategoryOrder)
          if (grouped.containsKey(cat))
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: _NutrientCategoryCard(
                category: cat,
                keys: grouped[cat]!,
                values: values,
              ),
            ),
      ],
    );
  }
}

// ─── Category card ────────────────────────────────────────────────────────────

class _NutrientCategoryCard extends StatelessWidget {
  const _NutrientCategoryCard({
    required this.category,
    required this.keys,
    required this.values,
  });

  final NutrientCategory category;
  final List<NutrientKey> keys;
  final Map<NutrientKey, double> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = _categoryColor(category, scheme);
    final label = nutrientCategoryLabels[category] ?? category.name;

    return StyledCard(
      tone: CardTone.low,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              Spacing.sm,
              Spacing.md,
              Spacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _categoryIcon(category),
                    size: 16,
                    color: accent,
                  ),
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${keys.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: scheme.outlineVariant.withValues(alpha: 0.6),
          ),
          // ── Nutrient rows ──
          ...List.generate(keys.length, (i) {
            final key = keys[i];
            return _NutrientLogRow(
              nutrientKey: key,
              value: values[key] ?? 0,
              accent: accent,
              showDivider: i < keys.length - 1,
            );
          }),
        ],
      ),
    );
  }
}

// ─── Individual row ───────────────────────────────────────────────────────────

class _NutrientLogRow extends StatelessWidget {
  const _NutrientLogRow({
    required this.nutrientKey,
    required this.value,
    required this.accent,
    required this.showDivider,
  });

  final NutrientKey nutrientKey;
  final double value;
  final Color accent;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final info = nutrientKey.info;
    final logged = value > 0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: 9,
          ),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: logged
                      ? accent.withValues(alpha: 0.65)
                      : scheme.outlineVariant,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  info.displayName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: logged
                        ? scheme.onSurface
                        : scheme.onSurface.withValues(alpha: 0.38),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Text(
                _fmtValue(value, info.unit),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: logged ? FontWeight.w600 : FontWeight.w400,
                  color: logged
                      ? scheme.onSurface
                      : scheme.onSurface.withValues(alpha: 0.32),
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            indent: Spacing.md + 5 + Spacing.sm,
            endIndent: Spacing.md,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
      ],
    );
  }

  String _fmtValue(double v, String unit) {
    if (v == 0) return '— $unit';
    if (v < 0.01) return '<0.01 $unit';
    if (v < 1) return '${v.toStringAsFixed(2)} $unit';
    if (v < 10) return '${v.toStringAsFixed(1)} $unit';
    return '${v.round()} $unit';
  }
}

// ─── Category helpers ─────────────────────────────────────────────────────────

IconData _categoryIcon(NutrientCategory cat) {
  switch (cat) {
    case NutrientCategory.macro:
      return Icons.restaurant_rounded;
    case NutrientCategory.subMacro:
      return Icons.grain_rounded;
    case NutrientCategory.mineral:
      return Icons.diamond_outlined;
    case NutrientCategory.vitamin:
      return Icons.spa_outlined;
    case NutrientCategory.fattyAcid:
      return Icons.water_drop_outlined;
    case NutrientCategory.aminoAcid:
      return Icons.science_outlined;
  }
}

Color _categoryColor(NutrientCategory cat, ColorScheme scheme) {
  switch (cat) {
    case NutrientCategory.macro:
      return scheme.primary;
    case NutrientCategory.subMacro:
      return scheme.secondary;
    case NutrientCategory.mineral:
      return scheme.tertiary;
    case NutrientCategory.vitamin:
      return scheme.primary;
    case NutrientCategory.fattyAcid:
      return scheme.secondary;
    case NutrientCategory.aminoAcid:
      return scheme.tertiary;
  }
}

// ─── Custom nutrient selector ─────────────────────────────────────────────────

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
            Container(
              margin: const EdgeInsets.only(top: Spacing.sm),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: scheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
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
                    onPressed: () => setState(() => _selected = {
                          NutrientKey.kcal,
                          NutrientKey.proteinG,
                          NutrientKey.totalCarbsG,
                          NutrientKey.totalFatG,
                        }),
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
                    _SelectorCategoryHeader(
                      category: cat,
                      scheme: scheme,
                      theme: theme,
                    ),
                    for (final key in nutrientsInCategory(cat))
                      CheckboxListTile(
                        dense: true,
                        title: Text(
                          key.displayName,
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          key.unit,
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
}

class _SelectorCategoryHeader extends StatelessWidget {
  const _SelectorCategoryHeader({
    required this.category,
    required this.scheme,
    required this.theme,
  });

  final NutrientCategory category;
  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final accent = _categoryColor(category, scheme);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        Spacing.md,
        Spacing.xs,
      ),
      child: Row(
        children: [
          Icon(_categoryIcon(category), size: 15, color: accent),
          const SizedBox(width: Spacing.xs),
          Text(
            nutrientCategoryLabels[category] ?? category.name,
            style: theme.textTheme.titleSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

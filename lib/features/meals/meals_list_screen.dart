import 'package:caltrack/app/app_snackbar.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/features/food/food_entry_sheet.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MealsListScreen extends StatefulWidget {
  const MealsListScreen({super.key});
  @override
  State<MealsListScreen> createState() => _MealsListScreenState();
}

class _MealsListScreenState extends State<MealsListScreen> {
  late Future<List<Meal>> _mealsFuture;

  @override
  void initState() {
    super.initState();
    _mealsFuture = context.read<CalTrackRepository>().allMeals();
  }

  void _refresh() {
    setState(() {
      _mealsFuture = context.read<CalTrackRepository>().allMeals();
    });
  }

  Future<void> _deleteMeal(Meal meal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete MealPrep?'),
        content: Text('Delete "${meal.name}"? This cannot be undone.'),
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
    if (confirmed != true) return;
    if (!mounted) return;
    await context.read<CalTrackRepository>().deleteMeal(meal.id);
    if (!mounted) return;
    context.showAppSnackBar('Deleted "${meal.name}".');
    _refresh();
  }

  Future<void> _logMealPrep(Meal m) async {
    final totalGrams = m.totalGrams > 0 ? m.totalGrams : 100.0;
    final divisor = m.servingCount <= 0 ? 1 : m.servingCount;
    final perServingWeight = totalGrams / divisor;

    final extra = decodeExtraNutrients(m.extraNutrients);
    final factor = 100.0 / totalGrams;
    final extra100 = extra.map((k, v) => MapEntry(k, v * factor));

    final action = await showFoodEntrySheet(
      context,
      FoodEntrySheetConfig(
        displayName: m.name,
        source: 'custom',
        customFoodId: null,
        catalogFoodId: null,
        kcalPer100g: m.calories * factor,
        proteinPer100g: m.proteinG * factor,
        carbsPer100g: m.carbsG * factor,
        sugarPer100g: m.sugarG * factor,
        fiberPer100g: m.fiberG * factor,
        fatPer100g: m.fatG * factor,
        extraNutrientsPer100g: extra100,
        initialGrams: perServingWeight,
        presets: [
          CatalogGroupPreset(
            foodId: 'meal:${m.id}',
            label: m.servingLabel ?? 'serving',
            grams: perServingWeight,
            isDefault: true,
            sortOrder: 0,
          ),
        ],
        initialPresetLabel: m.servingLabel ?? 'serving',
        showPresetPicker: false,
      ),
    );

    if (action == FoodEntryAction.added && mounted) {
      context.showAppSnackBar('Logged "${m.name}".');
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('My MealPreps')),
      body: FutureBuilder<List<Meal>>(
        future: _mealsFuture,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final meals = snap.data!;
          if (meals.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      size: 48,
                      color: t.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No saved MealPreps yet.',
                      style: t.textTheme.bodyLarge?.copyWith(
                        color: t.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () async {
                        await context.push('/create-meal');
                        _refresh();
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create a MealPrep'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView.builder(
              padding: const EdgeInsets.only(top: 4, bottom: 80),
              itemCount: meals.length,
              itemBuilder: (_, i) {
                final m = meals[i];
                return Dismissible(
                  key: ValueKey('meal-${m.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    color: t.colorScheme.errorContainer,
                    child: Icon(
                      Icons.delete_outline,
                      color: t.colorScheme.onErrorContainer,
                    ),
                  ),
                  confirmDismiss: (_) async {
                    await _deleteMeal(m);
                    return false;
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: t.colorScheme.secondaryContainer,
                        child: Icon(Icons.dining_outlined, color: t.colorScheme.onSecondaryContainer),
                      ),
                      title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Builder(
                        builder: (context) {
                          final divisor = m.servingCount <= 0
                              ? 1
                              : m.servingCount;
                          final kcal = m.calories / divisor;
                          final weight = m.totalGrams / divisor;
                          final p = m.proteinG / divisor;
                          final c = m.carbsG / divisor;
                          final f = m.fatG / divisor;
                          final label = m.servingLabel ?? 'serving';
                          return Text(
                            '${kcal.round()} kcal per $label (${weight.round()}g) · P:${p.toStringAsFixed(0)}g C:${c.toStringAsFixed(0)}g F:${f.toStringAsFixed(0)}g',
                          );
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: 'Edit MealPrep',
                            onPressed: () async {
                              await context.push('/create-meal', extra: {'existingMeal': m});
                              _refresh();
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete MealPrep',
                            onPressed: () => _deleteMeal(m),
                          ),
                        ],
                      ),
                      onTap: () => _logMealPrep(m),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/create-meal');
          _refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Create MealPrep'),
      ),
    );
  }
}

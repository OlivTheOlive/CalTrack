import 'dart:async';

import 'package:caltrack/data/app_database.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/features/food/food_entry_sheet.dart';
import 'package:caltrack/widgets/opennutrition_attribution.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class LogFoodScreen extends StatefulWidget {
  const LogFoodScreen({super.key});

  @override
  State<LogFoodScreen> createState() => _LogFoodScreenState();
}

class _LogFoodScreenState extends State<LogFoodScreen> {
  final TextEditingController _search = TextEditingController();
  Timer? _debounce;
  List<CatalogFood> _results = [];
  List<CustomFood> _customResults = [];
  bool _searching = false;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String q) async {
    final catalog = context.read<OpenNutritionCatalog>();
    final repo = context.read<CalTrackRepository>();
    setState(() {
      _searching = true;
      _lastQuery = q;
    });
    try {
      final res = await Future.wait([
        catalog.search(q),
        repo.searchCustomFoods(q),
      ]);
      if (!mounted || _lastQuery != q) return;
      setState(() {
        _results = res[0] as List<CatalogFood>;
        _customResults = res[1] as List<CustomFood>;
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _openCustomFood(CustomFood food, {double? initialAmount}) async {
    final serving = food.servingSize;
    final factor = serving > 0 ? 100.0 / serving : 1.0;
    final unit = ServingUnit.values.byName(food.servingUnit);

    final action = await showFoodEntrySheet(
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
        initialGrams: initialAmount ?? serving,
        subtitle: food.brand,
        unitLabel: unit.name,
      ),
    );
    if (!mounted || action == null) return;
    if (action == FoodEntryAction.added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged ${food.name}')),
      );
    }
  }

  Future<void> _openCatalogFood(
    CatalogFood food, {
    double initialGrams = 100,
  }) async {
    final action = await showFoodEntrySheet(
      context,
      FoodEntrySheetConfig(
        displayName: food.name,
        source: 'opennutrition',
        catalogFoodId: food.id,
        kcalPer100g: food.kcalPer100g,
        proteinPer100g: food.proteinPer100g,
        carbsPer100g: food.carbsPer100g,
        fatPer100g: food.fatPer100g,
        initialGrams: initialGrams,
        showOpenNutritionAttribution: true,
      ),
    );
    if (!mounted || action == null) return;
    if (action == FoodEntryAction.added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged ${food.name}')),
      );
    }
  }

  Future<void> _openRecentEntry(FoodLogEntry entry) async {
    final catalog = context.read<OpenNutritionCatalog>();
    final repo = context.read<CalTrackRepository>();
    final id = entry.catalogFoodId;
    if (id != null) {
      final food = await catalog.byId(id);
      if (!mounted) return;
      if (food != null) {
        await _openCatalogFood(food, initialGrams: entry.grams);
        return;
      }
    }
    final customId = entry.customFoodId;
    if (customId != null) {
      final custom = await repo.customFoodById(customId);
      if (!mounted) return;
      if (custom != null) {
        await _openCustomFood(custom, initialAmount: entry.grams);
        return;
      }
    }
    final per100Factor = entry.grams > 0 ? 100.0 / entry.grams : 1.0;
    final action = await showFoodEntrySheet(
      context,
      FoodEntrySheetConfig(
        displayName: entry.displayName,
        source: entry.source,
        catalogFoodId: entry.catalogFoodId,
        kcalPer100g: entry.kcal * per100Factor,
        proteinPer100g: entry.proteinG * per100Factor,
        carbsPer100g: entry.carbsG * per100Factor,
        sugarPer100g: entry.sugarG * per100Factor,
        fiberPer100g: entry.fiberG * per100Factor,
        fatPer100g: entry.fatG * per100Factor,
        initialGrams: entry.grams,
      ),
    );
    if (!mounted || action != FoodEntryAction.added) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged ${entry.displayName}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<CalTrackRepository>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log food'),
        actions: [
          IconButton(
            tooltip: 'Scan barcode',
            icon: const Icon(Icons.qr_code_scanner_outlined),
            onPressed: () async {
              final result = await context.push<Object?>('/scan-barcode');
              if (!mounted || result == null) return;
              if (result is CatalogFood) {
                await _openCatalogFood(result);
              } else if (result is CustomFood) {
                await _openCustomFood(result);
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _search,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Search foods',
                prefixIcon: Icon(Icons.search),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (text) {
                _debounce?.cancel();
                final q = text.trim();
                if (q.length < 2) {
                  setState(() {
                    _results = [];
                    _customResults = [];
                  });
                  return;
                }
                _debounce = Timer(const Duration(milliseconds: 280), () {
                  _runSearch(q);
                });
              },
            ),
          ),
          if (_searching)
            const LinearProgressIndicator(minHeight: 2)
          else
            const SizedBox(height: 2),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Text(
                    'Recent',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                FutureBuilder<List<FoodLogEntry>>(
                  future: repo.recentDistinctFoodLogs(limit: 12),
                  builder: (context, snap) {
                    final recent = snap.data;
                    if (recent == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (recent.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text('Your logged foods will appear here.'),
                      );
                    }
                    return Column(
                      children: recent
                          .map(
                            (e) => ListTile(
                              title: Text(e.displayName),
                              subtitle: Text(
                                '${e.grams.round()} g · ${e.kcal.round()} kcal',
                              ),
                              onTap: () => _openRecentEntry(e),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Custom foods',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (_customResults.isEmpty &&
                    _search.text.trim().length >= 2 &&
                    !_searching)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('No custom matches.'),
                  ),
                ..._customResults.map(
                  (f) => ListTile(
                    title: Text(f.name),
                    subtitle: Text(
                      [
                        if (f.brand != null && f.brand!.isNotEmpty) f.brand!,
                        '${f.calories.round()} kcal / ${f.servingSize.round()} ${f.servingUnit}',
                      ].join(' · '),
                    ),
                    onTap: () => _openCustomFood(f),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.add),
                  title: const Text('Add a custom food'),
                  subtitle: const Text('Create a food not in the offline catalog'),
                  onTap: () => context.push('/add-custom-food'),
                ),
                const Divider(height: 32),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    'Catalog results',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (_results.isEmpty &&
                    _search.text.trim().length >= 2 &&
                    !_searching)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('No catalog matches.'),
                  ),
                ..._results.map(
                  (f) => ListTile(
                    title: Text(f.name),
                    subtitle: Text('${f.kcalPer100g.round()} kcal / 100 g'),
                    onTap: () => _openCatalogFood(f),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: OpenNutritionAttribution(),
          ),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:caltrack/core/nutrition_scaling.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/widgets/opennutrition_attribution.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    setState(() {
      _searching = true;
      _lastQuery = q;
    });
    try {
      final list = await catalog.search(q);
      if (!mounted || _lastQuery != q) return;
      setState(() => _results = list);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  Future<void> _pickGramsAndLog({
    required String displayName,
    required String source,
    String? catalogFoodId,
    required ScaledNutrition Function(double grams) scale,
    double initialGrams = 100,
  }) async {
    final grams = await showGramPicker(context, initialGrams: initialGrams);
    if (grams == null || !mounted) return;
    final scaled = scale(grams);
    final repo = context.read<CalTrackRepository>();
    await repo.addFoodLog(
      source: source,
      catalogFoodId: catalogFoodId,
      displayName: displayName,
      grams: grams,
      kcal: scaled.kcal,
      proteinG: scaled.proteinG,
      carbsG: scaled.carbsG,
      fatG: scaled.fatG,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged $displayName')),
    );
  }

  Future<void> _onCatalogFood(CatalogFood food) async {
    await _pickGramsAndLog(
      displayName: food.name,
      source: 'opennutrition',
      catalogFoodId: food.id,
      scale: (g) => scaleFromPer100g(
            grams: g,
            kcalPer100g: food.kcalPer100g,
            proteinPer100g: food.proteinPer100g,
            carbsPer100g: food.carbsPer100g,
            fatPer100g: food.fatPer100g,
          ),
    );
  }

  Future<void> _onRecentEntry(FoodLogEntry entry) async {
    final catalog = context.read<OpenNutritionCatalog>();
    final id = entry.catalogFoodId;
    if (id != null) {
      final food = await catalog.byId(id);
      if (food != null && mounted) {
        await _pickGramsAndLog(
          displayName: food.name,
          source: 'opennutrition',
          catalogFoodId: food.id,
          initialGrams: entry.grams,
          scale: (g) => scaleFromPer100g(
                grams: g,
                kcalPer100g: food.kcalPer100g,
                proteinPer100g: food.proteinPer100g,
                carbsPer100g: food.carbsPer100g,
                fatPer100g: food.fatPer100g,
              ),
        );
        return;
      }
    }
    await _pickGramsAndLog(
      displayName: entry.displayName,
      source: entry.source,
      catalogFoodId: entry.catalogFoodId,
      initialGrams: entry.grams,
      scale: (g) => rescaleLoggedPortion(
            previousGrams: entry.grams,
            previousKcal: entry.kcal,
            previousProteinG: entry.proteinG,
            previousCarbsG: entry.carbsG,
            previousFatG: entry.fatG,
            newGrams: g,
          ),
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
              final food = await context.push<CatalogFood>('/scan-barcode');
              if (food != null && mounted) {
                await _onCatalogFood(food);
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
                  setState(() => _results = []);
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
                      return const Center(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ));
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
                                '${e.grams.round()} g · '
                                '${e.kcal.round()} kcal',
                              ),
                              onTap: () => _onRecentEntry(e),
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
                    'Catalog results',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (_results.isEmpty && _search.text.trim().length >= 2 && !_searching)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text('No matches.'),
                  ),
                ..._results.map(
                  (f) => ListTile(
                    title: Text(f.name),
                    subtitle: Text(
                      '${f.kcalPer100g.round()} kcal / 100 g',
                    ),
                    onTap: () => _onCatalogFood(f),
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

Future<double?> showGramPicker(
  BuildContext context, {
  double initialGrams = 100,
}) async {
  final controller = TextEditingController(
    text: initialGrams.toStringAsFixed(
      initialGrams == initialGrams.roundToDouble() ? 0 : 1,
    ),
  );
  final result = await showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 16,
          left: 24,
          right: 24,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Amount (grams)',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixText: 'g',
              ),
              onSubmitted: (_) => FocusScope.of(ctx).unfocus(),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                final raw = controller.text.trim().replaceAll(',', '.');
                final g = double.tryParse(raw);
                if (g == null || g <= 0 || g > 100000) return;
                Navigator.pop(ctx, g);
              },
              child: const Text('Add to diary'),
            ),
          ],
        ),
      );
    },
  );
  return result;
}

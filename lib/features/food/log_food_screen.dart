import 'dart:async';

import 'package:caltrack/core/food_emoji.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/features/food/food_entry_sheet.dart';
import 'package:caltrack/widgets/opennutrition_attribution.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class LogFoodScreen extends StatefulWidget {
  const LogFoodScreen({super.key, this.initialDay});

  /// When non-null, new entries default to a timestamp on this day rather
  /// than [DateTime.now()].
  final DateTime? initialDay;

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

  /// Frequency of recent food-log keys. Loaded once at screen open and
  /// used to bubble up foods the user logs often. See
  /// [CalTrackRepository.foodLogKeyFrequencies].
  Map<String, int> _foodFrequencies = const {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFrequencies());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadFrequencies() async {
    final repo = context.read<CalTrackRepository>();
    final freq = await repo.foodLogKeyFrequencies();
    if (!mounted) return;
    setState(() => _foodFrequencies = freq);
  }

  int _catalogScore(CatalogFood f) =>
      _foodFrequencies[foodLogKeyForCatalogId(f.id)] ??
      _foodFrequencies[foodLogKeyForName(f.name)] ??
      0;

  int _customScore(CustomFood f) =>
      _foodFrequencies[foodLogKeyForCustomId(f.id)] ??
      _foodFrequencies[foodLogKeyForName(f.name)] ??
      0;

  List<CatalogFood> _rankCatalog(List<CatalogFood> raw) {
    if (_foodFrequencies.isEmpty) return raw;
    final indexed = [
      for (var i = 0; i < raw.length; i++) (i: i, food: raw[i]),
    ];
    indexed.sort((a, b) {
      final scoreCmp = _catalogScore(b.food).compareTo(_catalogScore(a.food));
      if (scoreCmp != 0) return scoreCmp;
      return a.i.compareTo(b.i);
    });
    return [for (final r in indexed) r.food];
  }

  List<CustomFood> _rankCustom(List<CustomFood> raw) {
    if (_foodFrequencies.isEmpty) return raw;
    final indexed = [
      for (var i = 0; i < raw.length; i++) (i: i, food: raw[i]),
    ];
    indexed.sort((a, b) {
      final scoreCmp = _customScore(b.food).compareTo(_customScore(a.food));
      if (scoreCmp != 0) return scoreCmp;
      return a.i.compareTo(b.i);
    });
    return [for (final r in indexed) r.food];
  }

  /// Returns the timestamp to use for a new log entry. If we're targeting
  /// a non-today day, snap to noon on that day so it deterministically
  /// falls inside the day bounds and reads as a reasonable time.
  DateTime? _initialLoggedAt() {
    final day = widget.initialDay;
    if (day == null) return null;
    final today = DateTime.now();
    final isToday = day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    if (isToday) return null;
    return DateTime(day.year, day.month, day.day, 12);
  }

  bool get _isAlternateDay {
    final day = widget.initialDay;
    if (day == null) return false;
    final today = DateTime.now();
    return !(day.year == today.year &&
        day.month == today.month &&
        day.day == today.day);
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
      final catalogRaw = res[0] as List<CatalogFood>;
      final customRaw = res[1] as List<CustomFood>;
      setState(() {
        _results = _rankCatalog(catalogRaw);
        _customResults = _rankCustom(customRaw);
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
    double? initialGrams,
    String? initialPresetLabel,
    double? initialPresetQty,
  }) async {
    final catalog = context.read<OpenNutritionCatalog>();
    final group = await catalog.groupForFood(food.id);
    if (!mounted) return;
    // When this food belongs to a group, render macros from the group's
    // canonical row so size presets line up with one consistent set of
    // per-100g numbers.
    final canonical = (group != null && group.canonicalFoodId != food.id)
        ? await catalog.byId(group.canonicalFoodId) ?? food
        : food;
    if (!mounted) return;
    final displayName = group?.label ?? canonical.name;
    final presets = group?.presets ?? const <CatalogGroupPreset>[];
    final defaultPreset = group?.defaultPreset;
    final resolvedInitialGrams = initialGrams ??
        (defaultPreset != null ? defaultPreset.grams : 100.0);

    final action = await showFoodEntrySheet(
      context,
      FoodEntrySheetConfig(
        displayName: displayName,
        source: 'opennutrition',
        catalogFoodId: canonical.id,
        kcalPer100g: canonical.kcalPer100g,
        proteinPer100g: canonical.proteinPer100g,
        carbsPer100g: canonical.carbsPer100g,
        fatPer100g: canonical.fatPer100g,
        initialGrams: resolvedInitialGrams,
        showOpenNutritionAttribution: true,
        loggedAtForEdit: _initialLoggedAt(),
        presets: presets,
        initialPresetLabel: initialPresetLabel,
        initialPresetQty: initialPresetQty,
      ),
    );
    if (!mounted || action == null) return;
    if (action == FoodEntryAction.added) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logged $displayName')),
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
        // If the original food belongs to a group, prefer the preset
        // that maps to that exact catalog id so the user lands on the
        // same size they picked last time (e.g. "Small egg").
        final group = await catalog.groupForFood(id);
        if (!mounted) return;
        final matched = group?.presetForFoodId(id);
        await _openCatalogFood(
          food,
          initialGrams: entry.grams,
          initialPresetLabel: matched?.label,
          initialPresetQty: matched != null && matched.grams > 0
              ? (entry.grams / matched.grams)
              : null,
        );
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
        loggedAtForEdit: _initialLoggedAt(),
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

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isAlternateDay && widget.initialDay != null
              ? 'Log food · ${DateFormat.MMMd().format(widget.initialDay!)}'
              : 'Log food',
        ),
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
          if (_isAlternateDay && widget.initialDay != null)
            Container(
              width: double.infinity,
              color: theme.colorScheme.tertiaryContainer
                  .withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 18,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Adding to '
                      '${DateFormat.yMMMEd().format(widget.initialDay!)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onTertiaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                              leading:
                                  _FoodEmojiAvatar(name: e.displayName),
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
                    leading: _FoodEmojiAvatar(name: f.name),
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
                    leading: _FoodEmojiAvatar(name: f.name),
                    title: Text(f.name),
                    subtitle: Text('${f.kcalPer100g.round()} kcal / 100 g'),
                    trailing: _GroupSizesBadge(foodId: f.id),
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

/// Round chip showing the food's emoji (or a fallback icon when no
/// rule matches the name). Mirrors the dashboard's tile avatar.
class _FoodEmojiAvatar extends StatelessWidget {
  const _FoodEmojiAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emoji = emojiForFood(name);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji, style: const TextStyle(fontSize: 18))
          : Icon(
              Icons.restaurant_outlined,
              size: 18,
              color: scheme.onSurfaceVariant,
            ),
    );
  }
}

/// Small badge that fetches the group attached to a catalog food and
/// shows "N sizes" when there are at least 2 presets. Silent otherwise.
class _GroupSizesBadge extends StatelessWidget {
  const _GroupSizesBadge({required this.foodId});

  final String foodId;

  @override
  Widget build(BuildContext context) {
    final catalog = context.read<OpenNutritionCatalog>();
    return FutureBuilder<CatalogFoodGroup?>(
      future: catalog.groupForFood(foodId),
      builder: (context, snap) {
        final group = snap.data;
        if (group == null || group.presets.length < 2) {
          return const SizedBox.shrink();
        }
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${group.presets.length} sizes',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSecondaryContainer,
            ),
          ),
        );
      },
    );
  }
}

import 'dart:async';

import 'package:caltrack/app/app_snackbar.dart';
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

  /// When non-null, new log entries default to a timestamp on this day.
  final DateTime? initialDay;

  @override
  State<LogFoodScreen> createState() => _LogFoodScreenState();
}

class _LogFoodScreenState extends State<LogFoodScreen> {
  final TextEditingController _search = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  List<CatalogFood> _results = [];
  List<CustomFood> _customResults = [];
  bool _searching = false;
  String _lastQuery = '';
  Map<String, int> _foodFrequencies = const {};
  late Future<List<FoodLogEntry>> _recentFuture;

  bool get _hasQuery => _search.text.trim().length >= 2;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFrequencies();
      _recentFuture =
          context.read<CalTrackRepository>().recentDistinctFoodLogs(limit: 15);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.removeListener(_onSearchChanged);
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {}); // rebuild for suffix-icon / idle↔results switch
    _debounce?.cancel();
    final q = _search.text.trim();
    if (q.length < 2) {
      setState(() {
        _results = [];
        _customResults = [];
        _lastQuery = '';
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 260), () => _runSearch(q));
  }

  void _clearSearch() {
    _search.clear();
    _searchFocus.requestFocus();
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
    final indexed = [for (var i = 0; i < raw.length; i++) (i: i, food: raw[i])];
    indexed.sort((a, b) {
      final s = _catalogScore(b.food).compareTo(_catalogScore(a.food));
      return s != 0 ? s : a.i.compareTo(b.i);
    });
    return [for (final r in indexed) r.food];
  }

  List<CustomFood> _rankCustom(List<CustomFood> raw) {
    if (_foodFrequencies.isEmpty) return raw;
    final indexed = [for (var i = 0; i < raw.length; i++) (i: i, food: raw[i])];
    indexed.sort((a, b) {
      final s = _customScore(b.food).compareTo(_customScore(a.food));
      return s != 0 ? s : a.i.compareTo(b.i);
    });
    return [for (final r in indexed) r.food];
  }

  Future<void> _runSearch(String q) async {
    final catalog = context.read<OpenNutritionCatalog>();
    final repo = context.read<CalTrackRepository>();
    if (!mounted) return;
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
        _results = _rankCatalog(res[0] as List<CatalogFood>);
        _customResults = _rankCustom(res[1] as List<CustomFood>);
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  DateTime? _initialLoggedAt() {
    final day = widget.initialDay;
    if (day == null) return null;
    final today = DateTime.now();
    final isToday =
        day.year == today.year && day.month == today.month && day.day == today.day;
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

  Future<void> _openCustomFood(CustomFood food, {double? initialAmount}) async {
    final serving = food.servingSize;
    final factor = serving > 0 ? 100.0 / serving : 1.0;
    final unit = ServingUnit.values.byName(food.servingUnit);
    final presets = serving > 0
        ? [
            CatalogGroupPreset(
              foodId: 'custom:${food.id}',
              label: 'serving',
              grams: serving,
              isDefault: true,
              sortOrder: 0,
            )
          ]
        : const <CatalogGroupPreset>[];
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
        presets: presets,
        initialPresetLabel: presets.isNotEmpty ? presets.first.label : null,
        showPresetPicker: presets.length > 1,
      ),
    );
    if (!mounted || action == null) return;
    if (action == FoodEntryAction.added) {
      _refreshRecent();
      if (mounted) {
        context.showAppSnackBar('Logged ${food.name}');
      }
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
    final canonical = (group != null && group.canonicalFoodId != food.id)
        ? await catalog.byId(group.canonicalFoodId) ?? food
        : food;
    if (!mounted) return;
    final displayName = group?.label ?? canonical.name;
    final presets = group?.presets ?? const <CatalogGroupPreset>[];
    final defaultPreset = group?.defaultPreset;
    final resolved = initialGrams ?? (defaultPreset?.grams ?? 100.0);

    final action = await showFoodEntrySheet(
      context,
      FoodEntrySheetConfig(
        displayName: displayName,
        source: 'opennutrition',
        catalogFoodId: canonical.id,
        kcalPer100g: canonical.kcalPer100g,
        proteinPer100g: canonical.proteinPer100g,
        carbsPer100g: canonical.carbsPer100g,
        sugarPer100g: canonical.sugarPer100g,
        fiberPer100g: canonical.fiberPer100g,
        fatPer100g: canonical.fatPer100g,
        initialGrams: resolved,
        showOpenNutritionAttribution: true,
        loggedAtForEdit: _initialLoggedAt(),
        presets: presets,
        initialPresetLabel: initialPresetLabel,
        initialPresetQty: initialPresetQty,
      ),
    );
    if (!mounted || action == null) return;
    if (action == FoodEntryAction.added) {
      _refreshRecent();
      if (mounted) {
        context.showAppSnackBar('Logged $displayName');
      }
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
        final group = await catalog.groupForFood(id);
        if (!mounted) return;
        final matched = group?.presetForFoodId(id);
        await _openCatalogFood(
          food,
          initialGrams: entry.grams,
          initialPresetLabel: matched?.label,
          initialPresetQty:
              matched != null && matched.grams > 0 ? entry.grams / matched.grams : null,
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
    final f = entry.grams > 0 ? 100.0 / entry.grams : 1.0;
    final action = await showFoodEntrySheet(
      context,
      FoodEntrySheetConfig(
        displayName: entry.displayName,
        source: entry.source,
        catalogFoodId: entry.catalogFoodId,
        kcalPer100g: entry.kcal * f,
        proteinPer100g: entry.proteinG * f,
        carbsPer100g: entry.carbsG * f,
        sugarPer100g: entry.sugarG * f,
        fiberPer100g: entry.fiberG * f,
        fatPer100g: entry.fatG * f,
        initialGrams: entry.grams,
        loggedAtForEdit: _initialLoggedAt(),
      ),
    );
    if (!mounted || action != FoodEntryAction.added) return;
    _refreshRecent();
    context.showAppSnackBar('Logged ${entry.displayName}');
  }

  void _refreshRecent() {
    if (!mounted) return;
    setState(() {
      _recentFuture = context
          .read<CalTrackRepository>()
          .recentDistinctFoodLogs(limit: 15);
    });
  }

  Future<void> _scanBarcode() async {
    final result = await context.push<Object?>('/scan-barcode');
    if (!mounted || result == null) return;
    if (result is CatalogFood) {
      await _openCatalogFood(result);
    } else if (result is CustomFood) {
      await _openCustomFood(result);
    }
  }

  // ---- Build -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isAlternateDay && widget.initialDay != null
              ? DateFormat.yMMMEd().format(widget.initialDay!)
              : 'Log food',
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // -- Alternate-day banner ------------------------------------------
          if (_isAlternateDay && widget.initialDay != null)
            _AlternateDayBanner(day: widget.initialDay!),

          // -- Search bar ----------------------------------------------------
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    focusNode: _searchFocus,
                    autofocus: true,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search foods…',
                      prefixIcon: _searching
                          ? Padding(
                              padding: const EdgeInsets.all(14),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: scheme.primary,
                                ),
                              ),
                            )
                          : const Icon(Icons.search_rounded),
                      suffixIcon: _hasQuery
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'Clear',
                              onPressed: _clearSearch,
                            )
                          : IconButton(
                              icon: const Icon(Icons.qr_code_scanner_outlined),
                              tooltip: 'Scan barcode',
                              onPressed: _scanBarcode,
                            ),
                    ),
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: ScaleTransition(scale: anim, child: child),
                    ),
                    child: _hasQuery
                        ? const SizedBox(key: ValueKey('hidden'), width: 0)
                        : Padding(
                            key: const ValueKey('add'),
                            padding: const EdgeInsets.only(left: 8),
                            child: _AddCustomFoodButton(
                              onPressed: () => context.push('/add-custom-food'),
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          // -- Content -------------------------------------------------------
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _hasQuery
                  ? _SearchResultsView(
                      key: const ValueKey('search'),
                      results: _results,
                      customResults: _customResults,
                      searching: _searching,
                      query: _search.text.trim(),
                      onCatalogTap: _openCatalogFood,
                      onCustomTap: _openCustomFood,
                      onAddCustomFood: () => context.push('/add-custom-food'),
                    )
                  : _IdleView(
                      key: const ValueKey('idle'),
                      recentFuture: _recentFuture,
                      onRecentTap: _openRecentEntry,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Idle view — shown when search bar is empty
// ---------------------------------------------------------------------------

class _IdleView extends StatelessWidget {
  const _IdleView({
    super.key,
    required this.recentFuture,
    required this.onRecentTap,
  });

  final Future<List<FoodLogEntry>> recentFuture;
  final ValueChanged<FoodLogEntry> onRecentTap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      children: [
        // Recent section
        _SectionHeader(
          icon: Icons.history_rounded,
          label: 'Recently logged',
        ),
        FutureBuilder<List<FoodLogEntry>>(
          future: recentFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final recent = snap.data ?? [];
            if (recent.isEmpty) {
              return const _EmptyRecent();
            }
            return Column(
              children: [
                for (var i = 0; i < recent.length; i++)
                  _RecentTile(
                    entry: recent[i],
                    onTap: () => onRecentTap(recent[i]),
                    showDivider: i < recent.length - 1,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Search results view — shown when query >= 2 chars
// ---------------------------------------------------------------------------

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    super.key,
    required this.results,
    required this.customResults,
    required this.searching,
    required this.query,
    required this.onCatalogTap,
    required this.onCustomTap,
    required this.onAddCustomFood,
  });

  final List<CatalogFood> results;
  final List<CustomFood> customResults;
  final bool searching;
  final String query;
  final void Function(CatalogFood) onCatalogTap;
  final void Function(CustomFood) onCustomTap;
  final VoidCallback onAddCustomFood;

  bool get _hasResults => results.isNotEmpty || customResults.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        // Custom food results
        if (customResults.isNotEmpty) ...[
          _SectionHeader(icon: Icons.person_outline_rounded, label: 'My foods'),
          for (var i = 0; i < customResults.length; i++)
            _CustomFoodTile(
              food: customResults[i],
              onTap: () => onCustomTap(customResults[i]),
              showDivider: i < customResults.length - 1 || results.isNotEmpty,
            ),
        ],

        // Catalog results
        if (results.isNotEmpty) ...[
          _SectionHeader(
            icon: Icons.menu_book_outlined,
            label: 'Catalog',
          ),
          for (var i = 0; i < results.length; i++)
            _CatalogFoodTile(
              food: results[i],
              onTap: () => onCatalogTap(results[i]),
              showDivider: i < results.length - 1,
            ),
        ],

        // Empty state
        if (!_hasResults && !searching)
          _NoResults(query: query, onAddCustomFood: onAddCustomFood),

        // Add custom food action (always present while in search mode)
        if (_hasResults) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text("Can't find it? Add a custom food"),
              style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onSurfaceVariant,
                side: BorderSide(color: scheme.outlineVariant),
              ),
              onPressed: onAddCustomFood,
            ),
          ),
        ],

        // Attribution
        if (results.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: OpenNutritionAttribution(),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared section header
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: scheme.primary),
          const SizedBox(width: 6),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: scheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent food tile
// ---------------------------------------------------------------------------

class _RecentTile extends StatelessWidget {
  const _RecentTile({
    required this.entry,
    required this.onTap,
    required this.showDivider,
  });

  final FoodLogEntry entry;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _EmojiAvatar(name: entry.displayName),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${entry.grams.round()} g  ·  '
                        'P ${entry.proteinG.round()}  '
                        'C ${entry.carbsG.round()}  '
                        'F ${entry.fatG.round()} g',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${entry.kcal.round()}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    Text(
                      'kcal',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 0,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Catalog food tile (search results)
// ---------------------------------------------------------------------------

class _CatalogFoodTile extends StatelessWidget {
  const _CatalogFoodTile({
    required this.food,
    required this.onTap,
    required this.showDivider,
  });

  final CatalogFood food;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _EmojiAvatar(name: food.name),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text(
                            'P ${food.proteinPer100g.round()}  '
                            'C ${food.carbsPer100g.round()}  '
                            'F ${food.fatPer100g.round()} g / 100 g',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _GroupSizesBadge(foodId: food.id),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${food.kcalPer100g.round()}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    Text(
                      'kcal/100g',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 0,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Custom food tile (search results)
// ---------------------------------------------------------------------------

class _CustomFoodTile extends StatelessWidget {
  const _CustomFoodTile({
    required this.food,
    required this.onTap,
    required this.showDivider,
  });

  final CustomFood food;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _EmojiAvatar(name: food.name),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              food.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _CustomBadge(),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (food.brand != null && food.brand!.isNotEmpty)
                            food.brand!,
                          '${food.servingSize.round()} ${food.servingUnit} serving',
                        ].join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${food.calories.round()}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    Text(
                      'kcal/serving',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 0,
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty & info states
// ---------------------------------------------------------------------------

class _EmptyRecent extends StatelessWidget {
  const _EmptyRecent();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu_outlined,
              size: 28,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Nothing logged yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Search for a food above or scan a barcode to get started.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.query, required this.onAddCustomFood});

  final String query;
  final VoidCallback onAddCustomFood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 48, 32, 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off_rounded,
              size: 28,
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No matches for "$query"',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try a different spelling, or create a custom food entry.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.tonalIcon(
            icon: const Icon(Icons.add_rounded, size: 18),
            label: Text('Create "$query" as custom food'),
            onPressed: onAddCustomFood,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Alternate day banner
// ---------------------------------------------------------------------------

class _AlternateDayBanner extends StatelessWidget {
  const _AlternateDayBanner({required this.day});

  final DateTime day;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      color: scheme.tertiaryContainer.withValues(alpha: 0.45),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 16,
            color: scheme.onTertiaryContainer,
          ),
          const SizedBox(width: 8),
          Text(
            'Adding to ${DateFormat.yMMMEd().format(day)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onTertiaryContainer,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small reusable widgets
// ---------------------------------------------------------------------------

class _EmojiAvatar extends StatelessWidget {
  const _EmojiAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final emoji = emojiForFood(name);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: emoji != null
          ? Text(emoji, style: const TextStyle(fontSize: 22))
          : Icon(Icons.restaurant_outlined, size: 20, color: scheme.onSurfaceVariant),
    );
  }
}

/// Compact "add custom food" action that sits next to the search bar.
/// Sized to match the TextField's height so the row aligns cleanly.
class _AddCustomFoodButton extends StatelessWidget {
  const _AddCustomFoodButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 48,
      height: 48,
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Tooltip(
            message: 'Add custom food',
            child: Icon(
              Icons.add_rounded,
              color: scheme.onPrimaryContainer,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge shown when a catalog food has multiple size/type presets.
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
        if (group == null || group.presets.length < 2) return const SizedBox.shrink();
        final scheme = Theme.of(context).colorScheme;
        return _Pill(
          label: '${group.presets.length} presets',
          color: scheme.secondaryContainer,
          onColor: scheme.onSecondaryContainer,
        );
      },
    );
  }
}

/// Badge shown on custom food tiles.
class _CustomBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _Pill(
      label: 'Custom',
      color: scheme.tertiaryContainer,
      onColor: scheme.onTertiaryContainer,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.onColor,
  });

  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: onColor,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

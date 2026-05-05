import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// One row from the bundled OpenNutrition SQLite catalog.
class CatalogFood {
  const CatalogFood({
    required this.id,
    required this.name,
    this.ean,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    required this.isLiquid,
  });

  final String id;
  final String name;
  final String? ean;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final bool isLiquid;
}

/// A named portion for a catalog food, harvested from OpenNutrition's
/// ``serving`` field at import time. Quantities are always in grams so
/// scaling math stays mass-based (see [scaleFromPer100g]).
class CatalogServing {
  const CatalogServing({
    required this.id,
    required this.foodId,
    required this.label,
    required this.grams,
    required this.isDefault,
    required this.sortOrder,
  });

  final int id;
  final String foodId;
  final String label;
  final double grams;
  final bool isDefault;
  final int sortOrder;
}

/// A preset inside a [CatalogFoodGroup]. Unlike [CatalogServing] a group
/// preset can "borrow" a foodId (so the same physical catalog row can
/// surface as multiple labeled portions, e.g. Large egg / Extra large egg
/// both backed by the Large Eggs row).
class CatalogGroupPreset {
  const CatalogGroupPreset({
    required this.foodId,
    required this.label,
    required this.grams,
    required this.isDefault,
    required this.sortOrder,
  });

  final String foodId;
  final String label;
  final double grams;
  final bool isDefault;
  final int sortOrder;
}

/// A logical grouping of several catalog foods under one user-facing
/// entry. E.g. Small/Medium/Large/Jumbo Eggs all collapse into a
/// "Eggs" group whose [canonicalFoodId] backs the displayed macros.
class CatalogFoodGroup {
  const CatalogFoodGroup({
    required this.id,
    required this.label,
    required this.canonicalFoodId,
    required this.presets,
  });

  final String id;
  final String label;
  final String canonicalFoodId;
  final List<CatalogGroupPreset> presets;

  CatalogGroupPreset? get defaultPreset {
    for (final preset in presets) {
      if (preset.isDefault) return preset;
    }
    return presets.isNotEmpty ? presets.first : null;
  }

  /// Returns the preset whose backing catalog row matches [foodId], or
  /// null if no such preset exists. Useful when reopening an existing
  /// log entry: we look up the group, then find the preset tied to the
  /// original food id.
  CatalogGroupPreset? presetForFoodId(String foodId) {
    for (final preset in presets) {
      if (preset.foodId == foodId) return preset;
    }
    return null;
  }
}

/// Offline search + barcode lookup against [assets/opennutrition.sqlite].
class OpenNutritionCatalog {
  OpenNutritionCatalog();

  static const _assetPath = 'assets/opennutrition.sqlite';

  /// Bump whenever the bundled SQLite is regenerated so existing
  /// installs replace their cached copy. The cache file in the
  /// documents directory is keyed by this version, and a sentinel
  /// `<file>.version` text file records the version that wrote it.
  ///
  /// History:
  /// * `v1` – initial import (had `fat_100g = 0` for every row because
  ///   the importer read the wrong JSON key).
  /// * `v2` – fixed `total_fat` extraction; full catalog rebuilt.
  /// * `v3` – added `is_liquid` column for ml-first UI defaults.
  /// * `v4` – added `food_servings`, `food_groups`,
  ///   `food_group_members` tables for serving presets (e.g. egg sizes).
  static const _catalogVersion = 'v4';

  Database? _db;

  Future<Database> _ensureOpen() async {
    final existing = _db;
    if (existing != null) return existing;

    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'opennutrition.sqlite');
    final versionPath = '$path.version';
    final file = File(path);
    final versionFile = File(versionPath);

    final cachedVersion = versionFile.existsSync()
        ? versionFile.readAsStringSync().trim()
        : null;
    final needsRefresh =
        !file.existsSync() || cachedVersion != _catalogVersion;
    if (needsRefresh) {
      final data = await rootBundle.load(_assetPath);
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      await versionFile.writeAsString(_catalogVersion, flush: true);
    }

    final db = sqlite3.open(path, mode: OpenMode.readOnly);
    _db = db;
    return db;
  }

  /// Strips non-digits; returns 13-digit EAN-13 or null.
  static String? normalizeEan(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 13) return digits;
    if (digits.length == 12) {
      return digits.padLeft(13, '0');
    }
    return null;
  }

  /// Builds a safe FTS5 `MATCH` expression (prefix terms with AND).
  static String ftsMatchExpression(String query) {
    final parts = query
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(12)
        .toList();
    if (parts.isEmpty) return '';
    return parts.map((t) {
      final escaped = t.replaceAll('"', '""');
      return '"$escaped"*';
    }).join(' AND ');
  }

  Future<List<CatalogFood>> search(String query, {int limit = 40}) async {
    final fts = ftsMatchExpression(query);
    if (fts.isEmpty) return [];

    final db = await _ensureOpen();
    // Over-fetch so group-collapsing doesn't starve the result list.
    final effectiveLimit = limit * 2;
    final result = db.select(
      '''
      SELECT f.id, f.name, f.ean, f.kcal_100g, f.protein_100g, f.carbs_100g, f.fat_100g, f.is_liquid
      FROM foods_fts
      JOIN foods f ON f.id = foods_fts.food_id
      WHERE foods_fts MATCH ?
      ORDER BY bm25(foods_fts)
      LIMIT ?
      ''',
      [fts, effectiveLimit],
    );
    final raw = result.map(_rowToFood).toList();
    return _collapseGroups(db, raw, limit);
  }

  /// Collapse search results that belong to the same group into a single
  /// row backed by the canonical food. Preserves the original order:
  /// the first member found for a group represents it.
  List<CatalogFood> _collapseGroups(
    Database db,
    List<CatalogFood> raw,
    int limit,
  ) {
    if (raw.isEmpty) return raw;
    // Lookup: food_id -> group_id for any row involved in a group.
    final ids = raw.map((f) => "'${f.id.replaceAll("'", "''")}'").join(',');
    final groupRows = db.select(
      'SELECT food_id, group_id FROM food_group_members WHERE food_id IN ($ids)',
    );
    if (groupRows.isEmpty) return raw.length > limit ? raw.sublist(0, limit) : raw;
    final groupByFood = <String, String>{};
    for (final row in groupRows) {
      groupByFood.putIfAbsent(
        row['food_id'] as String,
        () => row['group_id'] as String,
      );
    }
    if (groupByFood.isEmpty) {
      return raw.length > limit ? raw.sublist(0, limit) : raw;
    }
    // Preload canonical food rows for each touched group so we can swap
    // in the correct macros and display name.
    final canonicalByGroup = <String, CatalogFood>{};
    final groupLabelByGroup = <String, String>{};
    final touchedGroups = groupByFood.values.toSet().toList();
    if (touchedGroups.isNotEmpty) {
      final placeholders =
          touchedGroups.map((g) => "'${g.replaceAll("'", "''")}'").join(',');
      final gRows = db.select(
        '''
        SELECT g.id, g.label, g.canonical_food_id, f.name, f.ean,
               f.kcal_100g, f.protein_100g, f.carbs_100g, f.fat_100g, f.is_liquid
        FROM food_groups g
        JOIN foods f ON f.id = g.canonical_food_id
        WHERE g.id IN ($placeholders)
        ''',
      );
      for (final row in gRows) {
        final gid = row['id'] as String;
        groupLabelByGroup[gid] = row['label'] as String;
        canonicalByGroup[gid] = CatalogFood(
          id: row['canonical_food_id'] as String,
          name: row['label'] as String, // surface the group label, not raw row name
          ean: row['ean'] as String?,
          kcalPer100g: (row['kcal_100g'] as num).toDouble(),
          proteinPer100g: (row['protein_100g'] as num).toDouble(),
          carbsPer100g: (row['carbs_100g'] as num).toDouble(),
          fatPer100g: (row['fat_100g'] as num).toDouble(),
          isLiquid: (row['is_liquid'] as int) != 0,
        );
      }
    }
    // Unused: silence analyzer (groupLabelByGroup is the source for
    // future subtitle work; canonical name already uses it).
    groupLabelByGroup.length;

    final out = <CatalogFood>[];
    final seenGroups = <String>{};
    for (final food in raw) {
      final gid = groupByFood[food.id];
      if (gid == null) {
        out.add(food);
      } else {
        if (seenGroups.add(gid)) {
          out.add(canonicalByGroup[gid] ?? food);
        } else {
          continue; // skip duplicate group members
        }
      }
      if (out.length >= limit) break;
    }
    return out;
  }

  Future<CatalogFood?> byId(String id) async {
    if (id.isEmpty) return null;
    final db = await _ensureOpen();
    final result = db.select(
      '''
      SELECT id, name, ean, kcal_100g, protein_100g, carbs_100g, fat_100g, is_liquid
      FROM foods
      WHERE id = ?
      LIMIT 1
      ''',
      [id],
    );
    if (result.isEmpty) return null;
    return _rowToFood(result.first);
  }

  Future<List<CatalogFood>> byEan(String ean) async {
    final normalized = normalizeEan(ean);
    if (normalized == null) return [];

    final db = await _ensureOpen();
    final result = db.select(
      '''
      SELECT id, name, ean, kcal_100g, protein_100g, carbs_100g, fat_100g, is_liquid
      FROM foods
      WHERE ean = ?
      LIMIT 50
      ''',
      [normalized],
    );
    return result.map(_rowToFood).toList();
  }

  /// Per-food servings (e.g. "1 large egg = 50 g"). Empty if none were
  /// curated at import time.
  Future<List<CatalogServing>> servingsForFood(String foodId) async {
    if (foodId.isEmpty) return const [];
    final db = await _ensureOpen();
    final rows = db.select(
      '''
      SELECT id, food_id, label, grams, is_default, sort_order
      FROM food_servings
      WHERE food_id = ?
      ORDER BY sort_order ASC, id ASC
      ''',
      [foodId],
    );
    return rows
        .map((r) => CatalogServing(
              id: r['id'] as int,
              foodId: r['food_id'] as String,
              label: r['label'] as String,
              grams: (r['grams'] as num).toDouble(),
              isDefault: (r['is_default'] as int) != 0,
              sortOrder: r['sort_order'] as int,
            ))
        .toList();
  }

  /// Group that contains [foodId] as either the canonical row or a
  /// member. Returns null if [foodId] is not part of any group.
  Future<CatalogFoodGroup?> groupForFood(String foodId) async {
    if (foodId.isEmpty) return null;
    final db = await _ensureOpen();
    final gidRows = db.select(
      'SELECT group_id FROM food_group_members WHERE food_id = ? LIMIT 1',
      [foodId],
    );
    String? groupId;
    if (gidRows.isNotEmpty) {
      groupId = gidRows.first['group_id'] as String;
    } else {
      // Fall back to canonical match (canonical row may have no member row
      // of its own if the config didn't list it explicitly).
      final canon = db.select(
        'SELECT id FROM food_groups WHERE canonical_food_id = ? LIMIT 1',
        [foodId],
      );
      if (canon.isEmpty) return null;
      groupId = canon.first['id'] as String;
    }
    return groupById(groupId);
  }

  /// Load a group by its string id.
  Future<CatalogFoodGroup?> groupById(String groupId) async {
    if (groupId.isEmpty) return null;
    final db = await _ensureOpen();
    final gRows = db.select(
      'SELECT id, label, canonical_food_id FROM food_groups WHERE id = ? LIMIT 1',
      [groupId],
    );
    if (gRows.isEmpty) return null;
    final g = gRows.first;
    final presets = db.select(
      '''
      SELECT food_id, preset_label, grams, is_default, sort_order
      FROM food_group_members
      WHERE group_id = ?
      ORDER BY sort_order ASC, id ASC
      ''',
      [groupId],
    );
    return CatalogFoodGroup(
      id: g['id'] as String,
      label: g['label'] as String,
      canonicalFoodId: g['canonical_food_id'] as String,
      presets: presets.map((r) {
        final grams = (r['grams'] as num?)?.toDouble();
        return CatalogGroupPreset(
          foodId: r['food_id'] as String,
          label: (r['preset_label'] as String?) ?? '',
          grams: grams ?? 0.0,
          isDefault: (r['is_default'] as int) != 0,
          sortOrder: r['sort_order'] as int,
        );
      }).where((p) => p.grams > 0 && p.label.isNotEmpty).toList(),
    );
  }

  /// Total number of foods in the bundled OpenNutrition catalog.
  Future<int> foodRowCount() async {
    final db = await _ensureOpen();
    final result = db.select('SELECT COUNT(*) AS n FROM foods');
    if (result.isEmpty) return 0;
    final n = result.first['n'];
    if (n is int) return n;
    if (n is num) return n.toInt();
    return 0;
  }

  CatalogFood _rowToFood(Row row) {
    return CatalogFood(
      id: row['id'] as String,
      name: row['name'] as String,
      ean: row['ean'] as String?,
      kcalPer100g: (row['kcal_100g'] as num).toDouble(),
      proteinPer100g: (row['protein_100g'] as num).toDouble(),
      carbsPer100g: (row['carbs_100g'] as num).toDouble(),
      fatPer100g: (row['fat_100g'] as num).toDouble(),
      isLiquid: (row['is_liquid'] as int) != 0,
    );
  }

  void dispose() {
    _db?.dispose();
    _db = null;
  }
}

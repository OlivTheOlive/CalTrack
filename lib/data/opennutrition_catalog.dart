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
  });

  final String id;
  final String name;
  final String? ean;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
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
  static const _catalogVersion = 'v2';

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
    final result = db.select(
      '''
      SELECT f.id, f.name, f.ean, f.kcal_100g, f.protein_100g, f.carbs_100g, f.fat_100g
      FROM foods_fts
      JOIN foods f ON f.id = foods_fts.food_id
      WHERE foods_fts MATCH ?
      ORDER BY bm25(foods_fts)
      LIMIT ?
      ''',
      [fts, limit],
    );
    return result.map(_rowToFood).toList();
  }

  Future<CatalogFood?> byId(String id) async {
    if (id.isEmpty) return null;
    final db = await _ensureOpen();
    final result = db.select(
      '''
      SELECT id, name, ean, kcal_100g, protein_100g, carbs_100g, fat_100g
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
      SELECT id, name, ean, kcal_100g, protein_100g, carbs_100g, fat_100g
      FROM foods
      WHERE ean = ?
      LIMIT 50
      ''',
      [normalized],
    );
    return result.map(_rowToFood).toList();
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
    );
  }

  void dispose() {
    _db?.dispose();
    _db = null;
  }
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart';

/// Direct-SQLite tests against the bundled `assets/opennutrition.sqlite`
/// asset. These don't exercise the Dart catalog class (which needs
/// rootBundle + path_provider) but do lock in the schema + curated groups.
void main() {
  group('bundled opennutrition.sqlite v4', () {
    late Database db;

    setUpAll(() {
      final path = File('assets/opennutrition.sqlite').absolute.path;
      if (!File(path).existsSync()) {
        fail('Run `python3 tool/opennutrition_import.py --clean` first');
      }
      db = sqlite3.open(path, mode: OpenMode.readOnly);
    });

    tearDownAll(() {
      db.dispose();
    });

    test('schema has food_servings, food_groups, food_group_members', () {
      final rows = db.select(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final names = rows.map((r) => r['name'] as String).toSet();
      expect(names, containsAll([
        'foods',
        'foods_fts',
        'food_servings',
        'food_groups',
        'food_group_members',
      ]));
    });

    test('8 food groups exist', () {
      final rows = db.select('SELECT COUNT(*) AS n FROM food_groups');
      expect((rows.first['n'] as int), 8);
    });

    // ---- Eggs --------------------------------------------------------
    test('eggs group exists with canonical Large Eggs row', () {
      final rows = db.select(
        "SELECT id, label, canonical_food_id FROM food_groups WHERE id='eggs'",
      );
      expect(rows, hasLength(1));
      expect(rows.first['label'], 'Eggs');
      expect(rows.first['canonical_food_id'], 'fd_F2MYJuH8UsE9');
    });

    test('eggs group exposes 5 presets sorted by size', () {
      final rows = db.select(
        "SELECT preset_label, grams, is_default FROM food_group_members "
        "WHERE group_id='eggs' ORDER BY sort_order",
      );
      expect(rows, hasLength(5));
      final labels = rows.map((r) => r['preset_label'] as String).toList();
      expect(labels, ['Small egg', 'Medium egg', 'Large egg', 'Extra large egg', 'Jumbo egg']);
      expect(rows.where((r) => r['is_default'] == 1), hasLength(1));
      expect(rows.firstWhere((r) => r['is_default'] == 1)['preset_label'], 'Large egg');
    });

    // ---- Banana ------------------------------------------------------
    test('banana group has 4 presets and 1 medium = 118g default', () {
      final rows = db.select(
        "SELECT preset_label, grams, is_default FROM food_group_members "
        "WHERE group_id='banana' ORDER BY sort_order",
      );
      expect(rows, hasLength(4));
      final def = rows.firstWhere((r) => r['is_default'] == 1);
      expect(def['preset_label'], '1 medium banana');
      expect((def['grams'] as num).toDouble(), 118.0);
    });

    // ---- Butter ------------------------------------------------------
    test('butter group has 4 presets covering salted and unsalted', () {
      final rows = db.select(
        "SELECT preset_label FROM food_group_members WHERE group_id='butter' ORDER BY sort_order",
      );
      expect(rows, hasLength(4));
      final labels = rows.map((r) => r['preset_label'] as String).toList();
      expect(labels.any((l) => l.contains('Unsalted')), isTrue);
      expect(labels.any((l) => l.contains('Salted')), isTrue);
    });

    // ---- Oats --------------------------------------------------------
    test('oats group has 5 presets and rolled oats is default', () {
      final rows = db.select(
        "SELECT preset_label, grams, is_default FROM food_group_members "
        "WHERE group_id='oats' ORDER BY sort_order",
      );
      expect(rows, hasLength(5));
      final def = rows.firstWhere((r) => r['is_default'] == 1);
      expect(def['preset_label'], contains('Rolled oats'));
    });

    // ---- White Rice --------------------------------------------------
    test('white_rice group has 3 grain-size presets', () {
      final rows = db.select(
        "SELECT preset_label FROM food_group_members WHERE group_id='white_rice'",
      );
      expect(rows, hasLength(3));
      final labels = rows.map((r) => r['preset_label'] as String).toList();
      expect(labels.any((l) => l.contains('Long grain')), isTrue);
      expect(labels.any((l) => l.contains('Medium grain')), isTrue);
      expect(labels.any((l) => l.contains('Short grain')), isTrue);
    });

    // ---- Brown Rice --------------------------------------------------
    test('brown_rice group has 3 grain-size presets', () {
      final rows = db.select(
        "SELECT preset_label FROM food_group_members WHERE group_id='brown_rice'",
      );
      expect(rows, hasLength(3));
    });

    // ---- Cheddar -----------------------------------------------------
    test('cheddar group has 5 presets including 1 oz and 2 oz options', () {
      final rows = db.select(
        "SELECT preset_label, grams FROM food_group_members "
        "WHERE group_id='cheddar' ORDER BY sort_order",
      );
      expect(rows, hasLength(5));
      final gramValues = rows.map((r) => (r['grams'] as num).toDouble()).toSet();
      expect(gramValues, containsAll([28.0, 57.0]));
    });

    // ---- Cottage Cheese ----------------------------------------------
    test('cottage_cheese group has 4 presets with ½ cup and 1 cup options', () {
      final rows = db.select(
        "SELECT preset_label, grams FROM food_group_members "
        "WHERE group_id='cottage_cheese' ORDER BY sort_order",
      );
      expect(rows, hasLength(4));
      final gramValues = rows.map((r) => (r['grams'] as num).toDouble()).toSet();
      expect(gramValues, containsAll([113.0, 226.0]));
    });

    // ---- Serving harvest -------------------------------------------
    test('Large Eggs row has a per-piece serving harvested from TSV', () {
      final rows = db.select(
        "SELECT label, grams FROM food_servings WHERE food_id='fd_F2MYJuH8UsE9'",
      );
      expect(rows, isNotEmpty);
      expect(rows.any((r) => (r['grams'] as num).toDouble() == 50.0), isTrue);
    });
  });
}

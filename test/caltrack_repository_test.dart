import 'package:caltrack/data/app_database.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalTrackRepository (in-memory)', () {
    late AppDatabase db;
    late CalTrackRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = CalTrackRepository(db);

      // Minimal seeded profile so repo helpers that depend on it won't crash.
      await db.into(db.profiles).insert(
            ProfilesCompanion.insert(
              sex: 'male',
              birthDateMillis: DateTime(1996, 1, 1).millisecondsSinceEpoch,
              ageBandMaxYears: const Value(30),
              heightCm: 175,
              activityLevel: 2,
              weightUnit: 'kg',
              proteinPct: 30,
              carbsPct: 40,
              fatPct: 30,
              reminderWeekday: DateTime.sunday,
              reminderHour: 9,
              reminderMinute: 0,
              onboardingCompleted: const Value(true),
              dailyCalorieTarget: const Value(2000),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('watchFoodLogsForDay only returns entries in that calendar day', () async {
      final day = DateTime(2026, 4, 28);
      final start = DateTime(2026, 4, 28, 0, 0);
      final endMinus1 = DateTime(2026, 4, 28, 23, 59);
      final nextDay = DateTime(2026, 4, 29, 0, 1);

      await repo.addFoodLog(
        source: 'custom',
        displayName: 'A',
        grams: 100,
        kcal: 100,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        loggedAt: start,
      );
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'B',
        grams: 100,
        kcal: 200,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        loggedAt: endMinus1,
      );
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'C',
        grams: 100,
        kcal: 300,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        loggedAt: nextDay,
      );

      final results = await repo.watchFoodLogsForDay(day).first;
      expect(results.map((e) => e.displayName).toList(), ['B', 'A']);
    });

    test('watchIntakeForDay sums kcal/macros within day bounds', () async {
      final day = DateTime(2026, 4, 28);
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'A',
        grams: 100,
        kcal: 100,
        proteinG: 10,
        carbsG: 20,
        fatG: 5,
        loggedAt: DateTime(2026, 4, 28, 8, 0),
      );
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'B',
        grams: 100,
        kcal: 250,
        proteinG: 5,
        carbsG: 10,
        fatG: 10,
        loggedAt: DateTime(2026, 4, 28, 20, 0),
      );
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'NextDay',
        grams: 100,
        kcal: 999,
        proteinG: 999,
        carbsG: 999,
        fatG: 999,
        loggedAt: DateTime(2026, 4, 29, 0, 1),
      );

      final totals = await repo.watchIntakeForDay(day).first;
      expect(totals.kcal, 350);
      expect(totals.proteinG, 15);
      expect(totals.carbsG, 30);
      expect(totals.fatG, 15);
    });

    test('dailyKcalTotals aggregates by calendar day', () async {
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'D1-A',
        grams: 100,
        kcal: 100,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        loggedAt: DateTime(2026, 4, 27, 10),
      );
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'D1-B',
        grams: 100,
        kcal: 200,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        loggedAt: DateTime(2026, 4, 27, 20),
      );
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'D2',
        grams: 100,
        kcal: 50,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        loggedAt: DateTime(2026, 4, 28, 9),
      );

      final totals = await repo.dailyKcalTotals(
        start: DateTime(2026, 4, 27),
        endExclusive: DateTime(2026, 4, 29),
      );

      expect(totals[DateTime(2026, 4, 27)], 300);
      expect(totals[DateTime(2026, 4, 28)], 50);
      expect(totals.containsKey(DateTime(2026, 4, 29)), isFalse);
    });

    test('weightEntryForDay returns latest entry within that day', () async {
      final day = DateTime(2026, 4, 28);
      await db.into(db.weightEntries).insert(
            WeightEntriesCompanion.insert(
              recordedAt: DateTime(2026, 4, 28, 8, 0),
              weightKg: 80.0,
              note: const Value('morning'),
            ),
          );
      await db.into(db.weightEntries).insert(
            WeightEntriesCompanion.insert(
              recordedAt: DateTime(2026, 4, 28, 18, 0),
              weightKg: 79.5,
              note: const Value('evening'),
            ),
          );
      await db.into(db.weightEntries).insert(
            WeightEntriesCompanion.insert(
              recordedAt: DateTime(2026, 4, 29, 8, 0),
              weightKg: 79.0,
              note: const Value('next'),
            ),
          );

      final entry = await repo.weightEntryForDay(day);
      expect(entry, isNotNull);
      expect(entry!.weightKg, 79.5);
      expect(entry.note, 'evening');
    });

    test('updateWeightEntry updates weight and note', () async {
      final id = await db.into(db.weightEntries).insert(
            WeightEntriesCompanion.insert(
              recordedAt: DateTime(2026, 4, 28, 8, 0),
              weightKg: 80.0,
              note: const Value('before'),
            ),
          );

      await repo.updateWeightEntry(id: id, weightKg: 79.8, note: 'after');
      final updated = await repo.weightEntryById(id);

      expect(updated, isNotNull);
      expect(updated!.weightKg, 79.8);
      expect(updated.note, 'after');
    });

    test('exportJson includes foodPrefs', () async {
      await repo.setTreatAsLiquid(foodKey: 'cat:abc', treatAsLiquid: true);
      await repo.setSavedServing(foodKey: 'cat:abc', amount: 250, unit: 'ml');

      final out = await repo.exportJson();
      expect(out['version'], 1);
      final prefs = out['foodPrefs'] as List;
      expect(prefs, isNotEmpty);
    });

    test('importJson overwrite clears existing data first', () async {
      // Prepare an export payload that does NOT include the row we will add
      // later. (This simulates restoring from an older backup.)
      await repo.setTreatAsLiquid(foodKey: 'cat:x', treatAsLiquid: true);
      final exportPayload = await repo.exportJson();

      // Seed some data that should be wiped by overwrite import.
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'Old',
        grams: 100,
        kcal: 123,
        proteinG: 1,
        carbsG: 2,
        fatG: 3,
        loggedAt: DateTime(2026, 4, 28, 8),
      );
      await repo.setTreatAsLiquid(foodKey: 'name:old', treatAsLiquid: true);

      await repo.importJson(exportPayload, overwrite: true);

      final logs = await db.select(db.foodLogEntries).get();
      final fp = await db.select(db.foodPrefs).get();
      // After overwrite import, rows should match the import payload; in
      // particular, we should no longer have the original 'Old' log.
      expect(logs.where((e) => e.displayName == 'Old'), isEmpty);
      // And prefs table should be populated from import.
      expect(fp, isNotEmpty);
    });

    test('importJson merge upserts by id without duplicating', () async {
      // Create a custom food and a pref row.
      final customId = await repo.upsertCustomFood(
        name: 'MyFood',
        brand: null,
        barcode: null,
        servingSize: 100,
        servingUnit: 'g',
        calories: 100,
        fatG: 1,
        carbsG: 2,
        sugarG: 0,
        fiberG: 0,
        proteinG: 3,
      );
      await repo.setSavedServing(
        foodKey: foodLogKeyForCustomId(customId),
        amount: 42,
        unit: 'g',
      );

      final export = await repo.exportJson();

      // Mutate existing pref to a different value, then merge import.
      await repo.setSavedServing(
        foodKey: foodLogKeyForCustomId(customId),
        amount: 99,
        unit: 'g',
      );

      await repo.importJson(export, overwrite: false);

      final pref = await repo.foodPrefByKey(foodLogKeyForCustomId(customId));
      expect(pref, isNotNull);
      // Should match the imported value (42), not duplicate rows.
      expect(pref!.savedServingAmount, 42);
      final allPrefs = await db.select(db.foodPrefs).get();
      expect(
        allPrefs.where((p) => p.foodKey == foodLogKeyForCustomId(customId)),
        hasLength(1),
      );
    });

    test('schema contains food_prefs table', () async {
      final rows = await db
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type='table' AND name='food_prefs'",
          )
          .get();
      expect(rows, isNotEmpty);
    });

    test('setLastUsedServing persists label and quantity, then clears them',
        () async {
      const key = 'cat:fd_F2MYJuH8UsE9';
      await repo.setLastUsedServing(
        foodKey: key,
        label: 'Large egg',
        quantity: 2,
      );
      final saved = await repo.foodPrefByKey(key);
      expect(saved, isNotNull);
      expect(saved!.lastServingLabel, 'Large egg');
      expect(saved.lastServingQty, 2);

      // Clearing should null both columns without deleting the row
      // (other prefs like treatAsLiquid may still live on it).
      await repo.setLastUsedServing(
        foodKey: key,
        label: null,
        quantity: null,
      );
      final cleared = await repo.foodPrefByKey(key);
      expect(cleared, isNotNull);
      expect(cleared!.lastServingLabel, equals(null));
      expect(cleared.lastServingQty, equals(null));
    });

    test('quick-add entry saved with source=quick and grams=100', () async {
      await repo.addFoodLog(
        source: 'quick',
        displayName: 'Pizza slice',
        grams: 100,
        kcal: 285,
        proteinG: 12,
        carbsG: 36,
        fatG: 10,
        loggedAt: DateTime(2026, 5, 4, 13),
      );

      final entries = await db.select(db.foodLogEntries).get();
      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.source, 'quick');
      expect(e.displayName, 'Pizza slice');
      expect(e.grams, 100);
      expect(e.kcal, 285);
      expect(e.proteinG, 12);
      expect(e.carbsG, 36);
      expect(e.fatG, 10);
      // No catalog or custom id attached.
      expect(e.catalogFoodId, equals(null));
      expect(e.customFoodId, equals(null));
    });

    test('quick-add with calories only (macros default to 0)', () async {
      await repo.addFoodLog(
        source: 'quick',
        displayName: 'Handful of nuts',
        grams: 100,
        kcal: 180,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
        loggedAt: DateTime(2026, 5, 4, 14),
      );

      final entries = await db.select(db.foodLogEntries).get();
      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.kcal, 180);
      expect(e.proteinG, 0);
      expect(e.carbsG, 0);
      expect(e.fatG, 0);
    });

    test('food log with mealPeriod', () async {
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'Oatmeal',
        grams: 200,
        kcal: 300,
        proteinG: 10,
        carbsG: 50,
        fatG: 5,
        loggedAt: DateTime(2026, 5, 5, 8),
        mealPeriod: MealPeriod.breakfast,
      );

      final entries = await db.select(db.foodLogEntries).get();
      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.mealPeriod, 'breakfast');
      expect(e.isPlanned, false);
    });

    test('food log with isPlanned', () async {
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'Meal prep',
        grams: 300,
        kcal: 500,
        proteinG: 30,
        carbsG: 60,
        fatG: 15,
        loggedAt: DateTime(2026, 5, 10, 12),
        mealPeriod: MealPeriod.lunch,
        isPlanned: true,
      );

      final entries = await db.select(db.foodLogEntries).get();
      expect(entries, hasLength(1));
      final e = entries.first;
      expect(e.mealPeriod, 'lunch');
      expect(e.isPlanned, true);
    });

    test('updateFoodLog preserves mealPeriod', () async {
      final id = await repo.addFoodLogReturnId(
        source: 'custom',
        displayName: 'Salad',
        grams: 200,
        kcal: 350,
        proteinG: 15,
        carbsG: 30,
        fatG: 20,
        loggedAt: DateTime(2026, 5, 6, 12),
        mealPeriod: MealPeriod.lunch,
      );

      await repo.updateFoodLog(
        id: id,
        grams: 250,
        kcal: 400,
        proteinG: 18,
        carbsG: 35,
        fatG: 22,
        mealPeriod: MealPeriod.dinner,
      );

      final e = await db.select(db.foodLogEntries).getSingle();
      expect(e.mealPeriod, 'dinner');
      expect(e.grams, 250);
    });

    test('intakeForDayByPeriod groups correctly', () async {
      final day = DateTime(2026, 5, 7);
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'Oatmeal',
        grams: 200,
        kcal: 300,
        proteinG: 10,
        carbsG: 50,
        fatG: 5,
        loggedAt: DateTime(2026, 5, 7, 8),
        mealPeriod: MealPeriod.breakfast,
      );
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'Chicken',
        grams: 200,
        kcal: 400,
        proteinG: 40,
        carbsG: 10,
        fatG: 20,
        loggedAt: DateTime(2026, 5, 7, 13),
        mealPeriod: MealPeriod.lunch,
      );
      await repo.addFoodLog(
        source: 'custom',
        displayName: 'Yogurt',
        grams: 150,
        kcal: 150,
        proteinG: 8,
        carbsG: 12,
        fatG: 5,
        loggedAt: DateTime(2026, 5, 7, 16),
        mealPeriod: MealPeriod.snack,
      );

      final byPeriod = await repo.intakeForDayByPeriod(day);
      expect(byPeriod[MealPeriod.breakfast]!.kcal, 300);
      expect(byPeriod[MealPeriod.lunch]!.kcal, 400);
      expect(byPeriod[MealPeriod.snack]!.kcal, 150);
    });
  });
}


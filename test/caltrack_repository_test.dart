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
  });
}


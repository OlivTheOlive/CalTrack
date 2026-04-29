import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/core/nutrition_scaling.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mifflinStJeorBmr', () {
    test('example male', () {
      final bmr = mifflinStJeorBmr(
        isMale: true,
        weightKg: 80,
        heightCm: 180,
        ageYears: 30,
      );
      expect(bmr, closeTo(1785, 5));
    });
  });

  group('dailyCalorieTarget', () {
    test('maintenance', () {
      expect(dailyCalorieTarget(tdee: 2500, weeklyWeightChangeKg: 0), 2500);
    });

    test('loss half kg per week', () {
      final target = dailyCalorieTarget(tdee: 2500, weeklyWeightChangeKg: -0.5);
      expect(target, closeTo(2500 - (0.5 * 7700 / 7), 1));
    });
  });

  group('macroGramsFromPercentages', () {
    test('sums to daily calories approximately', () {
      final m = macroGramsFromPercentages(2000, 30, 40, 30);
      final kcal = m.protein * 4 + m.carbs * 4 + m.fat * 9;
      expect(kcal, closeTo(2000, 1));
    });
  });

  group('scaleFromPer100g', () {
    test('50g of 200 kcal per 100g', () {
      final s = scaleFromPer100g(
        grams: 50,
        kcalPer100g: 200,
        proteinPer100g: 10,
        carbsPer100g: 20,
        fatPer100g: 5,
      );
      expect(s.kcal, 100);
      expect(s.proteinG, 5);
      expect(s.carbsG, 10);
      expect(s.fatG, 2.5);
    });
  });

  group('rescaleLoggedPortion', () {
    test('double grams doubles macros', () {
      final s = rescaleLoggedPortion(
        previousGrams: 100,
        previousKcal: 250,
        previousProteinG: 20,
        previousCarbsG: 30,
        previousFatG: 10,
        newGrams: 200,
      );
      expect(s.kcal, 500);
      expect(s.proteinG, 40);
      expect(s.carbsG, 60);
      expect(s.fatG, 20);
    });
  });

  group('computeDayStreak', () {
    DateTime d(int y, int m, int day) => DateTime(y, m, day);

    test('returns zero current and best when no qualifying days', () {
      final s = computeDayStreak(
        qualifyingDays: <DateTime>{},
        referenceDay: d(2026, 4, 28),
      );
      expect(s.current, 0);
      expect(s.best, 0);
    });

    test('counts current streak ending at reference day', () {
      final s = computeDayStreak(
        qualifyingDays: {
          d(2026, 4, 26),
          d(2026, 4, 27),
          d(2026, 4, 28),
        },
        referenceDay: d(2026, 4, 28),
      );
      expect(s.current, 3);
      expect(s.best, 3);
    });

    test('treats reference day not yet logged as still streaking', () {
      final s = computeDayStreak(
        qualifyingDays: {
          d(2026, 4, 26),
          d(2026, 4, 27),
        },
        referenceDay: d(2026, 4, 28),
      );
      expect(s.current, 2);
      expect(s.best, 2);
    });

    test('best streak ignores gaps and exceeds current', () {
      final s = computeDayStreak(
        qualifyingDays: {
          d(2026, 4, 1),
          d(2026, 4, 2),
          d(2026, 4, 3),
          d(2026, 4, 4),
          d(2026, 4, 5),
          d(2026, 4, 27),
          d(2026, 4, 28),
        },
        referenceDay: d(2026, 4, 28),
      );
      expect(s.current, 2);
      expect(s.best, 5);
    });

    test('normalizes timestamps to calendar day', () {
      final s = computeDayStreak(
        qualifyingDays: {
          DateTime(2026, 4, 27, 8, 30),
          DateTime(2026, 4, 27, 19, 5),
          DateTime(2026, 4, 28, 7, 0),
        },
        referenceDay: DateTime(2026, 4, 28, 23, 59),
      );
      expect(s.current, 2);
    });

    test('breaks streak when a day is missing before reference', () {
      final s = computeDayStreak(
        qualifyingDays: {
          d(2026, 4, 24),
          d(2026, 4, 25),
          d(2026, 4, 27),
        },
        referenceDay: d(2026, 4, 28),
      );
      expect(s.current, 1);
      expect(s.best, 2);
    });
  });

  group('computeWeightTrendStats', () {
    ({DateTime recordedAt, double weightKg}) e(DateTime t, double kg) =>
        (recordedAt: t, weightKg: kg);

    test('filters to window and sorts chronologically', () {
      final ref = DateTime(2026, 4, 28);
      final stats = computeWeightTrendStats(
        entries: [
          e(DateTime(2026, 4, 28, 8), 80.0),
          e(DateTime(2026, 4, 1), 90.0),
          e(DateTime(2026, 4, 22), 81.0),
        ],
        windowDays: 7,
        referenceDay: ref,
      );
      expect(stats.points.length, 2);
      expect(stats.points.first.weightKg, 81.0);
      expect(stats.points.last.weightKg, 80.0);
    });

    test('reports kg/week from linear fit', () {
      final ref = DateTime(2026, 4, 28);
      final stats = computeWeightTrendStats(
        entries: [
          e(DateTime(2026, 4, 21), 80.0),
          e(DateTime(2026, 4, 28), 79.0),
        ],
        windowDays: 14,
        referenceDay: ref,
      );
      expect(stats.kgPerWeek, isNotNull);
      expect(stats.kgPerWeek!, closeTo(-1.0, 0.01));
    });

    test('consistency reflects distinct days / window', () {
      final ref = DateTime(2026, 4, 28);
      final stats = computeWeightTrendStats(
        entries: [
          e(DateTime(2026, 4, 28, 6), 80.0),
          e(DateTime(2026, 4, 28, 18), 80.2),
          e(DateTime(2026, 4, 27, 7), 80.4),
        ],
        windowDays: 7,
        referenceDay: ref,
      );
      expect(stats.distinctDaysLogged, 2);
      expect(stats.consistency, closeTo(2 / 7, 0.001));
    });

    test('returns null kgPerWeek when fewer than two points', () {
      final ref = DateTime(2026, 4, 28);
      final stats = computeWeightTrendStats(
        entries: [e(DateTime(2026, 4, 28), 80.0)],
        windowDays: 7,
        referenceDay: ref,
      );
      expect(stats.kgPerWeek, isNull);
      expect(stats.hasEnoughData, isFalse);
    });
  });

  group('adjustCaloriesForProgress', () {
    test('no change when within band', () {
      expect(
        adjustCaloriesForProgress(
          currentDailyTarget: 2000,
          intendedWeeklyChangeKg: -0.5,
          actualWeeklyChangeKg: -0.52,
        ),
        2000,
      );
    });

    test('nudge when too far off', () {
      expect(
        adjustCaloriesForProgress(
          currentDailyTarget: 2000,
          intendedWeeklyChangeKg: -0.5,
          actualWeeklyChangeKg: -0.1,
        ),
        1900,
      );
    });
  });

  group('age bands', () {
    test('upper bound for known band', () {
      expect(ageBandUpperBoundForYears(22), 25);
      expect(ageBandUpperBoundForYears(25), 25);
      expect(ageBandUpperBoundForYears(31), 35);
    });

    test('clamps to top band for very old ages', () {
      expect(ageBandUpperBoundForYears(120), 90);
    });

    test('label uses previous bound as lower edge', () {
      expect(ageBandLabel(25), '20–25');
      expect(ageBandLabel(18), '14–18');
      expect(ageBandLabel(90), '85+');
    });
  });

  group('computeCalorieBands', () {
    test('maintenance equals tdee, goal subtracts loss kcal', () {
      final bands = computeCalorieBands(
        tdee: 2500,
        weeklyChangeKgPerWeek: -0.5,
      );
      expect(bands.maintenance, 2500);
      expect(bands.goalDaily, closeTo(2500 - (0.5 * 7700 / 7), 1));
      expect(bands.floor, defaultMinDailyCalories);
    });
  });

  group('paceLevelForKgPerWeek', () {
    test('bins by magnitude regardless of sign', () {
      expect(paceLevelForKgPerWeek(0.2), PaceLevel.gentle);
      expect(paceLevelForKgPerWeek(-0.5), PaceLevel.moderate);
      expect(paceLevelForKgPerWeek(0.9), PaceLevel.aggressive);
    });
  });
}

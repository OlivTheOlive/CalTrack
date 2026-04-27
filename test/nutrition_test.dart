import 'package:caltrack/core/nutrition.dart';
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
}

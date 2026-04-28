import 'dart:math' as math;

/// ~7700 kcal per kg body fat change (approximation).
const double kcalPerKgFat = 7700;

enum ActivityLevel {
  sedentary,
  light,
  moderate,
  active,
  veryActive;

  double get multiplier {
    switch (this) {
      case ActivityLevel.sedentary:
        return 1.2;
      case ActivityLevel.light:
        return 1.375;
      case ActivityLevel.moderate:
        return 1.55;
      case ActivityLevel.active:
        return 1.725;
      case ActivityLevel.veryActive:
        return 1.9;
    }
  }

  static ActivityLevel fromIndex(int i) =>
      ActivityLevel.values[i.clamp(0, ActivityLevel.values.length - 1)];
}

/// Mifflin–St Jeor BMR (kcal/day).
double mifflinStJeorBmr({
  required bool isMale,
  required double weightKg,
  required double heightCm,
  required int ageYears,
}) {
  final s = isMale ? 5 : -161;
  return 10 * weightKg + 6.25 * heightCm - 5 * ageYears + s;
}

double tdee({
  required bool isMale,
  required double weightKg,
  required double heightCm,
  required int ageYears,
  required ActivityLevel activity,
}) =>
    mifflinStJeorBmr(
          isMale: isMale,
          weightKg: weightKg,
          heightCm: heightCm,
          ageYears: ageYears,
        ) *
        activity.multiplier;

/// [weeklyWeightChangeKg] signed: negative = losing weight (kg/week).
double dailyCalorieTarget({
  required double tdee,
  required double weeklyWeightChangeKg,
}) {
  final dailyAdjustment = weeklyWeightChangeKg * kcalPerKgFat / 7.0;
  return tdee + dailyAdjustment;
}

class MacroGrams {
  const MacroGrams({
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  final double protein;
  final double carbs;
  final double fat;

  static const proteinKcalPerG = 4.0;
  static const carbsKcalPerG = 4.0;
  static const fatKcalPerG = 9.0;
}

/// Percentages must sum to 100; grams are rounded for display consistency.
MacroGrams macroGramsFromPercentages(
  double dailyCalories,
  int proteinPct,
  int carbsPct,
  int fatPct,
) {
  assert(proteinPct + carbsPct + fatPct == 100);
  final pCal = dailyCalories * proteinPct / 100.0;
  final cCal = dailyCalories * carbsPct / 100.0;
  final fCal = dailyCalories * fatPct / 100.0;
  return MacroGrams(
    protein: pCal / MacroGrams.proteinKcalPerG,
    carbs: cCal / MacroGrams.carbsKcalPerG,
    fat: fCal / MacroGrams.fatKcalPerG,
  );
}

/// Nudge daily calories if average weekly change is outside [bandKgPerWeek].
double adjustCaloriesForProgress({
  required double currentDailyTarget,
  required double intendedWeeklyChangeKg,
  required double actualWeeklyChangeKg,
  double bandKgPerWeek = 0.15,
  double stepKcal = 100,
  double minCalories = 1200,
  double maxCalories = 6000,
}) {
  final delta = actualWeeklyChangeKg - intendedWeeklyChangeKg;
  if (delta.abs() <= bandKgPerWeek) {
    return currentDailyTarget;
  }
  // Losing too slowly (actual less negative than intended): lower calories.
  // Gaining too slowly: raise calories.
  final nudge = delta > 0 ? -stepKcal : stepKcal;
  return math.min(maxCalories, math.max(minCalories, currentDailyTarget + nudge));
}

int ageFromBirthDate(DateTime birthDate, DateTime today) {
  var age = today.year - birthDate.year;
  final hadBirthday = today.month > birthDate.month ||
      (today.month == birthDate.month && today.day >= birthDate.day);
  if (!hadBirthday) age--;
  return age.clamp(14, 120);
}

/// Simple 7-day moving average of weight entries (most recent day = last in list).
double? movingAverageWeightKg(List<double> weightsDescending, {int window = 7}) {
  if (weightsDescending.isEmpty) return null;
  final slice = weightsDescending.take(window).toList();
  var total = 0.0;
  for (final w in slice) {
    total += w;
  }
  return total / slice.length;
}

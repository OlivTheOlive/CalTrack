import 'dart:math' as math;

/// ~7700 kcal per kg body fat change (approximation).
const double kcalPerKgFat = 7700;

/// Lower clamp shared between the calorie-band display and the weekly
/// auto-adjust nudges. Picked as a conservative everyday-use floor; not
/// medical advice.
const double defaultMinDailyCalories = 1200;

/// Upper clamp for auto-adjust nudges to avoid runaway escalation.
const double defaultMaxDailyCalories = 6000;

/// Tolerance band around the intended weekly weight change. While the
/// actual weekly change stays within ±[defaultProgressBandKgPerWeek] of
/// the intent, the calorie target is left untouched.
const double defaultProgressBandKgPerWeek = 0.15;

/// Step size used by the auto-adjust nudges when the actual weekly
/// change is outside the tolerance band.
const double defaultProgressStepKcal = 100;

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
  double bandKgPerWeek = defaultProgressBandKgPerWeek,
  double stepKcal = defaultProgressStepKcal,
  double minCalories = defaultMinDailyCalories,
  double maxCalories = defaultMaxDailyCalories,
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

/// Upper bound (exclusive of next band) for each age band, in years.
///
/// Bands read as `lower–upper`, where `lower` is the previous band's upper
/// bound (or 14 for the first band). The TDEE math uses the **upper bound**
/// per Feature.md ("use the bigger number"), which yields the most
/// conservative BMR for the band.
const List<int> ageBandUpperBoundsYears = [
  18,
  20,
  25,
  30,
  35,
  40,
  45,
  50,
  55,
  60,
  65,
  70,
  75,
  80,
  85,
  90,
];

/// Inclusive lower bound paired with [ageBandUpperBoundsYears] entries.
int ageBandLowerBound(int upperBound) {
  final i = ageBandUpperBoundsYears.indexOf(upperBound);
  if (i <= 0) return 14;
  return ageBandUpperBoundsYears[i - 1];
}

/// Human label for an age band identified by its upper bound.
String ageBandLabel(int upperBound) {
  if (upperBound == ageBandUpperBoundsYears.last) {
    final lower = ageBandUpperBoundsYears[ageBandUpperBoundsYears.length - 2];
    return '$lower+';
  }
  return '${ageBandLowerBound(upperBound)}–$upperBound';
}

/// Snap an exact age in years to the upper bound of its age band.
int ageBandUpperBoundForYears(int years) {
  final clamped = years.clamp(14, 120);
  for (final ub in ageBandUpperBoundsYears) {
    if (clamped <= ub) return ub;
  }
  return ageBandUpperBoundsYears.last;
}

/// Three "calorie bands" surfaced to users so they can see how a daily
/// goal target compares with their estimated maintenance and a sustainable
/// floor. Floor is a product-side guardrail, not medical advice.
class CalorieBands {
  const CalorieBands({
    required this.floor,
    required this.maintenance,
    required this.goalDaily,
  });

  /// Daily kcal floor: the lowest target we'd suggest sustaining day-to-day.
  /// Mirrors the lower clamp used by auto-adjust nudges.
  final double floor;

  /// Daily kcal at which weight is expected to stay roughly stable
  /// (= TDEE for the inputs supplied).
  final double maintenance;

  /// Daily kcal target that should yield the requested weekly pace.
  final double goalDaily;
}

/// Compute the three calorie bands from a TDEE and signed weekly pace
/// (negative = losing). [floorKcal] defaults to the same lower clamp used
/// by the weekly auto-adjust ([defaultMinDailyCalories]).
CalorieBands computeCalorieBands({
  required double tdee,
  required double weeklyChangeKgPerWeek,
  double floorKcal = defaultMinDailyCalories,
}) {
  final goal = dailyCalorieTarget(
    tdee: tdee,
    weeklyWeightChangeKg: weeklyChangeKgPerWeek,
  );
  return CalorieBands(
    floor: floorKcal,
    maintenance: tdee,
    goalDaily: goal,
  );
}

/// Sustainability tier for a weekly weight-change magnitude (kg/week).
/// Used to colour and annotate the pace slider.
enum PaceLevel { gentle, moderate, aggressive }

/// Map an absolute weekly pace magnitude (kg/week) to a [PaceLevel].
/// Thresholds chosen to align with the slider range used in onboarding
/// (0.1–1.0 kg/week): under 0.4 reads as easy/sustainable, 0.4–0.75 is
/// the typical "noticeable but doable" range, and ≥0.75 is aggressive.
PaceLevel paceLevelForKgPerWeek(double kgPerWeek) {
  final mag = kgPerWeek.abs();
  if (mag < 0.4) return PaceLevel.gentle;
  if (mag < 0.75) return PaceLevel.moderate;
  return PaceLevel.aggressive;
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

/// Truncate a [DateTime] to the local calendar day (year-month-day, midnight).
DateTime calendarDay(DateTime when) =>
    DateTime(when.year, when.month, when.day);

/// Stats over a trend window for weight tracking.
class WeightTrendStats {
  const WeightTrendStats({
    required this.points,
    required this.kgPerWeek,
    required this.consistency,
    required this.windowDays,
    required this.distinctDaysLogged,
  });

  /// Filtered, chronologically-sorted entries inside the window.
  final List<({DateTime recordedAt, double weightKg})> points;

  /// Linear-fit rate of change in kg/week (null if not computable).
  final double? kgPerWeek;

  /// Fraction of days in the window with at least one weigh-in (0..1).
  final double consistency;

  final int windowDays;
  final int distinctDaysLogged;

  bool get hasEnoughData => points.length >= 2;
}

/// Compute trend stats for a weight series over the trailing [windowDays]
/// ending at [referenceDay] (defaults to today).
///
/// Entries can be in any order. The result is sorted chronologically.
/// Rate-of-change uses simple least-squares linear regression on
/// (daysFromStart, weightKg) and is reported in **kg per week**.
WeightTrendStats computeWeightTrendStats({
  required Iterable<({DateTime recordedAt, double weightKg})> entries,
  required int windowDays,
  DateTime? referenceDay,
}) {
  assert(windowDays > 0);
  final ref = calendarDay(referenceDay ?? DateTime.now());
  final start = ref.subtract(Duration(days: windowDays - 1));
  final inWindow = entries
      .where((e) {
        final d = calendarDay(e.recordedAt);
        return !d.isBefore(start) && !d.isAfter(ref);
      })
      .toList()
    ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

  final distinctDays = <DateTime>{
    for (final e in inWindow) calendarDay(e.recordedAt),
  };
  final consistency = distinctDays.length / windowDays;

  double? kgPerWeek;
  if (inWindow.length >= 2) {
    final first = inWindow.first.recordedAt;
    final xs = <double>[];
    final ys = <double>[];
    for (final e in inWindow) {
      final dx = e.recordedAt.difference(first).inMinutes / (60.0 * 24.0);
      xs.add(dx);
      ys.add(e.weightKg);
    }
    final n = xs.length;
    final meanX = xs.reduce((a, b) => a + b) / n;
    final meanY = ys.reduce((a, b) => a + b) / n;
    var num = 0.0;
    var den = 0.0;
    for (var i = 0; i < n; i++) {
      final dx = xs[i] - meanX;
      num += dx * (ys[i] - meanY);
      den += dx * dx;
    }
    if (den > 0) {
      final slopePerDay = num / den;
      kgPerWeek = slopePerDay * 7.0;
    }
  }

  return WeightTrendStats(
    points: inWindow,
    kgPerWeek: kgPerWeek,
    consistency: consistency.clamp(0.0, 1.0),
    windowDays: windowDays,
    distinctDaysLogged: distinctDays.length,
  );
}

/// Result of a streak computation.
class StreakInfo {
  const StreakInfo({required this.current, required this.best});
  final int current;
  final int best;
}

/// Compute the current and best streaks of consecutive calendar days from
/// a set of qualifying days.
///
/// "Current" is the run ending at [referenceDay] (or the previous day if
/// [referenceDay] itself is not in the set, allowing today to count as
/// "still on track" before logging). Pass [referenceDay] = the user's
/// "today" in local time.
StreakInfo computeDayStreak({
  required Set<DateTime> qualifyingDays,
  required DateTime referenceDay,
}) {
  final ref = calendarDay(referenceDay);
  final norm = <DateTime>{
    for (final d in qualifyingDays) calendarDay(d),
  };

  var current = 0;
  var cursor = ref;
  if (!norm.contains(cursor)) {
    cursor = cursor.subtract(const Duration(days: 1));
  }
  while (norm.contains(cursor)) {
    current++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  if (norm.isEmpty) return const StreakInfo(current: 0, best: 0);
  final sorted = norm.toList()..sort();
  var best = 1;
  var run = 1;
  for (var i = 1; i < sorted.length; i++) {
    final diff = sorted[i].difference(sorted[i - 1]).inDays;
    if (diff == 1) {
      run++;
      if (run > best) best = run;
    } else {
      run = 1;
    }
  }
  if (current > best) best = current;
  return StreakInfo(current: current, best: best);
}

import 'dart:convert';

import 'package:caltrack/core/goal_logic.dart';
import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/core/nutrients.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:drift/drift.dart';

export 'package:caltrack/data/app_database.dart'
    show Profile, Goal, WeightEntry, FoodLogEntry, CustomFood, FoodPref, MealPeriod;

/// Aggregated intake for a calendar day (sums logged portions).
class DailyIntakeTotals {
  const DailyIntakeTotals({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.sugarG,
    required this.fiberG,
    required this.fatG,
    this.extra = const {},
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double sugarG;
  final double fiberG;
  final double fatG;
  final Map<NutrientKey, double> extra;

  static DailyIntakeTotals fromEntries(Iterable<FoodLogEntry> rows) {
    var k = 0.0;
    var p = 0.0;
    var c = 0.0;
    var s = 0.0;
    var fi = 0.0;
    var f = 0.0;
    final extra = <NutrientKey, double>{};
    for (final e in rows) {
      k += e.kcal;
      p += e.proteinG;
      c += e.carbsG;
      s += e.sugarG;
      fi += e.fiberG;
      f += e.fatG;
      _mergeExtra(extra, e.extraNutrients);
    }
    return DailyIntakeTotals(
      kcal: k,
      proteinG: p,
      carbsG: c,
      sugarG: s,
      fiberG: fi,
      fatG: f,
      extra: extra,
    );
  }

  static void _mergeExtra(
    Map<NutrientKey, double> target,
    String? json,
  ) {
    if (json == null || json.isEmpty) return;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      for (final entry in map.entries) {
        final key = NutrientKey.values
            .where((k) => k.name == entry.key)
            .firstOrNull;
        if (key == null) continue;
        final value = (entry.value as num).toDouble();
        target.update(key, (v) => v + value, ifAbsent: () => value);
      }
    } catch (_) {}
  }

  static const zero =
      DailyIntakeTotals(kcal: 0, proteinG: 0, carbsG: 0, sugarG: 0, fiberG: 0, fatG: 0);
}

/// Serialize a map of NutrientKey → double to a JSON string for storage.
String? encodeExtraNutrients(Map<NutrientKey, double>? map) {
  if (map == null || map.isEmpty) return null;
  return jsonEncode(
    map.map((k, v) => MapEntry(k.name, v)),
  );
}

/// Decode a JSON blob back into a map of NutrientKey → double.
Map<NutrientKey, double> decodeExtraNutrients(String? json) {
  if (json == null || json.isEmpty) return {};
  try {
    final map = jsonDecode(json) as Map<String, dynamic>;
    final out = <NutrientKey, double>{};
    for (final entry in map.entries) {
      final key = NutrientKey.values
          .where((k) => k.name == entry.key)
          .firstOrNull;
      if (key != null) {
        out[key] = (entry.value as num).toDouble();
      }
    }
    return out;
  } catch (_) {
    return {};
  }
}

class ComputedPlan {
  const ComputedPlan({
    required this.dailyCalories,
    required this.macros,
    required this.tdee,
  });

  final double dailyCalories;
  final MacroGrams macros;
  final double tdee;
}

/// Aggregated summary stats over all logged weight entries (in kg).
class WeightStats {
  const WeightStats({
    required this.averageKg,
    required this.minKg,
    required this.maxKg,
    required this.count,
  });

  final double averageKg;
  final double minKg;
  final double maxKg;
  final int count;

  /// Build stats from raw entries, or null when [rows] is empty.
  static WeightStats? fromEntries(Iterable<WeightEntry> rows) {
    final list = rows.toList();
    if (list.isEmpty) return null;
    var sum = 0.0;
    var min = list.first.weightKg;
    var max = list.first.weightKg;
    for (final e in list) {
      sum += e.weightKg;
      if (e.weightKg < min) min = e.weightKg;
      if (e.weightKg > max) max = e.weightKg;
    }
    return WeightStats(
      averageKg: sum / list.length,
      minKg: min,
      maxKg: max,
      count: list.length,
    );
  }
}

/// Canonical key used to deduplicate / rank food log entries by the
/// underlying food. Prefers stable ids (catalog id, custom id) before
/// falling back to a normalized display name.
String foodLogKey(FoodLogEntry entry) {
  final catalog = entry.catalogFoodId;
  if (catalog != null && catalog.isNotEmpty) return 'cat:$catalog';
  final custom = entry.customFoodId;
  if (custom != null) return 'cus:$custom';
  return 'name:${entry.displayName.trim().toLowerCase()}';
}

/// Same key namespace for catalog ids when the entry isn't yet a
/// log row (e.g. ranking incoming search results).
String foodLogKeyForCatalogId(String id) => 'cat:$id';

/// Same key namespace for custom-food ids.
String foodLogKeyForCustomId(int id) => 'cus:$id';

/// Name-based fallback for keying foods that have no stable id.
String foodLogKeyForName(String name) =>
    'name:${name.trim().toLowerCase()}';

/// Resolve the integer age (years) used by the TDEE math for a [Profile].
/// Prefers the stored [Profile.ageBandMaxYears] (added with age bands);
/// falls back to deriving it from the legacy birth date for older rows.
int ageYearsForProfile(Profile profile) {
  final band = profile.ageBandMaxYears;
  if (band != null) return band.clamp(14, 120);
  final birth = DateTime.fromMillisecondsSinceEpoch(profile.birthDateMillis);
  return ageFromBirthDate(birth, DateTime.now());
}

class CalTrackRepository {
  CalTrackRepository(this._db);

  final AppDatabase _db;

  static String? normalizeBarcode(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.length == 13) return digits;
    if (digits.length == 12) return digits.padLeft(13, '0');
    // Keep other lengths (e.g. UPC-E) as-is if user saved it.
    return digits;
  }

  Future<Profile> requireProfile() async {
    final rows = await _db.select(_db.profiles).get();
    if (rows.isEmpty) {
      await _db.seedIfEmpty();
    }
    return (await _db.select(_db.profiles).get()).first;
  }

  Stream<Profile> watchProfile() =>
      _db.select(_db.profiles).watchSingle();

  Future<Goal?> currentGoal() async {
    final goals = await (_db.select(_db.goals)
          ..orderBy([(t) => OrderingTerm.desc(t.id)])
          ..limit(1))
        .get();
    return goals.isEmpty ? null : goals.first;
  }

  Stream<Goal?> watchCurrentGoal() {
    return _db.select(_db.goals).watch().map((all) {
      if (all.isEmpty) return null;
      final sorted = [...all]..sort((a, b) => b.id.compareTo(a.id));
      return sorted.first;
    });
  }

  // ---- Food prefs (liquid override + serving quick-select) ----

  Future<FoodPref?> foodPrefByKey(String key) {
    return (_db.select(_db.foodPrefs)..where((t) => t.foodKey.equals(key)))
        .getSingleOrNull();
  }

  Stream<FoodPref?> watchFoodPrefByKey(String key) {
    return (_db.select(_db.foodPrefs)..where((t) => t.foodKey.equals(key)))
        .watchSingleOrNull();
  }

  Future<void> setTreatAsLiquid({
    required String foodKey,
    required bool? treatAsLiquid,
  }) async {
    await _db
        .into(_db.foodPrefs)
        .insertOnConflictUpdate(
          FoodPrefsCompanion(
            foodKey: Value(foodKey),
            treatAsLiquid: treatAsLiquid == null
                ? const Value.absent()
                : Value(treatAsLiquid),
          ),
        );
  }

  Future<void> setSavedServing({
    required String foodKey,
    required double? amount,
    required String? unit, // 'g' | 'ml'
  }) async {
    await _db.into(_db.foodPrefs).insertOnConflictUpdate(
          FoodPrefsCompanion(
            foodKey: Value(foodKey),
            savedServingAmount:
                amount == null ? const Value.absent() : Value(amount),
            savedServingUnit:
                unit == null ? const Value.absent() : Value(unit),
          ),
        );
  }

  /// Persist the last-used group preset so the entry sheet can default
  /// to "2 × Large egg" the next time the user opens this food. Pass
  /// both values as null to clear the preference.
  Future<void> setLastUsedServing({
    required String foodKey,
    required String? label,
    required double? quantity,
  }) async {
    await _db.into(_db.foodPrefs).insertOnConflictUpdate(
          FoodPrefsCompanion(
            foodKey: Value(foodKey),
            lastServingLabel: Value(label),
            lastServingQty: Value(quantity),
          ),
        );
  }

  Stream<List<WeightEntry>> watchWeightEntries() {
    final q = _db.select(_db.weightEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)]);
    return q.watch();
  }

  Future<List<WeightEntry>> weightEntriesLimit(int n) async {
    final q = _db.select(_db.weightEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
      ..limit(n);
    return q.get();
  }

  Future<ComputedPlan?> computePlanForProfile(Profile profile, Goal? goal) async {
    if (goal == null) return null;
    final entries = await weightEntriesLimit(1);
    if (entries.isEmpty) return null;
    final w = entries.first.weightKg;
    final age = ageYearsForProfile(profile);
    final isMale = profile.sex == 'male';
    final activity = ActivityLevel.fromIndex(profile.activityLevel);
    final tdeeVal = tdee(
      isMale: isMale,
      weightKg: w,
      heightCm: profile.heightCm,
      ageYears: age,
      activity: activity,
    );
    double weekly = goal.weeklyChangeKgPerWeek;
    if (goal.status == 'maintain') {
      weekly = 0;
    }
    final daily = dailyCalorieTarget(tdee: tdeeVal, weeklyWeightChangeKg: weekly);
    final macros = macroGramsFromPercentages(
      daily,
      profile.proteinPct,
      profile.carbsPct,
      profile.fatPct,
    );
    return ComputedPlan(dailyCalories: daily, macros: macros, tdee: tdeeVal);
  }

  Future<void> recacheDailyTarget() async {
    final profile = await requireProfile();
    final goal = await currentGoal();
    final plan = await computePlanForProfile(profile, goal);
    if (plan == null) return;
    await (_db.update(_db.profiles)..where((t) => t.id.equals(1))).write(
      ProfilesCompanion(dailyCalorieTarget: Value(plan.dailyCalories)),
    );
  }

  /// Full onboarding submit: profile, goal, first weight, cache calories.
  ///
  /// [ageBandMaxYears] is the upper bound of the user's age band (e.g. 25
  /// for the 20–25 band) and feeds the TDEE math directly per Feature.md.
  /// A synthetic [birthDateMillis] is also written so legacy code paths
  /// keep working until they are migrated to read the band.
  Future<void> submitOnboarding({
    required String sex,
    required int ageBandMaxYears,
    required double heightCm,
    required int activityLevelIndex,
    required WeightUnit weightUnit,
    required double currentWeightKg,
    required double targetWeightKg,
    required double weeklyChangeKgPerWeek,
    required int proteinPct,
    required int carbsPct,
    required int fatPct,
    required int reminderWeekday,
    required int reminderHour,
    required int reminderMinute,
  }) async {
    final now = DateTime.now();
    final syntheticBirth =
        DateTime(now.year - ageBandMaxYears, now.month, now.day);
    await _db.transaction(() async {
      await _db.delete(_db.goals).go();
      await _db.into(_db.goals).insert(
            GoalsCompanion.insert(
              targetWeightKg: targetWeightKg,
              weeklyChangeKgPerWeek: weeklyChangeKgPerWeek,
              status: 'active',
            ),
          );
      await (_db.into(_db.weightEntries)).insert(
        WeightEntriesCompanion.insert(
          recordedAt: DateTime.now(),
          weightKg: currentWeightKg,
        ),
      );
      await (_db.into(_db.profiles)).insertOnConflictUpdate(
        ProfilesCompanion.insert(
          id: const Value(1),
          sex: sex,
          birthDateMillis: syntheticBirth.millisecondsSinceEpoch,
          ageBandMaxYears: Value(ageBandMaxYears),
          heightCm: heightCm,
          activityLevel: activityLevelIndex,
          weightUnit: weightUnit.name,
          proteinPct: proteinPct,
          carbsPct: carbsPct,
          fatPct: fatPct,
          reminderWeekday: reminderWeekday,
          reminderHour: reminderHour,
          reminderMinute: reminderMinute,
          onboardingCompleted: const Value(true),
          dailyCalorieTarget: const Value.absent(),
        ),
      );
      final g = await currentGoal();
      final pRow = await requireProfile();
      final plan = await computePlanForProfile(pRow, g);
      if (plan != null) {
        await (_db.update(_db.profiles)..where((t) => t.id.equals(1))).write(
          ProfilesCompanion(dailyCalorieTarget: Value(plan.dailyCalories)),
        );
      }
    });
  }

  /// Update only the user's age band, recomputing the daily target.
  Future<void> updateAgeBandMaxYears(int ageBandMaxYears) async {
    final now = DateTime.now();
    final syntheticBirth =
        DateTime(now.year - ageBandMaxYears, now.month, now.day);
    await (_db.update(_db.profiles)..where((t) => t.id.equals(1))).write(
      ProfilesCompanion(
        birthDateMillis: Value(syntheticBirth.millisecondsSinceEpoch),
        ageBandMaxYears: Value(ageBandMaxYears),
      ),
    );
    await recacheDailyTarget();
  }

  Future<void> addWeightEntry({
    required double weightKg,
    String? note,
    DateTime? recordedAt,
  }) async {
    await _db.into(_db.weightEntries).insert(
          WeightEntriesCompanion.insert(
            recordedAt: recordedAt ?? DateTime.now(),
            weightKg: weightKg,
            note: Value(note),
          ),
        );
    await recacheDailyTarget();
    await checkGoalCompletionAfterWeighIn();
  }

  /// Re-insert a previously-deleted [WeightEntry] verbatim (same id,
  /// timestamp, weight and note). Used to implement swipe-to-delete undo.
  Future<void> restoreWeightEntry(WeightEntry entry) async {
    await _db.into(_db.weightEntries).insertOnConflictUpdate(
          WeightEntriesCompanion(
            id: Value(entry.id),
            recordedAt: Value(entry.recordedAt),
            weightKg: Value(entry.weightKg),
            note: Value(entry.note),
          ),
        );
    await recacheDailyTarget();
    await checkGoalCompletionAfterWeighIn();
  }

  /// Aggregate summary stats over all weight entries (average, min, max,
  /// count). Returns null when there are no entries.
  Future<WeightStats?> weightStats() async {
    final rows = await _db.select(_db.weightEntries).get();
    return WeightStats.fromEntries(rows);
  }


  /// Look up the most recent weight entry on the same calendar day as
  /// [day] (local time). Returns null if the day has no entries.
  Future<WeightEntry?> weightEntryForDay(DateTime day) async {
    final (s, e) = _dayBounds(day);
    final rows = await (_db.select(_db.weightEntries)
          ..where((t) =>
              t.recordedAt.isBiggerOrEqualValue(s) &
              t.recordedAt.isSmallerThanValue(e))
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<WeightEntry?> weightEntryById(int id) async {
    final rows = await (_db.select(_db.weightEntries)
          ..where((t) => t.id.equals(id))
          ..limit(1))
        .get();
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> updateWeightEntry({
    required int id,
    required double weightKg,
    String? note,
    DateTime? recordedAt,
  }) async {
    await (_db.update(_db.weightEntries)..where((t) => t.id.equals(id))).write(
      WeightEntriesCompanion(
        weightKg: Value(weightKg),
        note: Value(note),
        recordedAt:
            recordedAt == null ? const Value.absent() : Value(recordedAt),
      ),
    );
    await recacheDailyTarget();
    await checkGoalCompletionAfterWeighIn();
  }

  Future<void> deleteWeightEntry(int id) async {
    await (_db.delete(_db.weightEntries)..where((t) => t.id.equals(id))).go();
    await recacheDailyTarget();
  }

  Future<void> updateMacroSplit({
    required int proteinPct,
    required int carbsPct,
    required int fatPct,
  }) async {
    await (_db.update(_db.profiles)..where((t) => t.id.equals(1))).write(
      ProfilesCompanion(
        proteinPct: Value(proteinPct),
        carbsPct: Value(carbsPct),
        fatPct: Value(fatPct),
      ),
    );
    await recacheDailyTarget();
  }

  Future<void> updateReminderSchedule({
    required int weekday,
    required int hour,
    required int minute,
  }) async {
    await (_db.update(_db.profiles)..where((t) => t.id.equals(1))).write(
      ProfilesCompanion(
        reminderWeekday: Value(weekday),
        reminderHour: Value(hour),
        reminderMinute: Value(minute),
      ),
    );
  }

  Future<void> updateWeightUnit(WeightUnit unit) async {
    await (_db.update(_db.profiles)..where((t) => t.id.equals(1))).write(
      ProfilesCompanion(weightUnit: Value(unit.name)),
    );
  }

  Future<void> chooseMaintainWeight() async {
    final goal = await currentGoal();
    if (goal == null) return;
    await (_db.update(_db.goals)..where((t) => t.id.equals(goal.id))).write(
      GoalsCompanion(
        weeklyChangeKgPerWeek: const Value(0),
        status: const Value('maintain'),
      ),
    );
    await recacheDailyTarget();
  }

  Future<void> setNewGoal({
    required double targetWeightKg,
    required double weeklyChangeKgPerWeek,
  }) async {
    await _db.delete(_db.goals).go();
    await _db.into(_db.goals).insert(
          GoalsCompanion.insert(
            targetWeightKg: targetWeightKg,
            weeklyChangeKgPerWeek: weeklyChangeKgPerWeek,
            status: 'active',
          ),
        );
    await recacheDailyTarget();
  }

  Future<void> checkGoalCompletionAfterWeighIn() async {
    final goal = await currentGoal();
    if (goal == null || goal.status != 'active') return;
    final recent = await weightEntriesLimit(4);
    if (recent.length < 2) return;
    final weights = recent.map((e) => e.weightKg).toList();
    if (isGoalReached(
      latestWeightKg: weights.first,
      targetWeightKg: goal.targetWeightKg,
      recentWeightsKgNewestFirst: weights,
    )) {
      final g = await currentGoal();
      if (g == null) return;
      await (_db.update(_db.goals)..where((t) => t.id.equals(g.id))).write(
        const GoalsCompanion(status: Value('pending_choice')),
      );
    }
  }

  /// Compare weight ~7 days ago to now for weekly review.
  Future<double?> weeklyDeltaKg() async {
    final entries = await weightEntriesLimit(20);
    if (entries.length < 2) return null;
    final latest = entries.first;
    final weekAgo = latest.recordedAt.subtract(const Duration(days: 7));
    WeightEntry? anchor;
    for (final e in entries) {
      if (!e.recordedAt.isAfter(weekAgo)) {
        anchor = e;
        break;
      }
    }
    anchor ??= entries.last;
    return latest.weightKg - anchor.weightKg;
  }

  /// Average weight change per week over a recent window. Returns the
  /// signed kg/week (negative = losing). The window grows from the
  /// latest entry backward by [windowDays]; if there isn't enough
  /// history we fall back to the oldest available anchor so users with
  /// few weigh-ins still see an estimate.
  ///
  /// Returns null if fewer than two weigh-ins exist or the implied
  /// time span is too short to be meaningful (< 2 days).
  Future<double?> trendKgPerWeek({int windowDays = 14}) async {
    final entries = await weightEntriesLimit(60);
    if (entries.length < 2) return null;
    final latest = entries.first;
    final cutoff = latest.recordedAt.subtract(Duration(days: windowDays));
    WeightEntry? anchor;
    for (final e in entries) {
      if (!e.recordedAt.isAfter(cutoff)) {
        anchor = e;
        break;
      }
    }
    anchor ??= entries.last;
    final spanDays =
        latest.recordedAt.difference(anchor.recordedAt).inHours / 24.0;
    if (spanDays < 2) return null;
    final deltaKg = latest.weightKg - anchor.weightKg;
    return deltaKg * 7.0 / spanDays;
  }

  Future<void> applyWeeklyAdjustment() async {
    final profile = await requireProfile();
    final goal = await currentGoal();
    if (goal == null || goal.status != 'active') return;
    final delta = await weeklyDeltaKg();
    if (delta == null) return;
    final intendedWeeks = goal.weeklyChangeKgPerWeek;
    final currentTarget = profile.dailyCalorieTarget;
    if (currentTarget == null) return;
    final adjusted = adjustCaloriesForProgress(
      currentDailyTarget: currentTarget,
      intendedWeeklyChangeKg: intendedWeeks,
      actualWeeklyChangeKg: delta,
    );
    await (_db.update(_db.profiles)..where((t) => t.id.equals(1))).write(
      ProfilesCompanion(dailyCalorieTarget: Value(adjusted)),
    );
  }

  Future<void> keepCurrentPlan() async {
    await recacheDailyTarget();
  }

  (DateTime start, DateTime endExclusive) _dayBounds(DateTime when) {
    final start = DateTime(when.year, when.month, when.day);
    return (start, start.add(const Duration(days: 1)));
  }

  Future<DailyIntakeTotals> intakeForDay(DateTime day) async {
    final (s, e) = _dayBounds(day);
    final rows = await (_db.select(_db.foodLogEntries)
          ..where((t) =>
              t.loggedAt.isBiggerOrEqualValue(s) &
              t.loggedAt.isSmallerThanValue(e)))
        .get();
    return DailyIntakeTotals.fromEntries(rows);
  }

  /// Returns aggregated totals grouped by meal period for a single day.
  Future<Map<MealPeriod?, DailyIntakeTotals>> intakeForDayByPeriod(
      DateTime day) async {
    final (s, e) = _dayBounds(day);
    final rows = await (_db.select(_db.foodLogEntries)
          ..where((t) =>
              t.loggedAt.isBiggerOrEqualValue(s) &
              t.loggedAt.isSmallerThanValue(e)))
        .get();
    final out = <MealPeriod?, List<FoodLogEntry>>{};
    for (final r in rows) {
      final period = MealPeriod.fromDb(r.mealPeriod);
      out.putIfAbsent(period, () => []).add(r);
    }
    return out.map(
      (key, value) => MapEntry(key, DailyIntakeTotals.fromEntries(value)),
    );
  }

  /// Stream of all entries for a day, grouped by meal period.
  Stream<Map<MealPeriod?, List<FoodLogEntry>>> watchFoodLogsForDayByPeriod(
      DateTime day) {
    final (s, e) = _dayBounds(day);
    return (_db.select(_db.foodLogEntries)
          ..where((t) =>
              t.loggedAt.isBiggerOrEqualValue(s) &
              t.loggedAt.isSmallerThanValue(e))
          ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
        .watch()
        .map((rows) {
      final out = <MealPeriod?, List<FoodLogEntry>>{};
      for (final r in rows) {
        final period = MealPeriod.fromDb(r.mealPeriod);
        out.putIfAbsent(period, () => []).add(r);
      }
      return out;
    });
  }

  /// Aggregate kcal logged per calendar day in [start, endExclusive).
  /// Returned map keys are local-midnight DateTimes; days with no entries
  /// are omitted (callers should treat missing keys as 0).
  Future<Map<DateTime, double>> dailyKcalTotals({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day,
    );
    final rows = await (_db.select(_db.foodLogEntries)
          ..where((t) =>
              t.loggedAt.isBiggerOrEqualValue(s) &
              t.loggedAt.isSmallerThanValue(e)))
        .get();
    final out = <DateTime, double>{};
    for (final r in rows) {
      final d = DateTime(
        r.loggedAt.year,
        r.loggedAt.month,
        r.loggedAt.day,
      );
      out.update(d, (v) => v + r.kcal, ifAbsent: () => r.kcal);
    }
    return out;
  }

  /// Reactive variant of [dailyKcalTotals] driven by changes to the food
  /// log table.
  Stream<Map<DateTime, double>> watchDailyKcalTotals({
    required DateTime start,
    required DateTime endExclusive,
  }) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(
      endExclusive.year,
      endExclusive.month,
      endExclusive.day,
    );
    return (_db.select(_db.foodLogEntries)
          ..where((t) =>
              t.loggedAt.isBiggerOrEqualValue(s) &
              t.loggedAt.isSmallerThanValue(e)))
        .watch()
        .map((rows) {
      final out = <DateTime, double>{};
      for (final r in rows) {
        final d = DateTime(
          r.loggedAt.year,
          r.loggedAt.month,
          r.loggedAt.day,
        );
        out.update(d, (v) => v + r.kcal, ifAbsent: () => r.kcal);
      }
      return out;
    });
  }

  Stream<DailyIntakeTotals> watchIntakeForDay(DateTime day) {
    final (s, e) = _dayBounds(day);
    return (_db.select(_db.foodLogEntries)
          ..where((t) =>
              t.loggedAt.isBiggerOrEqualValue(s) &
              t.loggedAt.isSmallerThanValue(e)))
        .watch()
        .map(DailyIntakeTotals.fromEntries);
  }

  /// Stream of food log entries for a calendar day, newest first.
  Stream<List<FoodLogEntry>> watchFoodLogsForDay(DateTime day) {
    final (s, e) = _dayBounds(day);
    return (_db.select(_db.foodLogEntries)
          ..where((t) =>
              t.loggedAt.isBiggerOrEqualValue(s) &
              t.loggedAt.isSmallerThanValue(e))
          ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)]))
        .watch();
  }

  Future<void> deleteFoodLog(int id) async {
    await (_db.delete(_db.foodLogEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<void> updateFoodLog({
    required int id,
    required double grams,
    required double kcal,
    required double proteinG,
    required double carbsG,
    double? sugarG,
    double? fiberG,
    required double fatG,
    MealPeriod? mealPeriod,
    String? extraNutrients,
  }) async {
    await (_db.update(_db.foodLogEntries)..where((t) => t.id.equals(id))).write(
      FoodLogEntriesCompanion(
        grams: Value(grams),
        kcal: Value(kcal),
        proteinG: Value(proteinG),
        carbsG: Value(carbsG),
        sugarG: sugarG == null ? const Value.absent() : Value(sugarG),
        fiberG: fiberG == null ? const Value.absent() : Value(fiberG),
        fatG: Value(fatG),
        mealPeriod: Value(mealPeriod?.dbValue),
        extraNutrients: Value(extraNutrients),
      ),
    );
  }

  /// Updates just the display name of a log entry. Used by quick-add edit
  /// mode since [updateFoodLog] does not touch the display name column.
  Future<void> updateQuickAddName({
    required int id,
    required String displayName,
  }) async {
    await (_db.update(_db.foodLogEntries)..where((t) => t.id.equals(id))).write(
      FoodLogEntriesCompanion(displayName: Value(displayName)),
    );
  }

  Future<int> addFoodLogReturnId({
    required String source,
    String? catalogFoodId,
    int? customFoodId,
    required String displayName,
    required double grams,
    required double kcal,
    required double proteinG,
    required double carbsG,
    double sugarG = 0,
    double fiberG = 0,
    required double fatG,
    DateTime? loggedAt,
    MealPeriod? mealPeriod,
    bool isPlanned = false,
    String? extraNutrients,
  }) {
    return _db.into(_db.foodLogEntries).insert(
          FoodLogEntriesCompanion.insert(
            loggedAt: loggedAt ?? DateTime.now(),
            source: source,
            catalogFoodId: Value(catalogFoodId),
            customFoodId: Value(customFoodId),
            displayName: displayName,
            grams: grams,
            kcal: kcal,
            proteinG: proteinG,
            carbsG: carbsG,
            sugarG: Value(sugarG),
            fiberG: Value(fiberG),
            fatG: fatG,
            mealPeriod: Value(mealPeriod?.dbValue),
            isPlanned: Value(isPlanned),
            extraNutrients: Value(extraNutrients),
          ),
        );
  }

  Future<void> addFoodLog({
    required String source,
    String? catalogFoodId,
    int? customFoodId,
    required String displayName,
    required double grams,
    required double kcal,
    required double proteinG,
    required double carbsG,
    double sugarG = 0,
    double fiberG = 0,
    required double fatG,
    DateTime? loggedAt,
    MealPeriod? mealPeriod,
    bool isPlanned = false,
    String? extraNutrients,
  }) async {
    await _db.into(_db.foodLogEntries).insert(
          FoodLogEntriesCompanion.insert(
            loggedAt: loggedAt ?? DateTime.now(),
            source: source,
            catalogFoodId: Value(catalogFoodId),
            customFoodId: Value(customFoodId),
            displayName: displayName,
            grams: grams,
            kcal: kcal,
            proteinG: proteinG,
            carbsG: carbsG,
            sugarG: Value(sugarG),
            fiberG: Value(fiberG),
            fatG: fatG,
            mealPeriod: Value(mealPeriod?.dbValue),
            isPlanned: Value(isPlanned),
            extraNutrients: Value(extraNutrients),
          ),
        );
  }

  Future<List<FoodLogEntry>> recentDistinctFoodLogs({int limit = 15}) async {
    final rows = await (_db.select(_db.foodLogEntries)
          ..orderBy([(t) => OrderingTerm.desc(t.loggedAt)])
          ..limit(300))
        .get();
    final seen = <String>{};
    final out = <FoodLogEntry>[];
    for (final r in rows) {
      // Quick-add entries are raw calorie estimates, not reusable food items.
      if (r.source == 'quick') continue;
      final key = foodLogKey(r);
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(r);
      if (out.length >= limit) break;
    }
    return out;
  }

  /// Frequency map of food log keys over a recent window. Used to rank
  /// search results so foods you log often surface first.
  ///
  /// Keys come from [foodLogKey] (catalog id, custom id, or name) so
  /// callers can look up by [CatalogFood.id], [CustomFood.id] or the
  /// food's display name.
  Future<Map<String, int>> foodLogKeyFrequencies({
    int windowDays = 60,
  }) async {
    final cutoff = DateTime.now().subtract(Duration(days: windowDays));
    final rows = await (_db.select(_db.foodLogEntries)
          ..where((t) => t.loggedAt.isBiggerOrEqualValue(cutoff)))
        .get();
    final out = <String, int>{};
    for (final r in rows) {
      if (r.source == 'quick') continue; // estimates are not reusable foods
      final k = foodLogKey(r);
      out.update(k, (v) => v + 1, ifAbsent: () => 1);
    }
    return out;
  }

  // ---- Custom foods ----

  Future<CustomFood?> customFoodById(int id) {
    return (_db.select(_db.customFoods)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Future<CustomFood?> customFoodByBarcode(String rawBarcode) async {
    final b = normalizeBarcode(rawBarcode);
    if (b == null) return null;
    return (_db.select(_db.customFoods)..where((t) => t.barcode.equals(b)))
        .getSingleOrNull();
  }

  Future<List<CustomFood>> searchCustomFoods(String query, {int limit = 30}) async {
    final q = query.trim();
    if (q.isEmpty) return [];

    final like = '%${q.replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
    final rows = await (_db.select(_db.customFoods)
          ..where((t) => t.name.like(like) | t.brand.like(like))
          ..orderBy([(t) => OrderingTerm.asc(t.name)])
          ..limit(limit))
        .get();
    return rows;
  }

  /// Returns all custom foods ordered by name. Used for the custom foods
  /// management list screen.
  Future<List<CustomFood>> allCustomFoods() async {
    return (_db.select(_db.customFoods)
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<int> upsertCustomFood({
    int? id,
    required String name,
    String? brand,
    String? barcode,
    required double servingSize,
    required String servingUnit, // 'g' | 'ml'
    required double calories,
    required double fatG,
    required double carbsG,
    required double sugarG,
    required double fiberG,
    required double proteinG,
    String? extraNutrients,
  }) async {
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) {
      throw ArgumentError.value(name, 'name', 'must not be empty');
    }
    final b = barcode == null ? null : normalizeBarcode(barcode);
    final companion = CustomFoodsCompanion(
      id: id == null ? const Value.absent() : Value(id),
      name: Value(cleanedName),
      brand: Value(brand?.trim().isEmpty ?? true ? null : brand!.trim()),
      barcode: Value(b),
      servingSize: Value(servingSize),
      servingUnit: Value(servingUnit),
      calories: Value(calories),
      fatG: Value(fatG),
      carbsG: Value(carbsG),
      sugarG: Value(sugarG),
      fiberG: Value(fiberG),
      proteinG: Value(proteinG),
      extraNutrients: Value(extraNutrients),
    );
    return _db.into(_db.customFoods).insertOnConflictUpdate(companion);
  }

  Future<void> deleteCustomFood(int id) async {
    await (_db.delete(_db.customFoods)..where((t) => t.id.equals(id))).go();
  }

  /// Number of user-created foods stored locally.
  Future<int> customFoodCount() async {
    final cnt = _db.customFoods.id.count();
    final row = await (_db.selectOnly(_db.customFoods)..addColumns([cnt]))
        .getSingle();
    return row.read(cnt) ?? 0;
  }

  Future<void> resetForTesting() async {
    await _db.delete(_db.foodLogEntries).go();
    await _db.delete(_db.customFoods).go();
    await _db.delete(_db.weightEntries).go();
    await _db.delete(_db.goals).go();
    await _db.delete(_db.foodPrefs).go();
    await (_db.update(_db.profiles)..where((t) => t.id.equals(1))).write(
      const ProfilesCompanion(
        onboardingCompleted: Value(false),
        dailyCalorieTarget: Value.absent(),
      ),
    );
  }

  // ---- Backup / export / import ----

  Future<Map<String, Object?>> exportJson() async {
    final profile = await requireProfile();
    final goals = await _db.select(_db.goals).get();
    final weights = await _db.select(_db.weightEntries).get();
    final custom = await _db.select(_db.customFoods).get();
    final foodLogs = await _db.select(_db.foodLogEntries).get();
    final prefs = await _db.select(_db.foodPrefs).get();

    return <String, Object?>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': profile.toJson(),
      'goals': goals.map((g) => g.toJson()).toList(),
      'weightEntries': weights.map((w) => w.toJson()).toList(),
      'customFoods': custom.map((c) => c.toJson()).toList(),
      'foodLogEntries': foodLogs.map((e) => e.toJson()).toList(),
      'foodPrefs': prefs.map((p) => p.toJson()).toList(),
    };
  }

  Future<void> importJson(
    Map<String, Object?> json, {
    required bool overwrite,
  }) async {
    final v = json['version'];
    if (v is! int || v != 1) {
      throw ArgumentError.value(v, 'version', 'Unsupported export version');
    }
    final profileJson = json['profile'];
    if (profileJson is! Map<String, Object?>) {
      throw ArgumentError('Missing/invalid profile');
    }

    List<Map<String, Object?>> list(String key) {
      final raw = json[key];
      if (raw == null) return const [];
      if (raw is! List) throw ArgumentError('Invalid list for $key');
      return raw.cast<Map>().map((e) => e.cast<String, Object?>()).toList();
    }

    final goals = list('goals').map((m) => Goal.fromJson(m)).toList();
    final weights =
        list('weightEntries').map((m) => WeightEntry.fromJson(m)).toList();
    final custom =
        list('customFoods').map((m) => CustomFood.fromJson(m)).toList();
    final foodLogs = list('foodLogEntries')
        .map((m) {
          // Ensure backward compatibility with exports that lack the new
          // columns (schema v6 → v7 migration).
          m.putIfAbsent('isPlanned', () => false);
          return FoodLogEntry.fromJson(m);
        })
        .toList();
    final prefs = list('foodPrefs').map((m) => FoodPref.fromJson(m)).toList();

    final profile = Profile.fromJson(profileJson);

    await _db.transaction(() async {
      if (overwrite) {
        await _db.delete(_db.foodLogEntries).go();
        await _db.delete(_db.customFoods).go();
        await _db.delete(_db.weightEntries).go();
        await _db.delete(_db.goals).go();
        await _db.delete(_db.foodPrefs).go();
      }

      await _db.into(_db.profiles).insertOnConflictUpdate(
            ProfilesCompanion(
              id: Value(profile.id),
              sex: Value(profile.sex),
              birthDateMillis: Value(profile.birthDateMillis),
              ageBandMaxYears: Value(profile.ageBandMaxYears),
              heightCm: Value(profile.heightCm),
              activityLevel: Value(profile.activityLevel),
              weightUnit: Value(profile.weightUnit),
              proteinPct: Value(profile.proteinPct),
              carbsPct: Value(profile.carbsPct),
              fatPct: Value(profile.fatPct),
              reminderWeekday: Value(profile.reminderWeekday),
              reminderHour: Value(profile.reminderHour),
              reminderMinute: Value(profile.reminderMinute),
              onboardingCompleted: Value(profile.onboardingCompleted),
              dailyCalorieTarget: profile.dailyCalorieTarget == null
                  ? const Value.absent()
                  : Value(profile.dailyCalorieTarget),
              breakfastTarget: profile.breakfastTarget == null
                  ? const Value.absent()
                  : Value(profile.breakfastTarget),
              lunchTarget: profile.lunchTarget == null
                  ? const Value.absent()
                  : Value(profile.lunchTarget),
              dinnerTarget: profile.dinnerTarget == null
                  ? const Value.absent()
                  : Value(profile.dinnerTarget),
              snackTarget: profile.snackTarget == null
                  ? const Value.absent()
                  : Value(profile.snackTarget),
            ),
          );

      for (final g in goals) {
        await _db.into(_db.goals).insertOnConflictUpdate(
              GoalsCompanion(
                id: Value(g.id),
                targetWeightKg: Value(g.targetWeightKg),
                weeklyChangeKgPerWeek: Value(g.weeklyChangeKgPerWeek),
                status: Value(g.status),
              ),
            );
      }
      for (final w in weights) {
        await _db.into(_db.weightEntries).insertOnConflictUpdate(
              WeightEntriesCompanion(
                id: Value(w.id),
                recordedAt: Value(w.recordedAt),
                weightKg: Value(w.weightKg),
                note: Value(w.note),
              ),
            );
      }
      for (final c in custom) {
        await _db.into(_db.customFoods).insertOnConflictUpdate(
              CustomFoodsCompanion(
                id: Value(c.id),
                name: Value(c.name),
                brand: Value(c.brand),
                barcode: Value(c.barcode),
                servingSize: Value(c.servingSize),
                servingUnit: Value(c.servingUnit),
                calories: Value(c.calories),
                fatG: Value(c.fatG),
                carbsG: Value(c.carbsG),
                sugarG: Value(c.sugarG),
                fiberG: Value(c.fiberG),
                proteinG: Value(c.proteinG),
                extraNutrients: Value(c.extraNutrients),
              ),
            );
      }
      for (final e in foodLogs) {
        await _db.into(_db.foodLogEntries).insertOnConflictUpdate(
              FoodLogEntriesCompanion(
                id: Value(e.id),
                loggedAt: Value(e.loggedAt),
                source: Value(e.source),
                catalogFoodId: Value(e.catalogFoodId),
                customFoodId: Value(e.customFoodId),
                displayName: Value(e.displayName),
                grams: Value(e.grams),
                kcal: Value(e.kcal),
                proteinG: Value(e.proteinG),
                carbsG: Value(e.carbsG),
                sugarG: Value(e.sugarG),
                fiberG: Value(e.fiberG),
                fatG: Value(e.fatG),
                mealPeriod: Value(e.mealPeriod),
                isPlanned: Value(e.isPlanned),
                extraNutrients: Value(e.extraNutrients),
              ),
            );
      }
      for (final p in prefs) {
        await _db.into(_db.foodPrefs).insertOnConflictUpdate(
              FoodPrefsCompanion(
                foodKey: Value(p.foodKey),
                treatAsLiquid: Value(p.treatAsLiquid),
                savedServingAmount: Value(p.savedServingAmount),
                savedServingUnit: Value(p.savedServingUnit),
                lastServingLabel: Value(p.lastServingLabel),
                lastServingQty: Value(p.lastServingQty),
              ),
            );
      }
    });
  }
}

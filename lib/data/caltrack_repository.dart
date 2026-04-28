import 'package:caltrack/core/goal_logic.dart';
import 'package:caltrack/core/nutrition.dart';
import 'package:caltrack/core/units.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:drift/drift.dart';

export 'package:caltrack/data/app_database.dart'
    show Profile, Goal, WeightEntry, FoodLogEntry, CustomFood;

/// Aggregated intake for a calendar day (sums logged portions).
class DailyIntakeTotals {
  const DailyIntakeTotals({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.sugarG,
    required this.fiberG,
    required this.fatG,
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double sugarG;
  final double fiberG;
  final double fatG;

  static DailyIntakeTotals fromEntries(Iterable<FoodLogEntry> rows) {
    var k = 0.0;
    var p = 0.0;
    var c = 0.0;
    var s = 0.0;
    var fi = 0.0;
    var f = 0.0;
    for (final e in rows) {
      k += e.kcal;
      p += e.proteinG;
      c += e.carbsG;
      s += e.sugarG;
      fi += e.fiberG;
      f += e.fatG;
    }
    return DailyIntakeTotals(
      kcal: k,
      proteinG: p,
      carbsG: c,
      sugarG: s,
      fiberG: fi,
      fatG: f,
    );
  }

  static const zero =
      DailyIntakeTotals(kcal: 0, proteinG: 0, carbsG: 0, sugarG: 0, fiberG: 0, fatG: 0);
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
    final birth = DateTime.fromMillisecondsSinceEpoch(profile.birthDateMillis);
    final age = ageFromBirthDate(birth, DateTime.now());
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
  Future<void> submitOnboarding({
    required String sex,
    required DateTime birthDate,
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
          birthDateMillis: birthDate.millisecondsSinceEpoch,
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

  Future<void> addWeightEntry({
    required double weightKg,
    String? note,
  }) async {
    await _db.into(_db.weightEntries).insert(
          WeightEntriesCompanion.insert(
            recordedAt: DateTime.now(),
            weightKg: weightKg,
            note: Value(note),
          ),
        );
    await recacheDailyTarget();
    await checkGoalCompletionAfterWeighIn();
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
      ),
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
      final key = r.catalogFoodId ?? (r.customFoodId?.toString() ?? r.displayName);
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(r);
      if (out.length >= limit) break;
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
    );
    return _db.into(_db.customFoods).insertOnConflictUpdate(companion);
  }

  Future<void> deleteCustomFood(int id) async {
    await (_db.delete(_db.customFoods)..where((t) => t.id.equals(id))).go();
  }

  Future<void> resetForTesting() async {
    await _db.delete(_db.foodLogEntries).go();
    await _db.delete(_db.customFoods).go();
    await _db.delete(_db.weightEntries).go();
    await _db.delete(_db.goals).go();
    await (_db.update(_db.profiles)..where((t) => t.id.equals(1))).write(
      const ProfilesCompanion(
        onboardingCompleted: Value(false),
        dailyCalorieTarget: Value.absent(),
      ),
    );
  }
}

import 'dart:io';

import 'package:caltrack/core/nutrition.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

/// Meal periods for grouping food log entries.
enum MealPeriod {
  breakfast,
  lunch,
  dinner,
  snack;

  String get dbValue => name;

  static MealPeriod? fromDb(String? value) {
    if (value == null) return null;
    return MealPeriod.values.where((p) => p.dbValue == value).firstOrNull;
  }
}

class Profiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get sex => text()(); // male | female
  IntColumn get birthDateMillis =>
      integer()(); // legacy: local date at midnight stored as millis
  /// Upper bound of the user's age band (years). Preferred input to TDEE
  /// math; older rows may have it null and fall back to [birthDateMillis].
  IntColumn get ageBandMaxYears => integer().nullable()();
  RealColumn get heightCm => real()();
  IntColumn get activityLevel => integer()(); // 0-4
  TextColumn get weightUnit => text()(); // kg | lb
  IntColumn get proteinPct => integer()();
  IntColumn get carbsPct => integer()();
  IntColumn get fatPct => integer()();
  IntColumn get reminderWeekday => integer()(); // DateTime.monday..sunday
  IntColumn get reminderHour => integer()();
  IntColumn get reminderMinute => integer()();
  BoolColumn get onboardingCompleted =>
      boolean().withDefault(const Constant(false))();
  RealColumn get dailyCalorieTarget =>
      real().nullable()();
  RealColumn get breakfastTarget => real().nullable()();
  RealColumn get lunchTarget => real().nullable()();
  RealColumn get dinnerTarget => real().nullable()();
  RealColumn get snackTarget => real().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {id};
}

class Goals extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get targetWeightKg => real()();
  RealColumn get weeklyChangeKgPerWeek =>
      real()(); // signed: negative = losing weight
  TextColumn get status => text()(); // active | maintain | pending_choice
}

class WeightEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get recordedAt => dateTime()();
  RealColumn get weightKg => real()();
  TextColumn get note => text().nullable()();
}

enum ServingUnit { g, ml }

/// Per-food user preferences that override catalog defaults and provide
/// quick-select serving sizes.
class FoodPrefs extends Table {
  /// Stable key for a food. For catalog foods: `cat:<id>`. For custom:
  /// `cus:<id>`. Fallback: `name:<lowercased name>`.
  TextColumn get foodKey => text()();

  /// If null, use the catalog's default; otherwise override.
  BoolColumn get treatAsLiquid => boolean().nullable()();

  /// Saved “serving” quick-select amount.
  RealColumn get savedServingAmount => real().nullable()();

  /// 'g' | 'ml'
  TextColumn get savedServingUnit => text().nullable()();

  /// Last-used serving preset label (e.g. "Large egg") for catalog foods
  /// that expose per-piece presets. Null when the user last logged by
  /// grams or when the food has no presets. Paired with
  /// [lastServingQty] to reconstruct "2 × Large egg".
  TextColumn get lastServingLabel => text().nullable()();

  /// Quantity of [lastServingLabel] used on the most recent log. E.g.
  /// 2.0 for "2 large eggs". Null when presets weren't used.
  RealColumn get lastServingQty => real().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {foodKey};
}

/// User-created foods stored locally for fast re-use and barcode lookup.
class CustomFoods extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Required display name, e.g. "Greek yogurt".
  TextColumn get name => text()();

  /// Optional, e.g. "Chobani".
  TextColumn get brand => text().nullable()();

  /// Optional, normalized digits (EAN-13 if present).
  TextColumn get barcode => text().nullable()();

  /// Serving size amount (in [servingUnit]).
  RealColumn get servingSize => real()();

  /// 'g' | 'ml'
  TextColumn get servingUnit => text()();

  /// Nutrition per serving.
  RealColumn get calories => real()();
  RealColumn get fatG => real()();
  RealColumn get carbsG => real()();
  RealColumn get sugarG => real()();
  RealColumn get fiberG => real()();
  RealColumn get proteinG => real()();

  /// JSON blob for extended nutrients (vitamins, minerals, fatty acids,
  /// amino acids). Map of NutrientKey name → double value.
  TextColumn get extraNutrients => text().nullable()();
}

/// Logged food with snapshot macros for the chosen portion (not per-100g).
class FoodLogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get source => text()(); // opennutrition | custom
  TextColumn get catalogFoodId => text().nullable()();
  IntColumn get customFoodId => integer().nullable()();
  TextColumn get displayName => text()();
  RealColumn get grams => real()();
  RealColumn get kcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get sugarG => real().withDefault(const Constant(0))();
  RealColumn get fiberG => real().withDefault(const Constant(0))();
  RealColumn get fatG => real()();
  TextColumn get mealPeriod => text().nullable()();
  BoolColumn get isPlanned => boolean().withDefault(const Constant(false))();

  /// JSON blob for extended nutrients (vitamins, minerals, fatty acids,
  /// amino acids). Map of NutrientKey name → double value.
  TextColumn get extraNutrients => text().nullable()();
}

class Meals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  
  // Total summary of standard macros
  RealColumn get calories => real()();
  RealColumn get fatG => real()();
  RealColumn get carbsG => real()();
  RealColumn get sugarG => real()();
  RealColumn get fiberG => real()();
  RealColumn get proteinG => real()();

  // Total weight of all ingredients combined (grams)
  RealColumn get totalGrams => real().withDefault(const Constant(0))();

  // Serving count (how many servings this meal makes)
  IntColumn get servingCount => integer().withDefault(const Constant(1))();

  // Custom label of the serving (e.g. "1 bowl", "1 plate")
  TextColumn get servingLabel => text().nullable()();

  /// JSON blob for aggregated extended nutrients (vitamins, minerals, etc.)
  TextColumn get extraNutrients => text().nullable()();
}

class MealItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get mealId => integer()(); // References Meals.id

  TextColumn get foodSource => text()(); // opennutrition | custom
  TextColumn get catalogFoodId => text().nullable()();
  IntColumn get customFoodId => integer().nullable()();
  TextColumn get displayName => text()();

  RealColumn get grams => real()();

  // Macros for this portion
  RealColumn get kcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();
  RealColumn get sugarG => real()();
  RealColumn get fiberG => real()();

  /// JSON blob for extended nutrients for this item portion
  TextColumn get extraNutrients => text().nullable()();
}

/// User-defined serving presets for custom foods.
///
/// Each custom food always has at least one serving.  Users can add extras
/// like "1 cup (250 g)" or "1 slice (45 g)".  The [label] describes the
/// serving (e.g. "1 bag") and [grams] is its mass.
class CustomFoodServings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customFoodId => integer()();
  TextColumn get label => text()(); // e.g. "1 bag", "1 cup", "1 slice"
  RealColumn get grams => real()(); // mass of this serving
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

@DriftDatabase(
  tables: [
    Profiles,
    Goals,
    WeightEntries,
    FoodPrefs,
    CustomFoods,
    FoodLogEntries,
    Meals,
    MealItems,
    CustomFoodServings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(foodLogEntries);
          }
          if (from < 3) {
            await m.createTable(customFoods);
            await m.addColumn(foodLogEntries, foodLogEntries.customFoodId);
            await m.addColumn(foodLogEntries, foodLogEntries.sugarG);
            await m.addColumn(foodLogEntries, foodLogEntries.fiberG);
          }
          if (from < 4) {
            await m.addColumn(profiles, profiles.ageBandMaxYears);
            final rows = await select(profiles).get();
            final today = DateTime.now();
            for (final row in rows) {
              final birth = DateTime.fromMillisecondsSinceEpoch(
                row.birthDateMillis,
              );
              final age = ageFromBirthDate(birth, today);
              final upper = ageBandUpperBoundForYears(age);
              await (update(profiles)..where((t) => t.id.equals(row.id)))
                  .write(ProfilesCompanion(ageBandMaxYears: Value(upper)));
            }
          }
          if (from < 5) {
            await m.createTable(foodPrefs);
          }
          if (from < 6) {
            await m.addColumn(foodPrefs, foodPrefs.lastServingLabel);
            await m.addColumn(foodPrefs, foodPrefs.lastServingQty);
          }
          if (from < 7) {
            await m.addColumn(foodLogEntries, foodLogEntries.mealPeriod);
            await m.addColumn(foodLogEntries, foodLogEntries.isPlanned);
            await m.addColumn(profiles, profiles.breakfastTarget);
            await m.addColumn(profiles, profiles.lunchTarget);
            await m.addColumn(profiles, profiles.dinnerTarget);
            await m.addColumn(profiles, profiles.snackTarget);
          }
          if (from < 8) {
            await m.addColumn(foodLogEntries, foodLogEntries.extraNutrients);
            await m.addColumn(customFoods, customFoods.extraNutrients);
          }
          if (from < 9) {
            await m.createTable(meals);
            await m.createTable(mealItems);
          }
          if (from < 10) {
            await m.createTable(customFoodServings);
            await m.addColumn(meals, meals.totalGrams);
          }
          if (from < 11) {
            await m.addColumn(meals, meals.servingCount);
            await m.addColumn(meals, meals.servingLabel);
          }
        },
      );

  Future<void> seedIfEmpty() async {
    final p = await select(profiles).getSingleOrNull();
    if (p == null) {
      final now = DateTime.now();
      final birth = DateTime(now.year - 30, now.month, now.day);
      await into(profiles).insert(
        ProfilesCompanion.insert(
          sex: 'male',
          birthDateMillis: birth.millisecondsSinceEpoch,
          heightCm: 175,
          activityLevel: 2,
          weightUnit: 'kg',
          proteinPct: 30,
          carbsPct: 40,
          fatPct: 30,
          reminderWeekday: DateTime.sunday,
          reminderHour: 9,
          reminderMinute: 0,
          onboardingCompleted: const Value(false),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'caltrack.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}

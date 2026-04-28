import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Profiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get sex => text()(); // male | female
  IntColumn get birthDateMillis =>
      integer()(); // local date at midnight stored as millis
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

/// Logged food with snapshot macros for the chosen portion (not per-100g).
class FoodLogEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get loggedAt => dateTime()();
  TextColumn get source => text()(); // opennutrition | custom
  TextColumn get catalogFoodId => text().nullable()();
  TextColumn get displayName => text()();
  RealColumn get grams => real()();
  RealColumn get kcal => real()();
  RealColumn get proteinG => real()();
  RealColumn get carbsG => real()();
  RealColumn get fatG => real()();
}

@DriftDatabase(tables: [Profiles, Goals, WeightEntries, FoodLogEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.createTable(foodLogEntries);
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

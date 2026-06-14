import 'package:caltrack/app/meal_time_controller.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/features/food/log_food_screen.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCatalog extends OpenNutritionCatalog {
  final List<CatalogFood> _searchResults;

  _FakeCatalog({List<CatalogFood>? searchResults})
      : _searchResults = searchResults ?? const [];

  @override
  Future<List<CatalogFood>> search(String query, {int limit = 40}) async {
    final q = query.toLowerCase();
    return _searchResults
        .where((f) => f.name.toLowerCase().contains(q))
        .toList();
  }

  @override
  Future<CatalogFood?> byId(String id) async => null;

  @override
  Future<CatalogFoodGroup?> groupForFood(String foodId) async => null;

  @override
  Future<int> foodRowCount() async => _searchResults.length;
}

Future<void> _pumpLogFoodScreen(
  WidgetTester tester, {
  required CalTrackRepository repo,
  required DateTime? initialDay,
  List<CatalogFood>? catalogResults,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        Provider<CalTrackRepository>.value(value: repo),
        Provider<OpenNutritionCatalog>.value(
          value: _FakeCatalog(searchResults: catalogResults),
        ),
        ChangeNotifierProvider<MealTimeController>(
          create: (_) => MealTimeController(prefs),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: LogFoodScreen(initialDay: initialDay),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _searchFor(WidgetTester tester, String query) async {
  final field = find.byType(TextField).first;
  await tester.enterText(field, query);
  await tester.pump(const Duration(milliseconds: 300));
  await tester.pumpAndSettle();
}

Future<void> _saveSheet(WidgetTester tester) async {
  final addButton = find.widgetWithText(FilledButton, 'Add to diary');
  await tester.ensureVisible(addButton);
  await tester.pumpAndSettle();
  await tester.tap(addButton);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  final messenger = tester.state<ScaffoldMessengerState>(
    find.byType(ScaffoldMessenger),
  );
  messenger.hideCurrentSnackBar();
  await tester.pumpAndSettle();
}

Future<List<FoodLogEntry>> _entriesForDay(
  AppDatabase db,
  DateTime day,
) async {
  final start = DateTime(day.year, day.month, day.day);
  final end = start.add(const Duration(days: 1));
  return (db.select(db.foodLogEntries)
        ..where(
          (t) => t.loggedAt.isBiggerOrEqualValue(start) &
              t.loggedAt.isSmallerThanValue(end),
        ))
      .get();
}

void main() {
  group('LogFoodScreen future-date entries', () {
    late AppDatabase db;
    late CalTrackRepository repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = CalTrackRepository(db);
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

    testWidgets(
        'custom food searched from a future day is logged on that day',
        (tester) async {
      final futureDay = DateTime.now().add(const Duration(days: 3));
      final customId = await repo.upsertCustomFood(
        name: 'Oatmeal',
        servingSize: 100,
        servingUnit: 'g',
        calories: 150,
        fatG: 3,
        carbsG: 25,
        sugarG: 1,
        fiberG: 4,
        proteinG: 5,
      );

      await _pumpLogFoodScreen(tester, repo: repo, initialDay: futureDay);
      await _searchFor(tester, 'Oat');

      await tester.tap(find.text('Oatmeal'));
      await tester.pumpAndSettle();

      await _saveSheet(tester);

      final futureEntries = await _entriesForDay(db, futureDay);
      expect(futureEntries, hasLength(1));
      expect(futureEntries.first.displayName, 'Oatmeal');
      expect(futureEntries.first.customFoodId, customId);

      final todayEntries = await _entriesForDay(db, DateTime.now());
      expect(todayEntries, isEmpty);
    });

    testWidgets(
        'catalog food searched from a future day is logged on that day',
        (tester) async {
      final futureDay = DateTime.now().add(const Duration(days: 2));
      const catalogFood = CatalogFood(
        id: 'apple_001',
        name: 'Apple',
        kcalPer100g: 52,
        proteinPer100g: 0.3,
        carbsPer100g: 14,
        fatPer100g: 0.2,
        fiberPer100g: 2.4,
        sugarPer100g: 10,
        isLiquid: false,
      );

      await _pumpLogFoodScreen(
        tester,
        repo: repo,
        initialDay: futureDay,
        catalogResults: const [catalogFood],
      );
      await _searchFor(tester, 'App');

      await tester.tap(find.text('Apple'));
      await tester.pumpAndSettle();

      await _saveSheet(tester);

      final futureEntries = await _entriesForDay(db, futureDay);
      expect(futureEntries, hasLength(1));
      expect(futureEntries.first.displayName, 'Apple');
      expect(futureEntries.first.catalogFoodId, 'apple_001');

      final todayEntries = await _entriesForDay(db, DateTime.now());
      expect(todayEntries, isEmpty);
    });

    testWidgets(
        're-logging a recent custom food keeps the future day for many entries',
        (tester) async {
      final futureDay = DateTime.now().add(const Duration(days: 4));
      final customId = await repo.upsertCustomFood(
        name: 'Protein bar',
        brand: 'Test Brand',
        servingSize: 60,
        servingUnit: 'g',
        calories: 200,
        fatG: 7,
        carbsG: 20,
        sugarG: 5,
        fiberG: 3,
        proteinG: 15,
      );

      // Seed one future entry so the food appears in the recent list.
      await repo.addFoodLogReturnId(
        source: 'custom',
        customFoodId: customId,
        displayName: 'Protein bar',
        grams: 60,
        kcal: 200,
        proteinG: 15,
        carbsG: 20,
        fatG: 7,
        loggedAt: futureDay,
      );

      await _pumpLogFoodScreen(tester, repo: repo, initialDay: futureDay);

      // The recent list should show the seeded entry.
      expect(find.text('Protein bar'), findsOneWidget);

      const repetitions = 5;
      for (var i = 0; i < repetitions; i++) {
        await tester.tap(find.text('Protein bar'));
        await tester.pumpAndSettle();

        await _saveSheet(tester);
      }

      final futureEntries = await _entriesForDay(db, futureDay);
      // Seed (1) + repetitions (5)
      expect(futureEntries, hasLength(repetitions + 1));
      for (final entry in futureEntries) {
        expect(entry.displayName, 'Protein bar');
        expect(
          DateTime(
            entry.loggedAt.year,
            entry.loggedAt.month,
            entry.loggedAt.day,
          ),
          DateTime(futureDay.year, futureDay.month, futureDay.day),
        );
      }

      final todayEntries = await _entriesForDay(db, DateTime.now());
      expect(todayEntries, isEmpty);
    });
  });
}

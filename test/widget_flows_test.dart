import 'package:caltrack/app/meal_time_controller.dart';
import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/app/theme_controller.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/features/food/food_entry_sheet.dart';
import 'package:caltrack/features/settings/data_tools_screen.dart';
import 'package:caltrack/features/settings/settings_screen.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeCatalog extends OpenNutritionCatalog {
  @override
  Future<int> foodRowCount() async => 0;

  @override
  Future<CatalogFood?> byId(String id) async => null;
}

Widget _wrapWithProviders({
  required Widget child,
  required CalTrackRepository repo,
  required ProfileController profileCtl,
  required SharedPreferences prefs,
  OpenNutritionCatalog? catalog,
}) {
  return MultiProvider(
    providers: [
      Provider<CalTrackRepository>.value(value: repo),
      ChangeNotifierProvider<ProfileController>.value(value: profileCtl),
      ChangeNotifierProvider<MealTimeController>.value(
        value: MealTimeController(prefs),
      ),
      Provider<OpenNutritionCatalog>.value(value: catalog ?? _FakeCatalog()),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  group('widget flows', () {
    late AppDatabase db;
    late CalTrackRepository repo;
    late ProfileController profileCtl;

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
      profileCtl = ProfileController(repo);
      await profileCtl.load();
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets('Settings shows Data tools and routes to DataToolsScreen',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final themeCtl = ThemeController(await SharedPreferences.getInstance());
      final router = GoRouter(
        initialLocation: '/settings',
        routes: [
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/data-tools',
            builder: (context, state) => const DataToolsScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<CalTrackRepository>.value(value: repo),
            ChangeNotifierProvider<ProfileController>.value(value: profileCtl),
            ChangeNotifierProvider<ThemeController>.value(value: themeCtl),
            ChangeNotifierProvider<MealTimeController>.value(
              value: MealTimeController(await SharedPreferences.getInstance()),
            ),
            Provider<OpenNutritionCatalog>.value(value: _FakeCatalog()),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final dataToolsTile = find.text('Backup / export / import');
      await tester.scrollUntilVisible(
        dataToolsTile,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(dataToolsTile);
      await tester.pumpAndSettle();

      expect(find.byType(DataToolsScreen), findsOneWidget);
      expect(find.text('Export backup (JSON)'), findsOneWidget);
    });

    testWidgets('FoodEntrySheet shows amount error and disables add',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final harness = Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                await showFoodEntrySheet(
                  context,
                  const FoodEntrySheetConfig(
                    displayName: 'Test food',
                    source: 'custom',
                    kcalPer100g: 100,
                    proteinPer100g: 10,
                    carbsPer100g: 10,
                    fatPer100g: 10,
                    initialGrams: 100,
                  ),
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        _wrapWithProviders(child: harness, repo: repo, profileCtl: profileCtl, prefs: prefs),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Clear amount, expect validation error, and primary action disabled.
      final amountField = find.byType(TextField).first;
      await tester.enterText(amountField, '');
      await tester.pumpAndSettle();

      expect(find.text('Amount must be a number.'), findsOneWidget);
      final addButton = find.widgetWithText(FilledButton, 'Add to diary');
      final btnWidget = tester.widget<FilledButton>(addButton);
      expect(btnWidget.onPressed, isNull);
    });
  });
}


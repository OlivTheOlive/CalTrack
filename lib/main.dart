import 'package:caltrack/app/meal_time_controller.dart';
import 'package:caltrack/app/nutrition_display_controller.dart';
import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/app/router.dart';
import 'package:caltrack/app/theme.dart';
import 'package:caltrack/app/theme_controller.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final db = AppDatabase();
  await db.seedIfEmpty();

  final repo = CalTrackRepository(db);
  final catalog = OpenNutritionCatalog();
  final profileController = ProfileController(repo);
  final prefs = await SharedPreferences.getInstance();
  final themeController = ThemeController(prefs);
  final mealTimeController = MealTimeController(prefs);
  final nutritionDisplayController = NutritionDisplayController(prefs);

  late final GoRouter router;
  router = createRouter(profileController);

  await NotificationService.instance.init(
    onTap: (NotificationResponse response) {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        router.go(payload);
      }
    },
  );

  await NotificationService.instance.scheduleWeeklyWeighIn(repo: repo);

  runApp(
    MultiProvider(
      providers: [
        Provider<CalTrackRepository>.value(value: repo),
        Provider<OpenNutritionCatalog>.value(value: catalog),
        ChangeNotifierProvider<ProfileController>.value(value: profileController),
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        ChangeNotifierProvider<MealTimeController>.value(value: mealTimeController),
        ChangeNotifierProvider<NutritionDisplayController>.value(
          value: nutritionDisplayController,
        ),
      ],
      child: CalTrackApp(router: router, repo: repo),
    ),
  );
}

class CalTrackApp extends StatefulWidget {
  const CalTrackApp({super.key, required this.router, required this.repo});

  final GoRouter router;
  final CalTrackRepository repo;

  @override
  State<CalTrackApp> createState() => _CalTrackAppState();
}

class _CalTrackAppState extends State<CalTrackApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotificationService.instance.rescheduleFromRepo(repo: widget.repo);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeController = context.watch<ThemeController>();
    final style = themeController.style;
    return MaterialApp.router(
      title: 'CalTrack',
      theme: buildCalTrackTheme(style: style),
      darkTheme: themeController.isOled
          ? buildCalTrackOledTheme(style: style)
          : buildCalTrackTheme(style: style, brightness: Brightness.dark),
      themeMode: themeController.themeMode,
      routerConfig: widget.router,
    );
  }
}

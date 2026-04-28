import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/app/router.dart';
import 'package:caltrack/app/theme.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:caltrack/data/caltrack_repository.dart';
import 'package:caltrack/data/opennutrition_catalog.dart';
import 'package:caltrack/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final db = AppDatabase();
  await db.seedIfEmpty();

  final repo = CalTrackRepository(db);
  final catalog = OpenNutritionCatalog();
  final profileController = ProfileController(repo);

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
      ],
      child: CalTrackApp(router: router),
    ),
  );
}

class CalTrackApp extends StatelessWidget {
  const CalTrackApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CalTrack',
      theme: buildCalTrackTheme(),
      darkTheme: buildCalTrackTheme(brightness: Brightness.dark),
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}

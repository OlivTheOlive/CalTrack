import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:caltrack/features/bands/calorie_bands_screen.dart';
import 'package:caltrack/features/calendar/calendar_screen.dart';
import 'package:caltrack/features/food/add_custom_food_screen.dart';
import 'package:caltrack/features/food/barcode_scan_screen.dart';
import 'package:caltrack/features/food/custom_foods_list_screen.dart';
import 'package:caltrack/features/food/log_food_screen.dart';
import 'package:caltrack/features/food/nutrition_label_scan_screen.dart';
import 'package:caltrack/features/nutrients/nutrient_breakdown_screen.dart';
import 'package:caltrack/features/onboarding/onboarding_screen.dart';
import 'package:caltrack/features/settings/data_tools_screen.dart';
import 'package:caltrack/features/settings/settings_screen.dart';
import 'package:caltrack/features/shell/root_shell.dart';
import 'package:caltrack/features/weight/log_weight_screen.dart';
import 'package:caltrack/features/weekly/weekly_review_screen.dart';
import 'package:go_router/go_router.dart';

GoRouter createRouter(ProfileController profileController) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: profileController,
    redirect: (context, state) {
      final p = profileController.profile;
      if (p == null || profileController.loading) return null;
      final loc = state.uri.path;
      if (!p.onboardingCompleted) {
        if (loc != '/onboarding') return '/onboarding';
      } else {
        if (loc == '/onboarding') return '/';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const RootShell(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/log-weight',
        builder: (context, state) {
          final raw = state.uri.queryParameters['id'];
          final id = raw == null ? null : int.tryParse(raw);
          return LogWeightScreen(editingEntryId: id);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/data-tools',
        builder: (context, state) => const DataToolsScreen(),
      ),
      GoRoute(
        path: '/weekly-review',
        builder: (context, state) => const WeeklyReviewScreen(),
      ),
      GoRoute(
        path: '/calorie-bands',
        builder: (context, state) => const CalorieBandsScreen(),
      ),
      GoRoute(
        path: '/log-food',
        builder: (context, state) {
          final dayParam = state.uri.queryParameters['day'];
          final initialDay = _parseIsoDay(dayParam);
          return LogFoodScreen(initialDay: initialDay);
        },
      ),
      GoRoute(
        path: '/scan-barcode',
        builder: (context, state) {
          final raw = state.uri.queryParameters['raw'] == '1';
          return BarcodeScanScreen(rawMode: raw);
        },
      ),
      GoRoute(
        path: '/add-custom-food',
        builder: (context, state) {
          final extra = state.extra;
          final barcode = extra is Map ? extra['barcode'] as String? : null;
          final existingFood = extra is Map ? extra['existingFood'] as CustomFood? : null;
          final loggedAtForEdit = extra is Map ? extra['loggedAtForEdit'] as DateTime? : null;
          return AddCustomFoodScreen(
            initialBarcode: barcode,
            existingFood: existingFood,
            loggedAtForEdit: loggedAtForEdit,
          );
        },
      ),
      GoRoute(
        path: '/custom-foods',
        builder: (context, state) => const CustomFoodsListScreen(),
      ),
      GoRoute(
        path: '/scan-nutrition-label',
        builder: (context, state) => const NutritionLabelScanScreen(),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: '/nutrients',
        builder: (context, state) => const NutrientBreakdownScreen(),
      ),
    ],
  );
}

/// Parse a `YYYY-MM-DD` query value into a local-midnight DateTime.
/// Returns null on malformed/missing input.
DateTime? _parseIsoDay(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(raw);
  if (m == null) return null;
  final y = int.tryParse(m.group(1)!);
  final mo = int.tryParse(m.group(2)!);
  final d = int.tryParse(m.group(3)!);
  if (y == null || mo == null || d == null) return null;
  return DateTime(y, mo, d);
}

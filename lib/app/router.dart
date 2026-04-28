import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/features/food/add_custom_food_screen.dart';
import 'package:caltrack/features/food/barcode_scan_screen.dart';
import 'package:caltrack/features/food/log_food_screen.dart';
import 'package:caltrack/features/food/nutrition_label_scan_screen.dart';
import 'package:caltrack/features/onboarding/onboarding_screen.dart';
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
        builder: (context, state) => const LogWeightScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/weekly-review',
        builder: (context, state) => const WeeklyReviewScreen(),
      ),
      GoRoute(
        path: '/log-food',
        builder: (context, state) => const LogFoodScreen(),
      ),
      GoRoute(
        path: '/scan-barcode',
        builder: (context, state) => const BarcodeScanScreen(),
      ),
      GoRoute(
        path: '/add-custom-food',
        builder: (context, state) {
          final extra = state.extra;
          final barcode = extra is Map ? extra['barcode'] as String? : null;
          return AddCustomFoodScreen(initialBarcode: barcode);
        },
      ),
      GoRoute(
        path: '/scan-nutrition-label',
        builder: (context, state) => const NutritionLabelScanScreen(),
      ),
    ],
  );
}

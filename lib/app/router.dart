import 'package:caltrack/app/profile_controller.dart';
import 'package:caltrack/features/dashboard/home_screen.dart';
import 'package:caltrack/features/onboarding/onboarding_screen.dart';
import 'package:caltrack/features/settings/settings_screen.dart';
import 'package:caltrack/features/weight/history_screen.dart';
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
        builder: (context, state) => const HomeScreen(),
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
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/weekly-review',
        builder: (context, state) => const WeeklyReviewScreen(),
      ),
    ],
  );
}

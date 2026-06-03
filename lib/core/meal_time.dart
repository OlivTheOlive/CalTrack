import 'package:caltrack/data/app_database.dart';

/// Configuration for auto-selecting a meal period based on the current
/// local time. Windows are hour-of-day ranges (inclusive start, exclusive
/// end). All times are local — no timezone logic needed since the device
/// clock is the reference.
class MealTimeConfig {
  const MealTimeConfig({
    this.enabled = true,
    this.breakfastStart = 5,
    this.breakfastEnd = 11,
    this.lunchStart = 12,
    this.lunchEnd = 16,
    this.dinnerStart = 17,
    this.dinnerEnd = 21,
  });

  final bool enabled;
  final int breakfastStart;
  final int breakfastEnd;
  final int lunchStart;
  final int lunchEnd;
  final int dinnerStart;
  final int dinnerEnd;

  /// Returns the [MealPeriod] whose window contains [now.hour], or null
  /// if no window matches. Windows are checked in breakfast → lunch →
  /// dinner order; the first match wins (so non-overlapping windows are
  /// required for predictable behaviour).
  MealPeriod? suggest(DateTime now) {
    if (!enabled) return null;

    final h = now.hour;

    if (h >= breakfastStart && h < breakfastEnd) return MealPeriod.breakfast;
    if (h >= lunchStart && h < lunchEnd) return MealPeriod.lunch;
    if (h >= dinnerStart && h < dinnerEnd) return MealPeriod.dinner;

    return null;
  }

  MealTimeConfig copyWith({
    bool? enabled,
    int? breakfastStart,
    int? breakfastEnd,
    int? lunchStart,
    int? lunchEnd,
    int? dinnerStart,
    int? dinnerEnd,
  }) {
    return MealTimeConfig(
      enabled: enabled ?? this.enabled,
      breakfastStart: breakfastStart ?? this.breakfastStart,
      breakfastEnd: breakfastEnd ?? this.breakfastEnd,
      lunchStart: lunchStart ?? this.lunchStart,
      lunchEnd: lunchEnd ?? this.lunchEnd,
      dinnerStart: dinnerStart ?? this.dinnerStart,
      dinnerEnd: dinnerEnd ?? this.dinnerEnd,
    );
  }

  static const defaults = MealTimeConfig();
}
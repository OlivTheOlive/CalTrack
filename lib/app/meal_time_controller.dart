import 'package:caltrack/core/meal_time.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealTimeController extends ChangeNotifier {
  MealTimeController(this._prefs) {
    _load();
  }

  final SharedPreferences _prefs;

  MealTimeConfig _config = MealTimeConfig.defaults;
  MealTimeConfig get config => _config;

  // SharedPreferences keys
  static const _keyEnabled = 'meal_auto_enabled';
  static const _keyBreakfastStart = 'meal_window_breakfast_start';
  static const _keyBreakfastEnd = 'meal_window_breakfast_end';
  static const _keyLunchStart = 'meal_window_lunch_start';
  static const _keyLunchEnd = 'meal_window_lunch_end';
  static const _keyDinnerStart = 'meal_window_dinner_start';
  static const _keyDinnerEnd = 'meal_window_dinner_end';

  void _load() {
    _config = MealTimeConfig(
      enabled: _prefs.getBool(_keyEnabled) ?? true,
      breakfastStart: _prefs.getInt(_keyBreakfastStart) ?? 5,
      breakfastEnd: _prefs.getInt(_keyBreakfastEnd) ?? 11,
      lunchStart: _prefs.getInt(_keyLunchStart) ?? 12,
      lunchEnd: _prefs.getInt(_keyLunchEnd) ?? 16,
      dinnerStart: _prefs.getInt(_keyDinnerStart) ?? 17,
      dinnerEnd: _prefs.getInt(_keyDinnerEnd) ?? 21,
    );
  }

  MealPeriod? suggestMealPeriod() => _config.suggest(DateTime.now());

  Future<void> setEnabled(bool value) async {
    _config = _config.copyWith(enabled: value);
    await _prefs.setBool(_keyEnabled, value);
    notifyListeners();
  }

  Future<void> setBreakfastWindow(int start, int end) async {
    _config = _config.copyWith(breakfastStart: start, breakfastEnd: end);
    await _prefs.setInt(_keyBreakfastStart, start);
    await _prefs.setInt(_keyBreakfastEnd, end);
    notifyListeners();
  }

  Future<void> setLunchWindow(int start, int end) async {
    _config = _config.copyWith(lunchStart: start, lunchEnd: end);
    await _prefs.setInt(_keyLunchStart, start);
    await _prefs.setInt(_keyLunchEnd, end);
    notifyListeners();
  }

  Future<void> setDinnerWindow(int start, int end) async {
    _config = _config.copyWith(dinnerStart: start, dinnerEnd: end);
    await _prefs.setInt(_keyDinnerStart, start);
    await _prefs.setInt(_keyDinnerEnd, end);
    notifyListeners();
  }
}
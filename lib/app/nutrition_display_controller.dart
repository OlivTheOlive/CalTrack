import 'package:caltrack/core/nutrients.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum NutritionDisplayMode { simple, detailed, custom }

class NutritionDisplayController extends ChangeNotifier {
  NutritionDisplayController({
    required SharedPreferences prefs,
  }) : _prefs = prefs {
    _mode = _readMode();
    _customSelection = _readCustomSelection();
  }

  final SharedPreferences _prefs;

  static const _modeKey = 'nutrition_display_mode';
  static const _customKeysKey = 'nutrition_custom_keys';

  NutritionDisplayMode _mode = NutritionDisplayMode.simple;
  Set<NutrientKey> _customSelection = {
    NutrientKey.kcal,
    NutrientKey.proteinG,
    NutrientKey.totalCarbsG,
    NutrientKey.totalFatG,
    NutrientKey.dietaryFiberG,
    NutrientKey.totalSugarsG,
  };

  NutritionDisplayMode get mode => _mode;
  Set<NutrientKey> get customSelection => Set.unmodifiable(_customSelection);

  void setMode(NutritionDisplayMode value) {
    if (_mode == value) return;
    _mode = value;
    _prefs.setString(_modeKey, value.name);
    notifyListeners();
  }

  void toggleCustomNutrient(NutrientKey key) {
    final updated = Set<NutrientKey>.from(_customSelection);
    if (updated.contains(key)) {
      updated.remove(key);
    } else {
      updated.add(key);
    }
    _customSelection = updated;
    _persistCustomSelection();
    notifyListeners();
  }

  void setCustomSelection(Set<NutrientKey> keys) {
    _customSelection = Set.from(keys);
    _persistCustomSelection();
    notifyListeners();
  }

  NutritionDisplayMode _readMode() {
    final raw = _prefs.getString(_modeKey);
    if (raw == null) return NutritionDisplayMode.simple;
    return NutritionDisplayMode.values
        .where((m) => m.name == raw)
        .firstOrNull ??
        NutritionDisplayMode.simple;
  }

  Set<NutrientKey> _readCustomSelection() {
    final raw = _prefs.getStringList(_customKeysKey);
    if (raw == null || raw.isEmpty) {
      return {
        NutrientKey.kcal,
        NutrientKey.proteinG,
        NutrientKey.totalCarbsG,
        NutrientKey.totalFatG,
        NutrientKey.dietaryFiberG,
        NutrientKey.totalSugarsG,
      };
    }
    final out = <NutrientKey>{};
    for (final name in raw) {
      final key = NutrientKey.values.where((k) => k.name == name).firstOrNull;
      if (key != null) out.add(key);
    }
    if (out.isEmpty) {
      return {
        NutrientKey.kcal,
        NutrientKey.proteinG,
        NutrientKey.totalCarbsG,
        NutrientKey.totalFatG,
      };
    }
    return out;
  }

  void _persistCustomSelection() {
    _prefs.setStringList(
      _customKeysKey,
      _customSelection.map((k) => k.name).toList(),
    );
  }
}
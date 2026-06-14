import 'package:caltrack/core/nutrients.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NutritionDisplayController extends ChangeNotifier {
  NutritionDisplayController(SharedPreferences prefs) : _prefs = prefs {
    _customSelection = _readCustomSelection();
  }

  final SharedPreferences _prefs;

  static const _customKeysKey = 'nutrition_custom_keys';

  Set<NutrientKey> _customSelection = {
    NutrientKey.kcal,
    NutrientKey.proteinG,
    NutrientKey.totalCarbsG,
    NutrientKey.totalFatG,
    NutrientKey.dietaryFiberG,
    NutrientKey.totalSugarsG,
  };

  Set<NutrientKey> get customSelection => Set.unmodifiable(_customSelection);

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

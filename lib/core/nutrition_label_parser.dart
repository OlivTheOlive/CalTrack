import 'dart:ui';

import 'package:caltrack/core/nutrients.dart';
import 'package:caltrack/data/app_database.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

enum NutritionField {
  servingSize,
  calories,
  totalFat,
  saturatedFat,
  transFat,
  cholesterol,
  sodium,
  totalCarbs,
  fiber,
  sugar,
  addedSugars,
  protein,
  vitaminD,
  calcium,
  iron,
  potassium,
}

class ExtractedField<T> {
  const ExtractedField({required this.value, required this.box});

  final T value;
  final Rect box;
}

class NutritionParseResult {
  const NutritionParseResult({required this.draft, required this.fields});

  final ({
    double? servingSize,
    ServingUnit? servingUnit,
    double? calories,
    double? fatG,
    double? carbsG,
    double? sugarG,
    double? fiberG,
    double? proteinG,
    Map<NutrientKey, double> extraNutrients,
  })
  draft;

  final Map<NutritionField, ExtractedField<double>> fields;
}

class OcrLine {
  const OcrLine({required this.text, required this.box});

  final String text;
  final Rect box;
}

// ---------------------------------------------------------------------------
// Regex helpers
// ---------------------------------------------------------------------------

/// Matches a number followed by a gram unit, e.g. "30 g", "30g", "3,5 gr".
/// Word-boundary anchored so "sugar", "grams of fat", etc. don't match.
final RegExp _gramQuantity = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(?:g|gr|gramme[s]?|grams?)\b',
  caseSensitive: false,
);

/// Matches a number followed by a millilitre unit.
final RegExp _mlQuantity = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(?:ml|millilitre[s]?|milliliter[s]?)\b',
  caseSensitive: false,
);

/// Matches a number followed by a milligram unit.
final RegExp _mgQuantity = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(?:mg|milligrams?)\b',
  caseSensitive: false,
);

/// Matches a number followed by a microgram/mcg unit.
final RegExp _mcgQuantity = RegExp(
  r'(\d+(?:[.,]\d+)?)\s*(?:mcg|µg|ug|micrograms?)\b',
  caseSensitive: false,
);

/// Bare number anywhere in the string.
final RegExp _bareNumber = RegExp(r'(-?\d+(?:[.,]\d+)?)');

double? _toDouble(String? raw) {
  if (raw == null) return null;
  return double.tryParse(raw.replaceAll(',', '.'));
}

double? _firstNumber(String s) => _toDouble(_bareNumber.firstMatch(s)?.group(1));

/// First explicit `<n> g` quantity in the line (ignores other numbers).
double? _firstGramQuantity(String s) =>
    _toDouble(_gramQuantity.firstMatch(s)?.group(1));

/// First explicit `<n> ml` quantity in the line.
double? _firstMlQuantity(String s) =>
    _toDouble(_mlQuantity.firstMatch(s)?.group(1));

/// First explicit `<n> mg` quantity in the line.
double? _firstMgQuantity(String s) =>
    _toDouble(_mgQuantity.firstMatch(s)?.group(1));

/// First explicit `<n> mcg` quantity in the line.
double? _firstMcgQuantity(String s) =>
    _toDouble(_mcgQuantity.firstMatch(s)?.group(1));

/// A serving-size measurement preferring the LAST occurrence on the line so
/// labels like "Per 1 cup (30 g)" pick the 30 g, not the 1.
({double value, ServingUnit unit})? _extractServingMeasurement(String s) {
  final mls = _mlQuantity.allMatches(s).toList();
  if (mls.isNotEmpty) {
    final v = _toDouble(mls.last.group(1));
    if (v != null) return (value: v, unit: ServingUnit.ml);
  }
  final gs = _gramQuantity.allMatches(s).toList();
  if (gs.isNotEmpty) {
    final v = _toDouble(gs.last.group(1));
    if (v != null) return (value: v, unit: ServingUnit.g);
  }
  return null;
}

bool _matchesAny(String text, List<RegExp> patterns) {
  for (final p in patterns) {
    if (p.hasMatch(text)) return true;
  }
  return false;
}

// ---------------------------------------------------------------------------
// Bilingual (EN/FR) keyword vocabulary
// ---------------------------------------------------------------------------

/// Words that introduce a serving-size declaration on a line. Permissive on
/// purpose; we still require a g/mL measurement to actually accept it, which
/// filters out incidental matches like "% Daily Value per serving".
final List<RegExp> _servingHeaderPatterns = [
  RegExp(r'\bserving size\b', caseSensitive: false),
  RegExp(r'\bservings?\b', caseSensitive: false),
  RegExp(r'\bportion\b', caseSensitive: false),
  RegExp(r'\bpar portion\b', caseSensitive: false),
  RegExp(r'\bvaleur nutritive\b', caseSensitive: false),
  RegExp(r'^\s*per\b', caseSensitive: false),
  RegExp(r'\bper\s+\d', caseSensitive: false),
  RegExp(r'\bper\s+[a-zàâçéèêëîïôûùüÿñæœ]+', caseSensitive: false),
  RegExp(r'^\s*pour\b', caseSensitive: false),
  RegExp(r'\bpour\s+\d', caseSensitive: false),
  RegExp(r'\bpour\s+[a-zàâçéèêëîïôûùüÿñæœ]+', caseSensitive: false),
];

final List<RegExp> _caloriePatterns = [
  RegExp(r'\bcalories\b', caseSensitive: false),
  RegExp(r'\bcalorie\b', caseSensitive: false),
  // French labels sometimes use "Énergie" with kcal.
  RegExp(r'\b[ée]nergie\b', caseSensitive: false),
];

final List<RegExp> _fatPatterns = [
  RegExp(r'\btotal fat\b', caseSensitive: false),
  RegExp(r'\bfat\b', caseSensitive: false),
  RegExp(r'\blipides?\b', caseSensitive: false),
  RegExp(r'\bmati[èe]res?\s+grasses?\b', caseSensitive: false),
];

final List<RegExp> _carbsPatterns = [
  RegExp(r'\btotal carbohydrate[s]?\b', caseSensitive: false),
  RegExp(r'\bcarbohydrate[s]?\b', caseSensitive: false),
  RegExp(r'\btotal carb[s]?\b', caseSensitive: false),
  RegExp(r'\bcarb[s]?\b', caseSensitive: false),
  RegExp(r'\bglucides?\b', caseSensitive: false),
];

final List<RegExp> _fiberPatterns = [
  RegExp(r'\bdietary fib(?:re|er)\b', caseSensitive: false),
  RegExp(r'\bfib(?:re|er)s?\b', caseSensitive: false),
  RegExp(r'\bfibres?\s+alimentaires?\b', caseSensitive: false),
];

final List<RegExp> _sugarPatterns = [
  RegExp(r'\btotal sugars?\b', caseSensitive: false),
  RegExp(r'\bincludes?\b.*\bsugars?\b', caseSensitive: false),
  RegExp(r'\bsugars?\b', caseSensitive: false),
  RegExp(r'\bsucres?\b', caseSensitive: false),
];

final List<RegExp> _proteinPatterns = [
  RegExp(r'\bproteins?\b', caseSensitive: false),
  RegExp(r'\bprot[ée]ines?\b', caseSensitive: false),
];

final List<RegExp> _saturatedFatPatterns = [
  RegExp(r'\bsaturated fat\b', caseSensitive: false),
  RegExp(r'\bsaturated\b', caseSensitive: false),
  RegExp(r'\bsatur[ée]s?\b', caseSensitive: false),
];

final List<RegExp> _transFatPatterns = [
  RegExp(r'\btrans fat\b', caseSensitive: false),
  RegExp(r'\btrans\b', caseSensitive: false),
];

final List<RegExp> _cholesterolPatterns = [
  RegExp(r'\bcholesterol\b', caseSensitive: false),
  RegExp(r'\bcholest[ée]rol\b', caseSensitive: false),
];

final List<RegExp> _sodiumPatterns = [
  RegExp(r'\bsodium\b', caseSensitive: false),
];

final List<RegExp> _addedSugarsPatterns = [
  RegExp(r'\badded sugars?\b', caseSensitive: false),
  RegExp(r'\badded sugar\b', caseSensitive: false),
  RegExp(r'^\s*includes?\s.*\badded sugars?\b', caseSensitive: false),
];

final List<RegExp> _vitaminDPatterns = [
  RegExp(r'\bvitamin d\b', caseSensitive: false),
  RegExp(r'\bvitamine d\b', caseSensitive: false),
];

final List<RegExp> _calciumPatterns = [
  RegExp(r'\bcalcium\b', caseSensitive: false),
];

final List<RegExp> _ironPatterns = [
  RegExp(r'\biron\b', caseSensitive: false),
  RegExp(r'\bfer\b', caseSensitive: false),
];

final List<RegExp> _potassiumPatterns = [
  RegExp(r'\bpotassium\b', caseSensitive: false),
];

// ---------------------------------------------------------------------------
// Public API
// ---------------------------------------------------------------------------

NutritionParseResult parseNutritionLabel(RecognizedText text) {
  final lines = <OcrLine>[];
  for (final b in text.blocks) {
    for (final l in b.lines) {
      lines.add(OcrLine(text: l.text, box: l.boundingBox));
    }
  }
  return parseNutritionLabelFromLines(lines);
}

NutritionParseResult parseNutritionLabelFromLines(Iterable<OcrLine> lines) {
  final list = lines.toList(growable: false);

  ExtractedField<double>? calories;
  ExtractedField<double>? fat;
  ExtractedField<double>? saturatedFat;
  ExtractedField<double>? transFat;
  ExtractedField<double>? cholesterol;
  ExtractedField<double>? sodium;
  ExtractedField<double>? carbs;
  ExtractedField<double>? sugar;
  ExtractedField<double>? addedSugars;
  ExtractedField<double>? fiber;
  ExtractedField<double>? protein;
  ExtractedField<double>? vitaminD;
  ExtractedField<double>? calcium;
  ExtractedField<double>? iron;
  ExtractedField<double>? potassium;

  double? servingSize;
  ServingUnit? servingUnit;
  Rect? servingBox;

  for (var i = 0; i < list.length; i++) {
    final line = list[i];
    final raw = line.text;
    final box = line.box;

    // Serving size: keyword + (g | mL) measurement on this or one of the
    // next two lines (covers vertical "Serving size\n1 cup (30 g)" layouts).
    if (servingSize == null && _matchesAny(raw, _servingHeaderPatterns)) {
      var m = _extractServingMeasurement(raw);
      if (m == null) {
        for (var j = 1; j <= 2 && (i + j) < list.length; j++) {
          m = _extractServingMeasurement(list[i + j].text);
          if (m != null) break;
        }
      }
      if (m != null) {
        servingSize = m.value;
        servingUnit = m.unit;
        servingBox = box;
        continue;
      }
    }

    // Calories: number is dimensionless; allow the value to live on the
    // next line for vertical layouts.
    if (calories == null && _matchesAny(raw, _caloriePatterns)) {
      var n = _firstNumber(raw);
      if (n == null && i + 1 < list.length) {
        n = _firstNumber(list[i + 1].text);
      }
      if (n != null) {
        calories = ExtractedField(value: n, box: box);
        continue;
      }
    }

    // Saturated Fat (checked before general fat so "Saturated Fat" is not consumed as general "Fat")
    if (saturatedFat == null && _matchesAny(raw, _saturatedFatPatterns)) {
      final n = _firstGramQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        saturatedFat = ExtractedField(value: n, box: box);
        continue;
      }
    }

    // Trans Fat (checked before general fat)
    if (transFat == null && _matchesAny(raw, _transFatPatterns)) {
      final n = _firstGramQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        transFat = ExtractedField(value: n, box: box);
        continue;
      }
    }

    // Macros: prefer the gram-anchored number (skips "% Daily Value" digits
    // and other companions); fall back to the first bare number if needed.
    if (fat == null && _matchesAny(raw, _fatPatterns)) {
      final n = _firstGramQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        fat = ExtractedField(value: n, box: box);
        continue;
      }
    }

    if (cholesterol == null && _matchesAny(raw, _cholesterolPatterns)) {
      final n = _firstMgQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        cholesterol = ExtractedField(value: n, box: box);
        continue;
      }
    }

    if (sodium == null && _matchesAny(raw, _sodiumPatterns)) {
      final n = _firstMgQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        sodium = ExtractedField(value: n, box: box);
        continue;
      }
    }

    // Added Sugars (checked before total sugars/carbs)
    if (addedSugars == null && _matchesAny(raw, _addedSugarsPatterns)) {
      final n = _firstGramQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        addedSugars = ExtractedField(value: n, box: box);
        continue;
      }
    }

    if (carbs == null && _matchesAny(raw, _carbsPatterns)) {
      final n = _firstGramQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        carbs = ExtractedField(value: n, box: box);
        continue;
      }
    }

    // Fiber checked before sugar so combined lines like "Fibres / Sucres"
    // (rare) don't get over-eagerly assigned to sugar.
    if (fiber == null && _matchesAny(raw, _fiberPatterns)) {
      final n = _firstGramQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        fiber = ExtractedField(value: n, box: box);
        continue;
      }
    }

    if (sugar == null && _matchesAny(raw, _sugarPatterns)) {
      final n = _firstGramQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        sugar = ExtractedField(value: n, box: box);
        continue;
      }
    }

    if (protein == null && _matchesAny(raw, _proteinPatterns)) {
      final n = _firstGramQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        protein = ExtractedField(value: n, box: box);
        continue;
      }
    }

    if (vitaminD == null && _matchesAny(raw, _vitaminDPatterns)) {
      final n = _firstMcgQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        vitaminD = ExtractedField(value: n, box: box);
        continue;
      }
    }

    if (calcium == null && _matchesAny(raw, _calciumPatterns)) {
      final n = _firstMgQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        calcium = ExtractedField(value: n, box: box);
        continue;
      }
    }

    if (iron == null && _matchesAny(raw, _ironPatterns)) {
      final n = _firstMgQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        iron = ExtractedField(value: n, box: box);
        continue;
      }
    }

    if (potassium == null && _matchesAny(raw, _potassiumPatterns)) {
      final n = _firstMgQuantity(raw) ?? _firstNumber(raw);
      if (n != null) {
        potassium = ExtractedField(value: n, box: box);
        continue;
      }
    }
  }

  // Last-resort: if no serving header matched but the OCR contains a stand-
  // alone "<n> g" or "<n> mL" line near the top, use it. Helps with very
  // tightly cropped labels where the header is cut off.
  if (servingSize == null) {
    for (var i = 0; i < list.length && i < 6; i++) {
      final ml = _firstMlQuantity(list[i].text);
      if (ml != null) {
        servingSize = ml;
        servingUnit = ServingUnit.ml;
        servingBox = list[i].box;
        break;
      }
      final g = _firstGramQuantity(list[i].text);
      if (g != null) {
        servingSize = g;
        servingUnit = ServingUnit.g;
        servingBox = list[i].box;
        break;
      }
    }
  }

  final fields = <NutritionField, ExtractedField<double>>{};
  if (calories != null) fields[NutritionField.calories] = calories;
  if (fat != null) fields[NutritionField.totalFat] = fat;
  if (saturatedFat != null) fields[NutritionField.saturatedFat] = saturatedFat;
  if (transFat != null) fields[NutritionField.transFat] = transFat;
  if (cholesterol != null) fields[NutritionField.cholesterol] = cholesterol;
  if (sodium != null) fields[NutritionField.sodium] = sodium;
  if (carbs != null) fields[NutritionField.totalCarbs] = carbs;
  if (sugar != null) fields[NutritionField.sugar] = sugar;
  if (addedSugars != null) fields[NutritionField.addedSugars] = addedSugars;
  if (fiber != null) fields[NutritionField.fiber] = fiber;
  if (protein != null) fields[NutritionField.protein] = protein;
  if (vitaminD != null) fields[NutritionField.vitaminD] = vitaminD;
  if (calcium != null) fields[NutritionField.calcium] = calcium;
  if (iron != null) fields[NutritionField.iron] = iron;
  if (potassium != null) fields[NutritionField.potassium] = potassium;
  if (servingSize != null && servingBox != null) {
    fields[NutritionField.servingSize] = ExtractedField(
      value: servingSize,
      box: servingBox,
    );
  }

  final extra = <NutrientKey, double>{};
  if (saturatedFat != null) extra[NutrientKey.saturatedFatG] = saturatedFat.value;
  if (transFat != null) extra[NutrientKey.transFatG] = transFat.value;
  if (cholesterol != null) extra[NutrientKey.cholesterolMg] = cholesterol.value;
  if (sodium != null) extra[NutrientKey.sodiumMg] = sodium.value;
  if (addedSugars != null) extra[NutrientKey.addedSugarsG] = addedSugars.value;
  if (vitaminD != null) extra[NutrientKey.vitaminD2D3Ug] = vitaminD.value;
  if (calcium != null) extra[NutrientKey.calciumMg] = calcium.value;
  if (iron != null) extra[NutrientKey.ironMg] = iron.value;
  if (potassium != null) extra[NutrientKey.potassiumMg] = potassium.value;

  return NutritionParseResult(
    draft: (
      servingSize: servingSize,
      servingUnit: servingUnit,
      calories: calories?.value,
      fatG: fat?.value,
      carbsG: carbs?.value,
      sugarG: sugar?.value,
      fiberG: fiber?.value,
      proteinG: protein?.value,
      extraNutrients: extra,
    ),
    fields: fields,
  );
}

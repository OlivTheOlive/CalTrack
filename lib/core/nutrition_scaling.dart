/// Scale per-100g nutrition values to a logged mass in grams.
ScaledNutrition scaleFromPer100g({
  required double grams,
  required double kcalPer100g,
  required double proteinPer100g,
  required double carbsPer100g,
  required double fatPer100g,
}) {
  final factor = grams / 100.0;
  return ScaledNutrition(
    kcal: kcalPer100g * factor,
    proteinG: proteinPer100g * factor,
    carbsG: carbsPer100g * factor,
    fatG: fatPer100g * factor,
  );
}

class ScaledNutrition {
  const ScaledNutrition({
    required this.kcal,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });

  final double kcal;
  final double proteinG;
  final double carbsG;
  final double fatG;
}

/// Scale a previously logged portion to a new mass (same food, linear scaling).
ScaledNutrition rescaleLoggedPortion({
  required double previousGrams,
  required double previousKcal,
  required double previousProteinG,
  required double previousCarbsG,
  required double previousFatG,
  required double newGrams,
}) {
  if (previousGrams <= 0) {
    return const ScaledNutrition(kcal: 0, proteinG: 0, carbsG: 0, fatG: 0);
  }
  final ratio = newGrams / previousGrams;
  return ScaledNutrition(
    kcal: previousKcal * ratio,
    proteinG: previousProteinG * ratio,
    carbsG: previousCarbsG * ratio,
    fatG: previousFatG * ratio,
  );
}

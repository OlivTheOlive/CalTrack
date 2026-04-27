// Goal reached when within tolerance of target for consecutive weigh-ins.

const double defaultGoalToleranceKg = 0.6;

bool isGoalReached({
  required double latestWeightKg,
  required double targetWeightKg,
  required List<double> recentWeightsKgNewestFirst,
  double toleranceKg = defaultGoalToleranceKg,
  int consecutiveLogs = 2,
}) {
  if (recentWeightsKgNewestFirst.length < consecutiveLogs) return false;
  final slice = recentWeightsKgNewestFirst.take(consecutiveLogs).toList();
  return slice.every((w) => (w - targetWeightKg).abs() <= toleranceKg);
}

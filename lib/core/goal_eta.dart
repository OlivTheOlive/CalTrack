/// Lightweight pure-math helpers for goal timeline predictions.
///
/// Two ETAs are computed independently:
///  * "static": uses the user's intended weekly pace from their goal.
///  * "trend": uses the actual recent average weekly weight change.
library;

class GoalEta {
  const GoalEta({
    required this.weeks,
    required this.eta,
    required this.weeklyKg,
  });

  /// Whole weeks from now until the goal is reached.
  final int weeks;

  /// Calendar date when the goal would be reached at this pace.
  final DateTime eta;

  /// Signed kg/week used to compute this ETA (negative = losing).
  final double weeklyKg;
}

const double _minMeaningfulPaceKg = 0.05;
const double _atGoalToleranceKg = 0.3;

/// Compute an ETA from a single weekly pace.
///
/// Returns null when:
///  - user is already within [_atGoalToleranceKg] of target
///  - the pace is too small to be meaningful, OR
///  - the pace points away from the goal (e.g. losing while goal is gain).
GoalEta? estimateGoalEta({
  required double currentWeightKg,
  required double targetWeightKg,
  required double weeklyKg,
  DateTime? now,
}) {
  final diff = targetWeightKg - currentWeightKg;
  if (diff.abs() <= _atGoalToleranceKg) return null;
  if (weeklyKg.abs() < _minMeaningfulPaceKg) return null;
  if (diff.sign != weeklyKg.sign) return null;

  final weeks = (diff / weeklyKg).abs();
  final n = now ?? DateTime.now();
  final eta = n.add(Duration(days: (weeks * 7).round()));
  return GoalEta(
    weeks: weeks.round(),
    eta: eta,
    weeklyKg: weeklyKg,
  );
}

/// Returns true when the user is essentially at goal weight already.
bool atGoalWeight({
  required double currentWeightKg,
  required double targetWeightKg,
}) {
  return (targetWeightKg - currentWeightKg).abs() <= _atGoalToleranceKg;
}

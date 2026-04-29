library;

/// Common parsing + validation helpers used across forms.
///
/// These return null on success, or a short human-friendly message when invalid.

String? validatePositiveDouble(
  String raw, {
  required String fieldLabel,
  double? min,
  double? max,
}) {
  final v = parseDouble(raw);
  if (v == null) return '$fieldLabel must be a number.';
  if (v <= 0) return '$fieldLabel must be greater than 0.';
  if (min != null && v < min) return '$fieldLabel must be at least $min.';
  if (max != null && v > max) return '$fieldLabel must be at most $max.';
  return null;
}

double? parseDouble(String raw) {
  final cleaned = raw.trim().replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

String? validateOptionalNote(String raw, {int maxLen = 140}) {
  final s = raw.trim();
  if (s.isEmpty) return null;
  if (s.length > maxLen) return 'Note must be $maxLen characters or fewer.';
  return null;
}

String trimOrNull(String raw) {
  final s = raw.trim();
  return s;
}


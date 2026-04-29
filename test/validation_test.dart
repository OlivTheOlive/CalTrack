import 'package:caltrack/core/validation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validation', () {
    test('parseDouble handles commas and trims', () {
      expect(parseDouble(' 12,5 '), 12.5);
      expect(parseDouble(''), isNull);
      expect(parseDouble('abc'), isNull);
    });

    test('validatePositiveDouble enforces numeric, >0 and bounds', () {
      expect(
        validatePositiveDouble('', fieldLabel: 'X'),
        'X must be a number.',
      );
      expect(
        validatePositiveDouble('0', fieldLabel: 'X'),
        'X must be greater than 0.',
      );
      expect(
        validatePositiveDouble('1', fieldLabel: 'X', min: 2),
        'X must be at least 2.0.',
      );
      expect(
        validatePositiveDouble('10', fieldLabel: 'X', max: 5),
        'X must be at most 5.0.',
      );
      expect(validatePositiveDouble('2.5', fieldLabel: 'X'), isNull);
    });

    test('validateOptionalNote allows empty and limits length', () {
      expect(validateOptionalNote('   '), isNull);
      expect(validateOptionalNote('ok', maxLen: 2), isNull);
      expect(validateOptionalNote('toolong', maxLen: 2), isNotNull);
    });
  });
}


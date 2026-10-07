// Validators: per-field violation paths + the B-6 asInt/asDouble matrix.

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/validation/validators.dart';

void main() {
  group('asInt (B-6 matrix)', () {
    test('accepts int', () => expect(asInt(3), 3));
    test('accepts integral double 0.0 -> 0', () => expect(asInt(0.0), 0));
    test('accepts 1e2 -> 100', () => expect(asInt(100.0), 100));
    test('rejects 1.5', () => expect(asInt(1.5), isNull));
    test('rejects "1"', () => expect(asInt('1'), isNull));
    test('rejects true', () => expect(asInt(true), isNull));
    test('rejects null', () => expect(asInt(null), isNull));
    test('rejects NaN', () => expect(asInt(double.nan), isNull));
    test('rejects Infinity', () => expect(asInt(double.infinity), isNull));
    test('rejects negative integral double correctly', () =>
        expect(asInt(-4.0), -4));
  });

  group('asDouble (B-6 matrix)', () {
    test('accepts int -> toDouble', () => expect(asDouble(3), 3.0));
    test('accepts double', () => expect(asDouble(2.5), 2.5));
    test('rejects "2.5"', () => expect(asDouble('2.5'), isNull));
    test('rejects null', () => expect(asDouble(null), isNull));
    test('rejects NaN', () => expect(asDouble(double.nan), isNull));
    test('rejects Infinity', () => expect(asDouble(double.infinity), isNull));
    test('rejects bool', () => expect(asDouble(false), isNull));
  });

  group('stripControlChars (AC-3)', () {
    test('strips Cc controls', () =>
        expect(stripControlChars('a\x00b\x1Fc'), 'abc'));
    test('strips DEL and C1', () =>
        expect(stripControlChars('a\x7Fb\x9Fc'), 'abc'));
    test('keeps bidi marks for RTL', () =>
        expect(stripControlChars('a\u200Eb'), 'a\u200Eb'));
    test('keeps normal text untouched', () =>
        expect(stripControlChars('Paris 75001'), 'Paris 75001'));
  });

  group('asCleanString', () {
    test('trims and returns valid', () =>
        expect(asCleanString('  Paris ', minLength: 1, maxLength: 200),
            'Paris'));
    test('too short -> null', () =>
        expect(asCleanString('', minLength: 1, maxLength: 200), isNull));
    test('too long -> null', () =>
        expect(asCleanString('abc', minLength: 1, maxLength: 2), isNull));
    test('non-string -> null', () =>
        expect(asCleanString(42, minLength: 1, maxLength: 200), isNull));
    test('control chars stripped before length check', () => expect(
        asCleanString('\x00ab', minLength: 2, maxLength: 200), 'ab'));
  });

  group('sanitizeQuery', () {
    test('collapses whitespace', () =>
        expect(sanitizeQuery('  new   york  '), 'new york'));
    test('strips control chars', () =>
        expect(sanitizeQuery('a\x00b'), 'ab'));
    test('caps at 100 chars', () =>
        expect(sanitizeQuery('x' * 150).length, 100));
  });

  group('escapeQueryEcho (FM-12)', () {
    test('caps at 50 chars', () =>
        expect(escapeQueryEcho('y' * 80).length, 50));
    test('strips control chars', () =>
        expect(escapeQueryEcho('a\x00b'), 'ab'));
  });

  group('sanitizeUri (R-2)', () {
    test('redacts the full query string', () {
      final Uri uri = Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41');
      final String out = sanitizeUri(uri);
      expect(out, isNot(contains('latitude')));
      expect(out, isNot(contains('52.52')));
      expect(out, contains('api.open-meteo.com'));
    });
    test('no query -> unchanged', () {
      final Uri uri = Uri.parse('https://example.com/path');
      expect(sanitizeUri(uri), uri.toString());
    });
  });

  group('scrubCoordinates (R-2)', () {
    test('scrubs lat/lon pairs', () {
      final String out = scrubCoordinates('at 52.5234,13.4100 failed');
      expect(out, isNot(contains('52.5234')));
    });
  });
}

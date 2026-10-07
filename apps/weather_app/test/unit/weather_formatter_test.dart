// WeatherFormatter: precision table, negative-zero, round-half-away,
// locale separators, compass, clock injection, tz provenance.

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/core/units/weather_formatter.dart';
import 'package:weather_app/core/utils/clock.dart';

WeatherFormatter _fmt({
  UnitSystem? units,
  Locale? locale,
  Clock? clock,
}) =>
    WeatherFormatter(
      units: units ?? UnitSystem.metric,
      locale: locale ?? const Locale('en', 'US'),
      clock: clock ?? FakeClock(DateTime.utc(2026, 10, 6, 12, 0)),
    );

void main() {
  group('precision table + round-half-away', () {
    test('temp 0 dp', () =>
        expect(_fmt().formatTemp(21.5).display, '22°'));
    test('temp -0.4 -> "0°" (negative-zero normalization)', () =>
        expect(_fmt().formatTemp(-0.4).display, '0°'));
    test('round-half-away: 21.5 °C -> 22°', () =>
        expect(_fmt().formatTemp(21.5).display, '22°'));
    test('°F: 21.5 °C -> 70.7 °F -> "71°"', () => expect(
        _fmt(units: UnitSystem.imperial).formatTemp(21.5).display, '71°'));
    test('null -> em dash + unavailable label', () {
      final FormattedValue v = _fmt().formatTemp(null);
      expect(v.display, '—');
      expect(v.semanticLabel, contains('unavailable'));
    });
    test('semantic label is words, not symbols', () {
      final FormattedValue v = _fmt().formatTemp(21.0);
      expect(v.display, '21°');
      expect(v.semanticLabel, '21 degrees Celsius');
    });
  });

  group('intl locale separators', () {
    test('de locale uses comma decimals', () {
      final WeatherFormatter f = _fmt(locale: const Locale('de', 'DE'));
      expect(f.formatPrecipitation(1.5).display, contains(','));
    });
    test('en locale uses point decimals', () {
      final WeatherFormatter f = _fmt(locale: const Locale('en', 'US'));
      expect(f.formatPrecipitation(1.5).display, contains('.'));
    });
  });

  group('16-point compass', () {
    test('cardinal + intercardinal', () {
      expect(WeatherFormatter.compassLabel(0), 'N');
      expect(WeatherFormatter.compassLabel(90), 'E');
      expect(WeatherFormatter.compassLabel(180), 'S');
      expect(WeatherFormatter.compassLabel(270), 'W');
      expect(WeatherFormatter.compassLabel(45), 'NE');
      expect(WeatherFormatter.compassLabel(22.5), 'NNE');
    });
    test('wraps 360 -> N', () =>
        expect(WeatherFormatter.compassLabel(360), 'N'));
    test('null -> "—"? degrades gracefully', () {
      expect(WeatherFormatter.compassLabel(null), isNotEmpty);
    });
    test('compass words for screen readers', () {
      expect(WeatherFormatter.compassWord('NNE'), contains('north'));
    });
  });

  group('clock injection: updatedAgoLabel', () {
    test('minutes', () {
      final WeatherFormatter f = _fmt(
          clock: FakeClock(DateTime.utc(2026, 10, 6, 12, 4)));
      expect(f.updatedAgoLabel(DateTime.utc(2026, 10, 6, 12, 0)), '4 min ago');
    });
    test('just now', () {
      final WeatherFormatter f =
          _fmt(clock: FakeClock(DateTime.utc(2026, 10, 6, 12, 0, 30)));
      expect(f.updatedAgoLabel(DateTime.utc(2026, 10, 6, 12, 0)), 'just now');
    });
  });

  group('location-timezone provenance', () {
    test('locationTimeLabel uses the location offset, not device tz', () {
      final WeatherFormatter f = _fmt(
          clock: FakeClock(DateTime.utc(2026, 10, 6, 12, 0)));
      // fetched 12:00 UTC, location at UTC+2 -> "14:00".
      expect(f.locationTimeLabel(DateTime.utc(2026, 10, 6, 12, 0),
          utcOffsetSeconds: 7200), '14:00');
    });
    test('null offset degrades to the device clock (flagged by the view)', () {
      final WeatherFormatter f = _fmt(
          clock: FakeClock(DateTime.utc(2026, 10, 6, 12, 0)));
      expect(
          f.locationTimeLabel(DateTime.utc(2026, 10, 6, 12, 0),
              utcOffsetSeconds: null),
          isNotEmpty);
    });
  });
}

// WeatherFormatter (R-11 / ADR-09 formatter spec): pure, injectable,
// unit-testable without widgets.
//
// Signature: (SI value, UnitSystem, Locale, Clock) -> FormattedValue.
// The domain/cache always holds SI; ALL conversion happens here at the
// presentation boundary (ADR-04).
//
// Spec:
//  * Per-quantity precision: temp 0 dp, feels-like 0 dp, wind/gusts 0 dp,
//    precip mm 1 dp / in 2 dp, pressure hPa 0 dp / inHg 2 dp,
//    humidity/cloud/probability/UV 0 dp.
//  * Round-half-away (explicit — never rely on toStringAsFixed's mode).
//  * Negative-zero normalization (-0.4 °C -> "0°", never "-0°").
//  * intl locale decimal separators (de-DE: "21,5"); unit symbols stay fixed.
//  * FormattedValue(display, semanticLabel): visual "21°" vs SR
//    "21 degrees Celsius" (design §6).
//  * 16-point compass; clock injection for "Updated X ago"; location-timezone
//    provenance (times shown in the LOCATION's tz, not the device's).

import 'dart:math' show pow;

import 'package:flutter/widgets.dart' show Locale;
import 'package:intl/intl.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/core/utils/clock.dart';

/// Display string + screen-reader string for one formatted value.
class FormattedValue {
  final String display;
  final String semanticLabel;

  const FormattedValue(this.display, this.semanticLabel);

  /// Null/missing input -> em dash, announced as unavailable (R-1 Tier 2).
  const FormattedValue.unavailable(String noun)
      : display = '—',
        semanticLabel = '$noun unavailable';
}

class WeatherFormatter {
  final UnitSystem units;
  final Locale locale;
  final Clock clock;

  late final String _localeTag = locale.toString();
  late final NumberFormat _intFmt = _make(0);
  late final NumberFormat _oneFmt = _make(1);
  late final NumberFormat _twoFmt = _make(2);

  WeatherFormatter({
    required this.units,
    required this.locale,
    required this.clock,
  });

  NumberFormat _make(int places) {
    final String pattern = switch (places) {
      0 => '#,##0',
      1 => '#,##0.0',
      _ => '#,##0.00',
    };
    return NumberFormat(pattern, _localeTag)
      ..minimumFractionDigits = places
      ..maximumFractionDigits = places;
  }

  NumberFormat _fmtFor(int places) =>
      places == 0 ? _intFmt : (places == 1 ? _oneFmt : _twoFmt);

  // --- rounding -----------------------------------------------------------

  /// Round-half-away to [places] decimals, with negative-zero normalization.
  /// Explicit so °F boundaries (e.g. 21.5 °C -> 71 °F... precisely 70.7 °F ->
  /// "71°F") are deterministic and locale-independent.
  static double roundHalfAway(double value, int places) {
    final double factor = pow(10, places).toDouble();
    final double shifted = value * factor;
    final double rounded =
        ((shifted.abs() + 0.5 + 1e-9).floorToDouble()) / factor;
    final double signed = shifted < 0 ? -rounded : rounded;
    return signed == 0 ? 0.0 : signed; // -0.0 -> 0.0
  }

  String _num(double value, int places) =>
      _fmtFor(places).format(roundHalfAway(value, places));

  // --- temperature ---------------------------------------------------------

  double _toDisplayTemp(double celsius) => units.temp == TempUnit.fahrenheit
      ? celsius * 9 / 5 + 32
      : celsius;

  String get _tempUnitWord =>
      units.temp == TempUnit.fahrenheit ? 'Fahrenheit' : 'Celsius';

  FormattedValue formatTemp(double? celsius) {
    if (celsius == null) return const FormattedValue.unavailable('Temperature');
    final String n = _num(_toDisplayTemp(celsius), 0);
    return FormattedValue('$n°', '$n degrees $_tempUnitWord');
  }

  FormattedValue formatFeelsLike(double? celsius) {
    if (celsius == null) {
      return const FormattedValue.unavailable('Feels like temperature');
    }
    final String n = _num(_toDisplayTemp(celsius), 0);
    return FormattedValue('$n°', 'Feels like $n degrees $_tempUnitWord');
  }

  // --- wind ----------------------------------------------------------------

  double _toDisplayWind(double kmh) => switch (units.wind) {
        WindUnit.kmh => kmh,
        WindUnit.mph => kmh * 0.621371,
        WindUnit.ms => kmh / 3.6,
      };

  String get _windUnitSymbol => switch (units.wind) {
        WindUnit.kmh => 'km/h',
        WindUnit.mph => 'mph',
        WindUnit.ms => 'm/s',
      };

  String get _windUnitWord => switch (units.wind) {
        WindUnit.kmh => 'kilometers per hour',
        WindUnit.mph => 'miles per hour',
        WindUnit.ms => 'meters per second',
      };

  FormattedValue formatWindSpeed(double? kmh) {
    if (kmh == null) return const FormattedValue.unavailable('Wind speed');
    final String n = _num(_toDisplayWind(kmh), 0);
    return FormattedValue('$n $_windUnitSymbol', '$n $_windUnitWord');
  }

  /// 16-point compass label (pure; unit-tested).
  static String compassLabel(double? degrees) {
    if (degrees == null) return '—';
    const List<String> points = <String>[
      'N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE',
      'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW',
    ];
    final int index = ((degrees % 360) / 22.5).round() % 16;
    return points[index];
  }

  static String compassWord(String label) => switch (label) {
        'N' => 'north',
        'NNE' => 'north-northeast',
        'NE' => 'northeast',
        'ENE' => 'east-northeast',
        'E' => 'east',
        'ESE' => 'east-southeast',
        'SE' => 'southeast',
        'SSE' => 'south-southeast',
        'S' => 'south',
        'SSW' => 'south-southwest',
        'SW' => 'southwest',
        'WSW' => 'west-southwest',
        'W' => 'west',
        'WNW' => 'west-northwest',
        'NW' => 'northwest',
        'NNW' => 'north-northwest',
        _ => 'unknown direction',
      };

  // --- precipitation -------------------------------------------------------

  FormattedValue formatPrecipitation(double? mm) {
    if (mm == null) return const FormattedValue.unavailable('Precipitation');
    if (units.temp == TempUnit.fahrenheit) {
      final String n = _num(mm / 25.4, 2);
      return FormattedValue('$n in', '$n inches');
    }
    final String n = _num(mm, 1);
    return FormattedValue('$n mm', '$n millimeters');
  }

  // --- pressure ------------------------------------------------------------

  FormattedValue formatPressure(double? hpa) {
    if (hpa == null) return const FormattedValue.unavailable('Pressure');
    if (units.pressure == PressureUnit.inhg) {
      final String n = _num(hpa * 0.02953, 2);
      return FormattedValue('$n inHg', '$n inches of mercury');
    }
    final String n = _num(hpa, 0);
    return FormattedValue('$n hPa', '$n hectopascals');
  }

  // --- percentages / UV ----------------------------------------------------

  FormattedValue formatPercent(double? value, String noun) {
    if (value == null) return FormattedValue.unavailable(noun);
    final String n = _num(value, 0);
    return FormattedValue('$n%', '$n percent $noun');
  }

  FormattedValue formatUvIndex(double? value) {
    if (value == null) return const FormattedValue.unavailable('UV index');
    final String n = _num(value, 0);
    return FormattedValue(n, 'UV index $n');
  }

  // --- time ----------------------------------------------------------------

  /// "just now" | "N min ago" | "N h ago" (clock-injected; future clamped
  /// to zero per the clock-skew rule, C-10.8).
  String updatedAgoLabel(DateTime fetchedAtUtc) {
    final Duration age = clock.now().toUtc().difference(fetchedAtUtc);
    final Duration clamped = age.isNegative ? Duration.zero : age;
    if (clamped.inSeconds < 60) return 'just now';
    if (clamped.inMinutes < 60) return '${clamped.inMinutes} min ago';
    return '${clamped.inHours} h ago';
  }

  /// Location-local "HH:mm" for the provenance strip / "updated 12:04".
  /// [utcOffsetSeconds] is the API's validated offset; when null the caller
  /// passes the device offset and sets [deviceTimezoneFallback] so the UI
  /// can label it (PRD FM-14: "Times shown in device timezone").
  String locationTimeLabel(
    DateTime utc, {
    required int? utcOffsetSeconds,
  }) {
    final DateTime local = utcOffsetSeconds == null
        ? utc.toLocal()
        : utc.add(Duration(seconds: utcOffsetSeconds));
    return DateFormat.Hm(_localeTag).format(local);
  }

  /// "14:00" / "2 PM" per device locale (arch §8: 12 h follows locale).
  /// Open-Meteo returns local ISO strings (e.g. "2026-10-06T14:00") when
  /// timezone=auto; they are parsed as wall-clock, not converted.
  String hourLabel(String isoLocal) {
    try {
      final DateTime dt = DateTime.parse(isoLocal);
      return DateFormat.jm(_localeTag).format(dt);
    } on FormatException {
      return '—';
    }
  }

  /// "Tue" + "Oct 6" for the daily list.
  ({String weekday, String date}) dayLabels(DateTime date) {
    return (
      weekday: DateFormat.E(_localeTag).format(date),
      date: DateFormat.MMMd(_localeTag).format(date),
    );
  }
}

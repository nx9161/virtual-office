// UnitSystem: independent axes (R-11 / ADR-09 amendment).
//
// Temperature, wind, and pressure are independent preferences — this data
// model is decision-proof regardless of which Settings UX ships (all-or-
// nothing °F preset vs. the design spec's segmented controls).
//
// Rules:
//  * Temperature preset drives pressure: °F -> inHg, °C -> hPa (R-11).
//  * Wind is fully independent (km/h | mph | m/s).
//  * °F default follows device locale: US/LR/MM -> imperial, else metric.
//  * Serialized as a compact string for SharedPreferences.
//
// NOTE: domain stays pure Dart (no dart:ui / flutter imports — the
// domain_stays_pure lint) — so the locale entry point takes a country code
// string, not a Locale.

enum TempUnit { celsius, fahrenheit }

enum WindUnit { kmh, mph, ms }

enum PressureUnit { hpa, inhg }

class UnitSystem {
  final TempUnit temp;
  final WindUnit wind;
  final PressureUnit pressure;

  const UnitSystem({
    required this.temp,
    required this.wind,
    required this.pressure,
  });

  static const UnitSystem metric = UnitSystem(
    temp: TempUnit.celsius,
    wind: WindUnit.kmh,
    pressure: PressureUnit.hpa,
  );

  static const UnitSystem imperial = UnitSystem(
    temp: TempUnit.fahrenheit,
    wind: WindUnit.mph,
    pressure: PressureUnit.inhg,
  );

  /// Device-locale default (R-11): US/Liberia/Myanmar -> imperial, else
  /// metric. Takes the ISO country code (not a Locale) so domain stays
  /// pure Dart — callers pass `PlatformDispatcher.instance.locale.countryCode`.
  factory UnitSystem.fromLocaleCode(String? countryCode) {
    final String cc = (countryCode ?? '').toUpperCase();
    if (cc == 'US' || cc == 'LR' || cc == 'MM') return UnitSystem.imperial;
    return UnitSystem.metric;
  }

  /// Temperature change carries the pressure preset with it (R-11).
  UnitSystem withTemperature(TempUnit temp) => UnitSystem(
        temp: temp,
        wind: wind,
        pressure:
            temp == TempUnit.fahrenheit ? PressureUnit.inhg : PressureUnit.hpa,
      );

  UnitSystem withWind(WindUnit wind) =>
      UnitSystem(temp: temp, wind: wind, pressure: pressure);

  /// 'celsius|kmh|hpa' — compact prefs serialization.
  String serialize() => '${temp.name}|${wind.name}|${pressure.name}';

  static UnitSystem deserialize(String raw) {
    final List<String> parts = raw.split('|');
    if (parts.length != 3) return UnitSystem.metric;
    TempUnit temp = TempUnit.celsius;
    WindUnit wind = WindUnit.kmh;
    PressureUnit pressure = PressureUnit.hpa;
    for (final TempUnit t in TempUnit.values) {
      if (t.name == parts[0]) temp = t;
    }
    for (final WindUnit w in WindUnit.values) {
      if (w.name == parts[1]) wind = w;
    }
    for (final PressureUnit p in PressureUnit.values) {
      if (p.name == parts[2]) pressure = p;
    }
    return UnitSystem(temp: temp, wind: wind, pressure: pressure);
  }

  @override
  bool operator ==(Object other) =>
      other is UnitSystem &&
      other.temp == temp &&
      other.wind == wind &&
      other.pressure == pressure;

  @override
  int get hashCode => Object.hash(temp, wind, pressure);

  @override
  String toString() => 'UnitSystem(${serialize()})';
}

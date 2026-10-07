// UnitSystem: independent axes (R-11), locale default, serialization.

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/units/unit_system.dart';

void main() {
  test('independent axes: wind can be mph while temp stays °C', () {
    const UnitSystem u = UnitSystem(
        temp: TempUnit.celsius, wind: WindUnit.mph, pressure: PressureUnit.hpa);
    expect(u.temp, TempUnit.celsius);
    expect(u.wind, WindUnit.mph);
    expect(u.pressure, PressureUnit.hpa);
  });

  test('US locale -> imperial default', () {
    expect(UnitSystem.fromLocaleCode('US'), UnitSystem.imperial);
  });

  test('LR and MM -> imperial default', () {
    expect(UnitSystem.fromLocaleCode('LR'), UnitSystem.imperial);
    expect(UnitSystem.fromLocaleCode('MM'), UnitSystem.imperial);
  });

  test('DE locale -> metric default', () {
    expect(UnitSystem.fromLocaleCode('DE'), UnitSystem.metric);
  });

  test('null country code -> metric default', () {
    expect(UnitSystem.fromLocaleCode(null), UnitSystem.metric);
  });

  test('temperature switch carries the pressure preset (R-11)', () {
    final UnitSystem f =
        UnitSystem.metric.withTemperature(TempUnit.fahrenheit);
    expect(f.pressure, PressureUnit.inhg);
    final UnitSystem c = f.withTemperature(TempUnit.celsius);
    expect(c.pressure, PressureUnit.hpa);
  });

  test('wind switch preserves the other axes', () {
    final UnitSystem u = UnitSystem.metric.withWind(WindUnit.ms);
    expect(u.temp, TempUnit.celsius);
    expect(u.wind, WindUnit.ms);
  });

  test('serialize/deserialize round-trip', () {
    const UnitSystem u = UnitSystem(
        temp: TempUnit.fahrenheit,
        wind: WindUnit.ms,
        pressure: PressureUnit.inhg);
    expect(UnitSystem.deserialize(u.serialize()), u);
  });
}

// ForecastDto: two-tier validation (R-1) against the PRD §7.2 tables.
// Uses the recorded fixtures (test/contract/contract_test.dart pins the
// same files against live shapes weekly via tool/regen_fixtures.dart).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/data/models/forecast_dto.dart';
import 'package:weather_app/domain/entities/forecast.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

Object _fixture(String name) => jsonDecode(
      File('test/fixtures/$name').readAsStringSync(),
    );

GeoPlace _place() => GeoPlace(
      name: 'Berlin',
      admin1: null,
      country: 'Germany',
      countryCode: 'DE',
      lat: 52.52,
      lon: 13.41,
    );

void main() {
  test('valid fixture parses (Tier-1 + Tier-2)', () {
    final Forecast f = ForecastDto.parse(
      json: _fixture('forecast_valid.json'),
      place: _place(),
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
    );
    expect(f.current.temperatureC, 21.3);
    expect(f.current.weatherCode, 1);
    expect(f.hourly, hasLength(2));
    expect(f.daily, hasLength(2));
    expect(f.utcOffsetSeconds, 7200);
    expect(f.timezone, 'Europe/Berlin');
    // Echo stripped: the entity carries no lat/lon echo (B-1).
    expect(ForecastDto.encode(f), isNot(contains('latitude')));
  });

  test('malformed Tier-1 (bad temp type, empty arrays) -> schemaViolation',
      () {
    expect(
      () => ForecastDto.parse(
        json: _fixture('forecast_malformed.json'),
        place: _place(),
        fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
      ),
      throwsA(isA<SchemaViolationFailure>()),
    );
  });

  test('empty Tier-1 array -> schemaViolation (B-6)', () {
    final Map<String, Object?> root =
        (_fixture('forecast_valid.json') as Map).cast<String, Object?>();
    (root['hourly'] as Map)['temperature_2m'] = <Object?>[];
    expect(
      () => ForecastDto.parse(
        json: root,
        place: _place(),
        fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
      ),
      throwsA(isA<SchemaViolationFailure>()),
    );
  });

  test('Tier-2 violations degrade to null (never throw)', () {
    final Map<String, Object?> root =
        (_fixture('forecast_valid.json') as Map).cast<String, Object?>();
    // Out-of-range pressure (PRD §7.2: 800–1100 hPa).
    (root['current'] as Map)['pressure_msl'] = 2000;
    final Forecast f = ForecastDto.parse(
      json: root,
      place: _place(),
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
    );
    expect(f.current.pressureHpa, isNull);
    expect(f.current.temperatureC, 21.3); // the rest survives
  });

  test('unknown keys are ignored + reported via onDrift (B-4)', () {
    final Map<String, Object?> root =
        (_fixture('forecast_valid.json') as Map).cast<String, Object?>();
    (root['current'] as Map)['brand_new_field'] = 42;
    final List<String> drifted = <String>[];
    final Forecast f = ForecastDto.parse(
      json: root,
      place: _place(),
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
      onDrift: drifted.add,
    );
    expect(f.current.temperatureC, 21.3);
    expect(drifted, isNotEmpty);
  });

  test('lat/lon echo out of range -> schemaViolation (LOW-1/B-1)', () {
    final Map<String, Object?> root =
        (_fixture('forecast_valid.json') as Map).cast<String, Object?>();
    root['latitude'] = 99.99; // outside [-90, 90]: forged echo
    expect(
      () => ForecastDto.parse(
        json: root,
        place: _place(),
        fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
      ),
      throwsA(isA<SchemaViolationFailure>()),
    );
  });

  test('root not an object -> schemaViolation', () {
    expect(
      () => ForecastDto.parse(
        json: <Object?>[],
        place: _place(),
        fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
      ),
      throwsA(isA<SchemaViolationFailure>()),
    );
  });

  test('encode/decode round-trip', () {
    final Forecast f = ForecastDto.parse(
      json: _fixture('forecast_valid.json'),
      place: _place(),
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
    );
    final Forecast back = ForecastDto.decode(ForecastDto.encode(f));
    expect(back.current.temperatureC, f.current.temperatureC);
    expect(back.hourly.length, f.hourly.length);
    expect(back.daily.length, f.daily.length);
  });

  test('B-6 counter-example: unequal arrays + bad times -> schemaViolation, '
      'not RangeError', () {
    final Map<String, Object?> root =
        (_fixture('forecast_valid.json') as Map).cast<String, Object?>();
    // time has 3 entries (2 unparseable) while temperature_2m has 1:
    // the old filter-then-index pattern computed src=2 on a length-1
    // array -> RangeError. Equalize-first must fail closed instead.
    (root['hourly'] as Map)['time'] = <Object?>[
      'not-a-time',
      'also-not-a-time',
      '2026-10-06T14:00',
    ];
    (root['hourly'] as Map)['temperature_2m'] = <Object?>[21.0];
    (root['hourly'] as Map)['precipitation_probability'] = <Object?>[10];
    (root['hourly'] as Map)['weather_code'] = <Object?>[1];
    expect(
      () => ForecastDto.parse(
        json: root,
        place: _place(),
        fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
      ),
      throwsA(isA<SchemaViolationFailure>()),
    );
  });

  test('B-6 counter-example (daily): unequal arrays + bad times -> '
      'schemaViolation, not RangeError', () {
    final Map<String, Object?> root =
        (_fixture('forecast_valid.json') as Map).cast<String, Object?>();
    (root['daily'] as Map)['time'] = <Object?>[
      'not-a-date',
      'also-not-a-date',
      '2026-10-07',
    ];
    (root['daily'] as Map)['temperature_2m_max'] = <Object?>[22.0];
    (root['daily'] as Map)['temperature_2m_min'] = <Object?>[15.0];
    (root['daily'] as Map)['weather_code'] = <Object?>[1];
    (root['daily'] as Map)['sunrise'] = <Object?>['2026-10-07T07:00'];
    (root['daily'] as Map)['sunset'] = <Object?>['2026-10-07T18:30'];
    (root['daily'] as Map)['uv_index_max'] = <Object?>[3.0];
    (root['daily'] as Map)['precipitation_probability_max'] =
        <Object?>[20];
    expect(
      () => ForecastDto.parse(
        json: root,
        place: _place(),
        fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
      ),
      throwsA(isA<SchemaViolationFailure>()),
    );
  });

  test('B-6: equalize-first keeps in-range rows (no throw, rows survive)', () {
    final Map<String, Object?> root =
        (_fixture('forecast_valid.json') as Map).cast<String, Object?>();
    // 3 times but 2 temps -> truncate to 2 first, then drop the bad time.
    (root['hourly'] as Map)['time'] = <Object?>[
      '2026-10-06T12:00',
      'bad-time',
      '2026-10-06T14:00',
    ];
    (root['hourly'] as Map)['temperature_2m'] = <Object?>[20.0, 21.0];
    (root['hourly'] as Map)['precipitation_probability'] =
        <Object?>[10, 20];
    (root['hourly'] as Map)['weather_code'] = <Object?>[1, 2];
    final Forecast f = ForecastDto.parse(
      json: root,
      place: _place(),
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
    );
    expect(f.hourly, hasLength(1));
    expect(f.hourly[0].temperatureC, 20.0);
  });

  // B1: the DTO keeps up to 48 raw hourly entries (the API day-0 array
  // starts at 00:00); the view-mapping layer slices 24 from the current
  // local hour and raises the FM-17 note when fewer remain.
  test('B1: hourly parses up to 48 entries (was capped at 24)', () {
    final Map<String, Object?> root =
        (_fixture('forecast_valid.json') as Map).cast<String, Object?>();
    final Map<dynamic, dynamic> hourly = root['hourly'] as Map;
    final List<Object?> times =
        List<Object?>.from(hourly['time'] as List); // starts at 12:00
    final List<Object?> temps =
        List<Object?>.from(hourly['temperature_2m'] as List);
    final List<Object?> probs =
        List<Object?>.from(hourly['precipitation_probability'] as List);
    final List<Object?> codes =
        List<Object?>.from(hourly['weather_code'] as List);
    for (int i = times.length; i < 48; i++) {
      final int day = 6 + i ~/ 24;
      final int hour = i % 24;
      times.add('2026-10-${day.toString().padLeft(2, '0')}'
          'T${hour.toString().padLeft(2, '0')}:00');
      temps.add(20.0);
      probs.add(10);
      codes.add(1);
    }
    hourly['time'] = times;
    hourly['temperature_2m'] = temps;
    hourly['precipitation_probability'] = probs;
    hourly['weather_code'] = codes;
    final Forecast f = ForecastDto.parse(
      json: root,
      place: _place(),
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
    );
    expect(f.hourly, hasLength(48));
    expect(f.hourly.first.time, DateTime(2026, 10, 6, 12, 0));
    expect(f.hourly.last.time, DateTime(2026, 10, 7, 23, 0));
  });

  test('B1: hourly beyond 48 entries is still capped (49 -> 48)', () {
    final Map<String, Object?> root =
        (_fixture('forecast_valid.json') as Map).cast<String, Object?>();
    final Map<dynamic, dynamic> hourly = root['hourly'] as Map;
    final List<Object?> times =
        List<Object?>.from(hourly['time'] as List);
    final List<Object?> temps =
        List<Object?>.from(hourly['temperature_2m'] as List);
    final List<Object?> probs =
        List<Object?>.from(hourly['precipitation_probability'] as List);
    final List<Object?> codes =
        List<Object?>.from(hourly['weather_code'] as List);
    for (int i = times.length; i < 50; i++) {
      final int day = 6 + i ~/ 24;
      final int hour = i % 24;
      times.add('2026-10-${day.toString().padLeft(2, '0')}'
          'T${hour.toString().padLeft(2, '0')}:00');
      temps.add(20.0);
      probs.add(10);
      codes.add(1);
    }
    hourly['time'] = times;
    hourly['temperature_2m'] = temps;
    hourly['precipitation_probability'] = probs;
    hourly['weather_code'] = codes;
    final Forecast f = ForecastDto.parse(
      json: root,
      place: _place(),
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
    );
    expect(f.hourly, hasLength(48));
  });
}

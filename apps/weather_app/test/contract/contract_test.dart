// Contract test: pins the parsers against RECORDED fixtures.
//
// The fixtures are regenerated weekly from the live API by
// tool/regen_fixtures.dart (B-4). If the API shape drifts, this test fails
// loudly instead of the app silently degrading — the onDrift breadcrumb
// covers unknown keys at runtime; this covers structural breaks.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/data/models/bigdatacloud_dto.dart';
import 'package:weather_app/data/models/forecast_dto.dart';
import 'package:weather_app/data/models/geocoding_dto.dart';
import 'package:weather_app/domain/entities/forecast.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

dynamic _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync());

void main() {
  group('forecast contract', () {
    test('recorded shape still parses', () {
      final Forecast f = ForecastDto.parse(
        json: _fixture('forecast_valid.json'),
        place: GeoPlace(
            name: 'Berlin',
            admin1: null,
            country: 'Germany',
            countryCode: 'DE',
            lat: 52.52,
            lon: 13.41),
        fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
      );
      expect(f.current.temperatureC, isNotNull);
      expect(f.hourly, isNotEmpty);
      expect(f.daily, isNotEmpty);
      expect(f.utcOffsetSeconds, isNotNull);
    });

    test('required top-level keys present', () {
      final Map<String, dynamic> root =
          _fixture('forecast_valid.json') as Map<String, dynamic>;
      for (final String k in <String>[
        'current',
        'hourly',
        'daily',
        'utc_offset_seconds',
        'timezone'
      ]) {
        expect(root, contains(k), reason: 'missing top-level key $k');
      }
    });
  });

  group('geocoding contract', () {
    test('recorded shape still parses', () {
      final List<GeoPlace> places =
          GeocodingDto.parse(_fixture('geocoding_valid.json'));
      expect(places, isNotEmpty);
      expect(places.first.name, isNotEmpty);
    });

    test('empty results shape still parses', () {
      expect(GeocodingDto.parse(_fixture('geocoding_empty.json')), isEmpty);
    });
  });

  group('bigdatacloud contract', () {
    test('recorded shape still parses', () {
      final GeoPlace p = BigDataCloudDto.parse(
        json: _fixture('bigdatacloud_valid.json'),
        lat: 52.52,
        lon: 13.41,
      );
      expect(p.name, isNotEmpty);
      expect(p.countryCode, hasLength(2));
    });
  });
}

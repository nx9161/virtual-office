// GeocodingDto + BigDataCloudDto: PRD §7.3 two-tier validation.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/data/models/bigdatacloud_dto.dart';
import 'package:weather_app/data/models/geocoding_dto.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

dynamic _fixture(String name) =>
    jsonDecode(File('test/fixtures/$name').readAsStringSync());

void main() {
  group('GeocodingDto', () {
    test('valid fixture -> places', () {
      final List<GeoPlace> places =
          GeocodingDto.parse(_fixture('geocoding_valid.json'));
      expect(places, hasLength(2));
      expect(places.first.name, 'Berlin');
      expect(places.first.countryCode, 'DE');
      expect(places.first.lat, 52.52); // 2-dp rounded at construction
    });

    test('empty results -> empty list (not an error)', () {
      expect(GeocodingDto.parse(_fixture('geocoding_empty.json')), isEmpty);
    });

    test('missing results key -> empty list', () {
      expect(GeocodingDto.parse(<String, Object?>{}), isEmpty);
    });

    test('results not an array -> schemaViolation', () {
      expect(
        () => GeocodingDto.parse(
            <String, Object?>{'results': <String, Object?>{}}),
        throwsA(isA<SchemaViolationFailure>()),
      );
    });

    test('entry with bad name is dropped, rest survive (R-1)', () {
      final List<GeoPlace> places = GeocodingDto.parse(<String, Object?>{
        'results': <Object?>[
          <String, Object?>{
            'id': 1,
            'name': 'Ok City',
            'country': 'X',
            'latitude': 1.0,
            'longitude': 2.0
          },
          <String, Object?>{
            'id': 2,
            'name': '', // violates 1…200
            'country': 'X',
            'latitude': 1.0,
            'longitude': 2.0
          },
        ],
      });
      expect(places, hasLength(1));
      expect(places.first.name, 'Ok City');
    });

    test('root not an object -> schemaViolation', () {
      expect(() => GeocodingDto.parse(<Object?>[]),
          throwsA(isA<SchemaViolationFailure>()));
    });
  });

  group('BigDataCloudDto (B-3 whitelist)', () {
    test('valid fixture -> place (city preferred)', () {
      final GeoPlace p = BigDataCloudDto.parse(
        json: _fixture('bigdatacloud_valid.json'),
        lat: 52.52,
        lon: 13.41,
      );
      expect(p.name, 'Berlin');
      expect(p.countryCode, 'DE');
      expect(p.admin1, 'Berlin');
      expect(p.lat, 52.52);
    });

    test('locality fallback when city missing', () {
      final GeoPlace p = BigDataCloudDto.parse(
        json: <String, Object?>{
          'locality': 'Mitte',
          'countryName': 'Germany',
          'countryCode': 'DE'
        },
        lat: 52.52,
        lon: 13.41,
      );
      expect(p.name, 'Mitte');
    });

    test('unknown extra keys ignored', () {
      final GeoPlace p = BigDataCloudDto.parse(
        json: <String, Object?>{
          'city': 'Berlin',
          'countryCode': 'DE',
          'someNewField': <String, Object?>{'nested': true},
        },
        lat: 52.52,
        lon: 13.41,
      );
      expect(p.name, 'Berlin');
    });

    test('missing city -> schemaViolation', () {
      expect(
        () => BigDataCloudDto.parse(
          json: <String, Object?>{'countryCode': 'DE'},
          lat: 52.52,
          lon: 13.41,
        ),
        throwsA(isA<SchemaViolationFailure>()),
      );
    });

    test('bad countryCode length -> schemaViolation', () {
      expect(
        () => BigDataCloudDto.parse(
          json: <String, Object?>{
            'city': 'Berlin',
            'countryCode': 'DEU'
          },
          lat: 52.52,
          lon: 13.41,
        ),
        throwsA(isA<SchemaViolationFailure>()),
      );
    });
  });
}

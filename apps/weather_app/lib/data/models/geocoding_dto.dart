// GeocodingDto: PRD §7.3 whitelist, implemented literally.
//
// Per-entry degradation (never whole-list failure):
//  * id: integer >= 0, else drop entry
//  * name: 1…200 chars (PRD wins per R-3), else drop entry
//  * latitude/longitude: ranges, else drop entry
//  * country: 1…100 chars, else default "—"
//  * admin1: ≤100 chars optional, else omit
//  * country_code: exactly 2 chars optional, else omit
// `results` absent/empty -> empty list (US-2 AC3 empty state).
// Non-JSON/unparseable body or non-list `results` -> schemaViolation,
// which the search flow presents as FM-4 ("Search isn't working right now").

import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/logging/app_logger.dart';
import 'package:weather_app/core/validation/validators.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

abstract final class GeocodingDto {
  /// Parses a decoded JSON body into validated places.
  /// Throws AppFailure.schemaViolation on Tier-1 structural problems.
  static List<GeoPlace> parse(Object? json) {
    if (json is! Map) {
      throw const AppFailure.schemaViolation('results', 'root-not-object');
    }
    final Map<dynamic, dynamic> root = json;
    final Object? resultsRaw = root['results'];
    if (resultsRaw == null) return <GeoPlace>[];
    if (resultsRaw is! List) {
      AppLogger.validationFailure(
          field: 'results', reason: 'expected-array', valueType: 'object');
      throw const AppFailure.schemaViolation('results', 'expected-array');
    }
    final List<GeoPlace> places = <GeoPlace>[];
    for (int i = 0; i < resultsRaw.length; i++) {
      final GeoPlace? place = _parseEntry(resultsRaw[i], i);
      if (place != null) places.add(place);
    }
    return places;
  }

  static GeoPlace? _parseEntry(Object? raw, int index) {
    final String field = 'results[$index]';
    if (raw is! Map) {
      AppLogger.validationFailure(
          field: field, reason: 'entry-not-object', valueType: _type(raw));
      return null;
    }
    final Map<dynamic, dynamic> e = raw;

    final int? id = asInt(e['id']);
    if (id == null || id < 0) {
      AppLogger.validationFailure(
          field: '$field.id', reason: 'invalid-id', valueType: _type(e['id']));
      return null;
    }
    final String? name = asCleanString(e['name'], minLength: 1, maxLength: 200);
    if (name == null) {
      AppLogger.validationFailure(
          field: '$field.name', reason: 'invalid-name', valueType: _type(e['name']));
      return null;
    }
    final double? lat = asDouble(e['latitude']);
    final double? lon = asDouble(e['longitude']);
    if (lat == null || lat < -90 || lat > 90) {
      AppLogger.validationFailure(
          field: '$field.latitude',
          reason: 'out-of-range',
          valueType: _type(e['latitude']));
      return null;
    }
    if (lon == null || lon < -180 || lon > 180) {
      AppLogger.validationFailure(
          field: '$field.longitude',
          reason: 'out-of-range',
          valueType: _type(e['longitude']));
      return null;
    }
    final String? country =
        asCleanString(e['country'], minLength: 1, maxLength: 100) ?? '—';
    final String? admin1 = asCleanStringOrOmit(e['admin1'], maxLength: 100);
    final Object? codeRaw = e['country_code'];
    String? countryCode;
    if (codeRaw != null) {
      final String? code =
          asCleanString(codeRaw, minLength: 2, maxLength: 2);
      countryCode = code; // omit when invalid (PRD §7.3)
    }
    return GeoPlace(
      name: name,
      admin1: admin1,
      country: country,
      countryCode: countryCode,
      lat: lat,
      lon: lon,
      geocodingId: id,
    );
  }

  static String _type(Object? v) => v == null ? 'null' : v.runtimeType.toString();
}

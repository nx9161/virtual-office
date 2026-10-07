// BigDataCloudDto: fallback reverse-geocode whitelist (B-3 / MEDIUM-1).
//
// The fallback response is validated before its strings flow into the
// persisted place name and the home header:
//  * city/locality: 1…200 chars (PRD wins per R-3)
//  * countryCode: exactly 2 chars, optional
//  * countryName: ≤100 chars, optional
// Any violation -> throw -> the caller falls through to the "Current
// location" label (FM-17). The raw fallback payload is NEVER persisted.

import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/validation/validators.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

abstract final class BigDataCloudDto {
  /// Parses a decoded BigDataCloud reverse-geocode-client body.
  /// [lat]/[lon] are the already-rounded 2-dp coordinates.
  /// Throws AppFailure.schemaViolation on any whitelist violation.
  static GeoPlace parse({
    required Object? json,
    required double lat,
    required double lon,
  }) {
    if (json is! Map) {
      throw const AppFailure.schemaViolation(
          'bigdatacloud', 'root-not-object');
    }
    final Map<dynamic, dynamic> root = json;
    final Object? cityRaw = root['city'] ?? root['locality'];
    final String? name =
        asCleanString(cityRaw, minLength: 1, maxLength: 200);
    if (name == null) {
      throw const AppFailure.schemaViolation('bigdatacloud.city', 'invalid');
    }
    final Object? codeRaw = root['countryCode'];
    String? countryCode;
    if (codeRaw != null) {
      countryCode = asCleanString(codeRaw, minLength: 2, maxLength: 2);
      if (countryCode == null) {
        throw const AppFailure.schemaViolation(
            'bigdatacloud.countryCode', 'invalid');
      }
    }
    final String? country =
        asCleanStringOrOmit(root['countryName'], maxLength: 100) ?? '—';
    return GeoPlace(
      name: name,
      admin1: asCleanStringOrOmit(root['principalSubdivision'], maxLength: 100),
      country: country,
      countryCode: countryCode,
      lat: lat,
      lon: lon,
    );
  }
}

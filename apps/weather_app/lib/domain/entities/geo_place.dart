// GeoPlace: a named place with 2-decimal coordinates.
//
// Coordinates are ALWAYS rounded to 2 dp at creation (ADR-07). These are
// PUBLIC place coordinates (search results, recents) — never device-derived
// precise fixes. DevicePosition (memory-only, no serialization) is the
// separate type for device fixes.

import 'package:weather_app/core/validation/validators.dart';

class GeoPlace {
  final String name;
  final String? admin1;
  final String country;
  final String? countryCode;
  final double lat; // 2 dp
  final double lon; // 2 dp
  final int? geocodingId; // Open-Meteo result id, for dedupe

  GeoPlace({
    required this.name,
    required this.admin1,
    required this.country,
    required this.countryCode,
    required double lat,
    required double lon,
    this.geocodingId,
  })  : lat = roundTo2dp(lat),
        lon = roundTo2dp(lon);

  /// Cache/dedupe key basis (hashed before persistence — B-1).
  String get cacheKeySeed =>
      'forecast:${(lat * 100).round()}:${(lon * 100).round()}';

  String get displayName {
    final StringBuffer sb = StringBuffer(name);
    if (admin1 != null && admin1!.isNotEmpty) sb.write(', ${admin1!}');
    sb.write(', $country');
    return sb.toString();
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'name': name,
        if (admin1 != null) 'admin1': admin1,
        'country': country,
        if (countryCode != null) 'countryCode': countryCode,
        'lat': lat,
        'lon': lon,
        if (geocodingId != null) 'id': geocodingId,
      };

  /// Only for search-sourced places (public data). Device-derived places are
  /// persisted WITHOUT coordinates (ADR-07: city name only).
  factory GeoPlace.fromJson(Map<String, Object?> json) {
    final Object? latRaw = json['lat'];
    final Object? lonRaw = json['lon'];
    final double? lat = asDouble(latRaw);
    final double? lon = asDouble(lonRaw);
    if (lat == null || lon == null) {
      throw const FormatException('GeoPlace missing coordinates');
    }
    final Object? nameRaw = json['name'];
    if (nameRaw is! String || nameRaw.isEmpty) {
      throw const FormatException('GeoPlace missing name');
    }
    final Object? admin1Raw = json['admin1'];
    final Object? countryRaw = json['country'];
    final Object? codeRaw = json['countryCode'];
    final Object? idRaw = json['id'];
    return GeoPlace(
      name: nameRaw,
      admin1: admin1Raw is String && admin1Raw.isNotEmpty ? admin1Raw : null,
      country: countryRaw is String && countryRaw.isNotEmpty ? countryRaw : '—',
      countryCode: codeRaw is String && codeRaw.length == 2 ? codeRaw : null,
      lat: lat,
      lon: lon,
      geocodingId: asInt(idRaw),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GeoPlace &&
      other.name == name &&
      other.admin1 == admin1 &&
      other.country == country &&
      other.lat == lat &&
      other.lon == lon;

  @override
  int get hashCode => Object.hash(name, admin1, country, lat, lon);
}

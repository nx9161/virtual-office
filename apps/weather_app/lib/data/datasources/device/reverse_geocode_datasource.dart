// ReverseGeocodeDataSource: device fix -> city name (ADR-08).
//
// Chain (FM-17):
//  1. on-device `geocoding` package (no app-level network dependency; the
//     platform geocoder may use network per OS behavior — precision of
//     language matters for the privacy notice).
//  2. BigDataCloud reverse-geocode-client fallback (keyless, coarse 2-dp
//     coords only, named + disclosed in the privacy notice, Tech Law C2).
//  3. Label fallback: "Current location" (no name) — forecast still loads.
//
// Never persists anything; the caller (repository) persists only the city
// name for device-sourced places (ADR-07).

import 'package:geocoding/geocoding.dart';
import 'package:weather_app/core/validation/validators.dart';
import 'package:weather_app/data/datasources/remote/bigdatacloud_api.dart';
import 'package:weather_app/domain/entities/app_settings.dart'
    show DevicePosition;
import 'package:weather_app/domain/entities/geo_place.dart';

class ReverseGeocodeDataSource {
  final BigDataCloudApi _fallback;

  ReverseGeocodeDataSource(this._fallback);

  Future<GeoPlace> reverseGeocode(DevicePosition pos) async {
    final GeoPlace? onDevice = await _onDevice(pos);
    if (onDevice != null) return onDevice;
    try {
      return await _fallback.reverseGeocode(lat: pos.lat, lon: pos.lon);
    } catch (_) {
      // Fall through to the label fallback (FM-17).
    }
    return GeoPlace(
      name: 'Current location',
      admin1: null,
      country: '—',
      countryCode: null,
      lat: pos.lat,
      lon: pos.lon,
    );
  }

  Future<GeoPlace?> _onDevice(DevicePosition pos) async {
    try {
      final List<Placemark> marks =
          await placemarkFromCoordinates(pos.lat, pos.lon);
      if (marks.isEmpty) return null;
      final Placemark m = marks.first;
      final String? name = asCleanString(
        m.locality ?? m.subAdministrativeArea ?? m.administrativeArea,
        minLength: 1,
        maxLength: 200,
      );
      if (name == null) return null;
      return GeoPlace(
        name: name,
        admin1: asCleanStringOrOmit(m.administrativeArea, maxLength: 100),
        country:
            asCleanString(m.country, minLength: 1, maxLength: 100) ?? '—',
        countryCode: _exact2(m.isoCountryCode),
        lat: pos.lat,
        lon: pos.lon,
      );
    } catch (_) {
      return null;
    }
  }

  String? _exact2(String? code) {
    if (code == null) return null;
    final String trimmed = code.trim();
    return trimmed.length == 2 ? trimmed : null;
  }
}

// GetWeather: loads a forecast through the TTL ladder (PRD §8.2).

import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart';

class GetWeather {
  final WeatherRepository _weather;
  final LocationRepository _location;

  GetWeather(this._weather, this._location);

  /// Returns null when the request was dropped (revocation generation
  /// mismatch or supersede) — null is NOT a failure.
  Future<WeatherResult?> call({
    required GeoPlace place,
    required CacheSource source,
    bool forceRefresh = false,
  }) {
    return _weather.getForecast(
      place: place,
      source: source,
      forceRefresh: forceRefresh,
      deviceGeneration: source == CacheSource.deviceLocation
          ? _location.deviceGeneration
          : null,
    );
  }
}

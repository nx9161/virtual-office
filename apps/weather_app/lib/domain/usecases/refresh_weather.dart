// RefreshWeather: pull-to-refresh / foreground resume.
// User intent overrides the cache (PRD US-8 AC2); still subject to §8.3.

import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart';
import 'package:weather_app/domain/usecases/get_weather.dart';

class RefreshWeather {
  final GetWeather _getWeather;

  RefreshWeather(this._getWeather);

  Future<WeatherResult?> call({
    required GeoPlace place,
    required CacheSource source,
  }) =>
      _getWeather(place: place, source: source, forceRefresh: true);
}

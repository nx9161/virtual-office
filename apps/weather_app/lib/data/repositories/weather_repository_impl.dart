// WeatherRepositoryImpl: TTL ladder + in-flight dedupe + R-13 revocation.
//
// Flow (PRD §8.2):
//  1. L1/L2 read: fresh (≤10 min) -> return immediately.
//  2. SWR (10–60 min) -> return stale + background revalidate (repo exposes
//     revalidateInBackground; the controller awaits it without touching UI
//     state except for a silent update on success).
//  3. 60 min–24 h -> serve ONLY when the network is known-offline
//     (C-10.7 offline fast-path: skip the doomed network attempt); when
//     online, go to network.
//  4. Network: validation -> echo-free encode -> atomic write-through.
// In-flight dedupe: identical requests within 5 s attach to the same future
// (PRD §8.2); completed futures are always removed (no leak).
// R-13: device-sourced requests carry the device generation; revocation bumps
// it and cancels the shared device CancelToken — late responses are dropped
// (null), never repopulate cache/state.

import 'package:dio/dio.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/error_mapper.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/network/interceptors/rate_limit_interceptor.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/data/datasources/local/forecast_cache.dart';
import 'package:weather_app/data/datasources/remote/forecast_api.dart';
import 'package:weather_app/data/models/forecast_dto.dart';
import 'package:weather_app/domain/entities/forecast.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart';

class _InFlight {
  final Future<WeatherResult?> future;
  final DateTime startedAt;

  _InFlight(this.future, this.startedAt);
}

class WeatherRepositoryImpl implements WeatherRepository {
  final ForecastApi _api;
  final ForecastCache _cache;
  final Clock _clock;
  final bool Function() _isOnline;

  final Map<String, _InFlight> _inFlight = <String, _InFlight>{};
  int _deviceGeneration = 0;
  CancelToken? _deviceCancelToken;

  WeatherRepositoryImpl({
    required ForecastApi api,
    required ForecastCache cache,
    required Clock clock,
    required bool Function() isOnline,
  })  : _api = api,
        _cache = cache,
        _clock = clock,
        _isOnline = isOnline;

  @override
  int get deviceGeneration => _deviceGeneration;

  @override
  void bumpDeviceGeneration() {
    _deviceGeneration++;
    cancelDeviceRequests();
  }

  @override
  void cancelDeviceRequests() {
    _deviceCancelToken?.cancel();
    _deviceCancelToken = null;
  }

  @override
  Future<WeatherResult?> getForecast({
    required GeoPlace place,
    required CacheSource source,
    bool forceRefresh = false,
    int? deviceGeneration,
  }) async {
    final String rawKey = ForecastCache.rawKeyFor(place);
    final DateTime now = _clock.now().toUtc();

    if (!forceRefresh) {
      final CacheRead? read = _cache.read(rawKey);
      if (read != null) {
        switch (read.age) {
          case CacheAge.fresh:
            return _fromCache(read, CacheHit.fresh);
          case CacheAge.swrStale:
            return _fromCache(read, CacheHit.swrStale);
          case CacheAge.offlineStale:
            // C-10.7: known-offline -> serve stale immediately, labeled.
            if (!_isOnline()) return _fromCache(read, CacheHit.offlineStale);
            break; // online: fall through to network
          case CacheAge.expired:
            break; // fall through to network
        }
      }
    }

    // In-flight dedupe (PRD §8.2): attach to the same future within 5 s.
    final _InFlight? existing = _inFlight[rawKey];
    if (existing != null &&
        now.difference(existing.startedAt) <
            AppConstants.inFlightDedupeWindow) {
      final WeatherResult? r = await existing.future;
      if (_dropped(deviceGeneration)) return null;
      return r;
    }

    final CancelToken? token = source == CacheSource.deviceLocation
        ? (_deviceCancelToken ??= CancelToken())
        : null;
    final Future<WeatherResult?> future = _fetchNetwork(
      place: place,
      source: source,
      rawKey: rawKey,
      deviceGeneration: deviceGeneration,
      cancelToken: token,
      now: now,
    );
    _inFlight[rawKey] = _InFlight(future, now);
    try {
      return await future;
    } finally {
      _inFlight.remove(rawKey);
    }
  }

  @override
  Future<WeatherResult?> revalidateInBackground({
    required GeoPlace place,
    required CacheSource source,
    int? deviceGeneration,
  }) async {
    try {
      return await getForecast(
        place: place,
        source: source,
        forceRefresh: true,
        deviceGeneration: deviceGeneration,
      );
    } catch (_) {
      // SWR failure: the stale data on screen stays; the caller surfaces a
      // banner. Never throws out of the background path.
      return null;
    }
  }

  @override
  Future<WeatherResult?> getStaleFallback(GeoPlace place) async {
    final String rawKey = ForecastCache.rawKeyFor(place);
    final CacheRead? read = _cache.read(rawKey);
    if (read == null || read.age == CacheAge.expired) return null;
    try {
      final Forecast forecast = ForecastDto.decode(read.record.payloadJson);
      return WeatherResult(
        forecast: forecast,
        hit: CacheHit.offlineStale,
        age: read.duration,
      );
    } catch (_) {
      // FM-18 at fallback time: evict the undecodable payload.
      await _cache.delete(rawKey);
      return null;
    }
  }

  @override
  Future<void> deleteDeviceSourcedCache() =>
      _cache.deleteBySource(CacheSource.deviceLocation);

  @override
  Future<void> clearCache() => _cache.clear();

  Future<WeatherResult?> _fetchNetwork({
    required GeoPlace place,
    required CacheSource source,
    required String rawKey,
    required int? deviceGeneration,
    required CancelToken? cancelToken,
    required DateTime now,
  }) async {
    try {
      final Forecast forecast = await _api.getForecast(
        lat: place.lat,
        lon: place.lon,
        place: place,
        fetchedAtUtc: now,
        cancelToken: cancelToken,
      );
      // R-13: revocation mid-flight -> drop; never repopulate cache/state.
      if (_dropped(deviceGeneration)) return null;
      await _cache.write(
        rawKey: rawKey,
        // B-1: device-sourced entries encode the place name-only (no
        // lat/lon) — ADR-07; search-sourced entries keep public place
        // coords (US-13 carve-out).
        payloadJson: ForecastDto.encode(
          forecast,
          deviceSourcedPlace: source == CacheSource.deviceLocation,
        ),
        source: source,
        fetchedAtUtc: now,
      );
      return WeatherResult(
          forecast: forecast, hit: CacheHit.network, age: Duration.zero);
    } on DioException catch (e) {
      // Cancel/supersede is a drop (FM-12), not a failure.
      if (e.type == DioExceptionType.cancel || isSuperseded(e)) return null;
      throw mapToFailure(e);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapToFailure(e);
    }
  }

  WeatherResult? _fromCache(CacheRead read, CacheHit hit) {
    try {
      final Forecast forecast = ForecastDto.decode(read.record.payloadJson);
      return WeatherResult(forecast: forecast, hit: hit, age: read.duration);
    } catch (_) {
      return null; // treated as a miss by the caller
    }
  }

  bool _dropped(int? deviceGeneration) =>
      deviceGeneration != null && deviceGeneration != _deviceGeneration;
}

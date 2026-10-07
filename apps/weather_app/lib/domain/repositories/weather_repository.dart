// WeatherRepository — domain interface (R-9 DI composition rule).
//
// The abstract provider is declared HERE in domain. The data-layer
// implementation is bound via ProviderScope overrides in main.dart (and in
// tests). Presentation imports only this file — never data/.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/domain/entities/forecast.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

/// Origin tag for cache records (R-13 / HIGH-1.1): revocation deletes
/// device-location entries without needing the raw coordinates back.
enum CacheSource { deviceLocation, search }

/// How a forecast was obtained.
enum CacheHit {
  /// Fresh from network.
  network,
  /// Cache ≤ 10 min.
  fresh,
  /// Cache 10–60 min, served immediately (+ background revalidate).
  swrStale,
  /// Cache 60 min–24 h, served only because the network failed (labeled).
  offlineStale,
}

class WeatherResult {
  final Forecast forecast;
  final CacheHit hit;
  final Duration age;

  const WeatherResult({
    required this.forecast,
    required this.hit,
    required this.age,
  });
}

abstract class WeatherRepository {
  /// TTL ladder (PRD §8.2): L1 -> L2 fresh -> L2 SWR -> network.
  /// Returns null when the request was dropped (revocation generation
  /// mismatch or supersede) — null is NOT a failure.
  Future<WeatherResult?> getForecast({
    required GeoPlace place,
    required CacheSource source,
    bool forceRefresh = false,
    int? deviceGeneration,
  });

  /// Offline fallback: newest cache entry ≤ 24 h, regardless of source.
  /// Null when nothing usable exists (PRD US-10 AC2/AC3).
  Future<WeatherResult?> getStaleFallback(GeoPlace place);

  /// SWR background revalidate: fetches fresh data without touching UI state.
  /// Returns null when dropped or failed — the caller keeps the stale data
  /// and surfaces a banner. Never throws.
  Future<WeatherResult?> revalidateInBackground({
    required GeoPlace place,
    required CacheSource source,
    int? deviceGeneration,
  });

  /// R-13: delete all device-location-sourced entries (by hash — the raw
  /// coordinates are never needed back).
  Future<void> deleteDeviceSourcedCache();

  /// "Delete local data" (Tech Law C2 §7): wipes the entire forecast cache.
  Future<void> clearCache();

  /// R-13: revocation bumps the generation; in-flight device requests are
  /// cancelled and their late responses dropped.
  void bumpDeviceGeneration();
  int get deviceGeneration;
  void cancelDeviceRequests();
}

/// Domain-declared abstract provider — throws until overridden (R-9).
final weatherRepositoryProvider = Provider<WeatherRepository>(
  (ref) => throw UnimplementedError(
    'weatherRepositoryProvider is not overridden. '
    'Bind the implementation via ProviderScope overrides in main.dart (R-9).',
  ),
);

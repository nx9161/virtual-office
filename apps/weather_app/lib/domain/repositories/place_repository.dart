// PlaceRepository — domain interface for city search (R-10).
//
// Search/geocoding gets its own repository: search results are public place
// data and must never share a cache path with device-derived coordinates.
// Owns the 60 s per-query cache, the 5 s in-flight dedupe, and the
// CancelToken lifecycle for superseded keystrokes (FM-12).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

abstract class PlaceRepository {
  /// Debounced, cancellable search. The repository owns the CancelToken:
  /// [cancelInFlightSearch] supersedes the pending request (FM-12).
  /// Throws AppFailure (mapped through FailurePresentationMapper.forSearch).
  Future<List<GeoPlace>> searchPlaces(String query);

  /// Cancels the in-flight search, if any. Safe to call with none pending.
  void cancelInFlightSearch();

  /// True when [error] is the benign supersede/cancel marker (FM-12) —
  /// the controller must drop it silently, never map it to AppFailure.
  /// Implemented with Dio internals in data/; the interface stays pure.
  bool isSupersede(Object error);

  List<GeoPlace> get recentPlaces; // ≤ 10, most-recent-first (PRD US-13)
  Future<void> addRecent(GeoPlace place);
  Future<void> removeRecent(GeoPlace place);
  Future<void> clearRecents();
}

/// Domain-declared abstract provider — throws until overridden (R-9).
final placeRepositoryProvider = Provider<PlaceRepository>(
  (ref) => throw UnimplementedError(
    'placeRepositoryProvider is not overridden. '
    'Bind the implementation via ProviderScope overrides in main.dart (R-9).',
  ),
);

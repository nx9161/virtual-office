// Search screen state (R-8): sealed union via plain autoDispose Notifier.
//
// Recents are always visible (idle + offline); offline keeps recents
// tappable (design §3.2). FM-12: the echoed query is sanitized + ≤50 chars.

import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

sealed class SearchScreenState {
  const SearchScreenState();
}

/// No query yet (or query < 2 chars): recents only.
final class SearchIdle extends SearchScreenState {
  final List<GeoPlace> recentPlaces;

  const SearchIdle(this.recentPlaces);
}

/// Debounced query in flight: shimmer list.
final class SearchLoading extends SearchScreenState {
  final List<GeoPlace> recentPlaces;

  const SearchLoading(this.recentPlaces);
}

final class SearchResults extends SearchScreenState {
  final List<GeoPlace> results;
  final List<GeoPlace> recentPlaces;

  const SearchResults({required this.results, required this.recentPlaces});
}

/// FM-12: sanitized query, escaped, ≤50 chars.
final class SearchEmpty extends SearchScreenState {
  final String queryEcho;

  const SearchEmpty(this.queryEcho);
}

final class SearchError extends SearchScreenState {
  final AppFailure failure;
  final List<GeoPlace> recentPlaces;

  const SearchError(this.failure, this.recentPlaces);
}

/// Offline: the field is disabled; recents remain tappable (design §3.2).
final class SearchOffline extends SearchScreenState {
  final List<GeoPlace> recentPlaces;

  const SearchOffline(this.recentPlaces);
}

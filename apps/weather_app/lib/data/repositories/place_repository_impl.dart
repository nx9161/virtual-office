// PlaceRepositoryImpl: city search (R-10).
//
//  * 60 s per-query cache on the normalized query (PRD §8.1).
//  * 5 s in-flight dedupe: identical queries reuse the in-flight result.
//  * CancelToken owned HERE: a new keystroke supersedes the pending request
//    via cancelInFlightSearch() (FM-12). Cancellation propagates as the raw
//    DioException; the search controller drops it by monotonic request id
//    (documented contract — never map a supersede to AppFailure).
//  * Recents via RecentPlacesStore (public place data only, US-13).

import 'package:dio/dio.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/network/interceptors/rate_limit_interceptor.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/core/validation/validators.dart';
import 'package:weather_app/data/datasources/local/recent_places_store.dart';
import 'package:weather_app/data/datasources/remote/geocoding_api.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/place_repository.dart';

class _CachedQuery {
  final List<GeoPlace> results;
  final DateTime at;

  _CachedQuery(this.results, this.at);
}

class PlaceRepositoryImpl implements PlaceRepository {
  final GeocodingApi _api;
  final RecentPlacesStore _recents;
  final Clock _clock;

  final Map<String, _CachedQuery> _queryCache = <String, _CachedQuery>{};
  final Map<String, Future<List<GeoPlace>>> _inFlight =
      <String, Future<List<GeoPlace>>>{};
  CancelToken? _searchToken;

  PlaceRepositoryImpl({
    required GeocodingApi api,
    required RecentPlacesStore recents,
    required Clock clock,
  })  : _api = api,
        _recents = recents,
        _clock = clock;

  @override
  Future<List<GeoPlace>> searchPlaces(String rawQuery) async {
    final String query = sanitizeQuery(rawQuery);
    if (query.length < AppConstants.searchMinChars) return <GeoPlace>[];
    final String key = normalizeQueryKey(query);
    final DateTime now = _clock.now().toUtc();

    final _CachedQuery? cached = _queryCache[key];
    if (cached != null &&
        now.difference(cached.at) < AppConstants.searchResultCacheTtl) {
      return cached.results;
    }
    final Future<List<GeoPlace>>? inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;

    // Supersede the previous keystroke's request (FM-12).
    _searchToken?.cancel();
    final CancelToken token = CancelToken();
    _searchToken = token;

    final Future<List<GeoPlace>> future = _api.search(query, cancelToken: token);
    _inFlight[key] = future;
    try {
      final List<GeoPlace> results = await future;
      _queryCache[key] = _CachedQuery(results, _clock.now().toUtc());
      return results;
    } finally {
      _inFlight.remove(key);
      if (_searchToken == token) _searchToken = null;
    }
    // NOTE: DioException (incl. cancel/supersede) propagates raw — the API
    // already mapped real failures to AppFailure; the search controller
    // drops superseded requests by monotonic request id before mapping.
  }

  @override
  void cancelInFlightSearch() {
    _searchToken?.cancel();
    _searchToken = null;
  }

  @override
  bool isSupersede(Object error) =>
      error is DioException &&
      (error.type == DioExceptionType.cancel || isSuperseded(error));

  @override
  List<GeoPlace> get recentPlaces => _recents.places;

  @override
  Future<void> addRecent(GeoPlace place) => _recents.add(place);

  @override
  Future<void> removeRecent(GeoPlace place) => _recents.remove(place);

  @override
  Future<void> clearRecents() => _recents.clear();
}

// SearchController: autoDispose, city search (S-2).
//
// Keystroke handling:
//  * every keystroke increments the monotonic request id and cancels the
//    300 ms debounce timer (timer lives in the event method — MEDIUM-9);
//  * a superseded request's completion is dropped by id comparison — the
//    raw DioException for cancel/supersede is NEVER mapped to AppFailure
//    (contract with PlaceRepositoryImpl).
//  * ref.onDispose cancels the timer and the in-flight Dio request.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/error_mapper.dart';
import 'package:weather_app/core/network/connectivity_provider.dart';
import 'package:weather_app/core/validation/validators.dart';
import 'package:weather_app/data/di/data_providers.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/repositories/place_repository.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';
import 'package:weather_app/features/home/home_controller.dart';
import 'package:weather_app/features/search/search_state.dart';

class SearchController extends Notifier<SearchScreenState> {
  Timer? _debounce;
  int _requestId = 0;
  bool _disposed = false;

  PlaceRepository get _places => ref.read(placeRepositoryProvider);

  @override
  SearchScreenState build() {
    ref.onDispose(() {
      _disposed = true;
      _debounce?.cancel();
      ref.read(searchPlacesProvider).cancelInFlight();
    });
    return SearchIdle(_recents());
  }

  List<GeoPlace> _recents() => _places.recentPlaces.take(5).toList();

  void onQueryChanged(String raw) {
    final String query = sanitizeQuery(raw);
    _requestId++; // every keystroke supersedes the previous request
    _debounce?.cancel();
    if (query.length < AppConstants.searchMinChars) {
      ref.read(searchPlacesProvider).cancelInFlight();
      if (!_disposed) state = SearchIdle(_recents());
      return;
    }
    final bool online = ref.read(isOnlineProvider).value ?? true;
    if (!online) {
      if (!_disposed) state = SearchOffline(_recents());
      return;
    }
    if (!_disposed) state = SearchLoading(_recents());
    final int id = _requestId;
    _debounce = Timer(
      AppConstants.searchDebounce,
      () => _search(id, query),
    );
  }

  Future<void> _search(int id, String query) async {
    try {
      final List<GeoPlace> results =
          await ref.read(searchPlacesProvider).call(query);
      if (_disposed || id != _requestId) return; // superseded — drop
      if (!_disposed) {
        state = results.isEmpty
            ? SearchEmpty(escapeQueryEcho(query))
            : SearchResults(results: results, recentPlaces: _recents());
      }
    } catch (e) {
      if (_disposed || id != _requestId) return;
      // FM-12: supersede/cancel is control flow, never a failure (the
      // repository owns the Dio-specific check — no dio import here).
      if (ref.read(placeRepositoryProvider).isSupersede(e)) return;
      if (!_disposed) state = SearchError(mapToFailure(e), _recents());
    }
  }

  /// A place was tapped: record it, save it (search-sourced), remember it as
  /// the last search city, and load its weather.
  Future<void> selectPlace(GeoPlace place) async {
    _debounce?.cancel();
    ref.read(searchPlacesProvider).cancelInFlight();
    await _places.addRecent(place);
    await ref
        .read(locationRepositoryProvider)
        .savePlace(place, deviceSourced: false);
    await ref.read(settingsRepositoryProvider).setLastSearchPlace(place);
    await ref
        .read(homeControllerProvider.notifier)
        .selectPlace(place, deviceSourced: false);
  }

  Future<void> removeRecent(GeoPlace place) async {
    await _places.removeRecent(place);
    if (!_disposed) state = SearchIdle(_recents());
  }

  Future<void> clearRecents() async {
    await _places.clearRecents();
    if (!_disposed) state = SearchIdle(_recents());
  }

  /// Dismisses a search error, returning to the recents list.
  void dismissError() {
    if (!_disposed) state = SearchIdle(_recents());
  }
}

/// autoDispose: the sheet's work must not outlive the sheet.
final searchControllerProvider =
    NotifierProvider.autoDispose<SearchController, SearchScreenState>(
        SearchController.new);

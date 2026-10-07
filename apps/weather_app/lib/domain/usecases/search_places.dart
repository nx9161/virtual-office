// SearchPlaces: city search (US-1/US-2). The repository owns debouncing
// support machinery (CancelToken, in-flight dedupe, 60 s per-query cache);
// the controller owns the 300 ms keystroke debounce.

import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/place_repository.dart';

class SearchPlaces {
  final PlaceRepository _places;

  SearchPlaces(this._places);

  Future<List<GeoPlace>> call(String query) => _places.searchPlaces(query);

  void cancelInFlight() => _places.cancelInFlightSearch();
}

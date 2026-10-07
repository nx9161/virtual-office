// SearchController: debounce, cancel/supersede, out-of-order drops, dispose.
//
// fake_async drives the 300 ms debounce timer deterministically; the fake
// PlaceRepository exposes completers so search latency is controlled.

import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/data/di/data_providers.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/repositories/place_repository.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';
import 'package:weather_app/domain/usecases/search_places.dart';
import 'package:weather_app/features/home/home_controller.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/features/search/search_controller.dart';
import 'package:weather_app/features/search/search_state.dart';

GeoPlace _place(String name) => GeoPlace(
      name: name,
      admin1: null,
      country: 'Testland',
      countryCode: 'TT',
      lat: 10.0,
      lon: 20.0,
    );

class _FakePlaceRepository implements PlaceRepository {
  final Map<String, Completer<List<GeoPlace>>> pending = <String, Completer<List<GeoPlace>>>{};
  final List<String> queries = <String>[];
  int cancelCalls = 0;
  List<GeoPlace> recents = <GeoPlace>[];

  @override
  Future<List<GeoPlace>> searchPlaces(String query) {
    queries.add(query);
    final Completer<List<GeoPlace>> c = Completer<List<GeoPlace>>();
    pending[query] = c;
    return c.future;
  }

  @override
  void cancelInFlightSearch() => cancelCalls++;

  @override
  bool isSupersede(Object error) => false;

  @override
  List<GeoPlace> get recentPlaces => recents;

  @override
  Future<void> addRecent(GeoPlace place) async => recents.insert(0, place);

  @override
  Future<void> removeRecent(GeoPlace place) async =>
      recents.removeWhere((GeoPlace p) => p.name == place.name);

  @override
  Future<void> clearRecents() async => recents.clear();
}

class _MockLocationRepository extends Mock implements LocationRepository {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _FakeHomeController extends HomeController {
  final List<GeoPlace> selected = <GeoPlace>[];

  @override
  Future<void> selectPlace(GeoPlace place, {required bool deviceSourced}) async {
    selected.add(place);
  }
}

ProviderContainer _container(
  _FakePlaceRepository places,
  _MockLocationRepository location,
  _MockSettingsRepository settings,
  _FakeHomeController home,
) {
  return ProviderContainer(
    overrides: <Override>[
      searchPlacesProvider.overrideWithValue(SearchPlaces(places)),
      placeRepositoryProvider.overrideWithValue(places),
      locationRepositoryProvider.overrideWithValue(location),
      settingsRepositoryProvider.overrideWithValue(settings),
      homeControllerProvider.overrideWith(() => home),
    ],
  );
}

void main() {
  late _FakePlaceRepository places;
  late _MockLocationRepository location;
  late _MockSettingsRepository settings;
  late _FakeHomeController home;

  setUp(() {
    places = _FakePlaceRepository();
    location = _MockLocationRepository();
    settings = _MockSettingsRepository();
    home = _FakeHomeController();
    when(() => location.savedPlace).thenReturn(null);
    when(() => location.savePlace(any(),
            deviceSourced: any(named: 'deviceSourced')))
        .thenAnswer((_) async {});
    when(() => settings.setLastSearchPlace(any())).thenAnswer((_) async {});
    registerFallbackValue(_place('x'));
  });

  test('debounce: rapid keystrokes -> single search for the final query', () {
    fakeAsync((FakeAsync async) {
      final ProviderContainer container =
          _container(places, location, settings, home);
      addTearDown(container.dispose);
      final SearchController c =
          container.read(searchControllerProvider.notifier);

      c.onQueryChanged('p');
      async.elapse(const Duration(milliseconds: 100));
      c.onQueryChanged('pa');
      async.elapse(const Duration(milliseconds: 100));
      c.onQueryChanged('par');
      async.elapse(const Duration(milliseconds: 300));

      expect(places.queries, <String>['par']);
    });
  });

  test('query below 2 chars -> idle, no search', () {
    fakeAsync((FakeAsync async) {
      final ProviderContainer container =
          _container(places, location, settings, home);
      addTearDown(container.dispose);
      final SearchController c =
          container.read(searchControllerProvider.notifier);

      c.onQueryChanged('p');
      async.elapse(const Duration(milliseconds: 500));
      expect(places.queries, isEmpty);
      expect(container.read(searchControllerProvider), isA<SearchIdle>());
    });
  });

  test('superseded result is dropped by request id', () {
    fakeAsync((FakeAsync async) {
      final ProviderContainer container =
          _container(places, location, settings, home);
      addTearDown(container.dispose);
      final SearchController c =
          container.read(searchControllerProvider.notifier);

      c.onQueryChanged('paris');
      async.elapse(const Duration(milliseconds: 300)); // fires id=1
      c.onQueryChanged('paris texas');
      async.elapse(const Duration(milliseconds: 300)); // fires id=2

      // Complete the NEWER request first, then the stale one.
      places.pending['paris texas']!.complete(<GeoPlace>[_place('Paris, TX')]);
      async.flushMicrotasks();
      places.pending['paris']!.complete(<GeoPlace>[_place('Paris')]);
      async.flushMicrotasks();

      final SearchScreenState state = container.read(searchControllerProvider);
      expect(state, isA<SearchResults>());
      expect((state as SearchResults).results.single.name, 'Paris, TX');
    });
  });

  test('search error surfaces, then dismiss returns to idle', () {
    fakeAsync((FakeAsync async) {
      final ProviderContainer container =
          _container(places, location, settings, home);
      addTearDown(container.dispose);
      final SearchController c =
          container.read(searchControllerProvider.notifier);

      c.onQueryChanged('nowhere');
      async.elapse(const Duration(milliseconds: 300));
      places.pending['nowhere']!
          .completeError(const NetworkUnreachableFailure());
      async.flushMicrotasks();

      expect(container.read(searchControllerProvider), isA<SearchError>());
      c.dismissError();
      expect(container.read(searchControllerProvider), isA<SearchIdle>());
    });
  });

  test('selectPlace records, saves, and loads home', () async {
    final ProviderContainer container =
        _container(places, location, settings, home);
    addTearDown(container.dispose);
    final SearchController c =
        container.read(searchControllerProvider.notifier);

    await c.selectPlace(_place('Berlin'));

    expect(places.recents.first.name, 'Berlin');
    verify(() => location.savePlace(any(),
        deviceSourced: false)).called(1);
    verify(() => settings.setLastSearchPlace(any())).called(1);
    expect(home.selected.single.name, 'Berlin');
  });

  test('dispose cancels the debounce timer and the in-flight search', () {
    fakeAsync((FakeAsync async) {
      final ProviderContainer container =
          _container(places, location, settings, home);
      final SearchController c =
          container.read(searchControllerProvider.notifier);

      c.onQueryChanged('par');
      container.dispose(); // provider disposed -> onDispose
      async.elapse(const Duration(milliseconds: 1000));

      expect(places.queries, isEmpty);
      expect(places.cancelCalls, greaterThan(0));
    });
  });
}

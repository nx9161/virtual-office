// PlaceRepositoryImpl: 60 s per-query cache, in-flight dedupe,
// cancel/supersede machinery.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/data/datasources/local/recent_places_store.dart';
import 'package:weather_app/data/datasources/remote/geocoding_api.dart';
import 'package:weather_app/data/repositories/place_repository_impl.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

GeoPlace _place(String name) => GeoPlace(
      name: name,
      admin1: null,
      country: 'Testland',
      countryCode: 'TT',
      lat: 10.0,
      lon: 20.0,
    );

class _FakeGeocodingApi extends GeocodingApi {
  _FakeGeocodingApi() : super(Dio());

  int calls = 0;
  final List<String> seenQueries = <String>[];

  @override
  Future<List<GeoPlace>> search(String rawQuery,
      {CancelToken? cancelToken}) async {
    calls++;
    seenQueries.add(rawQuery);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return <GeoPlace>[_place('Berlin')];
  }
}

void main() {
  late Directory tmp;
  late FakeClock clock;
  late _FakeGeocodingApi api;
  late RecentPlacesStore recents;
  late PlaceRepositoryImpl repo;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hive_places');
    Hive.init(tmp.path);
    clock = FakeClock(DateTime.utc(2026, 10, 6, 12, 0));
    api = _FakeGeocodingApi();
    recents = RecentPlacesStore();
    await recents.init();
    repo = PlaceRepositoryImpl(api: api, recents: recents, clock: clock);
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(RecentPlacesStore.boxName);
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  test('60 s per-query cache: repeat query hits no network', () async {
    final List<GeoPlace> first = await repo.searchPlaces('paris');
    final List<GeoPlace> second = await repo.searchPlaces('paris');
    expect(first.single.name, 'Berlin');
    expect(second.single.name, 'Berlin');
    expect(api.calls, 1);
  });

  test('cache is per normalized query (case/whitespace)', () async {
    await repo.searchPlaces('paris');
    await repo.searchPlaces('  Paris ');
    expect(api.calls, 1);
  });

  test('cache expires after 60 s', () async {
    await repo.searchPlaces('paris');
    clock.advance(const Duration(seconds: 61));
    await repo.searchPlaces('paris');
    expect(api.calls, 2);
  });

  test('in-flight dedupe: concurrent identical queries share one call',
      () async {
    final Future<List<GeoPlace>> a = repo.searchPlaces('berlin');
    final Future<List<GeoPlace>> b = repo.searchPlaces('berlin');
    final List<List<GeoPlace>> both = await Future.wait(<Future<List<GeoPlace>>>[a, b]);
    expect(both[0].single.name, 'Berlin');
    expect(both[1].single.name, 'Berlin');
    expect(api.calls, 1);
  });

  test('query below 2 chars short-circuits', () async {
    expect(await repo.searchPlaces('x'), isEmpty);
    expect(api.calls, 0);
  });

  test('cancelInFlightSearch is safe with nothing pending', () {
    repo.cancelInFlightSearch();
  });

  test('recents round-trip through the repository', () async {
    await repo.addRecent(_place('Berlin'));
    expect(repo.recentPlaces.single.name, 'Berlin');
    await repo.removeRecent(_place('Berlin'));
    expect(repo.recentPlaces, isEmpty);
  });
}

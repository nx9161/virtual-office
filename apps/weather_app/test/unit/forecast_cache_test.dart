// ForecastCache: TTL ladder, SHA-256 keys, source tagging, LRU cap,
// corruption -> evict (FM-18).
//
// Hive is initialized in a temp dir; boxes are torn down between tests.
// A FakeClock drives the TTL ladder deterministically.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/data/datasources/local/forecast_cache.dart';
import 'package:weather_app/data/models/forecast_dto.dart';
import 'package:weather_app/domain/entities/forecast.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart'
    show CacheSource;

GeoPlace _place(double lat, double lon) => GeoPlace(
      name: 'Test City',
      admin1: null,
      country: 'Testland',
      countryCode: 'TT',
      lat: lat,
      lon: lon,
    );

Forecast _forecast(DateTime fetchedAtUtc) => Forecast(
      place: _place(52.52, 13.41),
      current: CurrentConditions(
        time: DateTime.utc(2026, 10, 6, 12),
        temperatureC: 21.0,
        apparentTemperatureC: 20.0,
        weatherCode: 1,
        humidityPct: 50,
        precipitationMm: 0.0,
        cloudCoverPct: 10,
        pressureHpa: 1015.0,
        windSpeedKmh: 12.0,
        windDirectionDeg: 90.0,
        windGustsKmh: 20.0,
        isDay: 1,
      ),
      hourly: <HourlyPoint>[],
      daily: <DailySummary>[],
      utcOffsetSeconds: 7200,
      timezone: 'Europe/Berlin',
      fetchedAtUtc: fetchedAtUtc,
    );

void main() {
  late Directory tmp;
  late FakeClock clock;
  late ForecastCache cache;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hive_test');
    Hive.init(tmp.path);
    clock = FakeClock(DateTime.utc(2026, 10, 6, 12, 0));
    cache = ForecastCache(clock: clock);
    await cache.init();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(ForecastCache.boxName);
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  test('raw keys are canonical (integer hundredths) and hashed (B-1)', () {
    expect(ForecastCache.rawKeyFor(_place(52.52, 13.41)), 'forecast:5252:1341');
    final String hash = cache.hashKey('forecast:5252:1341');
    expect(hash, isNot(contains('5252')));
    expect(hash.length, 64); // SHA-256 hex
    expect(cache.hashKey('forecast:5252:1341'), hash); // deterministic
  });

  test('write then read: fresh + source tagging', () async {
    await cache.write(
      rawKey: ForecastCache.rawKeyFor(_place(52.52, 13.41)),
      payloadJson:
          ForecastDto.encode(_forecast(DateTime.utc(2026, 10, 6, 12, 0))),
      source: CacheSource.search,
      fetchedAtUtc: clock.now().toUtc(),
    );
    final CacheRead? read =
        cache.read(ForecastCache.rawKeyFor(_place(52.52, 13.41)));
    expect(read, isNotNull);
    expect(read!.age, CacheAge.fresh);
    expect(read.record.source, CacheSource.search);
    expect(read.record.keyHash, isNot(contains('5252')));
  });

  test('TTL ladder buckets (10 min / 60 min / 24 h)', () async {
    Future<CacheAge?> ageAfter(Duration age) async {
      final GeoPlace p = _place(10.0 + age.inMinutes * 0.01, 20.0);
      await cache.write(
        rawKey: ForecastCache.rawKeyFor(p),
        payloadJson: '{"t":1}',
        source: CacheSource.search,
        fetchedAtUtc: clock.now().toUtc(),
      );
      clock.advance(age);
      final CacheRead? read = cache.read(ForecastCache.rawKeyFor(p));
      // Reset the clock so each case is independent.
      clock.setNow(DateTime.utc(2026, 10, 6, 12, 0));
      return read?.age;
    }

    expect(await ageAfter(const Duration(minutes: 5)), CacheAge.fresh);
    expect(await ageAfter(const Duration(minutes: 30)), CacheAge.swrStale);
    expect(await ageAfter(const Duration(hours: 5)), CacheAge.offlineStale);
    // >24 h: evicted -> miss.
    final GeoPlace p = _place(11.0, 20.0);
    await cache.write(
      rawKey: ForecastCache.rawKeyFor(p),
      payloadJson: '{"t":1}',
      source: CacheSource.search,
      fetchedAtUtc: clock.now().toUtc(),
    );
    clock.advance(const Duration(hours: 25));
    expect(cache.read(ForecastCache.rawKeyFor(p)), isNull);
  });

  test('LRU cap 20: oldest evicted', () async {
    for (int i = 0; i < 25; i++) {
      final GeoPlace p = _place(40.0 + i * 0.01, 10.0);
      await cache.write(
        rawKey: ForecastCache.rawKeyFor(p),
        payloadJson: '{"t":$i}',
        source: CacheSource.search,
        fetchedAtUtc: clock.now().toUtc(),
      );
    }
    final GeoPlace first = _place(40.0, 10.0);
    expect(cache.read(ForecastCache.rawKeyFor(first)), isNull);
    // The newest survives.
    final GeoPlace last = _place(40.24, 10.0);
    expect(cache.read(ForecastCache.rawKeyFor(last)), isNotNull);
  });

  test('corruption -> evict + miss (FM-18)', () async {
    final GeoPlace p = _place(48.85, 2.35);
    await cache.write(
      rawKey: ForecastCache.rawKeyFor(p),
      payloadJson: '{"t":1}',
      source: CacheSource.search,
      fetchedAtUtc: clock.now().toUtc(),
    );
    // Corrupt the disk record directly.
    final Box<String> box = Hive.box<String>(ForecastCache.boxName);
    await box.put(cache.hashKey(ForecastCache.rawKeyFor(p)), 'not-json{{{');
    // L1 would mask the corruption — clear it via a fresh cache instance.
    final ForecastCache c2 = ForecastCache(clock: clock);
    await c2.init();
    expect(c2.read(ForecastCache.rawKeyFor(p)), isNull);
  });

  test('echo stripped from stored payload (B-1)', () async {
    final GeoPlace p = _place(52.52, 13.41);
    final String payload =
        ForecastDto.encode(_forecast(DateTime.utc(2026, 10, 6, 12)));
    expect(payload, isNot(contains('latitude')));
    await cache.write(
      rawKey: ForecastCache.rawKeyFor(p),
      payloadJson: payload,
      source: CacheSource.search,
      fetchedAtUtc: clock.now().toUtc(),
    );
    final CacheRead? read = cache.read(ForecastCache.rawKeyFor(p));
    expect(read!.record.payloadJson, isNot(contains('latitude')));
  });
}

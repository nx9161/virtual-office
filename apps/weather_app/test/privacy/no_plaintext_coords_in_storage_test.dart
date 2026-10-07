// DoD#5: zero coordinates in persistent storage.
//
// Scans every SharedPreferences value AND the raw Hive forecast box for
// coordinate patterns after exercising the device-location and search
// flows. Device-sourced places persist the city name only (ADR-07/B-1);
// search-sourced places persist public 2-dp place coords (US-13) — the
// assertion therefore targets DEVICE coordinates specifically.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/data/datasources/local/forecast_cache.dart';
import 'package:weather_app/data/datasources/local/recent_places_store.dart';
import 'package:weather_app/data/datasources/local/settings_store.dart';
import 'package:weather_app/data/models/forecast_dto.dart';
import 'package:weather_app/domain/entities/forecast.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart'
    show CacheSource;

/// Matches high-precision decimals (old DoD#5 pattern) AND explicit
/// lat/lon JSON keys at ANY precision — the old pattern alone could not
/// catch the 2-dp place coords ("lat":52.52) the B-1 finding is about.
/// The key-anchored form avoids false positives on ISO timestamps with
/// fractional seconds ("...T12:00:00.000Z") that a bare 2-dp decimal
/// pattern would flag.
final RegExp _coordLike =
    RegExp(r'"lat":\s*-?\d+\.\d+|"lon":\s*-?\d+\.\d+|\d{2,3}\.\d{4,}');

GeoPlace _devicePlace() => GeoPlace(
      name: 'Current location',
      admin1: null,
      country: 'Testland',
      countryCode: 'TT',
      // The PRECISE device fix — must never reach disk.
      lat: 52.52341,
      lon: 13.41002,
    );

/// A full forecast for the device-sourced place, encoded through the REAL
/// ForecastDto.encode write path (not a synthetic payload string).
Forecast _deviceForecast() => Forecast(
      place: _devicePlace(),
      current: const CurrentConditions(
        time: null,
        temperatureC: 21.3,
        apparentTemperatureC: 20.0,
        weatherCode: 1,
        humidityPct: 55,
        precipitationMm: 0,
        cloudCoverPct: 10,
        pressureHpa: 1013,
        windSpeedKmh: 12,
        windDirectionDeg: 180,
        windGustsKmh: 18,
        isDay: 1,
      ),
      hourly: <HourlyPoint>[
        HourlyPoint(
          time: DateTime.utc(2026, 10, 6, 12),
          temperatureC: 21.3,
          precipitationProbabilityPct: 10,
          weatherCode: 1,
        ),
      ],
      daily: <DailySummary>[
        DailySummary(
          date: DateTime.utc(2026, 10, 6),
          tempMaxC: 22.0,
          tempMinC: 15.0,
          weatherCode: 1,
          sunrise: DateTime.utc(2026, 10, 6, 5),
          sunset: DateTime.utc(2026, 10, 6, 16, 30),
          uvIndexMax: 3.0,
          precipitationProbabilityMaxPct: 20,
        ),
      ],
      utcOffsetSeconds: 7200,
      timezone: 'Europe/Berlin',
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12),
    );

Forecast _searchForecast() => Forecast(
      place: GeoPlace(
          name: 'Paris',
          admin1: null,
          country: 'France',
          countryCode: 'FR',
          lat: 48.85,
          lon: 2.35),
      current: const CurrentConditions(
        time: null,
        temperatureC: 19.0,
        apparentTemperatureC: 18.0,
        weatherCode: 2,
        humidityPct: 60,
        precipitationMm: 0,
        cloudCoverPct: 25,
        pressureHpa: 1012,
        windSpeedKmh: 10,
        windDirectionDeg: 200,
        windGustsKmh: 15,
        isDay: 1,
      ),
      hourly: <HourlyPoint>[
        HourlyPoint(
          time: DateTime.utc(2026, 10, 6, 12),
          temperatureC: 19.0,
          precipitationProbabilityPct: 15,
          weatherCode: 2,
        ),
      ],
      daily: <DailySummary>[
        DailySummary(
          date: DateTime.utc(2026, 10, 6),
          tempMaxC: 21.0,
          tempMinC: 13.0,
          weatherCode: 2,
          sunrise: DateTime.utc(2026, 10, 6, 5, 10),
          sunset: DateTime.utc(2026, 10, 6, 16, 45),
          uvIndexMax: 2.5,
          precipitationProbabilityMaxPct: 25,
        ),
      ],
      utcOffsetSeconds: 7200,
      timezone: 'Europe/Paris',
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12),
    );

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('hive_privacy');
    Hive.init(tmp.path);
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk(ForecastCache.boxName);
    await Hive.deleteBoxFromDisk(RecentPlacesStore.boxName);
    await Hive.close();
    await tmp.delete(recursive: true);
  });

  test('device-sourced place persists name only (ADR-07)', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SettingsStore store = await SettingsStore.init(prefs,
        fallbackUnits: UnitSystem.metric);

    await store.setSavedPlace(_devicePlace(), deviceSourced: true);
    await store.setLastSearchPlace(GeoPlace(
        name: 'Paris',
        admin1: null,
        country: 'France',
        countryCode: 'FR',
        lat: 48.85,
        lon: 2.35));

    final String saved = prefs.getString('saved_place')!;
    expect(saved, isNot(contains('52.52341')));
    expect(saved, isNot(contains('13.41002')));
    expect(saved, contains('Current location'));
  });

  test('no device-coordinate patterns anywhere in prefs', () async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SettingsStore store = await SettingsStore.init(prefs,
        fallbackUnits: UnitSystem.metric);
    await store.setSavedPlace(_devicePlace(), deviceSourced: true);

    for (final String key in prefs.getKeys()) {
      final Object? v = prefs.get(key);
      if (v is String) {
        expect(_coordLike.hasMatch(v), isFalse,
            reason: 'coordinate-like value in prefs key $key');
      }
    }
  });

  test(
      'device-sourced cache payload is name-only via the real encode path (B-1)',
      () async {
    final ForecastCache cache = ForecastCache();
    await cache.init();
    final RecentPlacesStore recents = RecentPlacesStore();
    await recents.init();

    // B-1: the repository encodes device-sourced entries with
    // ForecastDto.encode(..., deviceSourcedPlace: true) — exercise the
    // REAL path, not a synthetic payload string.
    final String devicePayload = ForecastDto.encode(
      _deviceForecast(),
      deviceSourcedPlace: true,
    );
    expect(devicePayload, isNot(contains('"lat"')),
        reason: 'device payload must not carry lat');
    expect(devicePayload, isNot(contains('"lon"')),
        reason: 'device payload must not carry lon');
    expect(devicePayload, isNot(contains('52.52')),
        reason: '2-dp device fix must not reach disk');
    expect(devicePayload, isNot(contains('13.41')));
    expect(devicePayload, contains('Current location'));

    await cache.write(
      rawKey: ForecastCache.rawKeyFor(_devicePlace()),
      payloadJson: devicePayload,
      source: CacheSource.deviceLocation,
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12),
    );

    // The name-only record decodes to the 0,0 sentinel (mirrors
    // SettingsStore's ADR-07 device branch) — it is never evicted as
    // corrupt (FM-18) and never carries the real fix.
    final Forecast decoded = ForecastDto.decode(devicePayload);
    expect(decoded.place.name, 'Current location');
    expect(decoded.place.lat, 0);
    expect(decoded.place.lon, 0);
    expect(decoded.hourly, hasLength(1));

    // Search-sourced entries are unchanged: public place coords stay
    // (US-13 carve-out) — this guards against over-redaction.
    final String searchPayload = ForecastDto.encode(_searchForecast());
    expect(searchPayload, contains('"lat":48.85'));
    expect(searchPayload, contains('"lon":2.35'));
    await cache.write(
      rawKey: ForecastCache.rawKeyFor(_searchForecast().place),
      payloadJson: searchPayload,
      source: CacheSource.search,
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12),
    );
    await recents.add(_searchForecast().place);

    // Scan every box entry: DEVICE records must be coordinate-free at
    // every precision (the extended regex catches 2-dp pairs the old
    // \d{4,} pattern missed). The search entry is skipped — its public
    // place coords are the accepted US-13 carve-out.
    final String searchKeyHash =
        cache.hashKey(ForecastCache.rawKeyFor(_searchForecast().place));
    final Box<String> box = Hive.box<String>(ForecastCache.boxName);
    for (final String key in box.keys.cast<String>()) {
      expect(_coordLike.hasMatch(key), isFalse,
          reason: 'coordinate-like KEY in ${ForecastCache.boxName}');
      final String? value = box.get(key);
      if (value != null && key != searchKeyHash) {
        expect(_coordLike.hasMatch(value), isFalse,
            reason: 'coordinate-like VALUE in ${ForecastCache.boxName}/$key');
      }
    }
  });
}

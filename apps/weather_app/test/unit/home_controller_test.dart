// HomeController: boot routing, banner-vs-fullscreen rule, 429 single
// retry (R-12), unit-toggle rebuild without network (US-12 AC2), reconnect
// single retry (HIGH-1.3).

import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:weather_app/core/config/app_providers.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/network/connectivity_provider.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/data/di/data_providers.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/domain/entities/forecast.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart';
import 'package:weather_app/features/home/home_controller.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/features/settings/settings_controller.dart';
import 'package:weather_app/features/settings/settings_state.dart';

GeoPlace _place() => GeoPlace(
      name: 'Berlin',
      admin1: null,
      country: 'Germany',
      countryCode: 'DE',
      lat: 52.52,
      lon: 13.41,
    );

Forecast _forecast() => Forecast(
      place: _place(),
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
      hourly: <HourlyPoint>[
        HourlyPoint(
          time: DateTime.utc(2026, 10, 6, 12),
          temperatureC: 21.0,
          precipitationProbabilityPct: 10.0,
          weatherCode: 1,
        ),
      ],
      daily: <DailySummary>[
        DailySummary(
          date: DateTime.utc(2026, 10, 6),
          tempMaxC: 22.0,
          tempMinC: 12.0,
          weatherCode: 1,
          sunrise: DateTime.utc(2026, 10, 6, 5, 12),
          sunset: DateTime.utc(2026, 10, 6, 16, 48),
          uvIndexMax: 3.5,
          precipitationProbabilityMaxPct: 20.0,
        ),
      ],
      utcOffsetSeconds: 7200,
      timezone: 'Europe/Berlin',
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
    );

class _FakeWeatherRepository implements WeatherRepository {
  WeatherResult? result;
  Object? error;
  WeatherResult? staleFallback;
  int getForecastCalls = 0;
  int revalidateCalls = 0;

  @override
  Future<WeatherResult?> getForecast({
    required GeoPlace place,
    required CacheSource source,
    bool forceRefresh = false,
    int? deviceGeneration,
  }) async {
    getForecastCalls++;
    if (error != null) throw error!;
    return result;
  }

  @override
  Future<WeatherResult?> getStaleFallback(GeoPlace place) async =>
      staleFallback;

  @override
  Future<WeatherResult?> revalidateInBackground({
    required GeoPlace place,
    required CacheSource source,
    int? deviceGeneration,
  }) async {
    revalidateCalls++;
    return null;
  }

  @override
  Future<void> deleteDeviceSourcedCache() async {}

  @override
  Future<void> clearCache() async {}

  @override
  void bumpDeviceGeneration() {}

  @override
  int get deviceGeneration => 0;

  @override
  void cancelDeviceRequests() {}

  @override
  Future<void> clearCache() async {}
}

class _MockLocationRepository extends Mock implements LocationRepository {}

class _FakeSettingsController extends SettingsController {
  UnitSystem units = UnitSystem.metric;

  @override
  SettingsState build() => SettingsState(
        unitSystem: units,
        themeMode: AppThemeMode.system,
        consentState: ConsentState.unknown,
        osPermission: null,
        locationEnabled: false,
        crashReportingEnabled: true,
        appVersionLabel: '1.0.0',
        savedPlaceLabel: null,
      );

  void setUnits(UnitSystem u) {
    units = u;
    state = state.copyWith(unitSystem: u);
  }
}

ProviderContainer _container({
  required _FakeWeatherRepository weather,
  required _MockLocationRepository location,
  required SettingsRepository settings,
  required _FakeSettingsController settingsController,
  Stream<bool> online = const Stream<bool>.empty(),
}) {
  return ProviderContainer(
    overrides: <Override>[
      weatherRepositoryProvider.overrideWithValue(weather),
      locationRepositoryProvider.overrideWithValue(location),
      settingsRepositoryProvider.overrideWithValue(settings),
      settingsControllerProvider.overrideWith(() => settingsController),
      isOnlineProvider.overrideWith((Ref ref) => online),
      localeProvider.overrideWithValue(const Locale('en', 'US')),
      clockProvider.overrideWithValue(
          FakeClock(DateTime.utc(2026, 10, 6, 12, 30))),
    ],
  );
}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

/// Lets the controller's boot microtasks + fake-repo futures settle.
Future<void> _flush() async {
  await Future<void>.delayed(const Duration(milliseconds: 10));
  await Future<void>.delayed(const Duration(milliseconds: 10));
}

void main() {
  late _FakeWeatherRepository weather;
  late _MockLocationRepository location;
  late _MockSettingsRepository settings;
  late _FakeSettingsController settingsController;

  setUp(() {
    weather = _FakeWeatherRepository();
    location = _MockLocationRepository();
    settings = _MockSettingsRepository();
    settingsController = _FakeSettingsController();
    when(() => location.savedPlace).thenReturn(_place());
    when(() => settings.savedPlaceIsDeviceSourced).thenReturn(false);
    when(() => settings.settings).thenReturn(AppSettings(
      unitSystem: UnitSystem.metric,
      themeMode: AppThemeMode.system,
      consentState: ConsentState.unknown,
      consentFlowStep: ConsentFlowStep.idle,
      consentDeclinedAt: null,
      crashReportingOptOut: false,
      privacyNoticeSeen: true,
    ));
    registerFallbackValue(_place());
  });

  test('boot with saved place -> HomeReady', () async {
    weather.result = WeatherResult(
        forecast: _forecast(), hit: CacheHit.network, age: Duration.zero);
    final ProviderContainer container = _container(
      weather: weather,
      location: location,
      settings: settings,
      settingsController: settingsController,
      online: Stream<bool>.value(true),
    );
    addTearDown(container.dispose);

    container.read(homeControllerProvider);
    await _flush();
    expect(container.read(homeControllerProvider), isA<HomeReady>());
    final HomeReady ready =
        container.read(homeControllerProvider) as HomeReady;
    expect(ready.view.temperature.display, '21°');
  });

  test('failure with no data -> fullscreen HomeFailure', () async {
    weather.error = const NetworkUnreachableFailure();
    final ProviderContainer container = _container(
      weather: weather,
      location: location,
      settings: settings,
      settingsController: settingsController,
      online: Stream<bool>.value(true),
    );
    addTearDown(container.dispose);

    container.read(homeControllerProvider);
    await _flush();
    expect(container.read(homeControllerProvider), isA<HomeFailure>());
  });

  test('failure with data -> banner over data (US-9 AC3)', () async {
    weather.result = WeatherResult(
        forecast: _forecast(), hit: CacheHit.network, age: Duration.zero);
    final ProviderContainer container = _container(
      weather: weather,
      location: location,
      settings: settings,
      settingsController: settingsController,
      online: Stream<bool>.value(true),
    );
    addTearDown(container.dispose);

    container.read(homeControllerProvider);
    await _flush();
    expect(container.read(homeControllerProvider), isA<HomeReady>());

    weather.error = const ServerErrorFailure(503);
    await container.read(homeControllerProvider.notifier).refresh();

    final HomeScreenState state = container.read(homeControllerProvider);
    expect(state, isA<HomeReady>());
    expect((state as HomeReady).bannerFailure, isA<ServerErrorFailure>());
  });

  test('429 -> banner + ONE scheduled retry (R-12)', () {
    fakeAsync((FakeAsync async) {
      weather.error =
          RateLimitedFailure(retryAfter: const Duration(seconds: 10));
      final ProviderContainer container = _container(
        weather: weather,
        location: location,
        settings: settings,
        settingsController: settingsController,
        online: Stream<bool>.value(true),
      );
      addTearDown(container.dispose);

      container.read(homeControllerProvider);
      async.flushMicrotasks();
      expect(container.read(homeControllerProvider), isA<HomeFailure>());

      // The scheduled retry fires once at t+10 s.
      weather.error = null;
      weather.result = WeatherResult(
          forecast: _forecast(), hit: CacheHit.network, age: Duration.zero);
      async.elapse(const Duration(seconds: 10));
      async.flushMicrotasks();
      expect(container.read(homeControllerProvider), isA<HomeReady>());
      expect(weather.getForecastCalls, 2);

      // A second consecutive 429 schedules nothing more (episode budget 1).
      weather.error =
          RateLimitedFailure(retryAfter: const Duration(seconds: 10));
      container.read(homeControllerProvider.notifier).retry();
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 30));
      async.flushMicrotasks();
      // Manual retry (1) + its single auto-retry (1) = 2 more calls, no more.
      expect(weather.getForecastCalls, 4);
    });
  });

  test('unit toggle rebuilds the view with zero network (US-12 AC2)', () async {
    weather.result = WeatherResult(
        forecast: _forecast(), hit: CacheHit.network, age: Duration.zero);
    final ProviderContainer container = _container(
      weather: weather,
      location: location,
      settings: settings,
      settingsController: settingsController,
      online: Stream<bool>.value(true),
    );
    addTearDown(container.dispose);

    container.read(homeControllerProvider);
    await _flush();
    expect((container.read(homeControllerProvider) as HomeReady)
        .view
        .temperature
        .display, '21°');
    final int calls = weather.getForecastCalls;

    settingsController.setUnits(UnitSystem.imperial);
    // The controller debounces unit rebuilds by 300 ms (FM-20).
    await Future<void>.delayed(const Duration(milliseconds: 400));

    expect((container.read(homeControllerProvider) as HomeReady)
        .view
        .temperature
        .display, '70°');
    expect(weather.getForecastCalls, calls); // no network
  });

  test('no saved place -> HomeNeedsLocationChoice', () async {
    when(() => location.savedPlace).thenReturn(null);
    final ProviderContainer container = _container(
      weather: weather,
      location: location,
      settings: settings,
      settingsController: settingsController,
      online: Stream<bool>.value(true),
    );
    addTearDown(container.dispose);

    container.read(homeControllerProvider);
    await _flush();
    expect(container.read(homeControllerProvider),
        isA<HomeNeedsLocationChoice>());
  });
}

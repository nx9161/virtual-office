// Entry point.
//
// Init order (binding):
//   1. SharedPreferences (settings, consent state, recents fallbacks)
//   2. Hive (forecast cache + recent places boxes)
//   3. SettingsStore (locale-derived unit fallback, R-11)
//   4. Sentry — crash-only, and ONLY after the R-17 first-run disclosure has
//      been shown (crashDisclosureSeen) and the user has not opted out.
//      The DSN comes from --dart-define=SENTRY_DSN (EU DSN, owner action C3).
//   5. Flutter error handlers -> Sentry (no raw DioException capture, R-2)
//   6. ProviderScope: R-9 DI composition — abstract repository providers from
//      domain/ are bound to implementations here. Nothing else in the app
//      may construct repositories.

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/app.dart';
import 'package:weather_app/core/logging/app_logger.dart';
import 'package:weather_app/core/telemetry/sentry_service.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/data/datasources/local/forecast_cache.dart';
import 'package:weather_app/data/datasources/local/recent_places_store.dart';
import 'package:weather_app/data/datasources/local/settings_store.dart';
import 'package:weather_app/data/di/data_providers.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/repositories/place_repository.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. SharedPreferences.
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  // 2. Hive boxes (forecast cache + recent places).
  await Hive.initFlutter();
  final ForecastCache forecastCache = ForecastCache();
  await forecastCache.init();
  final RecentPlacesStore recentPlaces = RecentPlacesStore();
  await recentPlaces.init();

  // 3. Settings (locale-derived unit fallback per R-11).
  final UnitSystem fallbackUnits = UnitSystem.fromLocaleCode(
      PlatformDispatcher.instance.locale.countryCode);
  final SettingsStore settings =
      await SettingsStore.init(prefs, fallbackUnits: fallbackUnits);

  // 4. Sentry: crash-only, gated on the R-17 first-run disclosure.
  await SentryService.init(
    optOut: settings.crashReportingOptOut,
    crashDisclosureSeen: settings.crashDisclosureSeen,
  );

  // 5. Error handlers (R-2/B-2: captureFailure maps a raw DioException to
  //    AppFailure FIRST — a runtime guard, in release as well as debug —
  //    so no transport object ever reaches Sentry).
  FlutterError.onError = (FlutterErrorDetails details) {
    if (SentryService.isInitialized) {
      SentryService.captureFailure(
          details.exception, details.stack ?? StackTrace.empty);
    } else {
      AppLogger.error('flutter-error', details.exception);
    }
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    if (SentryService.isInitialized) {
      SentryService.captureFailure(error, stack);
    } else {
      AppLogger.error('platform-error', error);
    }
    return true;
  };

  // 6. R-9 composition root.
  runApp(
    ProviderScope(
      overrides: <Override>[
        weatherRepositoryProvider.overrideWith(buildWeatherRepository),
        placeRepositoryProvider.overrideWith(buildPlaceRepository),
        locationRepositoryProvider.overrideWith(buildLocationRepository),
        settingsRepositoryProvider.overrideWithValue(settings),
        forecastCacheProvider.overrideWithValue(forecastCache),
        recentPlacesProvider.overrideWithValue(recentPlaces),
      ],
      child: const WeatherApp(),
    ),
  );
}

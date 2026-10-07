// Data-layer provider bindings (R-9 DI composition rule).
//
// Abstract repository providers are declared in domain/. These builder
// functions construct the implementations; main.dart binds them via
// ProviderScope overrides, and tests override them with fakes.
//
// NOTE (lint-driven): usecase providers live here, not in domain — domain
// must stay pure Dart (no flutter_riverpod import), so concrete providers
// that wire domain objects together belong to the composition layer.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:weather_app/core/network/connectivity_provider.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/data/datasources/device/location_datasource.dart';
import 'package:weather_app/data/datasources/device/reverse_geocode_datasource.dart';
import 'package:weather_app/data/datasources/local/forecast_cache.dart';
import 'package:weather_app/data/datasources/local/recent_places_store.dart';
import 'package:weather_app/data/datasources/remote/bigdatacloud_api.dart';
import 'package:weather_app/data/datasources/remote/forecast_api.dart';
import 'package:weather_app/data/datasources/remote/geocoding_api.dart';
import 'package:weather_app/data/repositories/location_repository_impl.dart';
import 'package:weather_app/data/repositories/place_repository_impl.dart';
import 'package:weather_app/data/repositories/weather_repository_impl.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/repositories/place_repository.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart';
import 'package:weather_app/domain/usecases/get_weather.dart';
import 'package:weather_app/domain/usecases/refresh_weather.dart';
import 'package:weather_app/domain/usecases/resolve_device_location.dart';
import 'package:weather_app/domain/usecases/search_places.dart';
import 'package:weather_app/domain/usecases/update_settings.dart';

// --- repository implementations (bound via overrides in main.dart) ---

WeatherRepository buildWeatherRepository(Ref ref) => WeatherRepositoryImpl(
      api: ref.watch(forecastApiProvider),
      cache: ref.watch(forecastCacheProvider),
      clock: ref.watch(clockProvider),
      // C-10.7 offline fast-path: when the connectivity signal is unknown,
      // assume online (the network attempt fails fast and falls back).
      isOnline: () => ref.read(isOnlineProvider).value ?? true,
    );

PlaceRepository buildPlaceRepository(Ref ref) => PlaceRepositoryImpl(
      api: ref.watch(geocodingApiProvider),
      recents: ref.watch(recentPlacesProvider),
      clock: ref.watch(clockProvider),
    );

LocationRepository buildLocationRepository(Ref ref) => LocationRepositoryImpl(
      location: LocationDataSource(),
      geocode: ReverseGeocodeDataSource(ref.watch(bigDataCloudApiProvider)),
      settings: ref.watch(settingsRepositoryProvider),
      weather: ref.watch(weatherRepositoryProvider),
      clock: ref.watch(clockProvider),
    );

// --- usecases (concrete; presentation calls these) ---

final getWeatherProvider = Provider<GetWeather>(
  (ref) => GetWeather(
    ref.watch(weatherRepositoryProvider),
    ref.watch(locationRepositoryProvider),
  ),
);

final refreshWeatherProvider = Provider<RefreshWeather>(
  (ref) => RefreshWeather(ref.watch(getWeatherProvider)),
);

final searchPlacesProvider = Provider<SearchPlaces>(
  (ref) => SearchPlaces(ref.watch(placeRepositoryProvider)),
);

final resolveDeviceLocationProvider = Provider<ResolveDeviceLocation>(
  (ref) => ResolveDeviceLocation(ref.watch(locationRepositoryProvider)),
);

final updateSettingsProvider = Provider<UpdateSettings>(
  (ref) => UpdateSettings(ref.watch(settingsRepositoryProvider)),
);

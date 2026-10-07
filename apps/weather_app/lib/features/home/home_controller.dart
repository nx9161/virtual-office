// HomeController: plain Notifier<HomeScreenState> (R-8 / ADR-14), keepAlive.
//
// Responsibilities:
//  * boot routing: saved place -> load; device-sourced saved place ->
//    re-resolve via OS (ADR-07: name only persisted); none -> needsLocationChoice
//  * TTL ladder via GetWeather; SWR background revalidate (silent update)
//  * banner-vs-fullscreen error rule (R-8): fullscreen only with no data
//  * 429: immediate banner + single scheduled auto-retry (R-12), countdown in
//    the widget, cancellable on dispose (AC-2)
//  * reconnect: single auto-retry per false->true transition, only for
//    connectivity failures (HIGH-1.3)
//  * unit toggle: rebuilds the view from the cached entity — zero network
//    (US-12 AC2); debounced 300 ms (FM-20)

import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/config/app_providers.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/error_mapper.dart';
import 'package:weather_app/core/error/failure_presentation.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/network/connectivity_provider.dart';
import 'package:weather_app/core/telemetry/sentry_service.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/core/units/weather_formatter.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/data/di/data_providers.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/domain/entities/forecast.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart';
import 'package:weather_app/features/common/announcer.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/features/settings/settings_controller.dart';
import 'package:weather_app/features/settings/settings_state.dart';

class HomeController extends Notifier<HomeScreenState> {
  bool _disposed = false;
  Timer? _rateLimitTimer;
  Timer? _unitDebounce;
  int _auto429Retries = 0;
  AppFailure? _lastFailure;

  GeoPlace? _place;
  CacheSource _source = CacheSource.search;
  int? _deviceGeneration;
  WeatherResult? _lastResult; // last good entity (unit-toggle rebuilds)

  @override
  HomeScreenState build() {
    ref.onDispose(() {
      _disposed = true;
      _rateLimitTimer?.cancel();
      _unitDebounce?.cancel();
    });
    // Auto-retry on reconnect: single attempt per false->true transition,
    // only when the last failure was a connectivity failure (HIGH-1.3).
    // The listen subscription is closed automatically on dispose.
    ref.listen<AsyncValue<bool>>(isOnlineProvider,
        (AsyncValue<bool>? prev, AsyncValue<bool> next) {
      final bool? was = prev?.valueOrNull;
      final bool? isNow = next.valueOrNull;
      if (was == false && isNow == true) _onReconnect();
    });
    // Unit toggle: rebuild the display view from the cached entity —
    // zero network, debounced 300 ms (US-12 AC2, FM-20).
    ref.listen<UnitSystem>(
      settingsControllerProvider.select((SettingsState s) => s.unitSystem),
      (_, __) {
        _unitDebounce?.cancel();
        _unitDebounce =
            Timer(AppConstants.unitToggleDebounce, _rebuildViewFromCache);
      },
    );
    Future.microtask(_boot);
    return const HomeFirstLoad();
  }

  // --- boot ---

  Future<void> _boot() async {
    if (_disposed) return;
    final LocationRepository location = ref.read(locationRepositoryProvider);
    final SettingsRepository settings = ref.read(settingsRepositoryProvider);
    final GeoPlace? saved = location.savedPlace;
    if (saved == null) {
      state = const HomeNeedsLocationChoice();
      return;
    }
    if (settings.savedPlaceIsDeviceSourced) {
      await _loadDeviceLocation();
    } else {
      _place = saved;
      _source = CacheSource.search;
      _deviceGeneration = null;
      await _load();
    }
  }

  Future<void> _loadDeviceLocation() async {
    final LocationRepository location = ref.read(locationRepositoryProvider);
    // AC-7: consent AND a live OS grant are both required.
    if (location.consentState != ConsentState.granted) {
      state = const HomeNeedsLocationChoice();
      return;
    }
    state = const HomeFirstLoad();
    try {
      final GeoPlace place =
          await ref.read(resolveDeviceLocationProvider).call();
      if (_disposed) return;
      await location.savePlace(place, deviceSourced: true);
      _place = place;
      _source = CacheSource.deviceLocation;
      _deviceGeneration = location.deviceGeneration;
      await _load();
    } on AppFailure catch (f) {
      if (!_disposed) _handleFailure(f, hasData: false);
    } catch (e) {
      if (!_disposed) _handleFailure(mapToFailure(e), hasData: false);
    }
  }

  // --- load ---

  Future<void> _load({bool forceRefresh = false}) async {
    final GeoPlace? place = _place;
    if (place == null) {
      state = const HomeNeedsLocationChoice();
      return;
    }
    final bool hadData = state is HomeReady;
    if (hadData) {
      state = (state as HomeReady)
          .copyWith(isRefreshing: true, clearBanner: true);
    } else {
      state = const HomeFirstLoad();
    }
    try {
      final WeatherResult? result = forceRefresh
          ? await ref
              .read(refreshWeatherProvider)
              .call(place: place, source: _source)
          : await ref
              .read(getWeatherProvider)
              .call(place: place, source: _source);
      if (_disposed) return;
      if (result == null) return; // dropped (revocation) — not a failure
      _lastFailure = null;
      _auto429Retries = 0;
      _applyResult(result);
      if (result.hit == CacheHit.swrStale) {
        final WeatherResult? fresh = await ref
            .read(weatherRepositoryProvider)
            .revalidateInBackground(
              place: place,
              source: _source,
              deviceGeneration: _deviceGeneration,
            );
        if (_disposed || fresh == null) return;
        _lastResult = fresh;
        _applyResult(fresh);
      }
    } on AppFailure catch (f) {
      if (!_disposed) _handleFailure(f, hasData: hadData);
    } catch (e) {
      if (!_disposed) _handleFailure(mapToFailure(e), hasData: hadData);
    }
  }

  void _applyResult(WeatherResult result) {
    _lastResult = result;
    final UnitSystem units =
        ref.read(settingsControllerProvider).unitSystem;
    final Locale locale = ref.read(localeProvider);
    final Clock clock = ref.read(clockProvider);
    final WeatherFormatter formatter = WeatherFormatter(
      units: units,
      locale: locale,
      clock: clock,
    );
    final ForecastView view = ForecastViewMapper.toView(
      result.forecast,
      formatter,
      isDeviceLocation: _source == CacheSource.deviceLocation,
      nowUtc: clock.now().toUtc(),
    );
    final Staleness staleness = switch (result.hit) {
      CacheHit.network || CacheHit.fresh => const Staleness.fresh(),
      CacheHit.swrStale => Staleness.stale(result.age),
      CacheHit.offlineStale => Staleness.offlineStale(result.age),
    };
    state = HomeReady(view: view, staleness: staleness);
  }

  void _rebuildViewFromCache() {
    final WeatherResult? result = _lastResult;
    if (_disposed || result == null || state is! HomeReady) return;
    _applyResult(result);
  }

  // --- failures ---

  void _handleFailure(AppFailure f, {required bool hasData}) {
    _lastFailure = f;
    if (f is RateLimitedFailure) {
      _handleRateLimited(f, hasData: hasData);
      return;
    }
    if (hasData && state is HomeReady) {
      // US-9 AC3: banner over data, never a fullscreen replacement.
      state =
          (state as HomeReady).copyWith(isRefreshing: false, bannerFailure: f);
      Announcer.announceError(FailurePresentationMapper.map(f).headline);
      return;
    }
    _fallbackOrFailure(f);
  }

  Future<void> _fallbackOrFailure(AppFailure f) async {
    final GeoPlace? place = _place;
    if (place != null) {
      // PRD US-10: cached ≤24 h renders with an offline banner.
      final WeatherResult? stale = await ref
          .read(weatherRepositoryProvider)
          .getStaleFallback(place);
      if (_disposed) return;
      if (stale != null) {
        _applyResult(stale);
        state = (state as HomeReady).copyWith(bannerFailure: f);
        Announcer.announceError(FailurePresentationMapper.map(f).headline);
        return;
      }
    }
    state = HomeFailure(f);
    Announcer.announceError(FailurePresentationMapper.map(f).headline);
  }

  void _handleRateLimited(RateLimitedFailure f, {required bool hasData}) {
    // AC-2: 429 telemetry (breadcrumb + counter; host only, never the URI).
    SentryService.breadcrumbRateLimited('api.open-meteo.com');
    if (hasData && state is HomeReady) {
      state =
          (state as HomeReady).copyWith(isRefreshing: false, bannerFailure: f);
    } else {
      state = HomeFailure(f);
    }
    Announcer.announceError(
        FailurePresentationMapper.map(f).headline);
    // R-12: ONE scheduled auto-retry per episode (B-7 budget), cancellable
    // on dispose. A second consecutive 429 leaves the banner + manual Retry.
    _rateLimitTimer?.cancel();
    if (_auto429Retries >= AppConstants.maxAutoRetriesAfter429) return;
    final Duration wait = f.retryAfter ?? const Duration(seconds: 5);
    _rateLimitTimer = Timer(wait, () {
      if (_disposed) return;
      _auto429Retries++;
      _load(forceRefresh: true);
    });
  }

  void _onReconnect() {
    final AppFailure? last = _lastFailure;
    if (last is NetworkUnreachableFailure || last is TimeoutFailure) {
      _load(forceRefresh: true);
    }
  }

  // --- public actions (widgets) ---

  /// Retry button: manual retry resets the 429 episode budget.
  Future<void> retry() async {
    _auto429Retries = 0;
    _rateLimitTimer?.cancel();
    await _load(forceRefresh: true);
  }

  /// Pull-to-refresh. The widget checks connectivity first and shows the
  /// explanatory snackbar when offline (design §3.1); this double-checks.
  Future<void> refresh() async {
    final bool online = ref.read(isOnlineProvider).valueOrNull ?? true;
    if (!online) return;
    await _load(forceRefresh: true);
  }

  /// A place was chosen (search selection or device flow).
  Future<void> selectPlace(GeoPlace place, {required bool deviceSourced}) async {
    final LocationRepository location = ref.read(locationRepositoryProvider);
    await location.savePlace(place, deviceSourced: deviceSourced);
    _place = place;
    _source = deviceSourced ? CacheSource.deviceLocation : CacheSource.search;
    _deviceGeneration = deviceSourced ? location.deviceGeneration : null;
    _lastFailure = null;
    _lastResult = null;
    await _load();
  }

  /// After revocation: the repository restored the last searched city (or
  /// nothing) — reload from the saved place.
  Future<void> reloadAfterRevoke() async {
    final GeoPlace? saved = ref.read(locationRepositoryProvider).savedPlace;
    _place = saved;
    _source = CacheSource.search;
    _deviceGeneration = null;
    _lastFailure = null;
    _lastResult = null;
    if (saved == null) {
      state = const HomeNeedsLocationChoice();
      return;
    }
    await _load();
  }

  /// Test hook: current place.
  GeoPlace? get currentPlace => _place;

  /// Dismisses the non-blocking error banner.
  void clearBanner() {
    if (state is HomeReady) {
      state = (state as HomeReady).copyWith(clearBanner: true);
    }
  }
}

/// keepAlive: the root screen; survives tab switches (provider lifecycle rule).
final homeControllerProvider =
    NotifierProvider<HomeController, HomeScreenState>(HomeController.new);

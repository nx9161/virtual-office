// SettingsController: keepAlive, user prefs (S-5).
//
// Responsibilities:
//  * unit/theme/crash toggles -> SettingsRepository (unit writes debounced
//    300 ms at the home consumer; writes here are immediate — cheap local I/O)
//  * "Use device location" toggle: ON re-triggers the consent sheet
//    (design §3.5); OFF revokes in-app immediately per US-3 AC3 / Tech Law
//    (one-tap withdrawal — this overrides the §3.5 deep-link-only text)
//  * "Delete local data": erasure path (recents + forecast cache + prefs)
//  * the live OS permission query: indeterminate shimmer capped at 1 s
//    (MEDIUM-8) -> disabled toggle, never a stuck shimmer

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/telemetry/sentry_service.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/repositories/place_repository.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart';
import 'package:weather_app/features/home/home_controller.dart';
import 'package:weather_app/features/settings/settings_state.dart';

class SettingsController extends Notifier<SettingsState> {
  bool _disposed = false;

  SettingsRepository get _settings => ref.read(settingsRepositoryProvider);
  LocationRepository get _location => ref.read(locationRepositoryProvider);

  @override
  SettingsState build() {
    ref.onDispose(() => _disposed = true);
    final AppSettings s = _settings.settings;
    Future.microtask(_refreshPermissionState);
    return SettingsState(
      unitSystem: s.unitSystem,
      themeMode: s.themeMode,
      consentState: s.consentState,
      osPermission: null, // pending -> shimmer (capped at 1 s)
      locationEnabled: _settings.savedPlaceIsDeviceSourced &&
          s.consentState == ConsentState.granted,
      crashReportingEnabled: !s.crashReportingOptOut,
      appVersionLabel: '1.0.0',
      savedPlaceLabel: _placeLabel(_settings.savedPlace),
    );
  }

  static String? _placeLabel(GeoPlace? place) => place?.displayName;

  /// Live OS query, capped at 1 s: after the cap the toggle renders disabled
  /// rather than shimmering forever (MEDIUM-8).
  Future<void> _refreshPermissionState() async {
    try {
      final OsPermissionStatus status = await _location
          .checkPermission()
          .timeout(const Duration(seconds: 1));
      if (_disposed) return;
      state = state.copyWith(
        osPermission: status,
        locationEnabled:
            state.locationEnabled && status == OsPermissionStatus.granted,
      );
    } on TimeoutException {
      if (_disposed) return;
      state = state.copyWith(osPermission: OsPermissionStatus.unableToDetermine);
    }
  }

  Future<void> setTempUnit(TempUnit unit) async {
    await _settings
        .setUnitSystem(state.unitSystem.withTemperature(unit));
    if (!_disposed) {
      state = state.copyWith(unitSystem: _settings.settings.unitSystem);
    }
  }

  Future<void> setWindUnit(WindUnit unit) async {
    await _settings.setUnitSystem(state.unitSystem.withWind(unit));
    if (!_disposed) {
      state = state.copyWith(unitSystem: _settings.settings.unitSystem);
    }
  }

  Future<void> setPressureUnit(PressureUnit unit) async {
    await _settings.setUnitSystem(state.unitSystem.withPressure(unit));
    if (!_disposed) {
      state = state.copyWith(unitSystem: _settings.settings.unitSystem);
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    await _settings.setThemeMode(mode);
    if (!_disposed) state = state.copyWith(themeMode: mode);
  }

  /// Toggling OFF: immediate in-app revocation (US-3 AC3 / Tech Law 7(3)):
  /// coordinates dropped, device cache deleted, saved place cleared,
  /// falls back to the last searched city.
  ///
  /// Toggling ON is handled by the settings SCREEN directly via the consent
  /// controller (kept out of this controller to avoid a settings→consent→
  /// home→settings import cycle).
  Future<void> revokeLocation() async {
    state = state.copyWith(busy: true);
    await _location.revokeConsent();
    await ref.read(homeControllerProvider.notifier).reloadAfterRevoke();
    if (_disposed) return;
    final AppSettings s = _settings.settings;
    state = state.copyWith(
      consentState: s.consentState,
      locationEnabled: false,
      savedPlaceLabel: _placeLabel(_settings.savedPlace),
      clearPlaceLabel: _settings.savedPlace == null,
      busy: false,
    );
  }

  /// Crash-reporting toggle: OFF stops the reporter AND deletes queued
  /// reports on the device (B-7).
  Future<void> setCrashReporting(bool enabled) async {
    await _settings.setCrashReportingOptOut(!enabled);
    await SentryService.setOptOut(!enabled);
    if (!_disposed) state = state.copyWith(crashReportingEnabled: enabled);
  }

  /// "Delete local data" erasure path (Tech Law C2 §7 + backend C-10.10):
  /// recents + forecast cache + all preferences. The crash opt-out is
  /// deliberately preserved by resetToDefaults.
  Future<void> deleteLocalData() async {
    state = state.copyWith(busy: true);
    await ref.read(placeRepositoryProvider).clearRecents();
    await ref.read(weatherRepositoryProvider).clearCache();
    await _settings.resetToDefaults();
    await ref.read(homeControllerProvider.notifier).reloadAfterRevoke();
    if (_disposed) return;
    final AppSettings s = _settings.settings;
    state = state.copyWith(
      unitSystem: s.unitSystem,
      themeMode: s.themeMode,
      consentState: s.consentState,
      locationEnabled: false,
      crashReportingEnabled: !s.crashReportingOptOut,
      savedPlaceLabel: _placeLabel(_settings.savedPlace),
      clearPlaceLabel: _settings.savedPlace == null,
      busy: false,
    );
  }

  /// Refreshes derived rows (called after the search sheet closes).
  void refreshPlaceRows() {
    if (_disposed) return;
    final AppSettings s = _settings.settings;
    state = state.copyWith(
      savedPlaceLabel: _placeLabel(_settings.savedPlace),
      clearPlaceLabel: _settings.savedPlace == null,
      locationEnabled: _settings.savedPlaceIsDeviceSourced &&
          s.consentState == ConsentState.granted,
    );
  }

  /// Test hook.
  OsPermissionStatus? get osPermission => state.osPermission;
}

/// keepAlive: prefs survive navigation; the screen re-opens to current values.
final settingsControllerProvider =
    NotifierProvider<SettingsController, SettingsState>(
        SettingsController.new);

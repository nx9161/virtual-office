// LocationRepositoryImpl: consent state machine + device location.
//
// Consent flow (§4.3 + HIGH-1 fixes):
//  * consentFlowStep persisted (idle | sheetShown | osPromptPending) so the
//    flow survives backgrounding at the OS dialog — resume via
//    resumeIfPending() on foreground.
//  * 30-day suppression for in-app declines (C4); OS-denied never re-prompts
//    (FM-7) — the two are distinct states, checked separately.
//  * Revocation (R-13): bumps the device generation (delegated to the weather
//    repo — single source), cancels in-flight device requests, drops the
//    in-memory coords, deletes the stored device city, deletes
//    device-sourced cache entries by hash.
//  * DevicePosition is memory-only: held in [_position], cleared after the
//    resolve chain, on revocation, and never serialized.

import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/data/datasources/device/location_datasource.dart';
import 'package:weather_app/data/datasources/device/reverse_geocode_datasource.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart';

class LocationRepositoryImpl implements LocationRepository {
  final LocationDataSource _location;
  final ReverseGeocodeDataSource _geocode;
  final SettingsRepository _settings;
  final WeatherRepository _weather;
  final Clock _clock;

  DevicePosition? _position; // memory-only, never serialized

  LocationRepositoryImpl({
    required LocationDataSource location,
    required ReverseGeocodeDataSource geocode,
    required SettingsRepository settings,
    required WeatherRepository weather,
    required Clock clock,
  })  : _location = location,
        _geocode = geocode,
        _settings = settings,
        _weather = weather,
        _clock = clock;

  // --- consent (persisted) ---

  @override
  ConsentState get consentState => _settings.settings.consentState;

  @override
  ConsentFlowStep get consentFlowStep => _settings.settings.consentFlowStep;

  @override
  DateTime? get consentDeclinedAt => _settings.settings.consentDeclinedAt;

  @override
  Future<void> setConsentFlowStep(ConsentFlowStep step) async {
    final AppSettings s = _settings.settings;
    await _settings.updateSettings(s.copyWith(consentFlowStep: step));
  }

  @override
  Future<void> grantConsent() async {
    final AppSettings s = _settings.settings;
    await _settings.updateSettings(s.copyWith(
      consentState: ConsentState.granted,
      consentFlowStep: ConsentFlowStep.idle,
      clearDeclinedAt: true,
    ));
  }

  @override
  Future<void> declineConsent() async {
    final AppSettings s = _settings.settings;
    await _settings.updateSettings(s.copyWith(
      consentState: ConsentState.declined,
      consentFlowStep: ConsentFlowStep.idle,
      consentDeclinedAt: _clock.now().toUtc(),
    ));
  }

  @override
  Future<void> recordOsDenied() async {
    final AppSettings s = _settings.settings;
    await _settings.updateSettings(s.copyWith(
      consentState: ConsentState.osDenied,
      consentFlowStep: ConsentFlowStep.idle,
    ));
  }

  @override
  bool get canPromptForConsent =>
      _settings.settings.canPromptForConsent(_clock.now().toUtc());

  @override
  Future<void> revokeConsent() async {
    // R-13: generation bump + cancel FIRST, so in-flight device requests
    // can never repopulate what we are about to wipe.
    _weather.bumpDeviceGeneration();
    _position = null; // US-11 AC2: in-memory coords cleared immediately
    await _weather.deleteDeviceSourcedCache();
    await _settings.setSavedPlace(null, deviceSourced: false);
    // US-3 AC3: fall back to the last searched city (or none -> the caller
    // routes to the search prompt).
    final GeoPlace? fallback = _settings.lastSearchPlace;
    if (fallback != null) {
      await _settings.setSavedPlace(fallback, deviceSourced: false);
    }
    final AppSettings s = _settings.settings;
    await _settings.updateSettings(s.copyWith(
      consentState: ConsentState.revoked,
      consentFlowStep: ConsentFlowStep.idle,
    ));
  }

  // --- platform permission (live) ---

  @override
  Future<bool> isServiceEnabled() => _location.isServiceEnabled();

  @override
  Future<OsPermissionStatus> checkPermission() => _location.checkPermission();

  @override
  Future<OsPermissionStatus> requestPermission() =>
      _location.requestPermission();

  // --- device fix -> place ---

  @override
  Future<DevicePosition> getDevicePosition() async {
    // AC-7 belt-and-braces: never return a fix without a live OS grant,
    // even if the caller already checked.
    final OsPermissionStatus p = await _location.checkPermission();
    if (p != OsPermissionStatus.granted) {
      throw const AppFailure.locationDenied();
    }
    final DevicePosition pos = await _location.getCurrentPosition();
    _position = pos;
    return pos;
  }

  @override
  Future<GeoPlace> resolveDevicePlace() async {
    final DevicePosition pos = await getDevicePosition();
    try {
      return await _geocode.reverseGeocode(pos);
    } finally {
      _position = null; // memory-only: discarded after the resolve chain
    }
  }

  // --- device request lifecycle (R-13; single-sourced in WeatherRepository) ---

  @override
  int get deviceGeneration => _weather.deviceGeneration;

  @override
  void cancelDeviceRequests() => _weather.cancelDeviceRequests();

  // --- saved place ---

  @override
  GeoPlace? get savedPlace => _settings.savedPlace;

  @override
  Future<void> savePlace(GeoPlace place, {required bool deviceSourced}) =>
      _settings.setSavedPlace(place, deviceSourced: deviceSourced);

  @override
  Future<void> clearSavedPlace() =>
      _settings.setSavedPlace(null, deviceSourced: false);

  @override
  Future<void> openAppSettings() => _location.openAppSettings();

  @override
  Future<void> openLocationSettings() => _location.openLocationSettings();
}

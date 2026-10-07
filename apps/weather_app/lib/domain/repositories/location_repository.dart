// LocationRepository — domain interface for consent + device location.
//
// Two legally distinct signals (Tech Law C4):
//  * ConsentState (in-app, persisted): unknown | granted | declined | revoked.
//  * OsPermissionStatus (platform, live): granted | denied | deniedForever.
// In-app decline -> 30-day suppression; OS denial -> never re-prompt (FM-7).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

/// Platform permission state, mapped from geolocator in the data layer.
/// (AC-1: mock-location detection is explicitly declined — documented non-issue.)
enum OsPermissionStatus { granted, denied, deniedForever, unableToDetermine }

abstract class LocationRepository {
  // --- consent (persisted) ---
  ConsentState get consentState;
  ConsentFlowStep get consentFlowStep;
  DateTime? get consentDeclinedAt;
  Future<void> setConsentFlowStep(ConsentFlowStep step);
  Future<void> grantConsent();
  Future<void> declineConsent();

  /// OS-level denial: records ConsentState.osDenied so the app never
  /// re-prompts in-app (FM-7) — the user must go through system settings.
  Future<void> recordOsDenied();

  /// C4: 30-day in-app-decline suppression. False while a recent in-app
  /// decline is still within its suppression window.
  bool get canPromptForConsent;

  /// R-13 revocation: clears in-memory coords, stored device city,
  /// device-sourced cache; bumps the device generation.
  Future<void> revokeConsent();

  // --- platform permission (live) ---
  Future<bool> isServiceEnabled();
  Future<OsPermissionStatus> checkPermission();
  Future<OsPermissionStatus> requestPermission();

  // --- device fix -> place (AC-7: requires a live OS grant, not just
  // ConsentState.granted — a granted consent + denied permission throws
  // locationDenied and NEVER issues a forecast call) ---
  Future<DevicePosition> getDevicePosition();
  Future<GeoPlace> resolveDevicePlace();

  // --- device request lifecycle (R-13) ---
  int get deviceGeneration;
  void cancelDeviceRequests();

  // --- saved place ---
  /// Null when nothing is saved. Device-sourced places carry name/country
  /// only (NO coordinates — ADR-07); search-sourced places carry 2-dp coords.
  GeoPlace? get savedPlace;
  Future<void> savePlace(GeoPlace place, {required bool deviceSourced});
  Future<void> clearSavedPlace();

  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

/// Domain-declared abstract provider — throws until overridden (R-9).
final locationRepositoryProvider = Provider<LocationRepository>(
  (ref) => throw UnimplementedError(
    'locationRepositoryProvider is not overridden. '
    'Bind the implementation via ProviderScope overrides in main.dart (R-9).',
  ),
);

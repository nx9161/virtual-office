// SettingsRepository — domain interface for durable preferences.
//
// Primitives live in SharedPreferences (ADR-13): unit system, theme, consent
// state/flow step, saved place (city name only for device-sourced — ADR-07),
// crash-reporting opt-out, privacy-notice-seen. NEVER coordinates (DoD#5).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

abstract class SettingsRepository {
  UnitSystem get unitSystem;
  Future<void> setUnitSystem(UnitSystem units);

  AppThemeMode get themeMode;
  Future<void> setThemeMode(AppThemeMode mode);

  AppSettings get settings;
  Future<void> updateSettings(AppSettings settings);

  GeoPlace? get savedPlace;
  Future<void> setSavedPlace(GeoPlace? place, {required bool deviceSourced});
  bool get savedPlaceIsDeviceSourced;

  /// Last search-selected city, updated on every search selection and NEVER
  /// overwritten by the device-location flow. Revocation falls back to this
  /// (US-3 AC3: "the last searched city (or search prompt if none)").
  GeoPlace? get lastSearchPlace;
  Future<void> setLastSearchPlace(GeoPlace place);

  bool get crashReportingOptOut;
  Future<void> setCrashReportingOptOut(bool optOut);

  bool get privacyNoticeSeen;
  Future<void> setPrivacyNoticeSeen(bool seen);

  /// R-17 first-run disclosure gate: the crash-reporting disclosure copy is
  /// shown on the welcome screen / consent sheet. Sentry may only initialize
  /// after this has been shown once AND the user has not opted out.
  bool get crashDisclosureSeen;
  Future<void> setCrashDisclosureSeen();

  /// "Delete local data" (Tech Law C6): clears recents, forecast cache is
  /// cleared by the caller via the repositories, and resets preferences to
  /// defaults — EXCEPT the crash-reporting opt-out (an explicit privacy
  /// choice that must survive) and privacyNoticeSeen.
  Future<void> resetToDefaults();

  /// Full wipe for tests.
  Future<void> clearAll();
}

/// Domain-declared abstract provider — throws until overridden (R-9).
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => throw UnimplementedError(
    'settingsRepositoryProvider is not overridden. '
    'Bind the implementation via ProviderScope overrides in main.dart (R-9).',
  ),
);

// SettingsStore: SharedPreferences-backed SettingsRepository (ADR-13).
//
// Primitives only: unit system, theme, consent state/flow step, saved place,
// crash-reporting opt-out, privacy-notice-seen. NEVER coordinates (DoD#5):
//  * the saved place stores the CITY NAME (+country/admin1) for
//    device-sourced places — no lat/lon (ADR-07);
//  * search-sourced places store public 2-dp place coords (US-13).

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/core/validation/validators.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';

class SettingsStore implements SettingsRepository {
  static const String _kUnitSystem = 'unit_system';
  static const String _kThemeMode = 'theme_mode';
  static const String _kConsentState = 'consent_state';
  static const String _kConsentFlowStep = 'consent_flow_step';
  static const String _kConsentDeclinedAt = 'consent_declined_at';
  static const String _kSavedPlace = 'saved_place';
  static const String _kSavedPlaceDeviceSourced = 'saved_place_device_sourced';
  static const String _kLastSearchPlace = 'last_search_place';
  static const String _kCrashOptOut = 'crash_reporting_opt_out';
  static const String _kPrivacyNoticeSeen = 'privacy_notice_seen';
  static const String _kCrashDisclosureSeen = 'crash_disclosure_seen';

  final SharedPreferences _prefs;
  final UnitSystem _fallbackUnits;

  SettingsStore._(this._prefs, this._fallbackUnits);

  /// [fallbackUnits] is the locale default (R-11), used until the user picks.
  static Future<SettingsStore> init(
    SharedPreferences prefs, {
    required UnitSystem fallbackUnits,
  }) async {
    return SettingsStore._(prefs, fallbackUnits);
  }

  // --- units / theme ---

  @override
  UnitSystem get unitSystem {
    final String? raw = _prefs.getString(_kUnitSystem);
    if (raw == null) return _fallbackUnits;
    return UnitSystem.deserialize(raw);
  }

  @override
  Future<void> setUnitSystem(UnitSystem units) =>
      _prefs.setString(_kUnitSystem, units.serialize());

  @override
  AppThemeMode get themeMode {
    final String? raw = _prefs.getString(_kThemeMode);
    for (final AppThemeMode m in AppThemeMode.values) {
      if (m.name == raw) return m;
    }
    return AppThemeMode.system;
  }

  @override
  Future<void> setThemeMode(AppThemeMode mode) =>
      _prefs.setString(_kThemeMode, mode.name);

  // --- consent ---

  @override
  AppSettings get settings => AppSettings(
        unitSystem: unitSystem,
        themeMode: themeMode,
        consentState: _consentState,
        consentFlowStep: _consentFlowStep,
        consentDeclinedAt: _consentDeclinedAt,
        crashReportingOptOut: crashReportingOptOut,
        privacyNoticeSeen: privacyNoticeSeen,
      );

  ConsentState get _consentState {
    final String? raw = _prefs.getString(_kConsentState);
    for (final ConsentState s in ConsentState.values) {
      if (s.name == raw) return s;
    }
    return ConsentState.unknown;
  }

  ConsentFlowStep get _consentFlowStep {
    final String? raw = _prefs.getString(_kConsentFlowStep);
    for (final ConsentFlowStep s in ConsentFlowStep.values) {
      if (s.name == raw) return s;
    }
    return ConsentFlowStep.idle;
  }

  DateTime? get _consentDeclinedAt {
    final String? raw = _prefs.getString(_kConsentDeclinedAt);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  @override
  Future<void> updateSettings(AppSettings s) async {
    await setUnitSystem(s.unitSystem);
    await setThemeMode(s.themeMode);
    await _prefs.setString(_kConsentState, s.consentState.name);
    await _prefs.setString(_kConsentFlowStep, s.consentFlowStep.name);
    if (s.consentDeclinedAt != null) {
      await _prefs.setString(
          _kConsentDeclinedAt, s.consentDeclinedAt!.toIso8601String());
    } else {
      await _prefs.remove(_kConsentDeclinedAt);
    }
    await setCrashReportingOptOut(s.crashReportingOptOut);
    await setPrivacyNoticeSeen(s.privacyNoticeSeen);
  }

  // --- saved place ---

  @override
  GeoPlace? get savedPlace {
    final String? raw = _prefs.getString(_kSavedPlace);
    if (raw == null) return null;
    try {
      final Object? json = jsonDecode(raw);
      if (json is! Map) return null;
      final Map<dynamic, dynamic> m = json;
      final Object? nameRaw = m['name'];
      if (nameRaw is! String || nameRaw.isEmpty) return null;
      final Object? admin1Raw = m['admin1'];
      final Object? countryRaw = m['country'];
      final Object? codeRaw = m['countryCode'];
      if (savedPlaceIsDeviceSourced) {
        // Device-sourced: name/country only, NO coordinates (ADR-07).
        // lat/lon 0,0 is a sentinel that must NEVER reach the network —
        // the controller re-resolves via the OS when this flag is set.
        return GeoPlace(
          name: nameRaw,
          admin1: admin1Raw is String && admin1Raw.isNotEmpty ? admin1Raw : null,
          country: countryRaw is String && countryRaw.isNotEmpty
              ? countryRaw
              : '—',
          countryCode:
              codeRaw is String && codeRaw.length == 2 ? codeRaw : null,
          lat: 0,
          lon: 0,
        );
      }
      final double? lat = asDouble(m['lat']);
      final double? lon = asDouble(m['lon']);
      if (lat == null || lon == null) return null;
      return GeoPlace(
        name: nameRaw,
        admin1: admin1Raw is String && admin1Raw.isNotEmpty ? admin1Raw : null,
        country:
            countryRaw is String && countryRaw.isNotEmpty ? countryRaw : '—',
        countryCode: codeRaw is String && codeRaw.length == 2 ? codeRaw : null,
        lat: lat,
        lon: lon,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  bool get savedPlaceIsDeviceSourced =>
      _prefs.getBool(_kSavedPlaceDeviceSourced) ?? false;

  @override
  GeoPlace? get lastSearchPlace {
    final String? raw = _prefs.getString(_kLastSearchPlace);
    if (raw == null) return null;
    try {
      final Object? json = jsonDecode(raw);
      if (json is! Map) return null;
      final Map<dynamic, dynamic> m = json;
      final Object? nameRaw = m['name'];
      final double? lat = asDouble(m['lat']);
      final double? lon = asDouble(m['lon']);
      if (nameRaw is! String || nameRaw.isEmpty || lat == null || lon == null) {
        return null;
      }
      final Object? admin1Raw = m['admin1'];
      final Object? countryRaw = m['country'];
      final Object? codeRaw = m['countryCode'];
      return GeoPlace(
        name: nameRaw,
        admin1: admin1Raw is String && admin1Raw.isNotEmpty ? admin1Raw : null,
        country:
            countryRaw is String && countryRaw.isNotEmpty ? countryRaw : '—',
        countryCode: codeRaw is String && codeRaw.length == 2 ? codeRaw : null,
        lat: lat,
        lon: lon,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> setLastSearchPlace(GeoPlace place) =>
      _prefs.setString(_kLastSearchPlace, jsonEncode(place.toJson()));

  @override
  Future<void> setSavedPlace(GeoPlace? place,
      {required bool deviceSourced}) async {
    if (place == null) {
      await _prefs.remove(_kSavedPlace);
      await _prefs.remove(_kSavedPlaceDeviceSourced);
      return;
    }
    // Device-sourced: persist name/country/admin1 ONLY (ADR-07).
    final Map<String, Object?> json = deviceSourced
        ? <String, Object?>{
            'name': place.name,
            if (place.admin1 != null) 'admin1': place.admin1,
            'country': place.country,
            if (place.countryCode != null) 'countryCode': place.countryCode,
          }
        : place.toJson();
    await _prefs.setString(_kSavedPlace, jsonEncode(json));
    await _prefs.setBool(_kSavedPlaceDeviceSourced, deviceSourced);
  }

  // --- crash reporting / notice ---

  @override
  bool get crashReportingOptOut => _prefs.getBool(_kCrashOptOut) ?? false;

  @override
  Future<void> setCrashReportingOptOut(bool optOut) =>
      _prefs.setBool(_kCrashOptOut, optOut);

  @override
  bool get privacyNoticeSeen => _prefs.getBool(_kPrivacyNoticeSeen) ?? false;

  @override
  Future<void> setPrivacyNoticeSeen(bool seen) =>
      _prefs.setBool(_kPrivacyNoticeSeen, seen);

  @override
  bool get crashDisclosureSeen =>
      _prefs.getBool(_kCrashDisclosureSeen) ?? false;

  @override
  Future<void> setCrashDisclosureSeen() =>
      _prefs.setBool(_kCrashDisclosureSeen, true);

  // --- erasure (Tech Law C6) ---

  @override
  Future<void> resetToDefaults() async {
    await _prefs.remove(_kUnitSystem);
    await _prefs.remove(_kThemeMode);
    await _prefs.remove(_kConsentState);
    await _prefs.remove(_kConsentFlowStep);
    await _prefs.remove(_kConsentDeclinedAt);
    await _prefs.remove(_kSavedPlace);
    await _prefs.remove(_kSavedPlaceDeviceSourced);
    await _prefs.remove(_kLastSearchPlace);
    // Kept deliberately: the crash-reporting opt-out is an explicit privacy
    // choice that must survive "Delete local data"; privacyNoticeSeen and
    // crashDisclosureSeen keep the Sentry first-run gate (R-17) consistent.
  }

  @override
  Future<void> clearAll() async {
    await _prefs.clear();
  }
}

// App settings + consent state (domain-owned value objects).
//
// ConsentState: unknown | granted | declined | revoked — persisted in
// SharedPreferences; drives the pre-OS-prompt sheet (GDPR Art. 6(1)(a)).
// ConsentFlowStep: idle | sheetShown | osPromptPending — persisted so the
// flow survives app backgrounding at the OS dialog (HIGH-1.4).
//
// Re-prompt policy (Tech Law C4 — two legally distinct events):
//  * in-app decline -> 30-day suppression (persisted consentDeclinedAt);
//  * OS denial -> never re-prompt from the app (FM-7); settings deep-link only.

import 'package:weather_app/core/units/unit_system.dart';

enum ConsentState { unknown, granted, declined, revoked, osDenied }

enum ConsentFlowStep { idle, sheetShown, osPromptPending }

/// Domain-owned theme mode (NOT flutter's ThemeMode — domain stays pure).
enum AppThemeMode { system, light, dark }

/// In-memory device fix. Rounded to 2 dp at creation (ADR-07), NEVER
/// serialized (no toJson), never logged, never persisted — enforced by type
/// design. Discarded after the forecast call / on revocation / on mode-off.
final class DevicePosition {
  final double lat;
  final double lon;

  DevicePosition._(this.lat, this.lon);

  factory DevicePosition.rounded(double latitude, double longitude) {
    double r(double v) => (v * 100).round() / 100; // + normalizes -0.0
    return DevicePosition._(r(latitude), r(longitude));
  }

  // No toString override: the default does not print field values, and we
  // never want coordinates in a log line by accident.
}

class AppSettings {
  final UnitSystem unitSystem;
  final AppThemeMode themeMode;
  final ConsentState consentState;
  final ConsentFlowStep consentFlowStep;
  final DateTime? consentDeclinedAt;
  final bool crashReportingOptOut;
  final bool privacyNoticeSeen;

  const AppSettings({
    required this.unitSystem,
    required this.themeMode,
    required this.consentState,
    required this.consentFlowStep,
    required this.consentDeclinedAt,
    required this.crashReportingOptOut,
    required this.privacyNoticeSeen,
  });

  /// 30-day suppression for in-app declines (C4). OS-denied is handled
  /// separately via the live permission state (never re-prompt, FM-7).
  bool canPromptForConsent(DateTime now) {
    if (consentState == ConsentState.unknown) return true;
    if (consentState == ConsentState.declined && consentDeclinedAt != null) {
      return now.difference(consentDeclinedAt!).inDays >= 30;
    }
    return false;
  }

  AppSettings copyWith({
    UnitSystem? unitSystem,
    AppThemeMode? themeMode,
    ConsentState? consentState,
    ConsentFlowStep? consentFlowStep,
    DateTime? consentDeclinedAt,
    bool clearDeclinedAt = false,
    bool? crashReportingOptOut,
    bool? privacyNoticeSeen,
  }) {
    return AppSettings(
      unitSystem: unitSystem ?? this.unitSystem,
      themeMode: themeMode ?? this.themeMode,
      consentState: consentState ?? this.consentState,
      consentFlowStep: consentFlowStep ?? this.consentFlowStep,
      consentDeclinedAt:
          clearDeclinedAt ? null : (consentDeclinedAt ?? this.consentDeclinedAt),
      crashReportingOptOut: crashReportingOptOut ?? this.crashReportingOptOut,
      privacyNoticeSeen: privacyNoticeSeen ?? this.privacyNoticeSeen,
    );
  }
}

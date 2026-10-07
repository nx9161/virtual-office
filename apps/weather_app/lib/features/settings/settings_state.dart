// SettingsState: mostly-static screen (design §3.5 — settings read from
// local storage is synchronous; no loading state needed).
//
// osPermission is null while the live OS query is pending -> the toggle
// shows an indeterminate shimmer, capped at 1 s, then falls back to a
// disabled toggle (MEDIUM-8).

import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/domain/repositories/location_repository.dart'
    show OsPermissionStatus;

class SettingsState {
  final UnitSystem unitSystem;
  final AppThemeMode themeMode;
  final ConsentState consentState;
  final OsPermissionStatus? osPermission;
  final bool locationEnabled;
  final bool crashReportingEnabled;
  final String appVersionLabel;
  final String? savedPlaceLabel;
  final bool busy;

  const SettingsState({
    required this.unitSystem,
    required this.themeMode,
    required this.consentState,
    required this.osPermission,
    required this.locationEnabled,
    required this.crashReportingEnabled,
    required this.appVersionLabel,
    required this.savedPlaceLabel,
    this.busy = false,
  });

  SettingsState copyWith({
    UnitSystem? unitSystem,
    AppThemeMode? themeMode,
    ConsentState? consentState,
    OsPermissionStatus? osPermission,
    bool? locationEnabled,
    bool? crashReportingEnabled,
    String? appVersionLabel,
    String? savedPlaceLabel,
    bool clearPlaceLabel = false,
    bool? busy,
  }) {
    return SettingsState(
      unitSystem: unitSystem ?? this.unitSystem,
      themeMode: themeMode ?? this.themeMode,
      consentState: consentState ?? this.consentState,
      osPermission: osPermission ?? this.osPermission,
      locationEnabled: locationEnabled ?? this.locationEnabled,
      crashReportingEnabled: crashReportingEnabled ?? this.crashReportingEnabled,
      appVersionLabel: appVersionLabel ?? this.appVersionLabel,
      savedPlaceLabel:
          clearPlaceLabel ? null : (savedPlaceLabel ?? this.savedPlaceLabel),
      busy: busy ?? this.busy,
    );
  }
}

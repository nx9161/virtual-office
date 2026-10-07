// AppLocalizations — v1 English-only (PRD §10.6: all user-facing strings
// externalized; l10n-ready).
//
// Hand-written for v1 so the app compiles without the gen-l10n codegen step;
// lib/l10n/app_en.arb is the canonical translator source and MUST be kept in
// sync with this file until gen-l10n codegen is wired (then this file is
// replaced by the generated one).

import 'package:flutter/widgets.dart';
import 'package:weather_app/core/error/failure_presentation.dart';

class AppLocalizations {
  const AppLocalizations();

  static const AppLocalizations current = AppLocalizations();

  /// v1: English only. The BuildContext parameter reserves the locale lookup
  /// for the gen-l10n migration.
  static AppLocalizations of(BuildContext context) => current;

  // --- app ---
  String get appTitle => 'Weather';

  // --- failure actions ---
  String failureActionLabel(FailureAction action) => switch (action) {
        FailureAction.retry => 'Retry',
        FailureAction.openSystemSettings => 'Open settings',
        FailureAction.openLocationSettings => 'Open settings',
        FailureAction.searchInstead => 'Search for a city',
        FailureAction.useDeviceLocation => 'Use device location',
        FailureAction.dismiss => 'Dismiss',
        FailureAction.none => '',
      };
  String get dismiss => 'Dismiss';
  String get cancel => 'Cancel';
  String get close => 'Close';
  String retryIn(int seconds) => 'Retry in ${seconds}s';

  // --- home ---
  String get searchTooltip => 'Search';
  String get settingsTooltip => 'Settings';
  String get hourlySection => 'Hourly forecast';
  String get dailySection => '7-day forecast';
  String get seeAll => 'See all';
  String get changeLocation => 'Change location';
  String get deviceTimezoneNote => 'Times shown in device timezone';
  String get someHoursUnavailable => 'Some hours unavailable';
  String get hourlyUnavailable =>
      'Hourly data unavailable for this location right now.';
  String get dailyUnavailable =>
      'Daily data unavailable for this location right now.';
  String get backToCurrent => 'Back to current conditions';
  String get pullToRefreshOffline =>
      "You're offline — reconnect to refresh the weather.";
  String get refreshed => 'Weather updated';
  String get reviewSettings => 'Review settings';
  String get loadingWeather => 'Loading weather';

  // --- WMO labels (PRD Appendix A) ---
  String wmoLabel(int? code) => switch (code) {
        0 => 'Clear sky',
        1 => 'Mainly clear',
        2 => 'Partly cloudy',
        3 => 'Overcast',
        45 => 'Fog',
        48 => 'Depositing rime fog',
        51 => 'Light drizzle',
        53 => 'Moderate drizzle',
        55 => 'Dense drizzle',
        56 => 'Light freezing drizzle',
        57 => 'Dense freezing drizzle',
        61 => 'Slight rain',
        63 => 'Moderate rain',
        65 => 'Heavy rain',
        66 => 'Light freezing rain',
        67 => 'Heavy freezing rain',
        71 => 'Slight snow',
        73 => 'Moderate snow',
        75 => 'Heavy snow',
        77 => 'Snow grains',
        80 => 'Slight rain showers',
        81 => 'Moderate rain showers',
        82 => 'Violent rain showers',
        85 => 'Slight snow showers',
        86 => 'Heavy snow showers',
        95 => 'Thunderstorm',
        96 => 'Thunderstorm with slight hail',
        99 => 'Thunderstorm with heavy hail',
        _ => 'Unknown conditions',
      };
  String wmoIconLabel(int? code) => '${wmoLabel(code)} icon';

  // --- search ---
  String get chooseACity => 'Choose a city';
  String get searchCitiesHint => 'Search cities…';
  String get searchHintMinChars => 'Type at least 2 characters';
  String get recentSearches => 'Recent searches';
  String get clearRecents => 'Clear recents';
  String get useDeviceLocation => 'Use device location';
  String get coarsePrecisionOn => 'Coarse precision on';
  String get searchNeedsConnection =>
      'Search needs a connection — your recent searches still work.';
  String showingPlace(String name) => 'Showing $name';
  String get noRecentSearches => 'Search for any city to see its weather.';

  // --- settings ---
  String get settingsTitle => 'Settings';
  String get locationGroup => 'Location';
  String get savedCity => 'Saved city';
  String get notSet => 'Not set';
  String get locationPrecision => 'Location precision';
  String get locationPrecisionValue => 'Coarse — ~1 km (rounded coordinates)';
  String get locationPrecisionExplainer =>
      'When you use device location, your coordinates are rounded to about '
      '1 km before anything else happens. The precise fix never leaves your '
      'device, is never stored, and is discarded right after we fetch the '
      'weather. Only the nearest city name is kept.';
  String get unitsGroup => 'Units';
  String get temperature => 'Temperature';
  String get celsius => 'Celsius';
  String get fahrenheit => 'Fahrenheit';
  String get wind => 'Wind';
  String get windGusts => 'Wind gusts';
  String get humidity => 'Humidity';
  String get uvIndexLabel => 'UV index';
  String get precipAmount => 'Precipitation amount';
  String get precipProbability => 'Precipitation probability';
  String get cloudCover => 'Cloud cover';
  String get pressure => 'Pressure';
  String get sunrise => 'Sunrise';
  String get sunset => 'Sunset';
  String get uvIndexMax => 'UV max';
  String get precipProbabilityMax => 'Precipitation probability (max)';
  String get privacyGroup => 'Privacy';
  String get privacyNotice => 'Privacy notice';
  String get whatWeStore => 'What we store';
  String get whatWeStoreBody =>
      'We store only your chosen city name and your unit and theme '
      'preferences on this device. Precise coordinates are never stored.';
  String get deleteLocalData => 'Delete local data';
  String get deleteLocalDataTitle => 'Delete local data?';
  String get deleteLocalDataBody =>
      'This clears your saved city, recent searches, cached weather, and '
      'preferences on this device. This cannot be undone.';
  String get delete => 'Delete';
  String get dataDeleted => 'Local data deleted';
  String get crashReporting => 'Crash reporting';
  String get crashReportingBody =>
      'Help us fix crashes by sending anonymous crash reports. '
      'Crash data only — no tracking, no analytics. You can turn this off '
      'anytime; turning it off also deletes any queued reports.';
  String get aboutGroup => 'About';
  String get dataSource => 'Weather data by Open-Meteo.com';
  String appVersion(String v) => 'Version $v';
  String get openSettingsFailed =>
      "Couldn't open system settings — change location permission manually.";
  String get themeGroup => 'Appearance';
  String get theme => 'Theme';
  String get themeSystem => 'System';
  String get themeLight => 'Light';
  String get themeDark => 'Dark';
  String get locationOff => 'Off';
  String get locationOn => 'On';

  // --- consent / welcome ---
  String get welcomeTitle => 'Know the weather, your way';
  String get welcomeBody =>
      'Get live weather for your area or any city you search. '
      'Location is always optional — the app works fully without it.';
  String get useMyLocation => 'Use my location';
  String get chooseCityInstead => 'Choose a city instead';
  String get howWeHandleLocation => 'How we handle location data';
  String get consentTitle => 'Allow location access?';
  String get consentBody =>
      "We'll use your device location once to find nearby weather. We request "
      'coarse precision only (~1 km — coordinates are rounded before use), '
      'and we never store your precise coordinates — only the nearest city name.';
  List<String> get consentBullets => <String>[
        'Used only to fetch weather',
        'Coarse precision (~1 km, rounded)',
        'You can switch to a manual city anytime',
      ];
  String get allow => 'Allow';
  String get notNow => 'Not now';
  String get crashDisclosure =>
      'Crash reports are on by default (crash data only, no tracking). '
      'You can turn them off in Settings.';
  String get usingApproximateLocation => 'Using your approximate location';
  String get privacyNoticeLink => 'Privacy notice';

  // --- offline ---
  String offlineBanner(String detail) =>
      "You're offline. Showing last update from $detail.";
  String offlineBannerAnnouncement(String detail) =>
      "You're offline. Showing data from $detail.";

  // --- privacy notice (Tech Law C2: 12-section spec) ---
  String get privacyTitle => 'Privacy notice';
  String get privacyUpdated => 'Last updated: 6 October 2026';
  String privacySection1Title() => '1. Who we are';
  String privacySection1Body() =>
      'This app is published by [owner entity]. For privacy questions, '
      'contact [support email]. The app owner is the data controller for '
      'information the app handles.';
  String privacySection2Title() => '2. What we collect';
  String privacySection2Body() =>
      'Only if you opt in: your approximate location (coarse, about 1 km — '
      'coordinates are rounded on your device before use). The city, region '
      'and country name you choose or we derive. Cities you search for. Your '
      'preferences (units, theme). Anonymous crash reports (what they contain '
      'is described in section 11).';
  String privacySection3Title() => '3. What we never collect or store';
  String privacySection3Body() =>
      'We never collect or store your precise GPS coordinates, your location '
      'history, or background location (location is foreground-only). There '
      'are no accounts, no advertising identifiers, and no analytics SDKs.';
  String privacySection4Title() => '4. Why we use it (purpose and lawful basis)';
  String privacySection4Body() =>
      'Weather for your area: based on your consent (GDPR Art. 6(1)(a)) — '
      'you opt in, and you can withdraw anytime. Crash diagnostics: based on '
      'our legitimate interest in keeping the app stable (Art. 6(1)(f)). '
      'Preferences: needed for the app to function as you configured it.';
  String privacySection5Title() => '5. What is sent, and to whom';
  String privacySection5Body() =>
      'Rounded coordinates (about 1 km precision) or a city name are sent to '
      'Open-Meteo (open-meteo.com) for forecasts and city search — see their '
      'privacy policy. If on-device reverse geocoding fails, coarse rounded '
      'coordinates are sent to BigDataCloud (bigdatacloud.net) as a fallback '
      'to find your city name — see their privacy policy. Anonymous crash '
      'reports go to Sentry, hosted in the EU. No other third party receives '
      'your data.';
  String privacySection6Title() => '6. What stays on your device';
  String privacySection6Body() =>
      'Everything else stays on your device. There is no account, no sync, '
      'and no server of ours.';
  String privacySection7Title() => '7. How long we keep it';
  String privacySection7Body() =>
      'Coordinates: memory only, never stored — discarded after the weather '
      'is fetched, when you revoke location, or when the app closes. City '
      'name, recent searches and preferences: kept until you change them, '
      'clear them, or use "Delete local data". Cached weather: at most 24 '
      'hours. Crash reports: 90 days at Sentry.';
  String privacySection8Title() => '8. Your rights';
  String privacySection8Body() =>
      'You can access, correct or delete your data in the app: Settings lets '
      'you change units and theme, clear recent searches, delete all local '
      'data, and turn crash reporting off. You can withdraw location consent '
      'anytime with the in-app toggle or in your system settings. You also '
      'have the right to complain to your supervisory authority.';
  String privacySection9Title() => '9. How to revoke location access';
  String privacySection9Body() =>
      'Turn "Use device location" off in Settings (takes effect immediately: '
      'your in-memory coordinates are dropped, the saved city is cleared, and '
      'cached device-location weather is deleted), or revoke the permission '
      'in your system settings. The app keeps working fully with city search.';
  String privacySection10Title() => '10. No ads, no tracking, no sale of data';
  String privacySection10Body() =>
      'There are no ads, no tracking, no analytics SDKs, and we do not sell '
      'your data. Ever.';
  String privacySection11Title() => '11. Crash reporting';
  String privacySection11Body() =>
      'Crash reporting is on by default and sends crash data only (what '
      'crashed and technical device details — never your coordinates or '
      'search queries). You can turn it off in Settings; turning it off '
      'stops the reporter and deletes any queued reports on your device.';
  String privacySection12Title() => '12. Changes to this notice';
  String privacySection12Body() =>
      'We will update this notice when the app changes. The date at the top '
      'shows the latest version.';
}

// WMO weather-code -> icon mapping (presentation asset concern).
//
// Lives in presentation per the frontend review (icons are presentation
// assets); human labels come from AppLocalizations so the l10n path stays
// clean. Unknown codes -> neutral icon + "Unknown conditions" (FM-10);
// the icon NEVER carries meaning alone (design §6: always paired with text,
// marked decorative via WeatherIcon).

import 'package:flutter/material.dart';

abstract final class WeatherCodeMapper {
  /// Neutral, decorative icon for a WMO code. [isDay] selects day/night
  /// variants for clear/partly-cloudy only.
  static IconData iconFor(int? code, {required bool isDay}) {
    return switch (code) {
      0 => isDay ? Icons.wb_sunny : Icons.nightlight,
      1 => isDay ? Icons.wb_sunny : Icons.nightlight,
      2 => isDay ? Icons.wb_cloudy : Icons.nights_stay,
      3 => Icons.cloud,
      45 || 48 => Icons.cloud, // fog — label carries the meaning
      51 || 53 || 55 || 56 || 57 => Icons.grain, // drizzle
      61 || 63 || 65 || 66 || 67 => Icons.water_drop, // rain
      71 || 73 || 75 || 77 => Icons.ac_unit, // snow
      80 || 81 || 82 => Icons.water_drop, // rain showers
      85 || 86 => Icons.ac_unit, // snow showers
      95 || 96 || 99 => Icons.thunderstorm,
      _ => Icons.help_outline, // FM-10 degraded: neutral icon
    };
  }

  /// True when the code is in the PRD Appendix A set.
  static bool isKnown(int? code) => switch (code) {
        0 ||
        1 ||
        2 ||
        3 ||
        45 ||
        48 ||
        51 ||
        53 ||
        55 ||
        56 ||
        57 ||
        61 ||
        63 ||
        65 ||
        66 ||
        67 ||
        71 ||
        73 ||
        75 ||
        77 ||
        80 ||
        81 ||
        82 ||
        85 ||
        86 ||
        95 ||
        96 ||
        99 =>
          true,
        _ => false,
      };
}

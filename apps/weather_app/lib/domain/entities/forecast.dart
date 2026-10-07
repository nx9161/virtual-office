// Domain entities: canonical SI, always. (ADR-04)
//
// Tier-2-validated scalars are NULLABLE: a wrong-typed or out-of-range field
// degrades to null ("—" at render) while the entity is still constructed
// (R-1 two-tier validation; PRD §7.2 / US-4 AC3). The domain never holds
// display units — conversion happens at the presentation boundary.

import 'package:weather_app/domain/entities/geo_place.dart';

/// A complete, validated forecast for one place.
class Forecast {
  final GeoPlace place;
  final CurrentConditions current;
  final List<HourlyPoint> hourly; // up to 48 parsed entries (US-5/FM-17);
  // the view layer filters time >= current local hour and takes 24.
  final List<DailySummary> daily; // 7 entries (PRD US-6)
  final int? utcOffsetSeconds; // null -> device-tz fallback + label (FM-14)
  final String? timezone; // informational
  final DateTime fetchedAtUtc;

  const Forecast({
    required this.place,
    required this.current,
    required this.hourly,
    required this.daily,
    required this.utcOffsetSeconds,
    required this.timezone,
    required this.fetchedAtUtc,
  });
}

class CurrentConditions {
  final DateTime? time; // null -> device clock fallback (PRD §7.2)
  final double? temperatureC;
  final double? apparentTemperatureC;
  final int? weatherCode; // null/unknown -> "Unknown conditions" (FM-10)
  final double? humidityPct;
  final double? precipitationMm;
  final double? cloudCoverPct;
  final double? pressureHpa;
  final double? windSpeedKmh;
  final double? windDirectionDeg; // null -> compass label omitted
  final double? windGustsKmh;
  final int isDay; // 0/1; defaults to 1 on violation (PRD §7.2)

  const CurrentConditions({
    required this.time,
    required this.temperatureC,
    required this.apparentTemperatureC,
    required this.weatherCode,
    required this.humidityPct,
    required this.precipitationMm,
    required this.cloudCoverPct,
    required this.pressureHpa,
    required this.windSpeedKmh,
    required this.windDirectionDeg,
    required this.windGustsKmh,
    required this.isDay,
  });
}

class HourlyPoint {
  final DateTime time; // location-local wall clock (timezone=auto)
  final double? temperatureC;
  final double? precipitationProbabilityPct;
  final int? weatherCode;

  const HourlyPoint({
    required this.time,
    required this.temperatureC,
    required this.precipitationProbabilityPct,
    required this.weatherCode,
  });
}

class DailySummary {
  final DateTime date; // location-local date
  final double? tempMaxC;
  final double? tempMinC;
  final int? weatherCode;
  final DateTime? sunrise; // null -> omitted (PRD §7.2)
  final DateTime? sunset;
  final double? uvIndexMax;
  final double? precipitationProbabilityMaxPct;

  const DailySummary({
    required this.date,
    required this.tempMaxC,
    required this.tempMinC,
    required this.weatherCode,
    required this.sunrise,
    required this.sunset,
    required this.uvIndexMax,
    required this.precipitationProbabilityMaxPct,
  });
}

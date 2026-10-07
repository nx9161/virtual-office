// Home screen state (R-8 / ADR-14): sealed union via plain Notifier.
//
// Staleness is a PROPERTY of data, not a state. Full-screen error card only
// when there is NO data (first load / cache >24 h); otherwise errors are
// banners over data (US-9 AC3).

import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/units/weather_formatter.dart';
import 'package:weather_app/domain/entities/forecast.dart';

sealed class HomeScreenState {
  const HomeScreenState();
}

/// First load: full-screen skeleton.
final class HomeFirstLoad extends HomeScreenState {
  const HomeFirstLoad();
}

/// No location chosen: routes to the welcome screen (§4.3).
final class HomeNeedsLocationChoice extends HomeScreenState {
  const HomeNeedsLocationChoice();
}

/// Unreachable in practice (home always has a place or routes away);
/// kept so the union is complete for exhaustive switches.
final class HomeEmpty extends HomeScreenState {
  const HomeEmpty();
}

final class HomeReady extends HomeScreenState {
  final ForecastView view;
  final Staleness staleness;
  final bool isRefreshing;
  final AppFailure? bannerFailure;

  const HomeReady({
    required this.view,
    required this.staleness,
    this.isRefreshing = false,
    this.bannerFailure,
  });

  HomeReady copyWith({
    ForecastView? view,
    Staleness? staleness,
    bool? isRefreshing,
    AppFailure? bannerFailure,
    bool clearBanner = false,
  }) {
    return HomeReady(
      view: view ?? this.view,
      staleness: staleness ?? this.staleness,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      bannerFailure: clearBanner ? null : (bannerFailure ?? this.bannerFailure),
    );
  }
}

/// Full-screen error card: only when there is no data at all.
final class HomeFailure extends HomeScreenState {
  final AppFailure failure;

  const HomeFailure(this.failure);
}

/// Staleness as a data property (R-8). The age drives "Updated X min ago",
/// the >30 min warning color (design §3.1), and the offline banner copy.
sealed class Staleness {
  const Staleness();
  const factory Staleness.fresh() = FreshStaleness;
  const factory Staleness.stale(Duration age) = StaleStaleness;
  const factory Staleness.offlineStale(Duration age) = OfflineStaleStaleness;

  bool get isFresh => this is FreshStaleness;
}

final class FreshStaleness extends Staleness {
  const FreshStaleness();
}

final class StaleStaleness extends Staleness {
  final Duration age;
  const StaleStaleness(this.age);
}

final class OfflineStaleStaleness extends Staleness {
  final Duration age;
  const OfflineStaleStaleness(this.age);
}

// --- display-ready view (already converted to display units) ---

class HourlyViewPoint {
  final String timeLabel;
  final FormattedValue temp;
  final FormattedValue precipProbability;
  final int? weatherCode;

  const HourlyViewPoint({
    required this.timeLabel,
    required this.temp,
    required this.precipProbability,
    required this.weatherCode,
  });
}

class DailyViewPoint {
  final String weekday;
  final String date;
  final int? weatherCode;
  final FormattedValue tempMax;
  final FormattedValue tempMin;
  final FormattedValue precipProbability;
  // B3: per-day expansion content (design spec §3.4).
  final String sunriseLabel; // '—' when the API omitted sunrise
  final String sunsetLabel;
  final FormattedValue uvIndexMax;

  const DailyViewPoint({
    required this.weekday,
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.precipProbability,
    required this.sunriseLabel,
    required this.sunsetLabel,
    required this.uvIndexMax,
  });
}

class ForecastView {
  final String placeLabel;
  final bool isDeviceLocation;
  final DateTime fetchedAtUtc;
  final String updatedAgo;
  final String updatedTime;
  final bool deviceTimezoneFallback;
  final FormattedValue temperature;
  final FormattedValue feelsLike;
  final int? weatherCode;
  final bool isDay;
  final FormattedValue humidity;
  final FormattedValue precipitation;
  final FormattedValue precipProbability; // sourced from hourly[0] (MEDIUM-2)
  final FormattedValue uvIndex; // sourced from daily[0] (MEDIUM-3)
  final FormattedValue pressure;
  final FormattedValue cloudCover; // B2: US-4 AC2 cloud cover %
  final FormattedValue windSpeed;
  final FormattedValue windGusts;
  final String windCompass;
  final String windCompassWord;
  final List<HourlyViewPoint> hourly;
  /// B1/FM-17: true when the hourly slice has fewer than 24 entries
  /// (filtered from the current local hour) — the UI shows the
  /// "Some hours unavailable" section note. Never fabricated values.
  final bool hourlyPartial;
  final List<DailyViewPoint> daily;

  const ForecastView({
    required this.placeLabel,
    required this.isDeviceLocation,
    required this.fetchedAtUtc,
    required this.updatedAgo,
    required this.updatedTime,
    required this.deviceTimezoneFallback,
    required this.temperature,
    required this.feelsLike,
    required this.weatherCode,
    required this.isDay,
    required this.humidity,
    required this.precipitation,
    required this.precipProbability,
    required this.uvIndex,
    required this.pressure,
    required this.cloudCover,
    required this.windSpeed,
    required this.windGusts,
    required this.windCompass,
    required this.windCompassWord,
    required this.hourly,
    required this.hourlyPartial,
    required this.daily,
  });
}

/// Pure entity -> view mapping (unit-testable).
abstract final class ForecastViewMapper {
  static ForecastView toView(
    Forecast forecast,
    WeatherFormatter formatter, {
    required bool isDeviceLocation,
    DateTime? nowUtc,
  }) {
    final CurrentConditions c = forecast.current;
    // B1 (US-5 AC1): the hourly slice starts at the CURRENT LOCAL HOUR of
    // the location, not at 00:00 day 0. [nowUtc] defaults to the device
    // clock; the controller passes the injected Clock.
    final List<HourlyPoint> upcomingHours = _upcomingFromCurrentHour(
      forecast.hourly,
      forecast.utcOffsetSeconds,
      nowUtc: nowUtc,
    );
    final HourlyPoint? firstHour =
        upcomingHours.isNotEmpty ? upcomingHours.first : null;
    final DailySummary? firstDay =
        forecast.daily.isNotEmpty ? forecast.daily.first : null;
    final String placeLabel = isDeviceLocation &&
            forecast.place.name == 'Current location'
        ? 'Current location'
        : forecast.place.displayName;
    return ForecastView(
      placeLabel: placeLabel,
      isDeviceLocation: isDeviceLocation,
      fetchedAtUtc: forecast.fetchedAtUtc,
      updatedAgo: formatter.updatedAgoLabel(forecast.fetchedAtUtc),
      updatedTime: formatter.locationTimeLabel(
        forecast.fetchedAtUtc,
        utcOffsetSeconds: forecast.utcOffsetSeconds,
      ),
      deviceTimezoneFallback: forecast.utcOffsetSeconds == null,
      temperature: formatter.formatTemp(c.temperatureC),
      feelsLike: formatter.formatFeelsLike(c.apparentTemperatureC),
      weatherCode: c.weatherCode,
      isDay: c.isDay == 1,
      humidity: formatter.formatPercent(c.humidityPct, 'humidity'),
      precipitation: formatter.formatPrecipitation(c.precipitationMm),
      precipProbability: formatter.formatPercent(
        firstHour?.precipitationProbabilityPct,
        'precipitation probability',
      ),
      uvIndex: formatter.formatUvIndex(firstDay?.uvIndexMax),
      pressure: formatter.formatPressure(c.pressureHpa),
      cloudCover: formatter.formatPercent(c.cloudCoverPct, 'cloud cover'),
      windSpeed: formatter.formatWindSpeed(c.windSpeedKmh),
      windGusts: formatter.formatWindSpeed(c.windGustsKmh),
      windCompass: WeatherFormatter.compassLabel(c.windDirectionDeg),
      windCompassWord:
          WeatherFormatter.compassWord(
              WeatherFormatter.compassLabel(c.windDirectionDeg)),
      hourly: <HourlyViewPoint>[
        for (final HourlyPoint p in upcomingHours)
          HourlyViewPoint(
            timeLabel: formatter.hourLabel(
              _isoLocal(p.time),
            ),
            temp: formatter.formatTemp(p.temperatureC),
            precipProbability: formatter.formatPercent(
              p.precipitationProbabilityPct,
              'precipitation probability',
            ),
            weatherCode: p.weatherCode,
          ),
      ],
      hourlyPartial:
          upcomingHours.length < AppConstants.hourlyEntryCount,
      daily: <DailyViewPoint>[
        for (final DailySummary d in forecast.daily)
          DailyViewPoint(
            weekday: formatter.dayLabels(d.date).weekday,
            date: formatter.dayLabels(d.date).date,
            weatherCode: d.weatherCode,
            tempMax: formatter.formatTemp(d.tempMaxC),
            tempMin: formatter.formatTemp(d.tempMinC),
            precipProbability: formatter.formatPercent(
              d.precipitationProbabilityMaxPct,
              'precipitation probability',
            ),
            sunriseLabel:
                d.sunrise == null ? '—' : formatter.hourLabel(_isoLocal(d.sunrise)),
            sunsetLabel:
                d.sunset == null ? '—' : formatter.hourLabel(_isoLocal(d.sunset)),
            uvIndexMax: formatter.formatUvIndex(d.uvIndexMax),
          ),
      ],
    );
  }

  /// Filters [hours] to entries at or after the start of the current local
  /// hour of the location, then takes 24 (US-5 AC1).
  ///
  /// Location-local wall clock is derived from [nowUtc] + [utcOffsetSeconds];
  /// when the offset is absent (FM-14) the device timezone is used — the
  /// same fallback the rest of the view applies. Comparisons are done on
  /// naive wall-clock fields (hourly times are location-local wall clock,
  /// never converted), so no DST/zone arithmetic can shift a slot.
  static List<HourlyPoint> _upcomingFromCurrentHour(
    List<HourlyPoint> hours,
    int? utcOffsetSeconds, {
    DateTime? nowUtc,
  }) {
    final DateTime anchor = (nowUtc ?? DateTime.now().toUtc()).toUtc();
    final DateTime locationNow = utcOffsetSeconds == null
        ? anchor.toLocal()
        : anchor.add(Duration(seconds: utcOffsetSeconds));
    final DateTime hourStart = DateTime(
      locationNow.year,
      locationNow.month,
      locationNow.day,
      locationNow.hour,
    );
    return hours
        .where((HourlyPoint p) => !p.time.isBefore(hourStart))
        .take(AppConstants.hourlyEntryCount)
        .toList();
  }

  static String _isoLocal(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)}T${two(dt.hour)}:${two(dt.minute)}';
  }
}

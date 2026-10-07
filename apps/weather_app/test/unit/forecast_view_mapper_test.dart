// ForecastViewMapper: US-5 AC1 hourly slice (B1), FM-17 partial flag,
// US-4 AC2 cloud cover (B2), daily sunrise/sunset (B3).

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/core/units/weather_formatter.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/domain/entities/forecast.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/features/home/home_state.dart';

GeoPlace _place() => GeoPlace(
      name: 'Berlin',
      admin1: null,
      country: 'Germany',
      countryCode: 'DE',
      lat: 52.52,
      lon: 13.41,
    );

CurrentConditions _current({double? cloudCoverPct}) => CurrentConditions(
      time: DateTime(2026, 10, 6, 14, 0),
      temperatureC: 21.0,
      apparentTemperatureC: 20.0,
      weatherCode: 1,
      humidityPct: 55.0,
      precipitationMm: 0.0,
      cloudCoverPct: cloudCoverPct,
      pressureHpa: 1015.0,
      windSpeedKmh: 14.0,
      windDirectionDeg: 90.0,
      windGustsKmh: 22.0,
      isDay: 1,
    );

/// 48 hourly points starting at day-1 00:00 (the API's day-0 array shape);
/// entry at hour h has precipitation probability h % (identifies slicing).
List<HourlyPoint> _hours48() => <HourlyPoint>[
      for (int i = 0; i < 48; i++)
        HourlyPoint(
          time: DateTime(2026, 10, 6).add(Duration(hours: i)),
          temperatureC: 20.0,
          precipitationProbabilityPct: (i % 24).toDouble(),
          weatherCode: 1,
        ),
    ];

List<DailySummary> _days() => <DailySummary>[
      DailySummary(
        date: DateTime(2026, 10, 6),
        tempMaxC: 22.0,
        tempMinC: 12.0,
        weatherCode: 1,
        sunrise: DateTime(2026, 10, 6, 7, 12),
        sunset: DateTime(2026, 10, 6, 18, 47),
        uvIndexMax: 4.0,
        precipitationProbabilityMaxPct: 20.0,
      ),
    ];

Forecast _forecast({List<HourlyPoint>? hourly, double? cloudCoverPct}) =>
    Forecast(
      place: _place(),
      current: _current(cloudCoverPct: cloudCoverPct),
      hourly: hourly ?? _hours48(),
      daily: _days(),
      utcOffsetSeconds: 7200,
      timezone: 'Europe/Berlin',
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
    );

WeatherFormatter _formatter() => WeatherFormatter(
      units: UnitSystem.metric,
      locale: const Locale('en', 'US'),
      clock: FakeClock(DateTime.utc(2026, 10, 6, 12, 0)),
    );

void main() {
  test('B1: hourly strip starts at the current local hour (US-5 AC1)', () {
    // nowUtc 14:30Z + 7200s offset -> location-local 16:30 -> slice from
    // 16:00, 24 entries (16:00 day 1 .. 15:00 day 2).
    final ForecastView view = ForecastViewMapper.toView(
      _forecast(),
      _formatter(),
      isDeviceLocation: false,
      nowUtc: DateTime.utc(2026, 10, 6, 14, 30),
    );
    expect(view.hourly, hasLength(24));
    expect(view.hourly.first.timeLabel, '4:00 PM');
    expect(view.hourlyPartial, isFalse);
  });

  test('B1: precip probability stays sourced from hourly[0] (the slice)', () {
    // The sliced first entry is 16:00 day 1 -> probability 16%.
    final ForecastView view = ForecastViewMapper.toView(
      _forecast(),
      _formatter(),
      isDeviceLocation: false,
      nowUtc: DateTime.utc(2026, 10, 6, 14, 30),
    );
    expect(view.precipProbability.display, '16%');
  });

  test('B1/FM-17: fewer than 24 remaining -> partial slice, flag set', () {
    // nowUtc 12:30Z day 2 + offset -> location-local 14:30 day 2:
    // only 14:00..23:00 remain (10 entries) — render them, never pad.
    final ForecastView view = ForecastViewMapper.toView(
      _forecast(),
      _formatter(),
      isDeviceLocation: false,
      nowUtc: DateTime.utc(2026, 10, 7, 12, 30),
    );
    expect(view.hourly, hasLength(10));
    expect(view.hourly.first.timeLabel, '2:00 PM');
    expect(view.hourlyPartial, isTrue);
  });

  test('B1: exactly 24 remaining -> not partial', () {
    // nowUtc 22:30Z day 1 + offset -> location-local 00:30 day 2:
    // all 24 day-2 entries remain.
    final ForecastView view = ForecastViewMapper.toView(
      _forecast(),
      _formatter(),
      isDeviceLocation: false,
      nowUtc: DateTime.utc(2026, 10, 6, 22, 30),
    );
    expect(view.hourly, hasLength(24));
    expect(view.hourlyPartial, isFalse);
  });

  test('B1: null utc offset (FM-14) falls back without throwing', () {
    final Forecast base = _forecast();
    final Forecast noOffset = Forecast(
      place: base.place,
      current: base.current,
      hourly: base.hourly,
      daily: base.daily,
      utcOffsetSeconds: null,
      timezone: null,
      fetchedAtUtc: base.fetchedAtUtc,
    );
    final ForecastView view = ForecastViewMapper.toView(
      noOffset,
      _formatter(),
      isDeviceLocation: true,
      nowUtc: DateTime.utc(2026, 10, 6, 14, 30),
    );
    expect(view.deviceTimezoneFallback, isTrue);
    expect(view.hourly.length, lessThanOrEqualTo(24));
  });

  test('B2: cloud cover mapped to the view (US-4 AC2)', () {
    final ForecastView view = ForecastViewMapper.toView(
      _forecast(cloudCoverPct: 40.0),
      _formatter(),
      isDeviceLocation: false,
      nowUtc: DateTime.utc(2026, 10, 6, 14, 30),
    );
    expect(view.cloudCover.display, '40%');
    expect(view.windGusts.display, '22 km/h');
    expect(view.precipitation.display, '0.0 mm');
    expect(view.pressure.display, '1015 hPa');
  });

  test('B2: missing cloud cover degrades to em dash', () {
    final ForecastView view = ForecastViewMapper.toView(
      _forecast(),
      _formatter(),
      isDeviceLocation: false,
      nowUtc: DateTime.utc(2026, 10, 6, 14, 30),
    );
    expect(view.cloudCover.display, '—');
  });

  test('B3: daily view carries sunrise/sunset/UV max (US-6 AC2)', () {
    final ForecastView view = ForecastViewMapper.toView(
      _forecast(),
      _formatter(),
      isDeviceLocation: false,
      nowUtc: DateTime.utc(2026, 10, 6, 14, 30),
    );
    final DailyViewPoint day = view.daily.single;
    expect(day.sunriseLabel, '7:12 AM');
    expect(day.sunsetLabel, '6:47 PM');
    expect(day.uvIndexMax.display, '4');
    expect(day.precipProbability.display, '20%');
  });
}

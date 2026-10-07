// Shared widget-test scaffolding: stub controllers + a canned ForecastView.

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/config/app_providers.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/network/connectivity_provider.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/core/units/weather_formatter.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/features/home/home_controller.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/features/settings/settings_controller.dart';
import 'package:weather_app/features/settings/settings_state.dart';

class StubHomeController extends HomeController {
  HomeScreenState stub;

  StubHomeController(this.stub);

  @override
  HomeScreenState build() => stub; // no boot side effects

  @override
  Future<void> retry() async {}

  @override
  Future<void> refresh() async {}

  @override
  void clearBanner() {}
}

class StubSettingsController extends SettingsController {
  final SettingsState stub;

  StubSettingsController(this.stub);

  @override
  SettingsState build() => stub;
}

SettingsState testSettingsState() => const SettingsState(
      unitSystem: UnitSystem.metric,
      themeMode: AppThemeMode.system,
      consentState: ConsentState.unknown,
      osPermission: null,
      locationEnabled: false,
      crashReportingEnabled: true,
      appVersionLabel: '1.0.0',
      savedPlaceLabel: null,
    );

FormattedValue _v(String display, String label) =>
    FormattedValue(display, label);

ForecastView testView() => ForecastView(
      placeLabel: 'Berlin, Germany',
      isDeviceLocation: false,
      fetchedAtUtc: DateTime.utc(2026, 10, 6, 12, 0),
      updatedAgo: '4 min ago',
      updatedTime: '14:00',
      deviceTimezoneFallback: false,
      temperature: _v('21°', '21 degrees Celsius'),
      feelsLike: _v('20°', '20 degrees Celsius'),
      weatherCode: 1,
      isDay: true,
      humidity: _v('55%', '55 percent humidity'),
      precipitation: _v('0.0 mm', '0 millimeters precipitation'),
      precipProbability: _v('10%', '10 percent precipitation probability'),
      uvIndex: _v('4', 'UV index 4'),
      pressure: _v('1015 hPa', '1015 hectopascals'),
      cloudCover: _v('40%', '40 percent cloud cover'),
      windSpeed: _v('14 km/h', '14 kilometers per hour'),
      windGusts: _v('22 km/h', '22 kilometers per hour'),
      windCompass: 'E',
      windCompassWord: 'east',
      hourly: <HourlyViewPoint>[
        HourlyViewPoint(
          timeLabel: '12:00',
          temp: _v('21°', '21 degrees Celsius'),
          precipProbability: _v('10%', '10 percent'),
          weatherCode: 1,
        ),
      ],
      hourlyPartial: false,
      daily: <DailyViewPoint>[
        DailyViewPoint(
          weekday: 'Tue',
          date: 'Oct 6',
          weatherCode: 1,
          tempMax: _v('22°', '22 degrees Celsius'),
          tempMin: _v('12°', '12 degrees Celsius'),
          precipProbability: _v('20%', '20 percent'),
          sunriseLabel: '7:42 AM',
          sunsetLabel: '6:51 PM',
          uvIndexMax: _v('4', 'UV index 4'),
        ),
      ],
    );

List<Override> baseOverrides({bool online = true}) => <Override>[
      localeProvider.overrideWithValue(const Locale('en', 'US')),
      clockProvider
          .overrideWithValue(FakeClock(DateTime.utc(2026, 10, 6, 12, 30))),
      isOnlineProvider.overrideWith(
          (Ref ref) => Stream<bool>.value(online)),
    ];

AppFailure networkFailure() => const NetworkUnreachableFailure();

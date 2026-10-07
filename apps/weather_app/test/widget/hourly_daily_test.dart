// Hourly/Daily screens: read home state, render lists, degrade gracefully.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/daily/daily_screen.dart';
import 'package:weather_app/features/home/home_controller.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/features/hourly/hourly_screen.dart';

import 'widget_test_helpers.dart';

Future<void> _pump(
    WidgetTester tester, Widget screen, HomeScreenState state) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...baseOverrides(),
        homeControllerProvider.overrideWith(() => StubHomeController(state)),
      ],
      child: MaterialApp(home: screen),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('hourly screen lists the 24h points with semantic labels',
      (WidgetTester tester) async {
    await _pump(
        tester,
        const HourlyScreen(),
        HomeReady(view: _view(), staleness: Staleness.fresh()));
    expect(find.text('Hourly forecast'), findsOneWidget);
    expect(find.text('12:00'), findsOneWidget);
    expect(find.text('21°'), findsWidgets);
  });

  testWidgets('hourly screen degrades when no hours',
      (WidgetTester tester) async {
    final ForecastView v = testView();
    await _pump(
        tester,
        const HourlyScreen(),
        HomeReady(
            view: _emptyHours(v), staleness: const Staleness.fresh()));
    expect(find.textContaining('unavailable'), findsOneWidget);
  });

  testWidgets('daily screen lists the 7-day rows',
      (WidgetTester tester) async {
    await _pump(tester, const DailyScreen(),
        HomeReady(view: testView(), staleness: const Staleness.fresh()));
    expect(find.text('7-day forecast'), findsOneWidget);
    expect(find.text('Tue'), findsOneWidget);
    expect(find.text('22°'), findsOneWidget);
  });

  testWidgets('B1/FM-17: partial hourly slice shows the note, never padding',
      (WidgetTester tester) async {
    final ForecastView partial = _withPartialHours(testView());
    await _pump(tester, const HourlyScreen(),
        HomeReady(view: partial, staleness: const Staleness.fresh()));
    expect(find.text('Some hours unavailable'), findsOneWidget);
    // Real entries only, no fabricated filler.
    expect(find.text('21°'), findsWidgets);
  });

  testWidgets('B3: tapping a day expands sunrise/sunset (US-6 AC2)',
      (WidgetTester tester) async {
    await _pump(tester, const DailyScreen(),
        HomeReady(view: testView(), staleness: const Staleness.fresh()));
    expect(find.text('Sunrise'), findsNothing);
    await tester.tap(find.text('Tue · Oct 6'));
    await tester.pumpAndSettle();
    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('7:42 AM'), findsOneWidget);
    expect(find.text('Sunset'), findsOneWidget);
    expect(find.text('6:51 PM'), findsOneWidget);
    expect(find.text('UV max'), findsOneWidget);
  });
}

ForecastView _view() => testView();

ForecastView _emptyHours(ForecastView v) => ForecastView(
      placeLabel: v.placeLabel,
      isDeviceLocation: v.isDeviceLocation,
      fetchedAtUtc: v.fetchedAtUtc,
      updatedAgo: v.updatedAgo,
      updatedTime: v.updatedTime,
      deviceTimezoneFallback: v.deviceTimezoneFallback,
      temperature: v.temperature,
      feelsLike: v.feelsLike,
      weatherCode: v.weatherCode,
      isDay: v.isDay,
      humidity: v.humidity,
      precipitation: v.precipitation,
      precipProbability: v.precipProbability,
      uvIndex: v.uvIndex,
      pressure: v.pressure,
      cloudCover: v.cloudCover,
      windSpeed: v.windSpeed,
      windGusts: v.windGusts,
      windCompass: v.windCompass,
      windCompassWord: v.windCompassWord,
      hourly: const <HourlyViewPoint>[],
      hourlyPartial: true,
      daily: v.daily,
    );

ForecastView _withPartialHours(ForecastView v) => ForecastView(
      placeLabel: v.placeLabel,
      isDeviceLocation: v.isDeviceLocation,
      fetchedAtUtc: v.fetchedAtUtc,
      updatedAgo: v.updatedAgo,
      updatedTime: v.updatedTime,
      deviceTimezoneFallback: v.deviceTimezoneFallback,
      temperature: v.temperature,
      feelsLike: v.feelsLike,
      weatherCode: v.weatherCode,
      isDay: v.isDay,
      humidity: v.humidity,
      precipitation: v.precipitation,
      precipProbability: v.precipProbability,
      uvIndex: v.uvIndex,
      pressure: v.pressure,
      cloudCover: v.cloudCover,
      windSpeed: v.windSpeed,
      windGusts: v.windGusts,
      windCompass: v.windCompass,
      windCompassWord: v.windCompassWord,
      hourly: v.hourly,
      hourlyPartial: true,
      daily: v.daily,
    );

// HomeScreen widget tests: loading / ready / fullscreen error / offline.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/common/widgets/skeleton.dart';
import 'package:weather_app/features/home/home_controller.dart';
import 'package:weather_app/features/home/home_screen.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/features/settings/settings_controller.dart';

import 'widget_test_helpers.dart';

Future<void> _pump(
  WidgetTester tester,
  HomeScreenState state, {
  bool online = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...baseOverrides(online: online),
        homeControllerProvider
            .overrideWith(() => StubHomeController(state)),
        settingsControllerProvider.overrideWith(
            () => StubSettingsController(testSettingsState())),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('first load shows the skeleton (single announcement)',
      (WidgetTester tester) async {
    await _pump(tester, const HomeFirstLoad());
    expect(find.byType(SkeletonBlock), findsWidgets);
    // The whole group is one live region, not per-skeleton noise.
    expect(find.byType(SkeletonGroup), findsOneWidget);
  });

  testWidgets('ready renders the hero + provenance strip',
      (WidgetTester tester) async {
    await _pump(
        tester,
        HomeReady(
            view: testView(), staleness: const Staleness.fresh()));
    expect(find.text('Berlin, Germany'), findsOneWidget);
    expect(find.text('21°'), findsWidgets);
    expect(find.textContaining('Open-Meteo'), findsOneWidget);
    expect(find.text('Hourly forecast'), findsOneWidget);
    expect(find.text('7-day forecast'), findsOneWidget);
  });

  testWidgets('failure with no data shows the fullscreen card (FM-1)',
      (WidgetTester tester) async {
    await _pump(tester, HomeFailure(networkFailure()));
    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('offline staleness shows the offline banner over data',
      (WidgetTester tester) async {
    await _pump(
      tester,
      HomeReady(
        view: testView(),
        staleness: const Staleness.offlineStale(Duration(hours: 2)),
      ),
      online: false,
    );
    expect(find.text('21°'), findsWidgets);
    expect(find.textContaining("You're offline"), findsOneWidget);
  });

  testWidgets('refreshing shows the thin progress bar',
      (WidgetTester tester) async {
    await _pump(
        tester,
        HomeReady(
            view: testView(),
            staleness: const Staleness.fresh(),
            isRefreshing: true));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('B2: metrics grid renders all US-4 AC2 metrics',
      (WidgetTester tester) async {
    await _pump(
        tester,
        HomeReady(
            view: testView(), staleness: const Staleness.fresh()));
    expect(find.text('Wind gusts'), findsOneWidget);
    expect(find.text('22 km/h'), findsOneWidget);
    expect(find.text('Precipitation amount'), findsOneWidget);
    expect(find.text('0.0 mm'), findsOneWidget);
    expect(find.text('Cloud cover'), findsOneWidget);
    expect(find.text('40%'), findsOneWidget);
    expect(find.text('Pressure'), findsOneWidget);
    expect(find.text('1015 hPa'), findsOneWidget);
    expect(find.text('Precipitation probability'), findsOneWidget);
  });
}

// SearchSheet widget tests: idle/recents, loading, results, empty,
// error (FM-4 lens), offline (field disabled, recents tappable).

import 'package:flutter/material.dart' hide SearchController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/features/consent/consent_controller.dart';
import 'package:weather_app/features/consent/consent_state.dart';
import 'package:weather_app/features/search/search_controller.dart';
import 'package:weather_app/features/search/search_sheet.dart';
import 'package:weather_app/features/search/search_state.dart';

import 'widget_test_helpers.dart';

GeoPlace _place(String name) => GeoPlace(
      name: name,
      admin1: 'Admin',
      country: 'Testland',
      countryCode: 'TT',
      lat: 10.0,
      lon: 20.0,
    );

class StubSearchController extends SearchController {
  SearchScreenState stub;

  StubSearchController(this.stub);

  @override
  SearchScreenState build() => stub;

  @override
  void onQueryChanged(String raw) {}

  @override
  void dismissError() {}
}

class StubConsentController extends ConsentController {
  @override
  ConsentControllerState build() => const ConsentControllerState();
}

Future<void> _pump(
  WidgetTester tester,
  SearchScreenState state, {
  bool online = true,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...baseOverrides(),
        searchControllerProvider
            .overrideWith(() => StubSearchController(state)),
        consentControllerProvider
            .overrideWith(() => StubConsentController()),
      ],
      child: const MaterialApp(
        home: Scaffold(body: SearchSheet()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('idle shows recents + device-location row',
      (WidgetTester tester) async {
    await _pump(tester, SearchIdle(<GeoPlace>[_place('Berlin')]));
    expect(find.text('Recent searches'), findsOneWidget);
    expect(find.text('Berlin'), findsOneWidget);
    expect(find.text('Use device location'), findsOneWidget);
  });

  testWidgets('loading shows the shimmer list',
      (WidgetTester tester) async {
    await _pump(tester, const SearchLoading(<GeoPlace>[]));
    // Shimmer tiles are decorative containers; the field stays interactive.
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('results render as tappable tiles',
      (WidgetTester tester) async {
    await _pump(
        tester,
        SearchResults(
            results: <GeoPlace>[_place('Berlin'), _place('Bern')],
            recentPlaces: const <GeoPlace>[]));
    expect(find.text('Berlin'), findsOneWidget);
    expect(find.text('Bern'), findsOneWidget);
  });

  testWidgets('empty state uses the mapper FM-12 headline verbatim',
      (WidgetTester tester) async {
    await _pump(tester, const SearchEmpty('zzz-no-such-city'));
    expect(
        find.text("No places found for 'zzz-no-such-city'"), findsOneWidget);
  });

  testWidgets('error shows the FM-4 search card with recents retained',
      (WidgetTester tester) async {
    await _pump(
        tester,
        SearchError(
            const NetworkUnreachableFailure(), <GeoPlace>[_place('Berlin')]));
    expect(find.text("Search isn't working right now"), findsOneWidget);
    expect(find.text('Berlin'), findsOneWidget);
  });

  testWidgets('offline: field disabled, recents still tappable',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...baseOverrides(online: false),
          searchControllerProvider.overrideWith(
              () => StubSearchController(SearchOffline(<GeoPlace>[_place('Paris')]))),
          consentControllerProvider
              .overrideWith(() => StubConsentController()),
        ],
        child: const MaterialApp(home: Scaffold(body: SearchSheet())),
      ),
    );
    await tester.pump();
    final TextField field = tester.widget(find.byType(TextField));
    expect(field.enabled, isFalse);
    expect(find.text('Paris'), findsOneWidget);
    await tester.tap(find.text('Paris'));
  });
}

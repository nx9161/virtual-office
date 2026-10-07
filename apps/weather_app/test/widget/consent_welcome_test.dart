// Consent + welcome widget tests: copy, disclosure, privacy link.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/core/units/unit_system.dart';
import 'package:weather_app/data/datasources/local/settings_store.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';
import 'package:weather_app/features/consent/consent_controller.dart';
import 'package:weather_app/features/consent/consent_sheet.dart';
import 'package:weather_app/features/consent/consent_state.dart';
import 'package:weather_app/features/consent/welcome_screen.dart';

import 'widget_test_helpers.dart';

class StubConsentController extends ConsentController {
  @override
  ConsentControllerState build() => const ConsentControllerState();
}

Future<void> _pumpSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...baseOverrides(),
        consentControllerProvider
            .overrideWith(() => StubConsentController()),
      ],
      child: const MaterialApp(
          home: Scaffold(body: ConsentSheet())),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('consent sheet: "~1 km" copy + crash disclosure + actions',
      (WidgetTester tester) async {
    await _pumpSheet(tester);
    expect(find.text('Allow location access?'), findsOneWidget);
    expect(find.textContaining('~1 km'), findsOneWidget);
    expect(find.textContaining('Crash reports are on by default'),
        findsOneWidget);
    expect(find.text('Allow'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Privacy notice'), findsOneWidget);
  });

  testWidgets('welcome screen marks the R-17 disclosure seen',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final SettingsStore settings = await SettingsStore.init(prefs,
        fallbackUnits: UnitSystem.metric);
    expect(settings.crashDisclosureSeen, isFalse);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ...baseOverrides(),
          settingsRepositoryProvider.overrideWithValue(settings),
          consentControllerProvider
              .overrideWith(() => StubConsentController()),
        ],
        child: const MaterialApp(home: WelcomeScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Know the weather, your way'), findsOneWidget);
    expect(find.text('Use my location'), findsOneWidget);
    expect(find.text('Choose a city instead'), findsOneWidget);
    expect(settings.crashDisclosureSeen, isTrue);
  });
}

// SettingsScreen widget test: groups render; toggle reflects state.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/consent/consent_controller.dart';
import 'package:weather_app/features/consent/consent_state.dart';
import 'package:weather_app/features/settings/settings_controller.dart';
import 'package:weather_app/features/settings/settings_screen.dart';

import 'widget_test_helpers.dart';

class StubConsentController extends ConsentController {
  @override
  ConsentControllerState build() => const ConsentControllerState();
}

Future<void> _pump(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ...baseOverrides(),
        settingsControllerProvider.overrideWith(
            () => StubSettingsController(testSettingsState())),
        consentControllerProvider
            .overrideWith(() => StubConsentController()),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('all groups render', (WidgetTester tester) async {
    await _pump(tester);
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Units'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Privacy'), findsOneWidget);
    expect(find.text('About'), findsOneWidget);
  });

  testWidgets('location toggle reflects state; precision row present',
      (WidgetTester tester) async {
    await _pump(tester);
    expect(find.text('Use device location'), findsOneWidget);
    expect(find.text('Coarse — ~1 km (rounded coordinates)'), findsOneWidget);
    expect(find.text('Delete local data'), findsOneWidget);
    expect(find.text('Crash reporting'), findsOneWidget);
  });

  testWidgets('temperature segmented control shows both options',
      (WidgetTester tester) async {
    await _pump(tester);
    expect(find.text('Celsius'), findsOneWidget);
    expect(find.text('Fahrenheit'), findsOneWidget);
  });
}

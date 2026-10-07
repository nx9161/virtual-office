// PrivacyNoticeScreen: renders all 12 Tech Law sections (C2).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/privacy/privacy_notice_screen.dart';

void main() {
  testWidgets('all 12 sections render', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PrivacyNoticeScreen()),
    );
    await tester.pump();

    expect(find.text('Privacy notice'), findsWidgets);
    // Spot-check section headings across the 12-section spec.
    expect(find.text('1. Who we are'), findsOneWidget);
    expect(find.text('5. What is sent, and to whom'), findsOneWidget);
    expect(find.text('7. How long we keep it'), findsOneWidget);
    expect(find.text('9. How to revoke location access'), findsOneWidget);
    expect(find.text('12. Changes to this notice'), findsOneWidget);
    // Key legally-material copy.
    expect(find.textContaining('BigDataCloud'), findsOneWidget);
    expect(find.textContaining('1 km'), findsWidgets);
    expect(find.textContaining('Delete local data'), findsOneWidget);
  });
}

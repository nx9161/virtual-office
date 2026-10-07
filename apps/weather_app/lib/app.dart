// WeatherApp: MaterialApp, themes, plain Navigator routes (ADR-12: no
// go_router v1), RootGate.
//
// RootGate routes on location state (§4.3): no saved place -> welcome
// screen; saved place -> home. Themes are DesignTokens' full palettes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/domain/entities/app_settings.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/consent/welcome_screen.dart';
import 'package:weather_app/features/daily/daily_screen.dart';
import 'package:weather_app/features/home/home_controller.dart';
import 'package:weather_app/features/home/home_screen.dart';
import 'package:weather_app/features/home/home_state.dart';
import 'package:weather_app/features/hourly/hourly_screen.dart';
import 'package:weather_app/features/privacy/privacy_notice_screen.dart';
import 'package:weather_app/features/settings/settings_controller.dart';
import 'package:weather_app/features/settings/settings_screen.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class WeatherApp extends ConsumerWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeMode themeMode = ref.watch(
        settingsControllerProvider.select((s) => s.themeMode));
    return MaterialApp(
      title: AppLocalizations.current.appTitle,
      debugShowCheckedModeBanner: false,
      theme: DesignTokens.lightTheme(),
      darkTheme: DesignTokens.darkTheme(),
      themeMode: switch (themeMode) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      },
      home: const RootGate(),
      routes: <String, WidgetBuilder>{
        '/home': (_) => const HomeScreen(),
        '/hourly': (_) => const HourlyScreen(),
        '/daily': (_) => const DailyScreen(),
        '/settings': (_) => const SettingsScreen(),
        '/privacy': (_) => const PrivacyNoticeScreen(),
        '/welcome': (_) => const WelcomeScreen(),
      },
    );
  }
}

/// First gate (§4.3): the home controller's boot state machine drives the
/// routing — no saved place (or a cleared one) -> HomeNeedsLocationChoice ->
/// welcome; otherwise home. Watching the plain repository instance would
/// not rebuild (select on a non-Listenable), so the controller state is the
/// routing signal.
class RootGate extends ConsumerWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final HomeScreenState homeState = ref.watch(homeControllerProvider);
    if (homeState is HomeNeedsLocationChoice) {
      return const WelcomeScreen();
    }
    return const HomeScreen();
  }
}

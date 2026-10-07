// WelcomeScreen: first-run gate (§4.3).
//
// Shown when there is no saved place. "Use my location" starts the consent
// flow; "Choose a city instead" opens the search sheet. After either, the
// RootGate routes to Home. The "Using your approximate location" + Undo
// snackbar (design §5.2) is shown here when the consent controller reports
// a replaced city.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/telemetry/sentry_service.dart';
import 'package:weather_app/domain/repositories/location_repository.dart';
import 'package:weather_app/domain/repositories/settings_repository.dart';
import 'package:weather_app/features/common/design_tokens.dart';
import 'package:weather_app/features/common/widgets/responsive_scaffold.dart';
import 'package:weather_app/features/consent/consent_controller.dart';
import 'package:weather_app/features/consent/consent_sheet.dart';
import 'package:weather_app/features/consent/consent_state.dart';
import 'package:weather_app/features/search/search_sheet.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  @override
  void initState() {
    super.initState();
    // R-17: the disclosure copy on this screen is the first-run gate for
    // crash reporting. Mark it seen so Sentry may initialize on next launch.
    Future.microtask(() async {
      final SettingsRepository settings =
          ref.read(settingsRepositoryProvider);
      if (!settings.crashDisclosureSeen) {
        await settings.setCrashDisclosureSeen();
      }
      SentryService.markCrashDisclosureSeen();
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations strings = AppLocalizations.of(context);
    final ConsentController consent =
        ref.read(consentControllerProvider.notifier);

    ref.listen<ConsentUiSignal>(
      consentControllerProvider.select((ConsentControllerState s) => s.uiSignal),
      (ConsentUiSignal? prev, ConsentUiSignal next) {
        if (prev == next) return;
        switch (next) {
          case ConsentUiSignal.showConsentSheet:
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const ConsentSheet(),
            ).then((_) => consent.uiSignalConsumed());
          case ConsentUiSignal.showOsPrompt:
            // Presented by the consent sheet itself.
            break;
          case ConsentUiSignal.showSettingsFallback:
            ref.read(locationRepositoryProvider).openAppSettings();
            consent.uiSignalConsumed();
          case ConsentUiSignal.showSearchPrompt:
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              builder: (_) => const SearchSheet(),
            ).then((_) => consent.uiSignalConsumed());
          case ConsentUiSignal.none:
            break;
        }
      },
    );

    // Design §5.2: confirm replacement of a saved city with the device city,
    // with Undo (persists until dismissed — the Undo action is the point).
    ref.listen(
      consentControllerProvider
          .select((ConsentControllerState s) => s.justReplacedPlace),
      (Object? prev, Object? next) {
        if (prev == null && next != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.usingApproximateLocation),
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () => consent.undoDevicePlace(),
              ),
            ),
          );
          consent.clearJustReplaced();
        }
      },
    );

    return ResponsiveScaffold(
      body: Padding(
        padding: const EdgeInsets.all(DesignTokens.s24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Icon(Icons.wb_sunny, size: 72),
            const SizedBox(height: DesignTokens.s24),
            Semantics(
              header: true,
              child: Text(
                strings.welcomeTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: DesignTokens.s12),
            Text(
              strings.welcomeBody,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DesignTokens.s32),
            FilledButton(
              onPressed: consent.beginFlow,
              child: Text(strings.useMyLocation),
            ),
            const SizedBox(height: DesignTokens.s8),
            OutlinedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                builder: (_) => const SearchSheet(),
              ),
              child: Text(strings.chooseCityInstead),
            ),
            const SizedBox(height: DesignTokens.s16),
            TextButton(
              onPressed: () => Navigator.of(context).pushNamed('/privacy'),
              child: Text(strings.howWeHandleLocation),
            ),
            const SizedBox(height: DesignTokens.s8),
            Text(
              strings.crashDisclosure,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DesignTokens.textSecondary(context),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

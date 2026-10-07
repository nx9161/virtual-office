// FailurePresentationMapper: PRD §11 exact headlines + the FM-4 search lens.

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/error/failure_presentation.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/l10n/app_localizations.dart';

void main() {
  test('network unreachable -> "No connection"', () {
    final FailurePresentation p =
        FailurePresentationMapper.map(const NetworkUnreachableFailure());
    expect(p.headline, 'No connection');
    expect(p.primaryAction, FailureAction.retry);
  });

  test('rate limited -> "Too many requests"', () {
    final FailurePresentation p = FailurePresentationMapper.map(
        RateLimitedFailure(retryAfter: const Duration(seconds: 7)));
    expect(p.headline, 'Too many requests');
    expect(p.primaryAction, FailureAction.retry);
  });

  test('server error interpolates the stale label (FM-2)', () {
    final FailurePresentation p = FailurePresentationMapper.map(
        const ServerErrorFailure(500),
        staleLabel: '2h');
    expect(p.headline, 'Weather service is down');
    expect(p.body, contains('2h'));
  });

  test('schema violation headline', () {
    final FailurePresentation p = FailurePresentationMapper.map(
        const SchemaViolationFailure('current.temperature_2m', 'missing'));
    expect(p.headline, "Couldn't read the weather data");
  });

  test('no results echoes the sanitized query (FM-12)', () {
    final FailurePresentation p = FailurePresentationMapper.map(
        const NoResultsFailure('Pa\x00ris-yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy'));
    expect(p.headline, startsWith("No places found for 'Paris-"));
    expect(p.headline.length, lessThan(80));
  });

  test('consent revoked -> saved-city fallback copy', () {
    final FailurePresentation p =
        FailurePresentationMapper.map(const ConsentRevokedFailure());
    expect(p.headline, 'Location access was revoked');
    expect(p.body, contains('saved city'));
  });

  test('location permanently denied -> system settings action', () {
    final FailurePresentation p = FailurePresentationMapper.map(
        const LocationPermanentlyDeniedFailure());
    expect(p.primaryAction, FailureAction.openSystemSettings);
  });

  test('FM-4 search lens: transport failures all become the search card', () {
    for (final AppFailure f in <AppFailure>[
      const NetworkUnreachableFailure(),
      const ServerErrorFailure(500),
      const SchemaViolationFailure('x', 'y'),
      const TimeoutFailure(),
    ]) {
      final FailurePresentation p = FailurePresentationMapper.forSearch(f);
      expect(p.headline, 'Search isn\'t working right now', reason: '$f');
    }
  });

  test('FM-4 search lens keeps no-results distinct', () {
    final FailurePresentation p = FailurePresentationMapper.forSearch(
        const NoResultsFailure('zzz'));
    expect(p.headline, contains('No places found'));
  });

  test('unknown failure is never a generic toast', () {
    final FailurePresentation p =
        FailurePresentationMapper.map(const UnknownFailure('boom'));
    expect(p.headline, "We couldn't load the weather");
    expect(p.primaryAction, FailureAction.retry);
  });

  // PRD §11 headline/action sweep (QA condition 2): every failure mode's
  // exact headline + primary action, parameterized. Mapper stays the
  // single source of truth; widgets consume it (B4).
  group('PRD §11 FM headline/action sweep', () {
    final List<
        ({
          String fm,
          AppFailure failure,
          String headline,
          FailureAction action,
        })> cases = <({
      String fm,
      AppFailure failure,
      String headline,
      FailureAction action,
    })>[
      (
        fm: 'FM-2',
        failure: const ServerErrorFailure(500),
        headline: 'Weather service is down',
        action: FailureAction.retry,
      ),
      (
        fm: 'FM-3',
        failure: const SchemaViolationFailure('current', 'missing'),
        headline: "Couldn't read the weather data",
        action: FailureAction.retry,
      ),
      (
        fm: 'FM-5',
        failure: const ApiClientErrorFailure(400),
        headline: 'Request problem (code 400)',
        action: FailureAction.retry,
      ),
      (
        fm: 'FM-6',
        failure:
            RateLimitedFailure(retryAfter: const Duration(seconds: 30)),
        headline: 'Too many requests',
        action: FailureAction.retry,
      ),
      (
        fm: 'FM-7',
        failure: const LocationDeniedFailure(),
        headline: 'Location access denied',
        action: FailureAction.searchInstead,
      ),
      (
        fm: 'FM-8',
        failure: const LocationPermanentlyDeniedFailure(),
        headline: 'Location is turned off',
        action: FailureAction.openSystemSettings,
      ),
      (
        fm: 'FM-9',
        failure: const LocationServicesDisabledFailure(),
        headline: 'Location services are off',
        action: FailureAction.openLocationSettings,
      ),
      (
        fm: 'FM-10',
        failure: const LocationTimeoutFailure(),
        headline: "Couldn't get your location",
        action: FailureAction.retry,
      ),
      (
        fm: 'FM-16',
        failure: const CacheExpiredFailure('key-hash'),
        headline: "You're offline",
        action: FailureAction.retry,
      ),
    ];

    for (final c in cases) {
      test('${c.fm}: headline + primary action', () {
        final FailurePresentation p =
            FailurePresentationMapper.map(c.failure);
        expect(p.headline, c.headline, reason: c.fm);
        expect(p.primaryAction, c.action, reason: c.fm);
        expect(p.headline, isNot(contains('Something went wrong')),
            reason: '${c.fm}: no generic fallback copy (US-9 AC1)');
      });
    }

    test('FM-6: Retry-After countdown label', () {
      // The error banner shows "Retry in Ns" and enables Retry only after
      // the interval elapses (error_banner.dart).
      expect(const AppLocalizations().retryIn(30), 'Retry in 30s');
      expect(const AppLocalizations().retryIn(1), 'Retry in 1s');
      final FailurePresentation p = FailurePresentationMapper.map(
          RateLimitedFailure(retryAfter: const Duration(seconds: 30)));
      expect(p.primaryAction, FailureAction.retry);
    });

    test('FM-13: unknown WMO code -> "Unknown conditions" (not an error)',
        () {
      const AppLocalizations strings = AppLocalizations();
      expect(strings.wmoLabel(999), 'Unknown conditions');
      expect(strings.wmoLabel(null), 'Unknown conditions');
      expect(strings.wmoLabel(-1), 'Unknown conditions');
    });

    test('FM-14: device-timezone fallback note copy', () {
      expect(const AppLocalizations().deviceTimezoneNote,
          'Times shown in device timezone');
    });

    test('FM-17: partial-data section note copy', () {
      expect(const AppLocalizations().someHoursUnavailable,
          'Some hours unavailable');
    });

    group('consent flow states', () {
      test('consent required -> device-location action', () {
        final FailurePresentation p =
            FailurePresentationMapper.map(const ConsentRequiredFailure());
        expect(p.headline, 'Location is off');
        expect(p.primaryAction, FailureAction.useDeviceLocation);
        expect(p.secondaryAction, FailureAction.searchInstead);
      });

      test('consent revoked -> saved-city fallback copy', () {
        final FailurePresentation p =
            FailurePresentationMapper.map(const ConsentRevokedFailure());
        expect(p.headline, 'Location access was revoked');
        expect(p.primaryAction, FailureAction.searchInstead);
      });

      test('location denied -> search-instead action', () {
        final FailurePresentation p =
            FailurePresentationMapper.map(const LocationDeniedFailure());
        expect(p.headline, 'Location access denied');
        expect(p.primaryAction, FailureAction.searchInstead);
      });
    });
  });
}

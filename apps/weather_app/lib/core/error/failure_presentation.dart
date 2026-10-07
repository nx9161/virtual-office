// FailurePresentationMapper (presentation, pure): AppFailure ->
// (headline, body, primaryAction, secondaryAction?).
//
// Headlines are EXACT per PRD §11 (US-9 AC1: generic "Something went wrong"
// appears in zero states). Unit-tested against the PRD table.
//
// The failure->{inline state | side effect} policy (ADR-14):
//  * Inline render: networkUnreachable, timeout, rateLimited, apiClientError,
//    serverError, schemaViolation, outOfRange, noResults, cacheExpired,
//    locationTimeout, unknown — error card or banner (banner when cached data
//    exists, fullscreen card when it does not; R-8).
//  * Side effect (via ref.listen, never inline): consentRequired (open search
//    sheet), consentRevoked (banner + prompt to pick a city), permanentlyDenied
//    (settings deep-link card). The mapper still returns copy for these so
//    widget tests can assert the surfaces.

import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/validation/validators.dart';

/// User-facing actions an error surface can offer. Labels are resolved by the
/// widget (localized) from the enum — the mapper stays string-typed only for
/// headlines/bodies asserted verbatim in tests.
enum FailureAction {
  retry,
  openSystemSettings,
  openLocationSettings,
  searchInstead,
  useDeviceLocation,
  dismiss,
  none,
}

class FailurePresentation {
  final String headline;
  final String body;
  final FailureAction primaryAction;
  final FailureAction? secondaryAction;

  const FailurePresentation({
    required this.headline,
    required this.body,
    required this.primaryAction,
    this.secondaryAction,
  });
}

abstract final class FailurePresentationMapper {
  /// Maps a failure to its PRD §11 presentation.
  ///
  /// [staleLabel] (e.g. "1h") is interpolated into the FM-2 body per the PRD
  /// ("Your last update from Xh ago is shown.") when cached data is on screen.
  static FailurePresentation map(AppFailure failure, {String? staleLabel}) {
    return switch (failure) {
      NetworkUnreachableFailure() => const FailurePresentation(
          headline: 'No connection',
          body: 'Check your connection and try again.',
          primaryAction: FailureAction.retry,
        ),
      TimeoutFailure() => const FailurePresentation(
          headline: 'No connection',
          body: 'The request timed out. Check your connection and try again.',
          primaryAction: FailureAction.retry,
        ),
      LocationTimeoutFailure() => const FailurePresentation(
          headline: "Couldn't get your location",
          body: 'Try again or search for a city.',
          primaryAction: FailureAction.retry,
          secondaryAction: FailureAction.searchInstead,
        ),
      RateLimitedFailure() => const FailurePresentation(
          headline: 'Too many requests',
          body: 'Please wait a moment and try again.',
          primaryAction: FailureAction.retry,
        ),
      ApiClientErrorFailure(statusCode: final int s) => FailurePresentation(
          headline: 'Request problem (code $s)',
          body: 'Please try again later.',
          primaryAction: FailureAction.retry,
        ),
      ServerErrorFailure() => FailurePresentation(
          headline: 'Weather service is down',
          body: staleLabel == null
              ? "Open-Meteo isn't responding right now."
              : "Open-Meteo isn't responding right now. "
                  'Your last update from $staleLabel ago is shown.',
          primaryAction: FailureAction.retry,
        ),
      SchemaViolationFailure() => const FailurePresentation(
          headline: "Couldn't read the weather data",
          body: "The service sent data we couldn't understand. Try again.",
          primaryAction: FailureAction.retry,
        ),
      OutOfRangeFailure() => const FailurePresentation(
          // Defensive variant only: field-level violations degrade to "—"
          // per R-1 and never surface. Mapped to the FM-3 card if reached.
          headline: "Couldn't read the weather data",
          body: "The service sent data we couldn't understand. Try again.",
          primaryAction: FailureAction.retry,
        ),
      NoResultsFailure(query: final String q) => FailurePresentation(
          headline: "No places found for '${escapeQueryEcho(q)}'",
          body: 'Check the spelling or try a nearby larger city.',
          primaryAction: FailureAction.retry,
        ),
      LocationDeniedFailure() => const FailurePresentation(
          headline: 'Location access denied',
          body: 'Search for a city instead — everything works without location.',
          primaryAction: FailureAction.searchInstead,
        ),
      LocationPermanentlyDeniedFailure() => const FailurePresentation(
          headline: 'Location is turned off',
          body: 'Enable it in system settings, or search for a city.',
          primaryAction: FailureAction.openSystemSettings,
          secondaryAction: FailureAction.searchInstead,
        ),
      LocationServicesDisabledFailure() => const FailurePresentation(
          headline: 'Location services are off',
          body: 'Turn them on in Settings, or search for a city.',
          primaryAction: FailureAction.openLocationSettings,
          secondaryAction: FailureAction.searchInstead,
        ),
      ConsentRequiredFailure() => const FailurePresentation(
          headline: 'Location is off',
          body: 'Turn on device location or search for a city instead.',
          primaryAction: FailureAction.useDeviceLocation,
          secondaryAction: FailureAction.searchInstead,
        ),
      ConsentRevokedFailure() => const FailurePresentation(
          headline: 'Location access was revoked',
          body: 'We switched to your saved city. Turn location back on anytime.',
          primaryAction: FailureAction.searchInstead,
          secondaryAction: FailureAction.dismiss,
        ),
      ReverseGeocodeFailedFailure() => const FailurePresentation(
          // Degraded path (FM-17): label falls back to "Current location";
          // the failure itself is not surfaced inline.
          headline: 'Current location',
          body: "We couldn't determine the city name.",
          primaryAction: FailureAction.none,
        ),
      CacheCorruptedFailure() => const FailurePresentation(
          // Self-healing (FM-18): evicted and treated as a miss; the card
          // below only shows if the subsequent network call also fails.
          headline: "Couldn't read the weather data",
          body: 'Saved data was damaged. Try again.',
          primaryAction: FailureAction.retry,
        ),
      CacheExpiredFailure() => const FailurePresentation(
          headline: "You're offline",
          body: 'Connect to see the weather.',
          primaryAction: FailureAction.retry,
        ),
      UnknownFailure() => const FailurePresentation(
          // FM-20: crash path restarts the app; if this ever renders inline
          // it is still a specific, actionable card — never a generic toast.
          headline: "We couldn't load the weather",
          body: 'Something unexpected happened. Please try again.',
          primaryAction: FailureAction.retry,
        ),
    };
  }

  /// Search-flow lens (PRD FM-4): in the search sheet, network/5xx/parse
  /// failures ALL present as "Search isn't working right now" with previous
  /// results retained; only noResults gets the FM-12 empty state.
  static FailurePresentation forSearch(AppFailure failure) {
    if (failure is NoResultsFailure) return map(failure);
    return const FailurePresentation(
      headline: "Search isn't working right now",
      body: 'Check your connection and try again.',
      primaryAction: FailureAction.retry,
    );
  }
}

// Sealed AppFailure union (ARCHITECTURE.md §9 + R-14).
//
// Every failure mode (PRD FM-1…FM-20) maps to exactly one variant; the
// compiler enforces exhaustive handling at every `switch`. No `catch (e)` ->
// generic toast exists in production code paths.
//
// Privacy invariants (R-2, LOW-1, B-7):
//  * No variant carries raw coordinates. Latitude/longitude echo validation
//    failures route to `schemaViolation` (Tier 1), never to `outOfRange`.
//  * `outOfRange` carries the *expected range* description, never the raw value.
//  * `cacheCorrupted`/`cacheExpired` carry the SHA-256 key *hash* (B-1), never
//    the raw key.

sealed class AppFailure {
  const AppFailure();

  // --- network & transport ---
  const factory AppFailure.networkUnreachable() = NetworkUnreachableFailure; // FM-1, FM-2
  const factory AppFailure.timeout() = TimeoutFailure; // FM-3
  const factory AppFailure.locationTimeout() = LocationTimeoutFailure; // PRD FM-10 (R-14)
  const factory AppFailure.rateLimited({Duration? retryAfter}) = RateLimitedFailure; // FM-4/PRD FM-6
  const factory AppFailure.apiClientError(int statusCode) = ApiClientErrorFailure; // FM-5
  const factory AppFailure.serverError(int statusCode) = ServerErrorFailure; // FM-6/PRD FM-2

  // --- trust & schema ---
  const factory AppFailure.schemaViolation(String field, String reason) =
      SchemaViolationFailure; // PRD FM-3
  const factory AppFailure.outOfRange(String field, String expectedRange) =
      OutOfRangeFailure; // defensive; field-level violations degrade to "—" instead

  // --- search ---
  const factory AppFailure.noResults(String query) = NoResultsFailure; // PRD FM-12

  // --- location & consent ---
  const factory AppFailure.locationDenied() = LocationDeniedFailure; // PRD FM-7
  const factory AppFailure.locationPermanentlyDenied() =
      LocationPermanentlyDeniedFailure; // PRD FM-8
  const factory AppFailure.locationServicesDisabled() =
      LocationServicesDisabledFailure; // PRD FM-9
  const factory AppFailure.consentRequired() = ConsentRequiredFailure; // US-3
  const factory AppFailure.consentRevoked() = ConsentRevokedFailure; // US-11 AC2
  const factory AppFailure.reverseGeocodeFailed() = ReverseGeocodeFailedFailure;

  // --- cache ---
  const factory AppFailure.cacheCorrupted(String keyHash) = CacheCorruptedFailure; // FM-18
  const factory AppFailure.cacheExpired(String keyHash) = CacheExpiredFailure; // PRD FM-16

  // --- terminal ---
  const factory AppFailure.unknown([String? detail]) = UnknownFailure; // FM-20

  /// Stable variant name for sanitized logging/breadcrumbs (field names +
  /// reason codes are sufficient diagnostics — never raw values, R-2).
  String get code => switch (this) {
        NetworkUnreachableFailure() => 'networkUnreachable',
        TimeoutFailure() => 'timeout',
        LocationTimeoutFailure() => 'locationTimeout',
        RateLimitedFailure() => 'rateLimited',
        ApiClientErrorFailure() => 'apiClientError',
        ServerErrorFailure() => 'serverError',
        SchemaViolationFailure() => 'schemaViolation',
        OutOfRangeFailure() => 'outOfRange',
        NoResultsFailure() => 'noResults',
        LocationDeniedFailure() => 'locationDenied',
        LocationPermanentlyDeniedFailure() => 'locationPermanentlyDenied',
        LocationServicesDisabledFailure() => 'locationServicesDisabled',
        ConsentRequiredFailure() => 'consentRequired',
        ConsentRevokedFailure() => 'consentRevoked',
        ReverseGeocodeFailedFailure() => 'reverseGeocodeFailed',
        CacheCorruptedFailure() => 'cacheCorrupted',
        CacheExpiredFailure() => 'cacheExpired',
        UnknownFailure() => 'unknown',
      };
}

final class NetworkUnreachableFailure extends AppFailure {
  const NetworkUnreachableFailure();
}

final class TimeoutFailure extends AppFailure {
  const TimeoutFailure();
}

final class LocationTimeoutFailure extends AppFailure {
  const LocationTimeoutFailure();
}

final class RateLimitedFailure extends AppFailure {
  final Duration? retryAfter;
  const RateLimitedFailure({this.retryAfter});
}

final class ApiClientErrorFailure extends AppFailure {
  final int statusCode;
  const ApiClientErrorFailure(this.statusCode);
}

final class ServerErrorFailure extends AppFailure {
  final int statusCode;
  const ServerErrorFailure(this.statusCode);
}

final class SchemaViolationFailure extends AppFailure {
  final String field;
  final String reason;
  const SchemaViolationFailure(this.field, this.reason);
}

final class OutOfRangeFailure extends AppFailure {
  final String field;
  final String expectedRange;
  const OutOfRangeFailure(this.field, this.expectedRange);
}

final class NoResultsFailure extends AppFailure {
  final String query;
  const NoResultsFailure(this.query);
}

final class LocationDeniedFailure extends AppFailure {
  const LocationDeniedFailure();
}

final class LocationPermanentlyDeniedFailure extends AppFailure {
  const LocationPermanentlyDeniedFailure();
}

final class LocationServicesDisabledFailure extends AppFailure {
  const LocationServicesDisabledFailure();
}

final class ConsentRequiredFailure extends AppFailure {
  const ConsentRequiredFailure();
}

final class ConsentRevokedFailure extends AppFailure {
  const ConsentRevokedFailure();
}

final class ReverseGeocodeFailedFailure extends AppFailure {
  const ReverseGeocodeFailedFailure();
}

final class CacheCorruptedFailure extends AppFailure {
  /// SHA-256 hash of the cache key (B-1) — never the raw key.
  final String keyHash;
  const CacheCorruptedFailure(this.keyHash);
}

final class CacheExpiredFailure extends AppFailure {
  /// SHA-256 hash of the cache key (B-1) — never the raw key.
  final String keyHash;
  const CacheExpiredFailure(this.keyHash);
}

final class UnknownFailure extends AppFailure {
  /// Sanitized detail only (variant/type names, never values or URIs).
  final String? detail;
  const UnknownFailure([this.detail]);
}

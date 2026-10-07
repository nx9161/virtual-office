// Weather App — canonical constants (R-3: the single source of truth for all
// numeric budgets; PRD/design-spec reference this table).
//
// Binding numbers (PRD wins unless noted):
//  * requestTimeout 10 s (connect 8 s / receive 10 s / send 10 s)
//  * location fix timeout 15 s (PRD FM-10)
//  * utc_offset_seconds ±50400 (PRD §7.2; ±18 h does not exist)
//  * pressure 800–1100 hPa (PRD §7.2)
//  * recent searches: store 10 (PRD US-13), display 5 (design §3.2)
//  * hourly entries 24 (PRD US-5), home preview 8
//  * touch targets ≥ 48 dp (R-15; supersedes PRD's 44)

abstract final class AppConstants {
  // --- Hosts (keyless public APIs; no secrets exist by construction) ---
  static const String forecastHost = 'https://api.open-meteo.com';
  static const String geocodingHost = 'https://geocoding-api.open-meteo.com';
  static const String bigDataCloudHost = 'https://api.bigdatacloud.net';

  // --- HTTP ---
  static const Duration connectTimeout = Duration(seconds: 8);
  static const Duration receiveTimeout = Duration(seconds: 10); // PRD §8.3
  static const Duration sendTimeout = Duration(seconds: 10);
  static const Duration locationFixTimeout = Duration(seconds: 15); // PRD FM-10

  // --- Rate limiting (PRD §8) ---
  static const Duration searchDebounce = Duration(milliseconds: 300);
  static const int searchMinChars = 2;
  static const int searchQueryMaxChars = 100; // enforced at widget AND validation layer (AC-3)
  static const int searchNoResultsEchoMaxChars = 50; // PRD FM-12: echo ≤ 50 chars, escaped
  static const Duration searchResultCacheTtl = Duration(seconds: 60); // PRD §8.1
  static const Duration inFlightDedupeWindow = Duration(seconds: 5); // PRD §8.2
  static const int geocodingResultsCount = 8;

  // Per-host minimum inter-request intervals (RateLimitInterceptor).
  // Forecast host: TTL + in-flight dedupe do the real work; 1 s is a safety net
  // that never stalls pull-to-refresh (C-8).
  static const Duration forecastMinInterval = Duration(seconds: 1);
  static const Duration geocodingMinInterval = Duration(milliseconds: 300);
  static const int rateLimitQueueMaxDepth = 10;

  // --- Retry budget (PRD §8.3, B-7) ---
  static const int maxRetries = 2;
  static const Duration retryBaseDelay = Duration(seconds: 1); // 1 s -> 2 s
  static const Duration retryJitter = Duration(milliseconds: 250); // ±250 ms (thundering-herd guard)
  static const Duration retryAfterCap = Duration(seconds: 60);
  static const int maxAutoRetriesAfter429 = 1; // single scheduled retry per episode (R-12)

  // --- Response body gate (AC-4b) ---
  // Real payloads are 15–25 KB; 512 KB is ~20x headroom. Enforced BEFORE
  // jsonDecode on every Dio instance via responseType: bytes + the gate
  // interceptor. Oversize -> AppFailure.schemaViolation('body', 'oversize').
  static const int maxResponseBodyBytes = 512 * 1024;

  // --- Cache TTLs (PRD §8.2 / US-10) ---
  static const Duration forecastFreshTtl = Duration(minutes: 10);
  static const Duration forecastSwrTtl = Duration(minutes: 60);
  static const Duration forecastMaxAge = Duration(hours: 24);
  static const int forecastCacheLruCap = 20;
  static const int forecastCacheSchemaVersion = 1;

  // --- Content counts ---
  static const int recentPlacesMax = 10; // stored (PRD US-13)
  static const int recentPlacesDisplayMax = 5; // shown (design §3.2)
  static const int hourlyEntryCount = 24; // PRD US-5 (view slice)
  // Parse cap (US-5 AC1 / FM-17): the API day-0 array starts at 00:00, so the
  // DTO keeps up to 48 raw entries; ForecastViewMapper then filters
  // time >= current local hour and takes 24 (never fabricated).
  static const int hourlyApiParseCap = 48;
  static const int hourlyPreviewCount = 8; // home preview
  static const int dailyEntryCount = 7; // PRD US-6
  static const int dailyPreviewCount = 3; // home preview

  // --- Consent (Tech Law C4) ---
  static const Duration consentDeclineSuppression = Duration(days: 30);

  // --- Connectivity ---
  static const Duration reconnectDebounce = Duration(seconds: 2); // PRD US-10 AC2
  static const Duration unitToggleDebounce = Duration(milliseconds: 300); // PRD FM-20

  // --- Settings UX ---
  static const Duration permissionQueryShimmerCap = Duration(seconds: 1);

  // --- Accessibility ---
  static const double minTouchTarget = 48.0; // dp (R-15)

  // --- Forecast query contract (PRD §7.1 + R-5 uv_index_max) ---
  // Fixed parameter set — no other params without PO approval.
  static const String currentParams =
      'temperature_2m,relative_humidity_2m,apparent_temperature,is_day,'
      'precipitation,weather_code,cloud_cover,pressure_msl,'
      'wind_speed_10m,wind_direction_10m,wind_gusts_10m';
  static const String hourlyParams =
      'temperature_2m,precipitation_probability,weather_code';
  static const String dailyParams =
      'weather_code,temperature_2m_max,temperature_2m_min,'
      'sunrise,sunset,uv_index_max,precipitation_probability_max';
  static const int forecastDays = 7;
}

/// App version, overridable at build time for the User-Agent header (B-7).
const String appVersion =
    String.fromEnvironment('APP_VERSION', defaultValue: '1.0.0');

/// Sentry DSN. Empty by default (no reporting); the EU DSN is injected via
/// --dart-define=SENTRY_DSN at release time (Tech Law C3).
const String sentryDsn =
    String.fromEnvironment('SENTRY_DSN', defaultValue: '');

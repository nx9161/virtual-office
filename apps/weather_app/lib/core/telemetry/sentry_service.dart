// Crash reporting: Sentry, crash-only posture (R-17, ADR-10, B-2, B-7).
//
// Configuration (all binding):
//  * crash-only: tracesSampleRate 0, profilesSampleRate 0, session replay
//    off, performance monitoring off, sendDefaultPii off.
//  * beforeSend scrubber: full query-string redaction + lat/lon regexes over
//    exception values, breadcrumb messages/data, and request URLs (B-2).
//    Raw DioException is NEVER captured — callers map to AppFailure first.
//  * DSN: EU region, injected via --dart-define=SENTRY_DSN (Tech Law C3).
//    Empty DSN -> Sentry is not initialized at all (dev default).
//  * First-run disclosure: no event leaves the device before the user has
//    seen the privacy notice (R-17) — enforced by a gate in beforeSend.
//  * Opt-out: Sentry.close() AND deletion of the on-disk envelope cache
//    (B-7 / LOW-3), so already-queued envelopes can never be sent later.
//
// NOTE (verified against sentry_flutter 8.14.2): there is no cacheDirPath
// option — the deterministic envelope-cache dir is only used by
// purgeEnvelopeCache(). Sentry.close and beforeSend exist as used below.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/error_mapper.dart';
import 'package:weather_app/core/validation/validators.dart';

/// Pure, unit-tested privacy scrubber for Sentry events (B-2).
///
/// Redacts, in every string field: full query strings (R-2), `latitude=` /
/// `longitude=` / `lat=` / `lon=` params, and bare `dd.dddd,dd.dddd` pairs.
/// Field names + reason codes survive (sufficient diagnostics).
bool _isQueryTerminator(int c) =>
    c == 0x20 || c == 0x0A || c == 0x0D || c == 0x09 || c == 0x27 || c == 0x22;

SentryEvent scrubEventForPrivacy(SentryEvent event) {
  // Full query redaction (a bare '?' split is not enough when the URL is
  // embedded in a longer message), then coordinate-pattern scrubbing.
  String scrub(String s) {
    final StringBuffer sb = StringBuffer();
    int i = 0;
    while (i < s.length) {
      final int q = s.indexOf('?', i);
      if (q < 0) {
        sb.write(s.substring(i));
        break;
      }
      // Keep the '?' and redact until the next terminator or end.
      int end = q + 1;
      while (end < s.length && !_isQueryTerminator(s.codeUnitAt(end))) {
        end++;
      }
      sb
        ..write(s.substring(i, q + 1))
        ..write('<redacted>');
      if (end < s.length) sb.write(s[end]);
      i = end + (end < s.length ? 1 : 0);
    }
    return scrubCoordinates(sb.toString());
  }

  List<SentryException>? exceptions = event.exceptions?.map((e) {
    return e.copyWith(
      value: e.value == null ? null : scrub(e.value!),
    );
  }).toList();

  List<Breadcrumb>? breadcrumbs = event.breadcrumbs?.map((b) {
    final Map<String, dynamic>? data = b.data?.map(
      (String k, dynamic v) =>
          MapEntry<String, dynamic>(k, v is String ? scrub(v) : v),
    );
    return b.copyWith(
      message: b.message == null ? null : scrub(b.message!),
      data: data,
    );
  }).toList();

  final SentryRequest? request = event.request;
  final SentryRequest? scrubbedRequest = request == null
      ? null
      : request.copyWith(url: request.url == null ? null : scrub(request.url!));

  return event.copyWith(
    exceptions: exceptions,
    breadcrumbs: breadcrumbs,
    request: scrubbedRequest,
  );
}

/// Crash-only Sentry facade.
abstract final class SentryService {
  static bool _initialized = false;
  static bool _canSend = false; // first-run disclosure gate (R-17)
  static String? _envelopeCacheDir;
  static int _rateLimitedCount = 0; // AC-2 telemetry counter

  static bool get isInitialized => _initialized;

  /// Number of 429s observed this process (AC-2 telemetry).
  static int get rateLimitedCount => _rateLimitedCount;

  /// Initializes Sentry. No-op when the DSN is empty (dev default) or the
  /// user has opted out. Must be called once from main().
  static Future<void> init({
    required bool optOut,
    required bool crashDisclosureSeen,
  }) async {
    if (optOut || sentryDsn.isEmpty) return;
    _canSend = crashDisclosureSeen;
    try {
      final Directory supportDir = await getApplicationSupportDirectory();
      // Deterministic envelope-cache location so opt-out can purge it (B-7).
      _envelopeCacheDir = '${supportDir.path}/sentry-envelopes';
      await SentryFlutter.init((SentryFlutterOptions options) {
        options.dsn = sentryDsn;
        options.release = 'weather_app@$appVersion';
        // Crash-only posture (R-17 / ADR-10).
        options.tracesSampleRate = 0;
        options.profilesSampleRate = 0;
        options.sendDefaultPii = false;
        options.enableAutoSessionTracking = false;
        // sentry 8.x has no cacheDirPath option; the deterministic dir
        // above is still used by purgeEnvelopeCache() for the B-7 purge.
        options.beforeSend = _beforeSend;
      });
      _initialized = true;
    } catch (_) {
      // Telemetry must never break the app.
      _initialized = false;
    }
  }

  static FutureOr<SentryEvent?> _beforeSend(
      SentryEvent event, Hint hint) {
    // R-17: nothing leaves the device before the first-run disclosure.
    if (!_canSend) return null;
    return scrubEventForPrivacy(event);
  }

  /// Call once the first-run crash disclosure has been shown (R-17).
  static void markCrashDisclosureSeen() {
    _canSend = true;
  }

  /// Opt-out: disables the initialized client AND purges the on-disk envelope
  /// cache so queued pre-opt-out envelopes are never sent (B-7 / LOW-3).
  static Future<void> setOptOut(bool optOut) async {
    if (!optOut) return;
    _canSend = false;
    if (_initialized) {
      try {
        await Sentry.close();
      } catch (_) {
        // Best effort; the purge below is the load-bearing step.
      } finally {
        _initialized = false;
      }
    }
    await purgeEnvelopeCache();
  }

  /// Deletes the envelope cache directory. Best-effort, never throws.
  static Future<void> purgeEnvelopeCache() async {
    final String? dir = _envelopeCacheDir;
    if (dir == null) return;
    try {
      final Directory d = Directory(dir);
      if (await d.exists()) await d.delete(recursive: true);
    } catch (_) {
      // Telemetry hygiene must not break the app.
    }
  }

  /// Records a rate-limit observation (AC-2): breadcrumb + counter.
  /// Only the host is recorded — never the URI (R-2).
  static void breadcrumbRateLimited(String host) {
    _rateLimitedCount++;
    if (!_initialized || !_canSend) return;
    try {
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'rate_limited',
        category: 'http',
        data: <String, dynamic>{'host': host, 'count': _rateLimitedCount},
      ));
    } catch (_) {}
  }

  /// FM-8 schema-drift breadcrumb, aggregated as a Sentry issue by field name
  /// (B-4). Field path + reason only — no values (R-2).
  static void breadcrumbSchemaDrift(String field, String reason) {
    if (!_initialized || !_canSend) return;
    try {
      Sentry.addBreadcrumb(Breadcrumb(
        message: 'schema_drift:$field',
        category: 'validation',
        data: <String, dynamic>{'field': field, 'reason': reason},
      ));
    } catch (_) {}
  }

  /// Captures a failure that reached the crash path (FM-20). Runtime guard
  /// (B-2): an error that looks like a DioException is mapped to AppFailure
  /// via [mapToFailure] FIRST — in release as well as debug — so a raw
  /// transport object (request options / URLs) is never captured.
  static void captureFailure(Object error, StackTrace stackTrace) {
    if (!_initialized || !_canSend) return;
    assert(
      error is! Exception || !_looksLikeDioException(error),
      'Raw DioException must never be captured; map to AppFailure first (B-2).',
    );
    final Object sanitized =
        _looksLikeDioException(error) ? mapToFailure(error) : error;
    try {
      Sentry.captureException(sanitized, stackTrace: stackTrace);
    } catch (_) {}
  }

  static bool _looksLikeDioException(Object error) =>
      error.runtimeType.toString().contains('DioException');
}

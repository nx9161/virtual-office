// Canonical validation + sanitization helpers (B-6, R-2, AC-3).
//
// Every DTO in the data layer MUST use these instead of `as`/`!` casts on
// network data (DoD#2; enforced by the layer_lint no_json_casts rule).
//
// Coercion rules (B-6 / MEDIUM-4):
//  * asInt accepts `int`, or `double` with an integral value (0.0 -> 0,
//    1e2 -> 100). 1.5, "1", true, null, NaN -> null (Tier-2 violation).
//  * asDouble accepts any `num` (int -> toDouble); non-num -> null.
//    NaN/Infinity are rejected (never render unformattable values).
//  * asCleanString strips control characters (AC-3), trims, and enforces
//    [minLength, maxLength]; violations -> null.

import 'package:weather_app/core/config/constants.dart';

/// Canonical integer coercion (B-6).
int? asInt(Object? value) {
  if (value is int) return value;
  if (value is double) {
    if (value.isNaN || value.isInfinite) return null;
    final int truncated = value.truncate();
    // Accept only integral doubles (0.0 -> 0, 1e2 -> 100); 1.5 -> null.
    if (truncated.toDouble() == value) return truncated;
    return null;
  }
  return null;
}

/// Canonical double coercion (B-6).
double? asDouble(Object? value) {
  if (value is num) {
    final double d = value.toDouble();
    if (d.isNaN || d.isInfinite) return null;
    return d;
  }
  return null;
}

/// String ingestion boundary (AC-3): strips control characters
/// (U+0000–U+001F, U+007F–U+009F), trims, enforces length bounds.
/// Returns null on any violation. Applied to the search query AND every
/// API-supplied string field (name, country, admin1, timezone, ...).
String? asCleanString(
  Object? value, {
  required int minLength,
  required int maxLength,
}) {
  if (value is! String) return null;
  final String stripped = stripControlChars(value).trim();
  if (stripped.length < minLength || stripped.length > maxLength) return null;
  return stripped;
}

/// Optional variant: invalid -> null (omit), never throws.
String? asCleanStringOrOmit(
  Object? value, {
  required int maxLength,
}) {
  if (value == null) return null;
  if (value is! String) return null;
  final String stripped = stripControlChars(value).trim();
  if (stripped.isEmpty || stripped.length > maxLength) return null;
  return stripped;
}

/// Control-character stripper (AC-3). Keeps legitimate bidi controls used by
/// RTL scripts (U+200E/U+200F are NOT stripped); strips Cc controls that can
/// inject fake log lines or scramble UI rows.
String stripControlChars(String input) {
  bool needsFix = false;
  for (int i = 0; i < input.length; i++) {
    final int c = input.codeUnitAt(i);
    if (c < 0x20 || (c >= 0x7F && c <= 0x9F)) {
      needsFix = true;
      break;
    }
  }
  if (!needsFix) return input;
  final StringBuffer sb = StringBuffer();
  for (int i = 0; i < input.length; i++) {
    final int c = input.codeUnitAt(i);
    if (c < 0x20 || (c >= 0x7F && c <= 0x9F)) continue;
    sb.writeCharCode(c);
  }
  return sb.toString();
}

/// Search-query sanitization: control chars stripped, whitespace collapsed,
/// 100-char cap enforced at the validation layer (the widget enforces it too —
/// never trust the widget alone, AC-3).
String sanitizeQuery(String raw) {
  final String collapsed =
      stripControlChars(raw).trim().replaceAll(RegExp(r'\s+'), ' ');
  if (collapsed.length <= AppConstants.searchQueryMaxChars) return collapsed;
  return collapsed.substring(0, AppConstants.searchQueryMaxChars);
}

/// Per-query cache key: normalized (trimmed, lowercased) per PRD §8.1.
String normalizeQueryKey(String query) => sanitizeQuery(query).toLowerCase();

/// FM-12 echo: query echoed back ≤ 50 chars, escaped (control chars stripped).
String escapeQueryEcho(String query) {
  final String clean = stripControlChars(query).trim();
  if (clean.length <= AppConstants.searchNoResultsEchoMaxChars) return clean;
  return clean.substring(0, AppConstants.searchNoResultsEchoMaxChars);
}

/// R-2: full query-string redaction. Keeps scheme/host/path for debuggability;
/// the ENTIRE query string is redacted (the old 40-char truncation preserved
/// `latitude=…` — it is removed).
String sanitizeUri(Uri uri) {
  if (uri.query.isEmpty) return uri.toString();
  final StringBuffer sb = StringBuffer()
    ..write(uri.scheme)
    ..write('://')
    ..write(uri.host);
  if (uri.hasPort) {
    sb
      ..write(':')
      ..write(uri.port);
  }
  sb
    ..write(uri.path)
    ..write('?<query-redacted>');
  return sb.toString();
}

final RegExp _coordParamPattern = RegExp(
  r'(latitude|longitude|lat|lon)\s*=\s*[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?',
  caseSensitive: false,
);
final RegExp _bareCoordPairPattern =
    RegExp(r'[-+]?\d{1,3}\.\d+\s*,\s*[-+]?\d{1,3}\.\d+');

/// Coordinate scrubber for Sentry payloads / log strings (B-2 / HIGH-2):
/// redacts `latitude=`/`longitude=`/`lat=`/`lon=` params and bare
/// `dd.dddd,dd.dddd` pairs anywhere in the string.
String scrubCoordinates(String input) {
  return input
      .replaceAllMapped(
          _coordParamPattern, (Match m) => '${m.group(1)}=<redacted>')
      .replaceAll(_bareCoordPairPattern, '<coords-redacted>');
}

/// Round to 2 decimals at the datasource boundary (ADR-07). Integer-hundredths
/// math also normalizes negative zero.
double roundTo2dp(double value) => (value * 100).round() / 100;

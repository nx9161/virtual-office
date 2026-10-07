// DioException / transport / decode -> AppFailure mapping (C-9).
//
// Mapping ORDER is binding: HTTP status -> transport -> decode -> validation.
// (A 5xx with a Cloudflare HTML error page must map to serverError/FM-2, not
// to schemaViolation/FM-3.)
//
// R-12: 429 maps IMMEDIATELY to AppFailure.rateLimited(retryAfter) — the
// interceptor never holds a Dio call open for Retry-After. Countdown + the
// single scheduled retry live at the controller layer.

import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/network/interceptors/body_size_gate_interceptor.dart';

/// Maps any thrown object to an AppFailure.
///
/// Dio cancellations are NOT failures: they rethrow so callers can
/// distinguish "superseded" (FM-12, silently dropped) from real errors.
AppFailure mapToFailure(Object error) {
  if (error is AppFailure) return error;
  if (error is DioException) return _mapDioException(error);
  if (error is FormatException) {
    // JSON unparseable (PRD FM-3).
    return const AppFailure.schemaViolation('<body>', 'unparseable-json');
  }
  if (error is SocketException) {
    return const AppFailure.networkUnreachable();
  }
  if (error is TimeoutException) {
    return const AppFailure.timeout();
  }
  // Defensive: only the runtime type name, never the message (may embed URIs).
  return AppFailure.unknown('unexpected:${error.runtimeType}');
}

AppFailure _mapDioException(DioException e) {
  // AC-4b oversize marker from the body-size gate interceptor.
  if (e.error is BodyOversize) {
    return const AppFailure.schemaViolation('body', 'oversize');
  }

  // 1) HTTP status first (R-12 / C-9).
  final int? status = e.response?.statusCode;
  if (status == 429) {
    return AppFailure.rateLimited(
        retryAfter: parseRetryAfter(e.response?.headers));
  }
  if (status != null && status >= 500) {
    return AppFailure.serverError(status);
  }
  if (status != null && status >= 400) {
    return AppFailure.apiClientError(status);
  }

  // 2) Transport.
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return const AppFailure.timeout();
    case DioExceptionType.connectionError:
    case DioExceptionType.badCertificate:
      return const AppFailure.networkUnreachable();
    case DioExceptionType.cancel:
      rethrow; // not a failure — caller handles supersede/drop
    case DioExceptionType.badResponse:
      return const AppFailure.schemaViolation('<body>', 'bad-response');
    case DioExceptionType.unknown:
      final Object? inner = e.error;
      if (inner is SocketException) return const AppFailure.networkUnreachable();
      if (inner is TimeoutException) return const AppFailure.timeout();
      return const AppFailure.unknown('dio-unknown');
  }
}

/// Parses the Retry-After header (delta-seconds OR HTTP-date, C-11),
/// capped at 60 s per PRD §8.3. Null when absent/unparseable.
Duration? parseRetryAfter(Headers? headers) {
  if (headers == null) return null;
  final List<String>? values = headers['retry-after'];
  if (values == null || values.isEmpty) return null;
  final String raw = values.first.trim();
  final int? delta = int.tryParse(raw);
  Duration? parsed;
  if (delta != null) {
    parsed = Duration(seconds: delta);
  } else {
    final DateTime? date = _tryParseHttpDate(raw);
    if (date != null) {
      final Duration diff = date.difference(DateTime.now().toUtc());
      parsed = diff.isNegative ? Duration.zero : diff;
    }
  }
  if (parsed == null) return null;
  if (parsed > AppConstants.retryAfterCap) return AppConstants.retryAfterCap;
  return parsed;
}

DateTime? _tryParseHttpDate(String raw) {
  try {
    return HttpDate.parse(raw);
  } on FormatException {
    return null;
  }
}

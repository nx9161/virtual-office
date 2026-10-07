// Sanitized HTTP logging (R-2, HIGH-2).
//
// Release: method + host + status + latency ONLY — never the URI
// (the stale "40-char truncation" text is removed: truncation preserved
// `latitude=…`, so full query redaction replaced it).
// Debug: host + status + latency, URI with the full query redacted.

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:weather_app/core/logging/app_logger.dart';
import 'package:weather_app/core/validation/validators.dart';

class SanitizedLoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['log_start_ms'] = DateTime.now().millisecondsSinceEpoch;
    if (kDebugMode) {
      debugPrint('[http] ${options.method} ${sanitizeUri(options.uri)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    final int? startMs =
        response.requestOptions.extra['log_start_ms'] as int?;
    final int latencyMs = startMs == null
        ? -1
        : DateTime.now().millisecondsSinceEpoch - startMs;
    if (kDebugMode) {
      debugPrint('[http] ${response.statusCode} '
          '${response.requestOptions.uri.host} ${latencyMs}ms');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // Runs AFTER the retry interceptor (registration order), so only the
    // final error is logged — no URI, no query string, no coordinates (R-2).
    AppLogger.httpError(
      method: err.requestOptions.method,
      host: err.requestOptions.uri.host,
      statusCode: err.response?.statusCode,
    );
    handler.next(err);
  }
}

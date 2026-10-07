// HTTP client construction: two Dio instances (forecast + geocoding) sharing
// one interceptor stack (ADR-11), built once via Riverpod providers.
//
// Both instances use `responseType: bytes` so the body-size gate interceptor
// (AC-4b) runs BEFORE `jsonDecode`. Datasources decode explicitly with
// `utf8.decode` inside a try/catch.
//
// Interceptor order (registration):
//   RateLimit -> SanitizedLogging -> Retry -> BodySizeGate
// onResponse/onError run in reverse, so the size gate rejects oversize bodies
// before anything else sees them, and logging records only the final error.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/network/interceptors/body_size_gate_interceptor.dart';
import 'package:weather_app/core/network/interceptors/rate_limit_interceptor.dart';
import 'package:weather_app/core/network/interceptors/retry_interceptor.dart';
import 'package:weather_app/core/network/interceptors/sanitized_logging_interceptor.dart';

Dio _buildDio({required String baseUrl, required Duration minInterval}) {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.sendTimeout,
      // Bytes: the AC-4b size gate runs before decode, always.
      responseType: ResponseType.bytes,
      // B-7 / LOW-2: identify the client for Open-Meteo fair-use attribution.
      headers: <String, String>{'User-Agent': 'weather-app/$appVersion'},
    ),
  );
  dio.interceptors.addAll(<Interceptor>[
    RateLimitInterceptor(
      minIntervalByHost: <String, Duration>{
        Uri.parse(baseUrl).host: minInterval,
      },
    ),
    SanitizedLoggingInterceptor(),
    RetryInterceptor(dio: dio),
    const BodySizeGateInterceptor(),
  ]);
  return dio;
}

/// Forecast API client: https://api.open-meteo.com/v1/forecast
final forecastDioProvider = Provider<Dio>((ref) {
  final Dio dio = _buildDio(
    baseUrl: AppConstants.forecastHost,
    minInterval: AppConstants.forecastMinInterval,
  );
  ref.onDispose(dio.close);
  return dio;
});

/// Geocoding API client: https://geocoding-api.open-meteo.com/v1/search
final geocodingDioProvider = Provider<Dio>((ref) {
  final Dio dio = _buildDio(
    baseUrl: AppConstants.geocodingHost,
    minInterval: AppConstants.geocodingMinInterval,
  );
  ref.onDispose(dio.close);
  return dio;
});

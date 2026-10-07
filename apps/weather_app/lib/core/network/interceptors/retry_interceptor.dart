// Retry interceptor (PRD §8.3, B-7).
//
// Budget: exactly 2 retries, backoff 1 s -> 2 s with ±250 ms jitter
// (thundering-herd guard). Retried ONLY for idempotent GETs on
// timeout / 5xx. NEVER retried: 4xx (429 maps immediately per R-12 — the
// controller owns the countdown + single scheduled retry), validation
// failures, oversize bodies, cancellations.

import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/network/interceptors/body_size_gate_interceptor.dart';

class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Random _random = Random();

  RetryInterceptor({
    required this.dio,
    this.maxRetries = AppConstants.maxRetries,
  });

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final RequestOptions options = err.requestOptions;
    final int attempt = (options.extra['retry_attempt'] as int?) ?? 0;
    if (attempt >= maxRetries || !_isRetryable(err)) {
      handler.next(err);
      return;
    }
    options.extra['retry_attempt'] = attempt + 1;
    await Future<void>.delayed(_backoff(attempt));
    if (options.cancelToken?.isCancelled ?? false) {
      handler.next(err);
      return;
    }
    try {
      final Response<dynamic> response = await dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
    }
  }

  bool _isRetryable(DioException err) {
    if (err.error is BodyOversize) return false;
    if (err.type == DioExceptionType.cancel) return false;
    final int? status = err.response?.statusCode;
    if (status != null) {
      // 5xx only. 429 is mapped immediately by the error mapper (R-12);
      // holding a retry here would violate the single-scheduled-retry rule.
      return status >= 500;
    }
    return err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;
  }

  Duration _backoff(int attempt) {
    final int baseMs =
        AppConstants.retryBaseDelay.inMilliseconds * (1 << attempt);
    final int jitterRange = AppConstants.retryJitter.inMilliseconds;
    final int jitter =
        _random.nextInt(jitterRange * 2 + 1) - jitterRange; // ±250 ms
    final int totalMs = baseMs + jitter;
    return Duration(milliseconds: totalMs < 0 ? 0 : totalMs);
  }
}

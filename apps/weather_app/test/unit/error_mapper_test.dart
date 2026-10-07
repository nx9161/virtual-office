// Error mapper (C-9 order, R-12 429 handling).

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/error/error_mapper.dart';
import 'package:weather_app/core/error/failures.dart';

DioException _httpError(int status, {Map<String, List<String>>? headers}) {
  return DioException(
    requestOptions: RequestOptions(path: '/v1/forecast'),
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/v1/forecast'),
      statusCode: status,
      headers: Headers.fromMap(headers ?? <String, List<String>>{}),
    ),
    type: DioExceptionType.badResponse,
  );
}

void main() {
  group('R-12: 429 maps immediately', () {
    test('429 -> rateLimited with delta-seconds Retry-After', () {
      final AppFailure f = mapToFailure(
          _httpError(429, headers: <String, List<String>>{
        'retry-after': <String>['7']
      }));
      expect(f, isA<RateLimitedFailure>());
      expect((f as RateLimitedFailure).retryAfter, const Duration(seconds: 7));
    });

    test('429 without Retry-After -> rateLimited with null retryAfter', () {
      final AppFailure f = mapToFailure(_httpError(429));
      expect(f, isA<RateLimitedFailure>());
      expect((f as RateLimitedFailure).retryAfter, isNull);
    });

    test('Retry-After is capped at 60 s', () {
      final AppFailure f = mapToFailure(
          _httpError(429, headers: <String, List<String>>{
        'retry-after': <String>['3600']
      }));
      expect((f as RateLimitedFailure).retryAfter, const Duration(seconds: 60));
    });

    test('429 beats transport classification (status first, C-9)', () {
      final AppFailure f = mapToFailure(DioException(
        requestOptions: RequestOptions(path: '/v1/forecast'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/v1/forecast'),
          statusCode: 429,
        ),
        type: DioExceptionType.connectionTimeout,
      ));
      expect(f, isA<RateLimitedFailure>());
    });
  });

  group('C-9 order: status -> transport -> decode', () {
    test('500 -> serverError even with a timeout type', () {
      final AppFailure f = mapToFailure(DioException(
        requestOptions: RequestOptions(path: '/v1/forecast'),
        response: Response<dynamic>(
          requestOptions: RequestOptions(path: '/v1/forecast'),
          statusCode: 503,
        ),
        type: DioExceptionType.receiveTimeout,
      ));
      expect(f, isA<ServerErrorFailure>());
    });

    test('404 -> apiClientError', () {
      expect(mapToFailure(_httpError(404)), isA<ApiClientErrorFailure>());
    });

    test('connection error -> networkUnreachable', () {
      final AppFailure f = mapToFailure(DioException(
        requestOptions: RequestOptions(path: '/v1/forecast'),
        type: DioExceptionType.connectionError,
      ));
      expect(f, isA<NetworkUnreachableFailure>());
    });

    test('FormatException -> schemaViolation', () {
      expect(mapToFailure(const FormatException('bad json')),
          isA<SchemaViolationFailure>());
    });

    test('cancel rethrows (supersede is not a failure)', () {
      final DioException cancel = DioException(
        requestOptions: RequestOptions(path: '/v1/search'),
        type: DioExceptionType.cancel,
      );
      expect(() => mapToFailure(cancel), throwsA(same(cancel)));
    });

    test('unknown errors carry only the runtime type name', () {
      final AppFailure f = mapToFailure(StateError('secret stuff'));
      expect(f, isA<UnknownFailure>());
      expect((f as UnknownFailure).detail, isNot(contains('secret')));
    });
  });
}

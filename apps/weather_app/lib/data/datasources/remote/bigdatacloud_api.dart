// BigDataCloudApi: fallback reverse-geocode (ADR-08).
//
// Chain position: LAST — on-device `geocoding` package first, this only when
// platform geocoding fails, "Current location" label when this fails too
// (FM-17). Receives coarse 2-dp coordinates only; disclosed + named in the
// privacy notice (Tech Law C2/C6).
//
// Shares the hardened interceptor stack (body-size gate, sanitized logging,
// retry, User-Agent) — a third Dio instance with no rate-limit queue of its
// own (single-shot fallback calls don't need pacing).

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/error_mapper.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/network/interceptors/body_size_gate_interceptor.dart';
import 'package:weather_app/core/network/interceptors/retry_interceptor.dart';
import 'package:weather_app/core/network/interceptors/sanitized_logging_interceptor.dart';
import 'package:weather_app/data/models/bigdatacloud_dto.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

class BigDataCloudApi {
  final Dio _dio;

  BigDataCloudApi([Dio? dio]) : _dio = dio ?? _buildDio();

  static Dio _buildDio() {
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.bigDataCloudHost,
        connectTimeout: AppConstants.connectTimeout,
        receiveTimeout: AppConstants.receiveTimeout,
        sendTimeout: AppConstants.sendTimeout,
        responseType: ResponseType.bytes,
        headers: <String, String>{'User-Agent': 'weather-app/$appVersion'},
      ),
    );
    dio.interceptors.addAll(<Interceptor>[
      SanitizedLoggingInterceptor(),
      RetryInterceptor(dio: dio),
      const BodySizeGateInterceptor(),
    ]);
    return dio;
  }

  /// [lat]/[lon] must already be rounded to 2 dp.
  Future<GeoPlace> reverseGeocode({
    required double lat,
    required double lon,
  }) async {
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        '/data/reverse-geocode-client',
        queryParameters: <String, String>{
          'latitude': lat.toStringAsFixed(2),
          'longitude': lon.toStringAsFixed(2),
          'localityLanguage': 'en',
        },
      );
      final List<int>? bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const AppFailure.schemaViolation('bigdatacloud', 'empty-body');
      }
      return BigDataCloudDto.parse(
        json: jsonDecode(utf8.decode(bytes)),
        lat: lat,
        lon: lon,
      );
    } on DioException catch (e) {
      // Failure URIs are covered by the beforeSend scrubber (HIGH-2).
      throw mapToFailure(e);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapToFailure(e);
    }
  }
}

final bigDataCloudApiProvider = Provider<BigDataCloudApi>(
  (ref) {
    final BigDataCloudApi api = BigDataCloudApi();
    ref.onDispose(api._dio.close);
    return api;
  },
);

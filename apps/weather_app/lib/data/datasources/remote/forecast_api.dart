// ForecastApi: GET https://api.open-meteo.com/v1/forecast
//
// Fixed query contract (PRD §7.1 + R-5 uv_index_max) — built by code, never
// by string interpolation of user input. Units are NOT requested from the
// server: native SI is accepted and all conversion is client-side (ADR-04).
// `timezone=auto` aligns hourly slots with the location's civil day.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/error_mapper.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/network/interceptors/rate_limit_interceptor.dart';
import 'package:weather_app/core/network/open_meteo_client.dart';
import 'package:weather_app/core/telemetry/sentry_service.dart';
import 'package:weather_app/data/models/forecast_dto.dart';
import 'package:weather_app/domain/entities/forecast.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

class ForecastApi {
  final Dio _dio;
  final void Function(String field)? onDrift;

  ForecastApi(this._dio, {this.onDrift});

  /// [lat]/[lon] must already be rounded to 2 dp (ADR-07 — rounding happens
  /// once at the datasource boundary, in the repository).
  Future<Forecast> getForecast({
    required double lat,
    required double lon,
    required GeoPlace place,
    required DateTime fetchedAtUtc,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        '/v1/forecast',
        queryParameters: <String, String>{
          'latitude': lat.toStringAsFixed(2),
          'longitude': lon.toStringAsFixed(2),
          'current': AppConstants.currentParams,
          'hourly': AppConstants.hourlyParams,
          'daily': AppConstants.dailyParams,
          'timezone': 'auto',
          'forecast_days': AppConstants.forecastDays.toString(),
        },
        cancelToken: cancelToken,
      );
      final List<int>? bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const AppFailure.schemaViolation('body', 'empty');
      }
      // The AC-4b size gate already ran (responseType: bytes + interceptor);
      // decode here, inside try, so malformed bodies -> FM-3.
      final Object? json = jsonDecode(utf8.decode(bytes));
      return ForecastDto.parse(
        json: json,
        place: place,
        fetchedAtUtc: fetchedAtUtc,
        onDrift: onDrift ?? SentryService.breadcrumbSchemaDrift,
      );
    } on DioException catch (e) {
      // Supersede/cancel is not a failure (FM-12) — propagate for the caller.
      if (e.type == DioExceptionType.cancel || isSuperseded(e)) rethrow;
      throw mapToFailure(e);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapToFailure(e);
    }
  }
}

final forecastApiProvider = Provider<ForecastApi>(
  (ref) => ForecastApi(ref.watch(forecastDioProvider)),
);

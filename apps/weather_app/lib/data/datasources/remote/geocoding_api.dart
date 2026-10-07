// GeocodingApi: GET https://geocoding-api.open-meteo.com/v1/search
//
// The query is percent-encoded by Dio. The 100-char cap is enforced here at
// the validation layer AND at the widget (AC-3 — never trust the widget).

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/error_mapper.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/network/interceptors/rate_limit_interceptor.dart';
import 'package:weather_app/core/network/open_meteo_client.dart';
import 'package:weather_app/core/validation/validators.dart';
import 'package:weather_app/data/models/geocoding_dto.dart';
import 'package:weather_app/domain/entities/geo_place.dart';

class GeocodingApi {
  final Dio _dio;

  GeocodingApi(this._dio);

  Future<List<GeoPlace>> search(String rawQuery, {CancelToken? cancelToken}) async {
    final String query = sanitizeQuery(rawQuery);
    if (query.length < AppConstants.searchMinChars) return <GeoPlace>[];
    try {
      final Response<List<int>> response = await _dio.get<List<int>>(
        '/v1/search',
        queryParameters: <String, String>{
          'name': query,
          'count': AppConstants.geocodingResultsCount.toString(),
          'language': 'en',
          'format': 'json',
        },
        cancelToken: cancelToken,
      );
      final List<int>? bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const AppFailure.schemaViolation('results', 'empty-body');
      }
      return GeocodingDto.parse(jsonDecode(utf8.decode(bytes)));
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel || isSuperseded(e)) rethrow;
      throw mapToFailure(e);
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw mapToFailure(e);
    }
  }
}

final geocodingApiProvider = Provider<GeocodingApi>(
  (ref) => GeocodingApi(ref.watch(geocodingDioProvider)),
);

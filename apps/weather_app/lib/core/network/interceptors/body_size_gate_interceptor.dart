// Response body-size gate (AC-4b — the red team's mandatory finding).
//
// A hostile MITM (R-6: no cert pinning in v1) can serve 100k-entry arrays;
// PRD §7.2 truncation happens AFTER jsonDecode, so the whole body would be
// materialized first (multi-MB transient allocation, main-isolate block,
// plausible OOM on low-end devices).
//
// Mitigation: both Dio instances use `responseType: bytes`; this interceptor
// rejects bodies > 512 KB BEFORE any decode. Oversize ->
// AppFailure.schemaViolation('body', 'oversize') via the error mapper.
// Real payloads are 15–25 KB; 512 KB is ~20x headroom.

import 'package:dio/dio.dart';
import 'package:weather_app/core/config/constants.dart';

/// Marker attached to the DioException for oversize bodies.
class BodyOversize {
  const BodyOversize();
}

class BodySizeGateInterceptor extends Interceptor {
  final int maxBytes;

  const BodySizeGateInterceptor(
      {this.maxBytes = AppConstants.maxResponseBodyBytes});

  @override
  void onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) {
    final Object? data = response.data;
    if (data is List<int> && data.length > maxBytes) {
      handler.reject(
        DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
          error: const BodyOversize(),
        ),
        true,
      );
      return;
    }
    handler.next(response);
  }
}

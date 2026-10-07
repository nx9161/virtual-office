// Body-size gate (AC-4b): bodies > 512 KB are rejected BEFORE jsonDecode.
// Tested through a real Dio with a stub adapter so the interceptor runs in
// its real pipeline position.

import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/network/interceptors/body_size_gate_interceptor.dart';

class _StubAdapter implements HttpClientAdapter {
  final List<int> bytes;

  _StubAdapter(this.bytes);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      ResponseBody.fromBytes(
        bytes,
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>['application/json'],
        },
      );

  @override
  void close({bool force = false}) {}
}

Dio _dioWith(List<int> bytes) {
  final Dio dio = Dio()
    ..options.responseType = ResponseType.bytes
    ..httpClientAdapter = _StubAdapter(bytes)
    ..interceptors.add(const BodySizeGateInterceptor());
  return dio;
}

void main() {
  test('small body passes through', () async {
    final Dio dio = _dioWith(List<int>.filled(1024, 0x7B));
    final Response<List<int>> r =
        await dio.get<List<int>>('https://example.com/');
    expect(r.data, hasLength(1024));
  });

  test('body exactly at the limit passes', () async {
    final Dio dio =
        _dioWith(List<int>.filled(AppConstants.maxResponseBodyBytes, 0x7B));
    final Response<List<int>> r =
        await dio.get<List<int>>('https://example.com/');
    expect(r.data, hasLength(AppConstants.maxResponseBodyBytes));
  });

  test('oversize body is rejected with BodyOversize (never decoded)',
      () async {
    final Dio dio = _dioWith(
        List<int>.filled(AppConstants.maxResponseBodyBytes + 1, 0x5B));
    expect(
      () => dio.get<List<int>>('https://example.com/'),
      throwsA(isA<DioException>().having(
        (DioException e) => e.error,
        'error',
        isA<BodyOversize>(),
      )),
    );
  });

  test('default limit is 512 KB', () {
    expect(AppConstants.maxResponseBodyBytes, 512 * 1024);
  });
}

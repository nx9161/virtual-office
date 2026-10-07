// Per-host rate limiting at the HTTP layer (C-8, PRD §8.4).
//
// Enforces a minimum inter-request interval per host (geocoding 300 ms,
// forecast 1 s safety net). Queues rather than drops, with:
//  * per-key coalescing — newest wins, the older queued request is rejected
//    as superseded (its caller treats it as an FM-12 drop, never an error);
//  * bounded depth (10) — overflow drops the oldest;
//  * cancellation check at dispatch (a CancelToken-cancelled request never
//    fires — the FM-12 supersede path);
//  * paced drain — after a pause, queued requests release one per interval,
//    never as a burst (bursting is what re-triggers 429s).

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:weather_app/core/config/constants.dart';

/// Marker: this request was superseded by a newer identical request (FM-12).
/// Callers treat it as "silently dropped", not a failure.
class SupersededRequest {
  const SupersededRequest();
}

bool isSuperseded(DioException e) => e.error is SupersededRequest;

class _QueuedRequest {
  final String key;
  final String host;
  final RequestOptions options;
  final RequestInterceptorHandler handler;

  _QueuedRequest(this.key, this.host, this.options, this.handler);
}

class RateLimitInterceptor extends Interceptor {
  final Map<String, Duration> minIntervalByHost;
  final int maxQueueDepth;

  final Map<String, DateTime> _lastDispatchByHost = <String, DateTime>{};
  final Map<String, _QueuedRequest> _queuedByKey = <String, _QueuedRequest>{};
  final Map<String, Timer> _pumpByHost = <String, Timer>{};

  RateLimitInterceptor({
    required this.minIntervalByHost,
    this.maxQueueDepth = AppConstants.rateLimitQueueMaxDepth,
  });

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String host = options.uri.host;
    final Duration interval = minIntervalByHost[host] ?? Duration.zero;
    final String key = _dedupeKey(options);

    // Newest wins: supersede an older queued request with the same key.
    final _QueuedRequest? older = _queuedByKey.remove(key);
    if (older != null) {
      older.handler.reject(_cancelled(older.options), true);
    }

    final DateTime now = DateTime.now();
    final DateTime? last = _lastDispatchByHost[host];
    if (interval == Duration.zero ||
        last == null ||
        now.difference(last) >= interval) {
      _dispatch(host, options, handler, now);
      return;
    }

    // Bounded queue: overflow drops the oldest queued request.
    if (_queuedByKey.length >= maxQueueDepth) {
      final String oldestKey = _queuedByKey.keys.first;
      final _QueuedRequest? dropped = _queuedByKey.remove(oldestKey);
      dropped?.handler.reject(_cancelled(dropped.options), true);
    }
    _queuedByKey[key] = _QueuedRequest(key, host, options, handler);
    _ensurePump(host, interval);
  }

  String _dedupeKey(RequestOptions options) =>
      '${options.uri.host}?${options.uri.query}';

  DioException _cancelled(RequestOptions options) => DioException(
        requestOptions: options,
        type: DioExceptionType.cancel,
        error: const SupersededRequest(),
      );

  void _dispatch(String host, RequestOptions options,
      RequestInterceptorHandler handler, DateTime now) {
    // A request cancelled while queued must never hit the network (FM-12).
    if (options.cancelToken?.isCancelled ?? false) {
      handler.reject(
          DioException(
              requestOptions: options, type: DioExceptionType.cancel),
          true);
      return;
    }
    _lastDispatchByHost[host] = now;
    handler.next(options);
  }

  void _ensurePump(String host, Duration interval) {
    if (_pumpByHost.containsKey(host)) return;
    final DateTime? last = _lastDispatchByHost[host];
    final Duration elapsed =
        last == null ? interval : DateTime.now().difference(last);
    final Duration wait = elapsed >= interval ? Duration.zero : interval - elapsed;
    _pumpByHost[host] = Timer(wait, () {
      _pumpByHost.remove(host);
      String? keyToDispatch;
      for (final MapEntry<String, _QueuedRequest> entry
          in _queuedByKey.entries) {
        if (entry.value.host == host) {
          keyToDispatch = entry.key;
          break;
        }
      }
      final _QueuedRequest? queued =
          keyToDispatch == null ? null : _queuedByKey.remove(keyToDispatch);
      if (queued == null) return;
      _dispatch(host, queued.options, queued.handler, DateTime.now());
      // Paced drain: keep pumping while items remain, one per interval.
      if (_queuedByKey.values.any((q) => q.host == host)) {
        _ensurePump(host, interval);
      }
    });
  }
}

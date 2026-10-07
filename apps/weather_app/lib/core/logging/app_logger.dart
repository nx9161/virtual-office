// Sanitized, release-safe logging (R-2).
//
// Release builds log warnings/errors ONLY, shaped as variant + field path +
// reason + value TYPE — never raw values, never URIs, never coordinates.
// Debug builds may log verbose (still sanitized) lines.

import 'package:flutter/foundation.dart';
import 'package:weather_app/core/error/failures.dart';

abstract final class AppLogger {
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('[weather-app] $message');
    }
  }

  /// Release-safe error: tag + error TYPE only. The message is never logged —
  /// it may embed URIs or coordinates (R-2).
  static void error(String tag, Object e) {
    debugPrint('[weather-app][$tag] ${e.runtimeType}');
  }

  /// HTTP error, release-safe: method + host + status. No URI (R-2).
  static void httpError({
    required String method,
    required String host,
    required int? statusCode,
  }) {
    if (kDebugMode) {
      debugPrint('[weather-app][http] $method $host -> $statusCode');
    }
  }

  /// Validation failure, release-safe: field + reason + value type.
  /// Never the raw value (PRD §7.4.2).
  static void validationFailure({
    required String field,
    required String reason,
    required String valueType,
  }) {
    if (kDebugMode) {
      debugPrint(
          '[weather-app][validation] $field: $reason (type=$valueType)');
    }
  }

  /// Failure breadcrumb, release-safe: variant code + optional sanitized
  /// detail. Used for FM-8 schema-drift breadcrumbs (field name only).
  static void failureBreadcrumb(AppFailure failure, {String? detail}) {
    if (kDebugMode) {
      debugPrint('[weather-app][failure] ${failure.code}'
          '${detail == null ? '' : ' $detail'}');
    }
  }
}

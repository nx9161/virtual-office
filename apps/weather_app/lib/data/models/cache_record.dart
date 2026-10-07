// CacheRecord: the unit stored in the Hive `forecast_cache` box.
//
// Privacy shape (B-1 / HIGH-1):
//  * keyHash: SHA-256 hex of the canonical key — the Hive box NEVER holds a
//    plaintext coordinate pair.
//  * payloadJson: echo-free canonical forecast JSON (ForecastDto.encode —
//    entities never hold the lat/lon echo, so stripping is by construction).
//  * source: deviceLocation | search (R-13 — revocation deletes by source
//    without needing the raw coordinates back).
//  * schemaVersion: app upgrades treat mismatches as a miss (C-10.5).
//  * lastAccessUtc: LRU bookkeeping (cap 20, C-10.3).

import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart'
    show CacheSource;

class CacheRecord {
  final String keyHash;
  final DateTime fetchedAtUtc;
  final DateTime lastAccessUtc;
  final CacheSource source;
  final String payloadJson;
  final int schemaVersion;

  const CacheRecord({
    required this.keyHash,
    required this.fetchedAtUtc,
    required this.lastAccessUtc,
    required this.source,
    required this.payloadJson,
    this.schemaVersion = AppConstants.forecastCacheSchemaVersion,
  });

  CacheRecord touch(DateTime now) => CacheRecord(
        keyHash: keyHash,
        fetchedAtUtc: fetchedAtUtc,
        lastAccessUtc: now,
        source: source,
        payloadJson: payloadJson,
        schemaVersion: schemaVersion,
      );

  Map<String, Object?> toJson() => <String, Object?>{
        'keyHash': keyHash,
        'fetchedAtUtc': fetchedAtUtc.toIso8601String(),
        'lastAccessUtc': lastAccessUtc.toIso8601String(),
        'source': source.name,
        'payloadJson': payloadJson,
        'schemaVersion': schemaVersion,
      };

  /// Throws FormatException on corruption -> evict + miss (FM-18).
  factory CacheRecord.fromJson(Map<String, Object?> json) {
    final Object? keyHash = json['keyHash'];
    final Object? fetchedRaw = json['fetchedAtUtc'];
    final Object? accessRaw = json['lastAccessUtc'];
    final Object? sourceRaw = json['source'];
    final Object? payload = json['payloadJson'];
    final Object? versionRaw = json['schemaVersion'];
    if (keyHash is! String ||
        fetchedRaw is! String ||
        accessRaw is! String ||
        sourceRaw is! String ||
        payload is! String ||
        versionRaw is! int) {
      throw const FormatException('CacheRecord malformed');
    }
    final DateTime? fetchedAt = DateTime.tryParse(fetchedRaw);
    final DateTime? lastAccess = DateTime.tryParse(accessRaw);
    if (fetchedAt == null || lastAccess == null) {
      throw const FormatException('CacheRecord bad timestamps');
    }
    CacheSource source = CacheSource.search;
    for (final CacheSource s in CacheSource.values) {
      if (s.name == sourceRaw) source = s;
    }
    return CacheRecord(
      keyHash: keyHash,
      fetchedAtUtc: fetchedAt,
      lastAccessUtc: lastAccess,
      source: source,
      payloadJson: payload,
      schemaVersion: versionRaw,
    );
  }
}

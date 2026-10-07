// ForecastCache: L2 disk cache (Hive CE box `forecast_cache`) + L1 memory.
//
// Privacy shape (B-1 / HIGH-1):
//  * Keys are SHA-256 hex of the canonical key — NO plaintext coordinates at
//    rest (DoD#5 asserts this).
//  * payloadJson is echo-free (ForecastDto.encode; entities never hold echo).
//  * cacheCorrupted reports the key HASH only (R-2).
// TTL ladder (PRD §8.2): fresh ≤10 min -> serve; 10–60 min -> serve +
// background revalidate; 60 min–24 h -> serve ONLY when the network fails
// (labeled offline/stale); >24 h -> evict.
// Write-through: disk FIRST, L1 only on success (ADR-06) — a torn write can
// only leave the old record. Corruption -> evict + miss (FM-18). LRU cap 20
// (C-10.3). Schema version mismatch -> miss (C-10.5). Clock skew clamped
// (C-10.8). Key normalization via integer hundredths (C-10.9).

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:weather_app/core/config/constants.dart';
import 'package:weather_app/core/error/failures.dart';
import 'package:weather_app/core/logging/app_logger.dart';
import 'package:weather_app/core/utils/clock.dart';
import 'package:weather_app/data/models/cache_record.dart';
import 'package:weather_app/domain/entities/geo_place.dart';
import 'package:weather_app/domain/repositories/weather_repository.dart'
    show CacheSource;

enum CacheAge { fresh, swrStale, offlineStale, expired }

class CacheRead {
  final CacheRecord record;
  final CacheAge age;
  final Duration duration;

  const CacheRead({
    required this.record,
    required this.age,
    required this.duration,
  });
}

class ForecastCache {
  static const String boxName = 'forecast_cache';

  final Clock _clock;
  Box<String>? _box;
  final Map<String, CacheRecord> _l1 = <String, CacheRecord>{};

  ForecastCache({Clock clock = const SystemClock()}) : _clock = clock;

  Future<void> init() async {
    try {
      _box = await Hive.openBox<String>(boxName);
    } catch (_) {
      // C-10.4: box-level corruption -> delete + recreate. The cache must
      // never crash the app.
      try {
        await Hive.deleteBoxFromDisk(boxName);
      } catch (_) {}
      _box = await Hive.openBox<String>(boxName);
    }
  }

  /// Canonical raw key (C-10.9): integer hundredths avoid "-0.00" phantom
  /// misses; the `forecast:` prefix namespaces the box (PRD §8.2).
  /// HASHED before persistence (B-1).
  static String rawKeyFor(GeoPlace place) =>
      'forecast:${(place.lat * 100).round()}:${(place.lon * 100).round()}';

  String hashKey(String rawKey) =>
      sha256.convert(utf8.encode(rawKey)).toString();

  CacheRead? read(String rawKey) {
    final String keyHash = hashKey(rawKey);
    final DateTime now = _clock.now().toUtc();
    CacheRecord? record = _l1[keyHash];
    if (record == null) {
      final String? stored = _box?.get(keyHash);
      if (stored == null) return null;
      try {
        record = _decodeRecord(stored);
      } catch (_) {
        // FM-18: evict, treat as miss, report the key HASH only (B-1).
        try {
          _box?.delete(keyHash);
        } catch (_) {}
        AppLogger.failureBreadcrumb(AppFailure.cacheCorrupted(keyHash));
        return null;
      }
      if (record.schemaVersion != AppConstants.forecastCacheSchemaVersion) {
        try {
          _box?.delete(keyHash);
        } catch (_) {}
        return null;
      }
    }
    final Duration rawAge = now.difference(record.fetchedAtUtc);
    final Duration age = rawAge.isNegative ? Duration.zero : rawAge; // C-10.8
    // LRU touch: update access time (disk + memory).
    final CacheRecord touched = record.touch(now);
    _l1[keyHash] = touched;
    try {
      _box?.put(keyHash, jsonEncode(touched.toJson()));
    } catch (_) {}
    final CacheAge bucket = age <= AppConstants.forecastFreshTtl
        ? CacheAge.fresh
        : age <= AppConstants.forecastSwrTtl
            ? CacheAge.swrStale
            : age <= AppConstants.forecastMaxAge
                ? CacheAge.offlineStale
                : CacheAge.expired;
    return CacheRead(record: touched, age: bucket, duration: age);
  }

  Future<void> write({
    required String rawKey,
    required String payloadJson,
    required CacheSource source,
    required DateTime fetchedAtUtc,
  }) async {
    final String keyHash = hashKey(rawKey);
    final DateTime now = _clock.now().toUtc();
    final CacheRecord record = CacheRecord(
      keyHash: keyHash,
      fetchedAtUtc: fetchedAtUtc,
      lastAccessUtc: now,
      source: source,
      payloadJson: payloadJson,
    );
    // Write-through: disk FIRST, L1 only on success (ADR-06).
    try {
      await _box?.put(keyHash, jsonEncode(record.toJson()));
    } catch (_) {
      return;
    }
    _l1[keyHash] = record;
    await _evictLru();
  }

  /// R-13: delete all entries tagged with [source] (by hash — raw
  /// coordinates are never needed back).
  Future<void> deleteBySource(CacheSource source) async {
    final Box<String>? box = _box;
    if (box == null) return;
    final List<String> doomed = <String>[];
    for (final dynamic key in box.keys) {
      if (key is! String) continue;
      final String? stored = box.get(key);
      if (stored == null) continue;
      try {
        final CacheRecord record = _decodeRecord(stored);
        if (record.source == source) doomed.add(key);
      } catch (_) {
        // Corrupt record with unknown source: evict it too (fail safe).
        doomed.add(key);
      }
    }
    for (final String k in doomed) {
      try {
        await box.delete(k);
      } catch (_) {}
      _l1.remove(k);
    }
  }

  Future<void> clear() async {
    _l1.clear();
    try {
      await _box?.clear();
    } catch (_) {}
  }

  /// Deletes a single entry by raw key (FM-18 payload-level eviction).
  Future<void> delete(String rawKey) async {
    final String keyHash = hashKey(rawKey);
    _l1.remove(keyHash);
    try {
      await _box?.delete(keyHash);
    } catch (_) {}
  }

  Future<void> _evictLru() async {
    final Box<String>? box = _box;
    if (box == null || box.length <= AppConstants.forecastCacheLruCap) return;
    final List<MapEntry<String, DateTime>> entries = <MapEntry<String, DateTime>>[];
    for (final dynamic key in box.keys) {
      if (key is! String) continue;
      final String? stored = box.get(key);
      DateTime access = DateTime.fromMillisecondsSinceEpoch(0);
      if (stored != null) {
        try {
          access = _decodeRecord(stored).lastAccessUtc;
        } catch (_) {}
      }
      entries.add(MapEntry<String, DateTime>(key, access));
    }
    entries.sort((a, b) => a.value.compareTo(b.value));
    final int overflow = entries.length - AppConstants.forecastCacheLruCap;
    for (int i = 0; i < overflow; i++) {
      final String k = entries[i].key;
      try {
        await box.delete(k);
      } catch (_) {}
      _l1.remove(k);
    }
  }

  CacheRecord _decodeRecord(String stored) {
    final Object? json = jsonDecode(stored);
    if (json is! Map) throw const FormatException('record not object');
    final Map<String, Object?> m = <String, Object?>{
      for (final dynamic k in json.keys)
        if (k is String) k: json[k],
    };
    return CacheRecord.fromJson(m);
  }
}

/// Bound in main.dart after async init (R-9 composition root).
final forecastCacheProvider = Provider<ForecastCache>(
  (ref) => throw UnimplementedError(
    'forecastCacheProvider is not overridden. Bind after init in main.dart.',
  ),
);
